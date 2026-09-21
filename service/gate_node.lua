local skynet = require "skynet"
local cluster = require "skynet.cluster"
local registry = require "registry"

skynet.start(function ()
    skynet.uniqueservice("protoloader")
    skynet.error("西游之路2.0网关节点启动")

    registry.init_redis(skynet.getenv("redis_host"),skynet.getenv("redis_port"))

    local node = skynet.getenv("node_name") or "gate_node"
    local host = skynet.getenv("cluster_host") or "127.0.0.1"
    local port = tonumber(skynet.getenv("cluster_port")) or 2530

    registry.register_node(node, host, port)
    cluster.reload(registry.node_list())
    cluster.open(node)

    skynet.newservice("web")
    local watchdog = skynet.newservice("watchdog")
    skynet.call(watchdog,"lua","set_routes",registry.route_list())
    skynet.newservice("gated",watchdog)

    skynet.fork(function ()
        while true do
            registry.heartbeat(node)
            cluster.reload(registry.node_list())
            skynet.call(watchdog,"lua","set_routes",registry.route_list())
            skynet.sleep(100)
        end
    end)
end)
