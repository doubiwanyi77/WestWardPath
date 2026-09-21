local skynet = require "skynet"
local socket = require "skynet.socket"
local registry = require "registry"

local watchdog = tonumber(...)
local port = tonumber(skynet.getenv("ws_port")) or 9948

skynet.start(function ()
    local listen = socket.listen("0.0.0.0",port)
    skynet.error("WebSocket listen on:"..port)
    
    socket.start(listen,function (fd,addr)
        skynet.error("新连接 "..fd.." "..tostring(addr))
        skynet.call(watchdog,"lua","open",fd,addr)
    end)
end)