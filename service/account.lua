local skynet = require "skynet"
local crypt = require "skynet.crypt"
local registry = require "registry"
local sprotoloader = require "sprotoloader"
local cluster = require "skynet.cluster"
local game_data = require "game_data"

local mysql_conn
local user_TTL = 1800  --用户缓存半小时
local session_TTL = 3600    --登录session一小时
local redis_conn

local CMD = {}


local function user_key(username)
    return "wp2:user:"..username
end

local function session_key(token)
    return "wp2:session:"..token
end

---缓存
---@param user any
local function cache_user(user)
    local key = user_key(user.username)
    redis_conn:hmset(key,
        "uid",tostring(user.uid),
        "username",user.username,
        "password",user.password,
        "best_score",tostring(user.best_score)
)
    redis_conn:expire(key,user_TTL)
end

---通过用户名先查找缓存，缓存未命中再查数据库
---@param username any
---@return table
local function get_user(username)
    local key = user_key(username)
    if redis_conn:exists(key) ~=0 then
        local uid = redis_conn:hget(key,"uid")
        if uid then
            return {
                uid = tonumber(uid),
                username = redis_conn:hget(key,"username"),
                password = redis_conn:hget(key,"password"),
                best_score = tonumber(redis_conn:hget(key,"best_score"))
            }
        end
    end
    --缓存未命中，查询数据库
    local stmt = mysql_conn:prepare("select id,username,password,best_score from users where username = ? limit 1")
    local res = mysql_conn:execute(stmt,username)
    mysql_conn:stmt_close(stmt)

    if res.badresult or type(res) ~= "table" or #res == 0 then
        return nil
    end
    local row = res[1]
    local user = {
        uid = tonumber(row.id),
        username = row.username,
        password = row.password,
        best_score = tonumber(row.best_score)
    }
    --回填缓存
    cache_user(user)
    return user
    
end


---密码哈希处理
---@param password any
---@return 哈希后十六机制字符串的pssword
local function hash_password(password)
    return crypt.hexencode(crypt.hashkey(password))
end

---注册
---@param username any
---@param password any
---@return table
function CMD.register(username,password)
    if type(username) ~= "string" or username == "" then
        return {ok = false,err = "请输入用户名"}
    end
    if type(password) ~= "string" or password == "" then
        return {ok = false,err = "请输入正确密码"}
    end

    local stmt = mysql_conn:prepare("insert into users (username,password) value (?,?)")
    local res = mysql_conn:execute(stmt,username,hash_password(password))
    mysql_conn:stmt_close(stmt)

    if res.badresult then
        if res.errno == 1062 then
            return { ok = false,err = "用户名已存在,请前往的登录"}
        end
        return {ok = false,err = tostring(res.err)}
    end

    return {ok = true,uid = res.insert_id,username = username,best_score = 0}
end

---登录
---@param username any
---@param password any
---@return table
function CMD.login(username,password)
    local user = get_user(username)
    if not user then
        return {ok = false,err = "用户名不存在"}
    end
    if user.password ~= hash_password(password) then
        return {ok = false,err = "密码错误"}
    end
    --生成随即token给重连auth用
    local token = crypt.hexencode(crypt.randomkey())
    local skey = session_key(token)
    redis_conn : hmset(skey,"uid",tostring(user.uid),"username",user.username)
    redis_conn : expire(skey,session_TTL)
    return {
        ok = true,
        uid = user.uid,
        username = user.username,
        best_score = user.best_score,
        token = token
    }
end

---根据uid在数据库中查找用户
---@param uid any
---@return nil
function CMD.get_userByid(uid)
    local stmt = mysql_conn:prepare("select id,username,best_score from users where id = ? limit 1")
    local res = mysql_conn:execute(stmt,uid)
    mysql_conn:stmt_close(stmt)

    if type(res) ~= "table" or #res == 0 then
        return nil
    end

    local user = res[1]
    return {
        uid = tonumber(user.id),
        username = user.username,
        best_score = tonumber(user.best_score) or 0
    }
end

---房间
---@param uid any
---@return table
function CMD.lobby(uid)
    local user = CMD.get_userByid(uid)
    local node = skynet.getenv("node_name") or "service_node"
    local ok,has = pcall(cluster.call,node,"@battle","has_run",uid)
    local generals = {}
    for _, id in ipairs(game_data.general_order or {}) do
        local g = game_data.generals[id]
        if g then
            generals[#generals + 1] = {
                id = g.id,
                name = g.name,
                max_hp = g.max_hp,
                desc = g.desc or "",
            }
        end
    end
    return {
        ok = true,
        username = user and user.username,
        best_score = user and user.best_score or 0,
        has_run = ok and has == true,   --未完对局为true
        generals = generals,
    }
end

---功德榜：通过uid获取分数高的前20名逐一放进数组中
---@param uid any
function CMD.rank(uid)
    uid = tonumber(uid)
    local user = CMD.get_userByid(uid)
    local best = user and user.best_score or 0

    --最高分按降序取前20名，同分按用户名升序
    local stmt = mysql_conn:prepare(
        "select id,username,best_score from users where best_score > 0 order by best_score desc,username asc limit 20"
    )
    local res = mysql_conn:execute(stmt)
    mysql_conn:stmt_close(stmt)

    local rows = {}
    if type(res) == "table" then
        for i, row in ipairs(res) do
            rows[#rows + 1] = {
                rank = i,
                username = row.username,
                score = row.best_score or 0,
                is_self = row.id == uid
            }
        end
    end

    local my_rank  --自己的名次，即使未进前20也要显示自身名词及最高分数
    if best > 0 and user then
        local q = mysql_conn:prepare(  
            "select count(*) as n from users where best_score > 0 and (best_score > ?) or (best_score = ? and username < ?)"
        )
        local res = mysql_conn:execute(q,best,best,user.username)--三个 ？ 分别是比我分高的、同分、用户名比我小的
        mysql_conn:stmt_close(q)
        if type(res) == "table" and res[1] then  --count查询成功时第一行有字段n即排自己前面的人数
            my_rank = (tonumber(res[1].n) or 0) + 1  --前面的人数+1即为自己的名词
        end
    end
    return {
        ok = true,
        my_rank = my_rank,
        best_score = best,  --自己的最高分，即使未上榜也要显示
        rank = rows  --前20行
    }
end

---一局结束后写入战报run_logs,若刷新最高分则更新best_core和redis缓存
---@param uid any
---@param args any
---@return table
function CMD.finish_run(uid,args)
    uid = tonumber(uid)
    args = args or {}
    local score = tonumber(args.score) or 0
    local win = args.win and 1 or 0
    local gid = args.general_id or ""

    local insert = mysql_conn:prepare(
        "insert into run_logs (uid,general_id,score,win) values (?,?,?,?)"
    )
    local res = mysql_conn:execute(insert,uid,gid,score,win)
    mysql_conn:stmt_close(insert)
    if type(res) == "table" and res.badresult then
        skynet.error("finish_run insert 失败:"..tostring(res.err))
    end
    local user = CMD.get_userByid(uid)
    if user and score > (user.best_score or 0) then
        local up = mysql_conn:prepare(
            "update users set best_score = ? where id = ?"
        )
        local res1 = mysql_conn:execute(up,score,uid)
        if res1.badresult then
            skynet.error("finish_run update 失败:"..tostring(res1.err))
        end
        mysql_conn:stmt_close(up)
        redis_conn:hset(user_key(user.username),"best_score",tostring(score)) --最高分记录缓存回写
        redis_conn:expire(user_key(user.username),user_TTL)
    end
    return {ok = true}
end

---处理token
---@param token any
---@return uid,username
function CMD.auth(token)
    if not token then
        return {ok = false,err = "缺少token"}
    end
    local skey = session_key(token)
    if redis_conn:exists(skey) == 0 then
        return {ok = false,err = "token已过期或不存在"}
    end

    local uid = redis_conn:hget(skey,"uid")
    local username = redis_conn:hget(skey,"username")
    redis_conn:expire(skey,session_TTL)
    return {ok = true,uid = tonumber(uid),username = username}
end

---在此处解整包并编码回包
---@param msg string
---@return table {ok,uid,username,pack}
function CMD.handle_c2s(msg)
    local ok,ptype,cmd,args,response = pcall(host.dispatch,host,msg)
    if not ok then
        return {ok = false,err = "错误协议",pack = nil}
    end
    if ptype ~= "REQUEST" then
        return {ok = false,err = "非法包",pack = nil}
    end

    local res
    if cmd == "login" then
        res = CMD.login(args.username,args.password)
    elseif cmd == "register" then
        res = CMD.register(args.username,args.password)
    elseif cmd == "auth" then
        res = CMD.auth(args.token)
    else
        res = {ok = false,err = "未知命令"}
    end
    local pack
    if response then
        pack = response(res)
    end

    return {ok = res.ok,uid = res.uid,username = res.username,pack = pack}
end

skynet.start(function ()
    mysql_conn = registry.init_mysql(
        skynet.getenv("mysql_database"),
        skynet.getenv("mysql_user"),
        skynet.getenv("mysql_password"),
        skynet.getenv("mysql_host"),
        skynet.getenv("mysql_port")
    )

    redis_conn = registry.init_redis(
        skynet.getenv("redis_host"),
        skynet.getenv("redis_port")
    )
     host = sprotoloader.load(1):host "package"
    skynet.dispatch("lua",function (_,_,cmd,...)
        local f = assert(CMD[cmd],tostring(cmd).."不存在")
        skynet.retpack(f(...))
    end)
end)