local skynet = require "skynet"
local cluster = require "skynet.cluster"
local registry = require "registry"

skynet.start(function ()
    skynet.error("西游之路2.0服务节点启动")

    registry.init_redis(skynet.getenv("redis_host"),skynet.getenv("redis_port"))
    registry.init_mysql(
        skynet.getenv("mysql_database"),
        skynet.getenv("mysql_user"),
        skynet.getenv("mysql_password"),
        skynet.getenv("mysql_host"),
        skynet.getenv("mysql_port")
    )

    local node = skynet.getenv("node_name") or "service_node"
    local host = skynet.getenv("cluster_host") or "127.0.0.1"
    local port = tonumber(skynet.getenv("cluster_port")) or 2529
    registry.register_node(node,host,port)

    --数据库路由
    registry.register_route("register",node,"account","register")
    registry.register_route("login",node,"account","login")
    registry.register_route("lobby",node,"account","lobby")
    registry.register_route("rank",node,"account","rank")
    registry.register_route("handle_c2s",node,"account","handle_c2s")

    --对局路由
    registry.register_route("start_run",node,"battle","start_run")
    registry.register_route("resume_run",node,"battle","resume_run")  --大厅点继续未完对局
    registry.register_route("play_card",node,"battle","play_card")  --打出一张手牌
    registry.register_route("end_play",node,"battle","end_play")
    registry.register_route("discard",node,"battle","discard")
    registry.register_route("respond",node,"battle","respond")  --响应出牌
    registry.register_route("buy",node,"battle","buy")
    registry.register_route("next_stage",node,"battle","next_stage")
    registry.register_route("use_skill",node,"battle","use_skill")  --杨戬天眼等主动技

    cluster.reload(registry.node_list())
    skynet.uniqueservice("protoloader")
    local account = skynet.uniqueservice("account")
    local battle = skynet.uniqueservice("battle")
    cluster.register("account",account)
    cluster.register("battle",battle)
    cluster.open(node)

    skynet.fork(function ()
        while true do
            registry.heartbeat(node)
            cluster.reload(registry.node_list())
            skynet.sleep(100)
        end
    end)

end)