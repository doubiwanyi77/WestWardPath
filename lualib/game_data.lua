local data = {}

data.card_name = {
    sha = "杀",
    shan = "闪",
    tao = "桃"
}

data.card_counts = {sha = 36,shan = 28,tao = 12} --牌堆数

data.max_stage = 4  --总关数

data.general_order = {
    "sunwukong", "tangseng", "bajie", "shaseng",
    "nezha", "yangjian", "guanyin", "aolie", "longwang",
}

data.generals = {
    sunwukong = {
        id = "sunwukong",
        name = "孙悟空",
        title = "齐天大圣",
        portrait = "wukong.jpg",
        max_hp = 4,
        desc = "齐天大圣。西天行者、齐天战将。棒喝之间，先手破敌。",
        tags = { "西天行者", "齐天战将" },
        skill = {
            name = "棒喝",
            desc = "你使用的【杀】无法被【闪】抵消",
            mods = {ignore_shan = 1},
        }
    },
    tangseng = {
        id = "tangseng",
        name = "唐僧",
        title = "金蝉子",
        portrait = "tangseng.jpg",
        max_hp = 3,
        desc = "圣僧金蝉。西天行者、慈航普度。血薄心定，是取经队伍的主心骨。",
        tags = { "西天行者", "慈航普度" },
        skill = {
            name = "紧箍",
            desc = "【杀】命中后弃置首领一张手牌",
            mods = {hit_discard = 1}
        }
    },
    bajie = {
        id = "bajie",
        name = "猪八戒",
        title = "天蓬元帅",
        portrait = "bajie.jpg",
        max_hp = 5,
        desc = "天蓬转世。西天行者、天庭仙班。体厚能扛，也能唤来天兵。",
        tags = { "西天行者", "天庭仙班" },
        skill = {
            name = "食肠",
            desc = "你的回合开始时额外摸 1 张牌",
            mods = { extra_draw = 1 },
        },
    },
    shaseng = {
        id = "shaseng",
        name = "沙僧",
        title = "卷帘大将",
        portrait = "shaseng.jpg",
        max_hp = 5,
        desc = "默默担经。西天行者、慈航普度。稳如流沙，擅守擅援。",
        tags = { "西天行者", "慈航普度" },
        skill = {
            name = "铁杆",
            desc = "你的体力上限 +1",
            mods = { extra_hp = 1 },
        },
    },
    nezha = {
        id = "nezha",
        name = "哪吒",
        title = "三坛海会",
        portrait = "nezha.jpg",
        max_hp = 4,
        desc = "莲花化身。天庭仙班、齐天战将。火尖枪连刺，杀意最烈。",
        tags = { "天庭仙班", "齐天战将" },
        skill = {
            name = "三头",
            desc = "你每回合可额外使用 1 次【杀】",
            mods = { extra_sha = 1 },
        },
    },
    yangjian = {
        id = "yangjian",
        name = "杨戬",
        title = "二郎真君",
        portrait = "yangjian.jpg",
        max_hp = 4,
        desc = "三眼战神。天庭仙班、齐天战将。神通广大，专克妖邪。",
        tags = { "天庭仙班", "齐天战将" },
        skill = {
            id = "tianyan",          --use_skill传来的skill_id，须与此一致
            name = "天眼",
            desc = "出牌阶段限一次：观看首领手牌，并弃置其中 1 张",
            kind = "look_discard",   --有kind即主动技；新主动技换kind，并在battle里加skill_<kind>
            mods = { look_discard = 1 },
        },
    },
    guanyin = {
        id = "guanyin",
        name = "观音",
        title = "南海菩萨",
        portrait = "guanyin.jpg",
        max_hp = 4,
        desc = "慈航道人。慈航普度。杨枝净水，能把【桃】化作甘露。",
        tags = { "慈航普度" },
        skill = {
            name = "甘露",
            desc = "你使用【桃】时额外回复 1 点，并摸 1 张牌",
            mods = { tao_heal = 1, draw_on_tao = 1 },
        },
    },
    aolie = {
        id = "aolie",
        name = "白龙马",
        title = "西海三太子",
        portrait = "aolie.jpg",
        max_hp = 4,
        desc = "龙马驮经。西天行者、龙宫借宝。既是坐骑，也是第五位行者。",
        tags = { "西天行者", "龙宫借宝" },
        skill = {
            name = "龙马",
            desc = "你的手牌上限 +1",
            mods = { extra_hand = 1 },
        },
    },
    longwang = {
        id = "longwang",
        name = "敖广",
        title = "东海龙王",
        portrait = "longwang.jpg",
        max_hp = 5,
        desc = "龙宫之主。龙宫借宝、天庭仙班。借宝予人，开局便多一手牌。",
        tags = { "龙宫借宝", "天庭仙班" },
        skill = {
            name = "龙宫",
            desc = "每关开始时你额外摸 2 张牌",
            mods = { open_hand = 2 },
        },
    },
}

data.bosses = {                                        -- 下标 1..4 = 第几关
    {
        id = "heixiong", name = "黑熊精", title = "黑风山",
        max_hp = 20, sha_limit = 1, sha_damage = 1, draw_n = 2, portrait = "heixiong.jpg",
        --被【杀】时伤害 -1
        skill = {
            name = "熊皮",
            desc = "受到【杀】时伤害 -1（至少为 1）",
            mods = { reduce_in_sha = 1 },
        },
    },
    {
        id = "baigu", name = "白骨精", title = "白虎岭",
        max_hp = 24, sha_limit = 1, sha_damage = 1, draw_n = 2, portrait = "baigu.jpg",
        --额外出杀且回合多摸，保证第二刀有牌
        skill = {
            name = "三变",
            desc = "每回合可额外使用 1 次【杀】，回合开始时额外摸 1 张牌",
            mods = { extra_sha = 1, extra_draw = 1 },
        },
    },
    {
        id = "zhizhu", name = "蜘蛛精", title = "盘丝洞",
        max_hp = 28, sha_limit = 2, sha_damage = 1, draw_n = 3, portrait = "zhizhu.jpg",
        --自己的【杀】无视【闪】，且出杀后还摸牌
        skill = {
            name = "盘丝",
            desc = "你使用的【杀】无法被【闪】抵消，打出【杀】后摸 1 张牌",
            mods = { ignore_shan = 1, draw_on_sha = 1 },
        },
    },
    {
        id = "qingniu", name = "青牛精", title = "金兜山",
        max_hp = 32, sha_limit = 2, sha_damage = 2, draw_n = 3, portrait = "qingniu.jpg",
        --无视闪 + 杀伤再 +1 + 命中弃玩家 1 张手牌
        skill = {
            name = "金刚琢",
            desc = "你的【杀】无法被【闪】抵消，伤害 +1，命中后弃置对方 1 张手牌",
            mods = { ignore_shan = 1, sha_damage = 1, hit_discard = 1 },
        },
    },
}
data.shop_items = {
    { id = "ruyi",   name = "金箍棒",   cost = 8,  desc = "【杀】伤害 +1",   key = "sha_damage", add = 1 },
    { id = "kasaya", name = "锦襕袈裟", cost = 10, desc = "体力上限 +1",     key = "extra_hp",   add = 1 },
    { id = "fan",    name = "芭蕉扇",   cost = 8,  desc = "每回合多摸 1 张", key = "extra_draw", add = 1 },
    { id = "vase",   name = "净瓶杨枝", cost = 9,  desc = "【桃】额外回复 1", key = "tao_heal",   add = 1 },
}
--羁绊
data.bonds = {
    { 
        id = "xixing", 
        name = "西天行者", 
        tag = "西天行者", 
        lore = "师徒同心，西行不止。",
        thresholds = {
            {
                count = 3,
                desc = "心有灵犀：全体每回合额外摸 1 张牌",
                mods = { extra_draw = 1 },
            },
            {
                count = 4,
                desc = "真经在握：体力上限 +1，每回合多摸 1 张，手牌上限 +1",
                mods = { extra_draw = 1, extra_hp = 1, extra_hand = 1 },
            },
        },
    },
    { 
        id = "qitian", 
        name = "齐天战将", 
        tag = "齐天战将", 
        lore = "棒、枪、三尖两刃刀，专斩妖邪。",
        thresholds = {
            {
                count = 2,
                desc = "神通初显：【杀】伤害 +1",
                mods = { sha_damage = 1 },
            },
            {
                count = 3,
                desc = "连斩破阵：【杀】伤害 +1，打出【杀】后摸 1 张牌",
                mods = { sha_damage = 1, draw_on_sha = 1 },
            },
        },
     },
    { 
        id = "cihang", 
        name = "慈航普度", 
        tag = "慈航普度", 
        lore = "莲台高坐，杨枝洒遍西天路。",
        thresholds = {
            {
                count = 2,
                desc = "杨枝甘露：【桃】额外回复 1 点体力",
                mods = { tao_heal = 1 },
            },
            {
                count = 3,
                desc = "莲台护体：【桃】额外回复 1 点，手牌上限 +1",
                mods = { tao_heal = 1, extra_hand = 1 },
            },
        }, 
    },
    { 
        id = "heaven", 
        name = "天庭仙班", 
        tag = "天庭仙班", 
        thresholds = {
            {
                count = 2,
                desc = "天兵加持：全体每回合可额外打出 1 次【杀】",
                mods = { extra_sha = 1 },
            },
            {
                count = 3,
                desc = "天威降临：额外出杀，且【杀】伤害 +1",
                mods = { extra_sha = 1, sha_damage = 1 },
            },
        },
    },
    { 
        id = "dragon",
        name = "龙宫借宝", 
        tag = "龙宫借宝", 
        lore = "东海曾借定海神针，西海仍余龙息。",
        thresholds = {
            {
                count = 2,
                desc = "龙藏四海：开局手牌 +2，全体体力上限 +1",
                mods = { open_hand = 2, extra_hp = 1 },
            },
        },
     },
}
data.stage_reward = {
    { silver = 10, base = 40,  hp = 8 },
    { silver = 14, base = 70,  hp = 10 },
    { silver = 18, base = 110, hp = 12 },
    { silver = 24, base = 160, hp = 15 },
}

return data