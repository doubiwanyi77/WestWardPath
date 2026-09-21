# 西游之路· Westward Path

基于 [Skynet](https://github.com/cloudwu/skynet) 的双节点卡牌闯关：网页登录、点将组队、四关打首领。协议用 [sproto](https://github.com/cloudwu/sproto)，静态页由网关 HTTP 提供，对局走 WebSocket。

This is a local two-node Skynet demo (Lua server + browser client). See **How to run** below.

## 需要什么环境

- Linux（当前按本机路径编写）
- 已编译的 Skynet，且能执行 `skynet` 二进制
- Docker + Docker Compose（MySQL 8、Redis 7）
- 两个终端：一个跑服务节点，一个跑网关节点

默认假设 Skynet 在 `/home/zp/skynet`。若你的路径不同，改这三处：

- `Makefile` 里的 `SKYNET_ROOT`
- `config.service_node`、`config.gate_node` 里的 `skynet_root`

也可不改文件，启动时带变量：

```bash
make run-service SKYNET_ROOT=/path/to/skynet
make run-gate SKYNET_ROOT=/path/to/skynet
```

配置文件里的 `skynet_root` 仍须指向同一份 Skynet（Skynet 配置是 Lua，不能用 `os.getenv` 读环境变量）。

## 怎么跑

在仓库根目录：

```bash
# 1. 起 MySQL / Redis（首次会按 sql/schema.sql 建库）
make deps

# 2. 等数据库健康后再起服务节点（账号、排行、对局逻辑）
make run-service

# 3. 另开一个终端，起网关（网页 + WebSocket）
make run-gate
```

浏览器打开 **http://127.0.0.1:8080** ，注册或登录即可。

| 用途 | 地址 |
| --- | --- |
| 网页 | `http://127.0.0.1:8080` |
| WebSocket | `ws://127.0.0.1:9948` |
| 服务节点 cluster | `127.0.0.1:2529` |
| 网关节点 cluster | `127.0.0.1:2530` |
| MySQL | `127.0.0.1:3306`（库/用户/密码均为 `westwardpath2`，root 密码见 `docker-compose.yml`） |
| Redis | `127.0.0.1:6379` |

停数据库：`make down`。

**不要用** 单独的 `make run`：它会走旧的单进程 `config` + `service/main.lua`，不是现在的双节点。

立绘和登录图放在 `www/img/`（例如 `login-hero.png`、`table-felt.png`、各武将 jpg）。缺图时页面仍能玩，只是没有美术。

## 玩法

1. 注册账号，进大厅点主驾和最多 3 名助战。
2. 凑齐羁绊标签会有全队加成；角色仙术写在 `lualib/game_data.lua`。
3. 开始西行：自己出牌，助战由服务端代打。牌只有杀 / 闪 / 桃。
4. 四关首领，关间商店用银两请法宝。通关或落败记分，大厅有功德榜。
5. 未打完的对局可在大厅「继续」。

## 目录

```
config.service_node   服务节点 Skynet 配置
config.gate_node      网关节点 Skynet 配置
config                旧单进程配置，日常请忽略
Makefile
docker-compose.yml    本地 MySQL + Redis
sql/schema.sql        users、run_logs
service/              Skynet 服务
  service_node.lua    注册路由、起 account / battle
  gate_node.lua       HTTP + WS，把请求转到服务节点
  account.lua         注册登录大厅排行
  battle.lua          对局会话，转调 lualib/battle.lua
lualib/
  battle.lua          对局规则
  game_data.lua       武将、羁绊、首领、商店、牌堆
  proto.lua           sproto 协议（须与 www/app.js 中的文本一致）
  registry.lua        Redis 里的节点与路由
www/                  前端
```

客户端协议字符串写在 `www/app.js` 顶部，和 `lualib/proto.lua` 成对维护；改协议要两边一起改。

## 许可与注意

- 仓库尚未选定开源许可证。发布前请自行加入 `LICENSE`。
- `docker-compose.yml` 和 Skynet 配置里是**本地演示用**数据库口令，不要原样上公网。
- 账号密码用 Skynet `crypt.hashkey` 做摘要，仅适合练习，不适合生产。
- 西游人物名、故事为公众文化素材；仓库内美术若非你本人制作，开源前请确认授权。
