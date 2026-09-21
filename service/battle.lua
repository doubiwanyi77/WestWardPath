local skynet = require "skynet"
local game_data = require "game_data"
local Battle = require "battle"
local cluster = require "skynet.cluster"

local runs = {}    --内存表，暂不写入MYSQL
local CMD = {}

local function fail(err)
    return {ok = false,err = err or "失败"}
end

---获取uid的旧对局
---@param uid any
---@return nil
---@return table
local function get_run(uid)
    local b = runs[tonumber(uid)]
    if not b then
        return nil,fail("没有进行中的对局")
    end
    return b
end

---对局phase为“ended”时，通知账号服务写run_logs和刷新最高分
---@param uid any
---@param snap any
---@return any
local function finish_if_ended(uid,snap)
    if not snap or not snap.ok then --失败包不用写库
        return snap
    end
    if snap.phase ~= "ended" or not snap.result then --还没到终局
        return snap
    end
    local node = skynet.getenv("node_name") or "service_node"
    local b = runs[tonumber(uid)]
    if b and b.settled then     --已经写过库
        return snap
    end
    if b then
        b.settled = true
    end
    pcall(cluster.call,node,"@account","finish_run",uid,{
        score = snap.score,  --本局总分
        win = snap.result.win, 
        general_id = b and b.general_id or "", 
    })
    return snap
end

---规则层成功返回snapshot表
---@param snap any
---@param err any
---@return table
local function wrap(uid,snap,err)
    if not snap then
        return fail(err)
    end
    return finish_if_ended(uid,snap)
end


---新建对局，覆盖掉uid原来的旧对局
---@param uid any
---@param args any
---@return table
function CMD.start_run(uid,args)
    uid = tonumber(uid)
    args = args or {}
    local gid = args.general_id
    if not game_data.generals[gid] then
        return fail("未知仙佛")
    end
    local ally_ids = {}
    for _, id in ipairs(args.ally_ids or {}) do
        if id ~= gid and game_data.generals[id] then
            ally_ids[#ally_ids + 1] = id
        end
        if #ally_ids >= 3 then
            break
        end
    end
    local b = Battle.new({
        uid = uid,
        general_id = gid,
        ally_ids = ally_ids,
    })
    runs[uid] = b
    return b:snapshot()
end

---大厅点击继续对局
---@param uid any
---@return table
function CMD.resume_run(uid)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return b:snapshot()
end

---出牌阶段打出一张牌
---@param uid any
---@param args any
---@return table
function CMD.play_card(uid,args)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return wrap(uid,b:play_card(args and args.card_id))
end

---结束出牌
---@param uid any
---@return table
function CMD.end_play(uid)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return wrap(uid,b:end_play())
end

---弃牌阶段
---@param uid any
---@param args any
---@return table
function CMD.discard(uid,args)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return wrap(uid,b:discard_cards(args and args.card_ids))
end

---响应出牌
---@param uid any
---@param args any
---@return unknown
function CMD.respond(uid,args)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return wrap(uid,b:respond(args and args.card_id))
end

---商店购买法宝
---@param uid any
---@param args any
---@return table
function CMD.buy(uid,args)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return wrap(uid,b:buy(args and args.item_id))
end

---商店点击下一关,stage+1然后再setup_stage
---@param uid any
---@return table
function CMD.next_stage(uid)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return wrap(uid,b:next_stage())
end

---主动技（天眼：先看牌再弃一张）
function CMD.use_skill(uid,args)
    local b,err = get_run(uid)
    if not b then
        return err
    end
    return wrap(uid,b:use_skill(args and args.skill_id, args and args.card_id))
end

---给大厅里继续对局用，已结束的局不算未完
---@param uid any
---@return unknown
function CMD.has_run(uid)
    local b = runs[tonumber(uid)]
    if not b then
        return false
    end
    return b.phase ~= "ended"
end

skynet.start(function ()
    skynet.dispatch("lua",function (_,_,cmd,...)
        local f = assert(CMD[cmd],tostring(cmd).."不存在")
        skynet.retpack(f(...))
    end)
end)