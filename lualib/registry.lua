local skynet = require "skynet"
local redis = require "skynet.db.redis"
local mysql = require "skynet.db.mysql"

local mysql_conn
local redis_conn
local registry = {}

local TTL = 30
local node_key = "wp2:cluster:nodes"
local route_key = "wp2:cluster:routes"


function registry.init_mysql(database,user,pwd,host,port)
    mysql_conn = mysql.connect{
        database = database,
        user = user,
        password = pwd,
        host = host,
        port = tonumber(port)
    }
    assert(mysql_conn,"mysql连接失败!")
    return mysql_conn
end

function registry.init_redis(host,port,db_index)
    redis_conn = redis.connect{
        host = host,
        port = tonumber(port),
        db = db_index
    }
    assert(redis_conn,"redis连接失败")
    return redis_conn
end

---给account用
---@return unknown
function registry.mysql()
    return mysql_conn
end

function registry.redis()
    return redis_conn 
end

---注册节点
---@param node_name any
---@param host any
---@param port any
function registry.register_node(node_name,host,port)
    redis_conn:hset(node_key,node_name,host..":"..tostring(port))
    redis_conn:set(node_key..":hb:"..node_name,"1","EX",TTL)
end

---返回节点列表地址
---@return table
function registry.node_list()
    local list = redis_conn:hgetall(node_key) or {}
    local config = {}
    for i = 1, #list, 2 do
        local name,addr = list[i],list[i+1]
        if redis_conn:exists(node_key..":hb:"..name) ~=0 then
            config[name] = addr
        end
    end
    return config
end

function registry.register_route(route,node,service,cmd)
    return redis_conn:hset(route_key,route,node..":"..service..":"..cmd)
end

---查询路由命令表
---@return config
function registry.route_list()
    local list = redis_conn:hgetall(route_key) or {}
    local config = {}
    for i = 1, #list, 2 do
        config[list[i]] = list[i+1]
    end
    return config
end

function registry.heartbeat(name)
    redis_conn:set(node_key..":hb:"..name,"1","EX",TTL)
end

return registry