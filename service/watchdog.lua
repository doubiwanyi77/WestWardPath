local skynet = require "skynet"
local WebSocket = require "http.websocket"
local cluster = require "skynet.cluster"
local sprotoloader = require "sprotoloader"
local sproto = require "sproto"

local CMD = {}
local handler = {}
local routes = {}
local routes_table = {}
local agents = {}
local agent_pool = {}
local conn_state = {}

local pool_size = 10
local min_agents = 3
local heartbeat_timeout = 6000

local host  --c2s:dispatch请求
local send_request   --s2c:编码notification
local c2s_spt  --仅decode .package头


local function pares_route(value)
    local node,service,cmd = tostring(value):match("^([^:]+):([^:]+):([^:]+)$")
    return {node = node, service = service ,cmd = cmd }
end

function CMD.set_routes(r)
    routes = r
    routes_table = {}
    for name, value in pairs(routes) do
        routes_table[name] = pares_route(value)
    end
end

function CMD.get_routes()
    return routes
end

---agent推送通知时走watchdog写socket
---@param fd any
---@param msg any
function CMD.push_to_client(fd,msg)
    local pack = send_request("notification",{message = msg})
    pcall(WebSocket.write,fd,pack,"binary")
end

---远程调用
---@param cmd any
---@param ... unknown
---@return table
local function rpc(cmd,...)
    local route = routes_table[cmd]
    if not route then
        return {ok = false,err = "未知命令"}
    end
    local ok,res = pcall(cluster.call,route.node,"@"..route.service,route.cmd,...)
    if not ok then
        skynet.error("cluster.call失败:"..tostring(res))
        return {ok = false,err = "服务节点未就绪"}
    end
end

---创建agent
function create_agent()
    local agent = skynet.newservice("agent",skynet.self())
    table.insert(agent_pool,agent)
    skynet.error("agent池大小为:"..#agent_pool)
end

---绑定agent,从agent池中取，若无直接新new一个，init期间若断连则立即关闭该agent
---@param fd any
---@param state any
---@param user any
function bind_agent(fd,state,user)
    state.authenticated = true
    state.agent = table.remove(agent_pool)
    if not state.agent then
        state.agent = skynet.newservice("agent",skynet.self())
    end
    agents[fd] = state.agent
    skynet.call(state.agent,"lua","init",fd,user)
    if conn_state[fd] ~= state then
        skynet.send(state.agent,"lua","close")
        agents[fd] = nil
    end
end

function handler.connect(fd)
    conn_state[fd] = {authenticated = false,agent = nil,last_time = skynet.now()}
    skynet.timeout(100,function ()
        if conn_state[fd] then
            local pack = send_request("notification",{message = "已连接，请前往登录或注册"})
            pcall(WebSocket.write,fd,pack,"binary")
        end
    end)
end

function handler.close(fd)
    local state = conn_state[fd]
    conn_state[fd] = nil
    agents[fd] = nil
    if state and state.agent then
        skynet.send(state.agent,"lua","close")
    end
end

function handler.error(fd)
    handler.close(fd)
end

--协议类型
local type_name = {
    [2] = "register",
    [3] = "login",
    [5] = "auth"
}

--bind_agent表示成功后要不要占用一个agent，use_token表示这次的请求是用什么（token or 账号密码）去调db
local allow = {
    login = { bind_agent = true, use_token = false},
    register = {bind_agent = false, use_token = false},
    auth = {bind_agent = true, use_token = true}
}

---获取协议类型
---@param msg any
---@return type_name
function get_sptname(msg) 
    local bin = sproto.unpack(msg)  --去掉包的外壳
    local head = c2s_spt:decode("package",bin)  --解码type和session
    if not head or not head.type then
        return nil
    end
    return type_name[head.type]  
end

function handler.message(fd,msg)
    local state = conn_state[fd]
    if not state then
        return
    end
    state.last_time = skynet.now()
    --1.未认证时
    if not state.authenticated then
        local name = get_sptname(msg)
        if not allow[name] then
            local pack = send_request("notification",{message = "请先登录"})
            pcall(WebSocket.write,fd,pack,"binary")
            return
        end
        --路由走"handler_c2s",在db中获取uid和username
        local route = routes_table["handle_c2s"]
        local ok, res = pcall(cluster.call,route.node,"@"..route.service,route.cmd,msg)  --res来自服务节点，避免网关解包

        --服务节点未启或路由为空
        if not ok or type(res) ~= "table" then
            local pack = send_request("notification",{message = "服务节点未启动"})
            pcall(WebSocket.write,fd,pack,"binary")
            return
        end

        if res.ok and allow[name].bind_agent then  
            bind_agent(fd,state,res)
        end
        if res.pack then
            pcall(WebSocket.write,fd,res.pack,"binary")
        end
        return
    end

    local pack = skynet.call(state.agent,"lua","handle_message",msg)
    if pack then
        pcall(WebSocket.write,fd,pack,"binary")
    end

end

function CMD.open(fd,addr)
    skynet.fork(function ()
        local ok,err = WebSocket.accept(fd,handler,"ws",addr)
        if not ok then
            skynet.error("WebSocket accepet failed:"..tostring(err))
        end
    end)
end

skynet.start(function ()
    c2s_spt = sprotoloader.load(1)
    host = c2s_spt:host "package"
    send_request = host:attach(sprotoloader.load(2))
    skynet.dispatch("lua",function (_,_,cmd,...)
        local f = assert(CMD[cmd],tostring(cmd))
        skynet.retpack(f(...))
    end)

    for _ = 1, pool_size, 1 do
        create_agent()
    end

    skynet.fork(function ()
        while true do
            if #agent_pool < min_agents then
                create_agent()
            end
            skynet.sleep(500)
        end
    end)
end)