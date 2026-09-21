local data = require "game_data"

local Battle = {}  --一局对局
Battle.__index = Battle

---洗牌，从末张到第二张，然后获取随机下标牌并进行交换
---@param arr any
local function shuffle(arr)
    for i = #arr, 2, -1 do
        local j = math.random(i)
        arr[i],arr[j] = arr[j],arr[i]
    end
end

---在手牌中找id，
---@param hand any
---@param card_id any
---@return 下标i
---@return 找到的牌c
local function find_id(hand,card_id)
    for i, c in ipairs(hand) do
        if c.id == card_id then
            return i, c
        end
    end
end

---在手牌里查找第一张匹配的牌（首领自动出闪/桃）时用
---@param hand any 
---@param type any
---@return 下标i
---@return 找到的牌c
local function find_type(hand,cardName)
    for i, c in ipairs(hand) do
        if c.type == cardName then
            return i,c
        end
    end
end

---创建一局游戏
---@param args any
---@return table
function Battle.new(args)
    local self = setmetatable({},Battle)  --空表，方法从Battle中继承
    self.uid = args.uid
    self.general_id = args.general_id  --主将id
    self.ally_ids = args.ally_ids or {}  -- 开局选定的助战 id，每关 setup_stage 都用它
    self.card_seq = 0
    self.stage = 1
    self.silver = 0
    self.score = 0
    self.log = {}
    self.bought = {}  --已购买强化
    math.randomseed(os.time() + (args.uid or 0) * 31)  --用时间和uid作为种子，避免每局的牌序一样
    self:setup_stage()  --洗牌，玩家进场及首领，开局摸牌，进入玩家回合
    return self
end

---造一张牌
---@param cardName any
---@return table
function Battle:make_card(cardName)
    self.card_seq = self.card_seq + 1
    return {
        id = self.card_seq,
        type = cardName,
        name = data.card_name[cardName]
    }
end

---生成整副牌并打乱
---@return table
function Battle:build_deck()
    local deck = {}  --空牌堆
    for cardName, n in pairs(data.card_counts) do
        for _ = 1, n do          --造n张同类型的牌
            deck[#deck+1] = self:make_card(cardName)
        end
    end
    shuffle(deck)  --打乱牌堆
    return deck
end

---加入一条战报；超出上限时丢掉最旧的一行（前端用内容重叠来识别新增，不能只比长度）
function Battle:add_log(msg)
    self.log[#self.log+1] = msg
    if #self.log > 200 then
        table.remove(self.log,1)
    end
end

---根据玩家所选主将及助战激活羁绊
---@return bond_list 羁绊列表
function Battle:active_bonds()
    local count = {}
    local function add_tags(gid)
        local g = data.generals[gid]
        if not g or not g.tags then
            return
        end
        for _, tag in ipairs(g.tags) do
            count[tag] = (count[tag] or 0) +1
        end
    end
    add_tags(self.general_id)
    for _, aid in ipairs(self.ally_ids or {}) do
        add_tags(aid)
    end
    local bond_list = {}
    for _, bond in ipairs(data.bonds or {}) do
        local n = count[bond.tag] or 0
        local best
        for _, value in ipairs(bond.thresholds or {}) do
            if n >= value.count then    --覆盖羁绊buff,达到人数够的档
                best = value
            end
        end
        if best then
            bond_list[#bond_list+1] = {
                id = bond.id,
                name = bond.name,
                mods = best.mods
            }
        end
    end
    return bond_list
end

---将已买过的强化加成合成一张修正表
---@return bfs 玩家的buff表
function Battle:buffes()
    local bfs = {sha_damage = 0,extra_hp = 0,extra_draw = 0,tao_heal = 0, extra_sha = 0,extra_hand = 0,open_hand = 0,draw_on_sha = 0}
    --装备加成
    for _, product in ipairs(data.shop_items) do
        if self.bought[product.id] then  --通过id判断玩家买了哪间商品
            bfs[product.key] = (bfs[product.key] or 0) + product.add  --累加玩家已购买的装备buff
        end
    end
    --羁绊加成
    for _, bond in ipairs(self:active_bonds()) do
        for key, value in pairs(bond.mods or {}) do
            bfs[key] = (bfs[key] or 0) + value
        end
    end
    return bfs
end

---使用杀的上限，若为boos取数据表中的设定，若为玩家则先固定为1
---@param u any
---@return integer
function Battle:sha_limit(u)
    if u.is_boos then
        return u.sha_limit or 1
    end
    return 1 + self:buffes().extra_sha
end

---杀的伤害，根据boss的设定和玩家是否购买了增强装备设定
---@param u any
---@return integer
function Battle:sha_damage(u)
    if u.is_boos then
        return u.sha_damage or 1
    end
    return 1 + self:buffes().sha_damage
end

---桃的恢复值，boss固定1,玩家根据装备加成来定
---@param u any
---@return integer
function Battle:tao_heal(u)
    if u.is_boos then
        return 1
    end
    return 1 + self:buffes().tao_heal
end

---手牌上限根据血量值来定
---@param u any
---@return unknown
function Battle:hand_limit(u)
    if u.is_boos then
        return u.hp
    end
    return u.hp + (self:buffes().extra_hand or 0)  -- 慈航、西天行者提高手牌上限
end

---回合开始时的摸牌数
---@param u any
---@return integer
function Battle:draw_n(u)
    if u.is_boos then
        return u.draw_n or 2
    end
    return 2 + self:buffes().extra_draw
end

---从牌堆中摸n张牌到u手中；若牌堆空了则从弃牌堆中挪回并重洗
---@param u any
---@param n any
function Battle:draw(u,n)
    for _ = 1,n do
        if #self.deck == 0 then  --牌堆空了
            if #self.discard == 0 then  --弃牌堆也空了则跳出循环
                break
            end
            for i = #self.discard, 1, -1 do   --从后往前将弃牌挪回牌堆中
                self.deck[#self.deck+1] = table.remove(self.discard,i)
            end 
            shuffle(self.deck)  --洗牌
            self:add_log("已重置牌堆")
        end
        if #self.deck == 0 then
            break
        end
        u.hand[#u.hand+1] = table.remove(self.deck)
    end
end

---u弃置手牌
---@param u any
---@param index any
---@return any
function Battle:throw_hand(u,index)
    local card = table.remove(u.hand,index)
    self.discard[#self.discard+1] = card
    return card
end

function Battle:setup_stage()
    local boss = data.bosses[self.stage]  --数组下标：第一关即bosses[1]
    local general = data.generals[self.general_id] 
    self.deck = self:build_deck() 
    self.discard = {}
    self.shop = nil
    self.phase = "play"
    local extra_hp = self:buffes().extra_hp
    self.result = nil
    self.killer = nil  --每关清空击杀归属
    self.player = {
        name = general.name,
        title = general.title,
        portrait = general.portrait,   --图片
        hp = general.max_hp + extra_hp,
        max_hp = general.max_hp + extra_hp,
        hand = {},
        sha_used = 0,
        is_boos = false
    }
    self.boss = {
        name = boss.name,
        title = boss.title,
        portrait = boss.portrait,
        hp = boss.max_hp,
        max_hp = boss.max_hp,
        hand = {},
        sha_used = 0,
        sha_damage = boss.sha_damage,
        sha_limit = boss.sha_limit,
        draw_n = boss.draw_n,
        is_boos = true
    }
    self.allies = {}  
    --助战每关重置
    for _, aid in ipairs(self.ally_ids) do
        local ag = data.generals[aid]
        if ag then
            local ally = {
                general_id = aid,
                name = ag.name,
                title = ag.title,
                portrait = ag.portrait,
                hp = ag.max_hp + extra_hp,
                max_hp = ag.max_hp +extra_hp,
                hand = {},
                sha_used = 0,
                is_boos = false
            }
            self.allies[#self.allies+1] = ally
            self:draw(ally,4)
        end
    end
    local extra = self:buffes().open_hand or 0  --龙宫借宝，开局多摸牌
    if extra > 0 then
        self:draw(self.player,extra)
        for _, ally in ipairs(self.allies) do
            self:draw(ally,extra)
        end
    end
    self:draw(self.player,4)  --开局玩家和boss都先摸四张牌
    self:draw(self.boss,4)
    self:add_log("第 " .. self.stage .. " 关 · " .. (boss.title or "") .. "，对阵 " .. boss.name)
    self:begain_player()
end

---玩家回合开始
function Battle:begain_player()
    local n = self:draw_n(self.player)
    self:draw(self.player,n)
    self.player.sha_used = 0
    self.skill_used = false  --新回合重置主动技
    self.phase = "play"
    self.prompt = "出牌阶段，请选择你要出的牌或结束出牌"
    self:add_log(self.player.name.."的回合，摸"..n.."张牌")
end

---取出单位身上的skill配置（主将用Battle.general_id，助战用u.general_id）
function Battle:unit_skill(u)
    if not u or u.is_boos then
        return nil
    end
    local gid = u.general_id or (u == self.player and self.general_id)
    local g = gid and data.generals[gid]
    return g and g.skill
end

---主动技入口
---@param skill_id any
---@param card_id any
---@return nil
---@return string
function Battle:use_skill(skill_id, card_id)
    if self.phase ~= "play" and self.phase ~= "peek" then
        return nil, "现在不能发动技能"
    end
    local skill = self:unit_skill(self.player)
    -- 没有kind的是被动技，不能点发动
    if not skill or not skill.kind or not skill.id then
        return nil, "你没有主动技"
    end
    if skill.id ~= skill_id then
        return nil, "不能发动该技能"
    end
    if self.skill_used then
        return nil, "本回合已发动过主动技"
    end
    local fn = self["skill_" .. skill.kind]
    if type(fn) ~= "function" then
        return nil, "未知技能类型：" .. tostring(skill.kind)
    end
    return fn(self, skill, card_id)
end

---kind = look_discard：先看对方手牌，再点一张弃置（天眼）
function Battle:skill_look_discard(skill, card_id)
    local name = skill.name or "技能"
    if not card_id or card_id == 0 then
        if self.phase ~= "play" then
            return nil, "请选择一张牌弃置"
        end
        if #self.boss.hand == 0 then
            self.skill_used = true
            self:add_log(self.player.name.."发动【"..name.."】，但首领没有手牌")
            return self:snapshot()
        end
        self.phase = "peek"
        self.prompt = name.."：点选一张首领手牌弃置"
        self:add_log(self.player.name.."发动【"..name.."】，观看了首领的手牌")
        return self:snapshot()
    end
    if self.phase ~= "peek" then
        return nil, "请先发动技能观看手牌"
    end
    local i, card = find_id(self.boss.hand, card_id)
    if not card then
        return nil, "首领没有这张牌"
    end
    self:throw_hand(self.boss, i)
    self.skill_used = true
    self.phase = "play"
    self.prompt = "出牌阶段，请选择你要出的牌或结束出牌"
    self:add_log(self.player.name.."的【"..name.."】弃置了首领的【"..card.name.."】")
    return self:snapshot()
end

---助战查看并弃置技能
---@param ally any
---@param skill any
function Battle:skill_look_discard_auto(ally,skill)
    local name = skill.name or "技能"
    if #self.boss.hand == 0 then
        ally.skill_used = true
        self:add_log(ally.name.."对"..self.boss.name.."使用了"..name.."，但其无手牌")
        return
    end
    local i = math.random(#self.boss.hand)      --随即弃置boss的一张手牌
    local card = self:throw_hand(self.boss,i)
    self:add_log(ally.name.."对"..self.boss.name.."使用了"..name.."，弃置了其一张【"..card.name.."】")
end

---助战回合发动主动技：有kind才发动，没有对应_auto就跳过
---@param ally any
function Battle:ally_use_skill(ally)
    local skill = self:unit_skill(ally)
    if not skill or not skill.kind or not skill.id then
        return
    end
    if ally.skill_used then
        return
    end
    local fn = self["skill_"..skill.kind.."_auto"] --拼接技能名称
    if type(fn) ~= "function" then
        return
    end
    fn(self,ally,skill)
end

---转换成sproto协议中的.fitghter,与sproto中字段一致
---@param u any
---@param with_hand any
---@return table
function Battle:parse2spt(u,with_hand)
    local row = {
        name = u.name,
        title = u.title,
        portrait = u.portrait,
        hp = u.hp,
        max_hp = u.max_hp,
        hand_count = #u.hand,
        sha_used = u.sha_used >= self:sha_limit(u)
    }
    if with_hand then
        row.hand = u.hand
    end
    
    return row
end

---生成发给前端的整包，字段名必须与start_run/play_card等respponse一致
---@return table
function Battle:snapshot()
    --商店加成
    local passives = {}
    for _, value in ipairs(data.shop_items) do
        if self.bought[value.id] then
            passives[#passives+1] = {id = value.id,name = value.name}
        end
    end
    --羁绊加成
    local bonds = {}
    for _, bond in ipairs(self:active_bonds() or {}) do
        bonds[#bonds+1] = {id = bond.id,name = bond.name}
    end
    local need = 0
    if self.phase == "discard" then
        need = math.max(0,#self.player.hand - self:hand_limit(self.player))
    end
    local ally_rows = {}
    for _, value in ipairs(self.allies or {}) do
        ally_rows[#ally_rows+1] = self:parse2spt(value,false)
    end
    return {
        ok = true,
        phase = self.phase,
        prompt = self.prompt,
        stage = self.stage,
        max_stage = data.max_stage,
        silver = self.silver,
        score = self.score,
        need_discard = need,
        log = self.log,
        passives = passives,
        player = self:parse2spt(self.player,true),
        boss = self:parse2spt(self.boss,false),
        result = self.result,
        shop = self.shop,
        allies = ally_rows,
        bonds = bonds,
        peek_hand = (self.phase == "peek" and self.boss.hand or nil), --将首领手牌发给前端
        skill_used = self.skill_used and true or false,
        killer = self.killer or ""
    }
end

---对局结束检查胜负，若不是末关则打开商店
---@return boolean
function Battle:game_over()
    if self.player.hp <= 0 then
        self.phase = "ended"
        self.prompt = "落败，行者切莫灰心，请来更为强大的仙佛即可破敌"
        self.result = {win = false,reason = "不敌"..self.boss.name,score = self.score}
        self:add_log("西行中断,最终分数："..self.score)
        return true
    end
    if self.boss.hp <=0 then
        local reward = data.stage_reward[self.stage]  --本关奖励
        local gain = reward.base + self.player.hp   --通关分数与基础奖励、血量
        self.silver = self.silver + reward.silver
        self.score = self.score + gain
        self:add_log(string.format("降服 %s, 银两 + %d, 分数 + %d",self.boss.name,reward.silver,gain))
        if self.stage >= data.max_stage then
            self.phase = "ended"
            self.prompt = "西天已近"
            self.result = {win = true,reason = "一路降妖，取得真经气象",score = self.score}
        else
            self:open_shop()
        end
        return true
    end
    return false
end

---打开商店
function Battle:open_shop()
    self.phase = "shop"
    self.prompt = "路边野庙：用银两请宝"
    local items = {}
    for _, value in ipairs(data.shop_items) do
        if not self.bought[value.id] then   --买过的不再列出
            items[#items+1] = {
                id = value.id,
                name = value.name,
                cost = value.cost,
                desc = value.desc,
                affordable = self.silver >= value.cost
            }
        end
    end
    self.shop = {items = items}
end

---受伤时，玩家没血且有桃则进入dying；首领没血会自动吃桃
---@param target any
---@param n any
---@return string
function Battle:hurt(target,n,attacker)
    target.hp = target.hp - n
    self:add_log(string.format("%s 受到 %d 点伤害 (%d/%d) ",target.name,n,math.max(target.hp,0),target.max_hp))
    if target.hp > 0 then
        return "ok"
    end
    if not target.is_boos then
        if find_type(target.hand,"tao") then
            self.phase = "dying"  --濒死状态
            self.prompt = "濒死，请打出一张【桃】"
            return "dying"
        end
        if attacker and attacker.name then
            self.killer = attacker.name  --记下击杀者，给前端击败提示
        end
        return "dead"
    end
    --首领没血时自动出桃
    while target.hp <= 0 do
        local i = find_type(target.hand,"tao")
        if not i then
            break
        end
        local card = self:throw_hand(target,i)  
        local h = self:tao_heal(target)   --回复值
        target.hp = math.min(target.hp + h,target.max_hp)
    end
    if target.hp <= 0 then
        if attacker and attacker.name then
            self.killer = attacker.name
            self:add_log(attacker.name.."击败了"..target.name)
        end
        return "dead"
    end
    return "ok"
end

---首领有闪时自动打出
---@param u any
---@return boolean
function Battle:atuo_shan(u)
    local i = find_type(u.hand,"shan")
    if not i then
        return false
    end

    local card = self:throw_hand(u,i)
    self:add_log(u.name .. "打出【"..card.name.."】抵消了杀")
    return true
end

---玩家出牌
---@param card_id any
---@return nil
---@return string
function Battle:play_card(card_id)
    if self.phase ~= "play" then
        return nil,"还未到你的出牌回合"
    end
    local i,card = find_id(self.player.hand,card_id)
    if not card then
        return nil,"手中没有该牌"
    end
    --玩家打出“杀”
    if card.type == "sha" then
        if self.player.sha_used >= self:sha_limit(self.player) then
            return nil,"本回合使用杀的次数已上限"
        end
        self:throw_hand(self.player,i)
        self.player.sha_used = self.player.sha_used + 1
        self:add_log(self.player.name.."对"..self.boss.name.."使用了【杀】")

        --羁绊加成：出杀后摸一张牌
        local n = self:buffes().draw_on_sha or 0
        if n > 0 then
            self:draw(self.player,n)
        end
        --首领没闪
        if not self:atuo_shan(self.boss) then
            local st = self:hurt(self.boss,self:sha_damage(self.player),self.player)
            if st == "dead" then
                self:game_over()  --通关或进商店
            end
        end
        return self:snapshot()
    end
    --玩家打出“桃”
    if card.type == "tao" then
        self:throw_hand(self.player,i)
        local h = self:tao_heal(self.player)  --回复量
        self.player.hp = math.min(self.player.hp + h,self.player.max_hp)
        self:add_log(self.player.name.."使用【桃】，体力".. self.player.hp .. "/" .. self.player.max_hp)
        return self:snapshot()
    end
    return nil,"现在不能打出这张牌"
end

---助战回合
---@return table
function Battle:ally_turn()
    for _, ally in ipairs(self.allies or {}) do
        if ally.hp > 0 then
            --先摸牌
            local n = self:draw_n(ally)
            self:draw(ally,n)
            ally.sha_used = 0
            ally.skill_used = false
            self:add_log(ally.name.."的回合，摸 "..n.." 张牌")
            self:ally_use_skill(ally)  --自动使用技能
            --判断血量是否健康是否有桃可以打出
            while ally.hp < ally.max_hp do
                local i = find_type(ally.hand,"tao")
                if not i then
                    break
                end
                local card = self:throw_hand(ally,i)
                local h =  self:tao_heal(ally)
                ally.hp = math.min(ally.hp + h,ally.max_hp)
                self:add_log(ally.name.."使用了一张【"..card.name.."】")
            end
            --判断是否出杀
            while ally.sha_used < self:sha_limit(ally) do
                local i = find_type(ally.hand,"sha")
                if not i  then
                    break
                end
                local card = self:throw_hand(ally,i)
                ally.sha_used = ally.sha_used + 1
                self:add_log(ally.name.."对"..self.boss.name.."使用了一张【"..card.name.."】")

                --羁绊加成：出杀后摸一张牌
                local n = self:buffes().draw_on_sha or 0
                if n > 0 then
                    self:draw(ally,n)
                end

                if not self:atuo_shan(self.boss) then --首领没闪
                    local st = self:hurt(self.boss,self:sha_damage(ally),ally)
                    if st == "dead" then
                        self:game_over()
                        return self:snapshot()
                    end
                end
            end
            while #ally.hand > self:hand_limit(ally) do     --手牌上限了从第一张开始弃
                self:throw_hand(ally,1)
            end
        end
    end
    return nil
end

---回合结束并判断是否需要弃置手牌
---@return nil
---@return string
function Battle:end_play()
    if self.phase ~= "play" then
        return nil,"还未到你的出牌回合"
    end
    --手牌超过上限则进入弃牌阶段
    if #self.player.hand > self:hand_limit(self.player) then
        self.phase = "discard"
        local n = #self.player.hand - self:hand_limit(self.player) --需弃置牌数
        self.prompt = "请弃置"..n.."张手牌"
        return self:snapshot()
    end
    local snap = self:ally_turn()
    if snap then
        return snap
    end
    return self:boss_turn()
end

---弃牌阶段，判断需弃牌数并弃置
---@param ids any
---@return nil
---@return unknown
function Battle:discard_cards(ids)
    if self.phase ~= "discard" then
        return nil,"现在不是弃牌阶段"
    end
    ids = ids or {}
    local need = #self.player.hand - self:hand_limit(self.player)

    if #ids ~= need then
        return nil,"需要弃掉"..need.."张手牌"
    end
    for _, value in ipairs(ids) do
        local i = find_id(self.player.hand,value)
        if not i then
            return nil,"要弃的牌不在手中"
        end
        local card = self:throw_hand(self.player,i)
        self:add_log("弃置【"..card.name.."】")
    end
    local snap = self:ally_turn()
    if snap then
        return snap
    end
    return self:boss_turn()
end

---boss回合
---@return table
function Battle:boss_turn()
    local n = self:draw_n(self.boss)
    self:draw(self.boss,n)
    self.boss.sha_used = 0
    self:add_log(self.boss.name.."的回合，摸"..n.."张手牌")
    --boss血不满时在手牌中找桃回血
    while self.boss.hp < self.boss.max_hp do  
        local i = find_type(self.boss.hand,"tao")
        if not i  then
            break
        end
        local card = self:throw_hand(self.boss,i)
        local h = self:tao_heal(self.boss)
        self.boss.hp = math.min(self.boss.hp+h,self.boss.max_hp)
        self:add_log(self.boss.name.."使用【"..card.name.."】")
    end
    return self:boss_continue()   --有杀出杀
end

---看首领是否还能进行出牌
---@return table
function Battle:boss_continue()
    while self.boss.sha_used < self:sha_limit(self.boss) do
        local i = find_type(self.boss.hand,"sha")
        if not i then      --手牌中没杀
            break
        end
        local card = self:throw_hand(self.boss,i)
        self.boss.sha_used = self.boss.sha_used + 1
        local dmg = self:sha_damage(self.boss)
        self:add_log(self.boss.name.."使用了【"..card.name.."】")
        self.pending_dmg = dmg  --记录杀的伤害，若玩家不出闪则扣相应血量
        self.phase = "respond"
        self.prompt = "请使用一张【闪】响应【杀】"
        return self:snapshot()
    end
    while #self.boss.hand > self:hand_limit(self.boss) do
        self:throw_hand(self.boss,1)
    end
    self:add_log(self.boss.name.."结束回合")
    if self:game_over() then
        return self:snapshot()
    end
    self:begain_player()
    return self:snapshot()
end

---响应出牌，eg：濒死响应出桃，被杀指定响应出闪
---@param card_id any
---@return table
---@return unknown
function Battle:respond(card_id)
    if self.phase == "dying" then
        if not card_id or card_id == 0 then
            self.player.hp = 0
            self:game_over()
            return self:snapshot()
        end

        local i,card = find_id(self.player.hand,card_id)
        if not card or card.type ~= "tao" then
            return nil,self.player.name.."濒死，是否出【桃】相助"
        end
        self:throw_hand(self.player,i)
        local h = self:tao_heal(self.player)
        self.player.hp = self.player.hp + h
        self:add_log("打出【桃】，体力值为："..self.player.hp)
        if self.player.hp <= 0 then  --仍濒死
         --手中还有桃
            if find_type(self.player.hand,"tao") then
                self.prompt = "仍濒死，请继续出【桃】"
                return self:snapshot()
            end
            --无桃
            self:game_over()
            return self:snapshot()
        end
        self.pending_dmg = nil
        return self:boss_continue()
    end
    if self.phase ~= "respond" then
        return nil,"现在不需要响应"
    end
    if card_id and card_id ~= 0 then    --出闪
        local i,card = find_id(self.player.hand,card_id)
        if not card or card.type ~= "shan" then
            return nil,"请出闪以响应【杀】"
        end
        self:throw_hand(self.player,i)
        self:add_log(self.player.name.."打出了【闪】响应杀")
        self.pending_dmg = nil
        return self:boss_continue()
    end
    local dmg = self.pending_dmg or 1  --没有出闪响应杀
    self.pending_dmg = nil
    local st = self:hurt(self.player,dmg,self.boss)
    if st == "dying" or st == "dead" then
        if st == "dead" then
            self:game_over()
        end
        return self:snapshot()
    end
    return self:boss_continue()
end

---购买法宝阶段
---@param item_id any
---@return nil
---@return string
function Battle:buy(item_id)
    if self.phase ~= "shop" then
        return nil,"还未到购买阶段"
    end
    local found
    for _, value in ipairs(data.shop_items) do
        if value.id == item_id then
            found = value
            break
        end
    end
    if not found then
        return nil,"没有这件法宝"
    end
    if self.bought[item_id] then
        return nil,"已拥有该法宝"
    end
    if self.silver < found.cost then
        return nil,"银两不足"
    end
    self.silver = self.silver - found.cost
    self.bought[item_id] = true
    if found.key == "extra_hp" then   --若法宝为增加体力上限的则当场加上限并回复
        self.player.max_hp = self.player.max_hp + found.add
        self.player.hp = math.min(self.player.hp + found.add,self.player.max_hp)
    end
    self:add_log("请得法宝：【"..found.name.."】")
    self:open_shop()
    return self:snapshot()
end

---进入下一关,只有在商店阶段能点击
---@return nil
---@return string
function Battle:next_stage()
   if self.phase ~= "shop" then
        return nil,"现在还不能进入下一关"
   end
   self.stage = self.stage + 1
   self:setup_stage()
   return self:snapshot()
end

return Battle