local skynet = require "skynet"
local cluster = require "skynet.cluster"
local sprotoloader = require "sprotoloader"

local watchdog = tonumber(...)  --newservice("agent", watchdog地址) 时，... 就是 watchdog

local fd,uid,username
local routes_table = {}
local host
local CMD = {}

---解析路由
---@param value any
---@return node,service,cmd
local function pares_route(value)
    local node,service,cmd = tostring(value):match("^([^:]+):([^:]+):([^:]+)$")
    return {node = node,service = service,cmd = cmd}
end

---已登录后带uid去调服务节点，lobby不需要再传密码
---@param name any
---@param args any
---@return table
local function handle_request(name,args)
    local route = routes_table[name]
    if not route then
        return {ok = false,err = "未知命令"}
    end
    if name == "lobby" or name == "rank" then
        return cluster.call(route.node,"@"..route.service,route.cmd,uid)
    end
    return cluster.call(route.node,"@"..route.service,route.cmd,uid,args)
end

---初始化路由表
---@param fd any
---@param user any
function CMD.init(cilent_fd,user)
    fd = cilent_fd
    uid = user.uid
    username = user.username

    local routes = skynet.call(watchdog,"lua","get_routes")
    for name, value in pairs(routes) do
        routes_table[name] = pares_route(value)
    end
    skynet.error(string.format("agent init fd=%s uid=%s", tostring(fd), tostring(uid)))
end

---处理消息，不解websocket,只解sproto,编码后的二进制return给watchdo去write
---@param msg any
---@return unknown
function CMD.handle_message(msg)
    local ptype,name,args,response = host:dispatch(msg)
    if ptype ~= "REQUEST" then
        return
    end
    local ok,res = pcall(handle_request,name,args)
    if not ok then
        skynet.error("agent处理失败："..tostring(res))
        res = {ok = false,err = "处理失败"}
    end
    if response then
        return response(res)
    end
end

function CMD.close()
    skynet.fork(function ()
        skynet.exit()
    end)
end

skynet.start(function ()
    host = sprotoloader.load(1):host "package"
    skynet.dispatch("lua",function (_,_,cmd,...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        end
    end)
end)