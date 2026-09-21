local skynet = require "skynet"

skynet.start(function ()
    skynet.error("西游之路2.0 Westward Path 2.0 启动")
    skynet.uniqueservice("protoloader")
    skynet.newservice("web")

    local watchdog = skynet.newservice("watchdog")
    skynet.newservice("gated",watchdog)
end)