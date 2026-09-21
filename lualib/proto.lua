local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse[[
    .package {
        type 0 : integer
        session 1 : integer
    }
    
    .general {
        id 0 : string
        name 1 : string
        max_hp 2 : integer
        desc 3 : string
    }
    
    register 2 {
        request {
            username 0 : string
            password 1 : string
        }
        response {
            ok 0 : boolean
            err 1 : string
            uid 2 : integer
            username 3 : string
            best_score 4 : integer
        }
    }
    
    login 3 {
        request {
            username 0 : string
            password 1 : string
        }
        response {
            ok 0 : boolean
            err 1 : string
            uid 2 : integer
            username 3 : string
            best_score 4 : integer
            token 5 : string
        }
    }
    
    lobby 4 {
        request {}
        response {
            ok 0 : boolean
            err 1 : string
            username 2 : string
            best_score 3 : integer 
            has_run 4 : boolean
            generals 5 : *general
        }
    }
    
    auth 5 {
        request {
            token 0 : string
        }
        response {
            ok 0 : boolean
            uid 1 : integer
            username 2 : string
            err 3 : string
        }
}
    .rank_row {
        rank 0 : integer
        username 1 : string
        score 2 : integer
        is_self 3 : boolean   # 排行榜上高亮当前登录用户
    }

    rank 6 {
        request {}
        response {
            ok 0 : boolean
            err 1 : string
            my_rank 2 : integer  # 自己的名次
            best_score 3 : integer  # 自己的历史最高分
            rank 4 : *rank_row   # 前20名的数组，* 表示数组
        }
    }
    
    .card {
        id 0 : integer  #该牌在本局内的唯一id
        type 1 : string
        name 2 : string
    }
    
    .fighter {
        name 0 : string  #角色名
        hp 1 : integer  #当前体力值
        max_hp 2 : integer
        hand_count 3 : integer  #手牌数
        sha_used 4 : boolean #本回合是否用过杀
        hand 5 : *card  #玩家带手牌，首领省略
        portrait 6 : string
        title 7 : string
    }
    
    .passive {   #强化
        id 0 : string
        name 1 : string  # 强化名，开局为空数组
    }
    
    .run_result {  #游戏结算结果
        win 0 : boolean
        reason 1 : string  #结算文案
        score 2 : integer
    }
    
    .shop_item {
        id 0 : string
        name 1 : string
        cost 2 : integer
        desc 3 : string
        affordable 4 : boolean
    }
    .shop {
        items 0 : *shop_item
    }

    start_run 7 {  #开局
        request {
            general_id 0 : string  #选中的主将id，eg:sunwukong
            ally_ids 1 : *string  #助战的id列表，最多为3个
        }
        response {
            ok 0 : boolean
            err 1 : string
            phase 2 : string
            prompt 3 : string   #桌面中间的提示
            stage 4 : integer   #当前关
            max_stage 5 : integer  #总关数
            silver 6 : integer   #银两
            score 7 : integer   #当前分
            need_discard 8 : integer  #要弃置牌数
            log 9 : *string   #战报
            passives 10 : *passive  #已有强化
            player 11 : fighter  
            boss 12 : fighter
            result 13 : run_result
            shop 14 : shop
            allies 15 : *fighter
            bonds 16 : *passive
            peek_hand 17 : *card
            skill_used 18 : boolean
            killer 19 : string 
        }
    }
    
    play_card 8 {
        request {
            card_id 0 : integer
        }
        response {
            ok 0 : boolean
            err 1 : string
            phase 2 : string
            prompt 3 : string
            stage 4 : integer
            max_stage 5 : integer
            silver 6 : integer
            score 7 : integer
            need_discard 8 : integer
            log 9 : *string
            passives 10 : *passive
            player 11 : fighter
            boss 12 : fighter
            result 13 : run_result
            shop 14 : shop
            allies 15 : *fighter
            bonds 16 : *passive
            peek_hand 17 : *card
            skill_used 18 : boolean
            killer 19 : string 
        }
    }
    
    end_play 9 {
        request {}
        response {
            ok 0 : boolean
            err 1 : string
            phase 2 : string
            prompt 3 : string
            stage 4 : integer
            max_stage 5 : integer
            silver 6 : integer
            score 7 : integer
            need_discard 8 : integer
            log 9 : *string
            passives 10 : *passive
            player 11 : fighter
            boss 12 : fighter
            result 13 : run_result
            shop 14 : shop
            allies 15 : *fighter
            bonds 16 : *passive
            peek_hand 17 : *card
            skill_used 18 : boolean
            killer 19 : string 
        }
    }
    
    discard 10 {
        request {
            card_ids 0 : *integer
        }
        response {
            ok 0 : boolean
            err 1 : string
            phase 2 : string
            prompt 3 : string
            stage 4 : integer
            max_stage 5 : integer
            silver 6 : integer
            score 7 : integer
            need_discard 8 : integer
            log 9 : *string
            passives 10 : *passive
            player 11 : fighter
            boss 12 : fighter
            result 13 : run_result
            shop 14 : shop
            allies 15 : *fighter
            bonds 16 : *passive
            peek_hand 17 : *card
            skill_used 18 : boolean
            killer 19 : string 
        }
    }
    
    respond 11 {
        request {
            card_id 0 : integer
        }
        response {
        ok 0 : boolean
        err 1 : string
        phase 2 : string
        prompt 3 : string
        stage 4 : integer
        max_stage 5 : integer
        silver 6 : integer
        score 7 : integer
        need_discard 8 : integer
        log 9 : *string
        passives 10 : *passive
        player 11 : fighter
        boss 12 : fighter
        result 13 : run_result
        shop 14 : shop
        allies 15 : *fighter
        bonds 16 : *passive
        peek_hand 17 : *card
        skill_used 18 : boolean
        killer 19 : string 
    }
}
buy 12 {
    request {
        item_id 0 : string
    }
    response {
        ok 0 : boolean
        err 1 : string
        phase 2 : string
        prompt 3 : string
        stage 4 : integer
        max_stage 5 : integer
        silver 6 : integer
        score 7 : integer
        need_discard 8 : integer
        log 9 : *string
        passives 10 : *passive
        player 11 : fighter
        boss 12 : fighter
        result 13 : run_result
        shop 14 : shop
        allies 15 : *fighter
        bonds 16 : *passive
        peek_hand 17 : *card
        skill_used 18 : boolean
        killer 19 : string 
    }
}
next_stage 13 {
    request {}
    response {
        ok 0 : boolean
        err 1 : string
        phase 2 : string
        prompt 3 : string
        stage 4 : integer
        max_stage 5 : integer
        silver 6 : integer
        score 7 : integer
        need_discard 8 : integer
        log 9 : *string
        passives 10 : *passive
        player 11 : fighter
        boss 12 : fighter
        result 13 : run_result
        shop 14 : shop
        allies 15 : *fighter
        bonds 16 : *passive
        peek_hand 17 : *card
        skill_used 18 : boolean
        killer 19 : string 
    }
}
resume_run 14 {
    request {}
    response {
        ok 0 : boolean
        err 1 : string
        phase 2 : string
        prompt 3 : string
        stage 4 : integer
        max_stage 5 : integer
        silver 6 : integer
        score 7 : integer
        need_discard 8 : integer
        log 9 : *string
        passives 10 : *passive
        player 11 : fighter
        boss 12 : fighter
        result 13 : run_result
        shop 14 : shop
        allies 15 : *fighter
        bonds 16 : *passive
        peek_hand 17 : *card
        skill_used 18 : boolean
        killer 19 : string 
    }
}

use_skill 15 {
    request {
        skill_id 0 : string
        card_id 1 : integer
    }
    response {
        ok 0 : boolean
        err 1 : string
        phase 2 : string
        prompt 3 : string
        stage 4 : integer
        max_stage 5 : integer
        silver 6 : integer
        score 7 : integer
        need_discard 8 : integer
        log 9 : *string
        passives 10 : *passive
        player 11 : fighter
        boss 12 : fighter
        result 13 : run_result
        shop 14 : shop
        allies 15 : *fighter
        bonds 16 : *passive
        peek_hand 17 : *card
        skill_used 18 : boolean
        killer 19 : string
    }
}

]]

proto.s2c = sprotoparser.parse[[
    .package {
        type 0 : integer
        session 1 : integer
    }
    
    heartbeat 1 {}

    notification 2 {
        request {
            message 0 : string
        }
    }
]]

return proto