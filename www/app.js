const WS_URL = `ws://${location.hostname}:9948`;

// 必须和 lualib/proto.lua 的编号、字段一致。改协议两边一起改。
const C2S_TEXT = `
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
    request { username 0 : string  password 1 : string }
    response { ok 0 : boolean  err 1 : string  uid 2 : integer  username 3 : string  best_score 4 : integer }
}
login 3 {
    request { username 0 : string  password 1 : string }
    response { ok 0 : boolean  err 1 : string  uid 2 : integer  username 3 : string  best_score 4 : integer  token 5 : string }
}
lobby 4 {
    request {}
    response { ok 0 : boolean  err 1 : string  username 2 : string  best_score 3 : integer  has_run 4 : boolean  generals 5 : *general }
}
auth 5 {
    request { token 0 : string }
    response { ok 0 : boolean  uid 1 : integer  username 2 : string  err 3 : string }
}
.rank_row {
    rank 0 : integer
    username 1 : string
    score 2 : integer
    is_self 3 : boolean
}
rank 6 {
    request {}
    response { ok 0 : boolean  err 1 : string  my_rank 2 : integer  best_score 3 : integer  rank 4 : *rank_row }
}
.card {
    id 0 : integer
    type 1 : string
    name 2 : string
}
.fighter {
    name 0 : string
    hp 1 : integer
    max_hp 2 : integer
    hand_count 3 : integer
    sha_used 4 : boolean
    hand 5 : *card
    portrait 6 : string
    title 7 : string
}
.passive {
    id 0 : string
    name 1 : string
}
.run_result {
    win 0 : boolean
    reason 1 : string
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
start_run 7 {
    request { general_id 0 : string ally_ids 1 : *string }
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
play_card 8 {
    request { card_id 0 : integer }
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
end_play 9 {
    request {}
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
discard 10 {
    request { card_ids 0 : *integer }
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
respond 11 {
    request { card_id 0 : integer }
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
buy 12 {
    request { item_id 0 : string }
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
next_stage 13 {
    request {}
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
resume_run 14 {
    request {}
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
use_skill 15 {
    request { skill_id 0 : string  card_id 1 : integer }
    response {
        ok 0 : boolean  err 1 : string  phase 2 : string  prompt 3 : string
        stage 4 : integer  max_stage 5 : integer  silver 6 : integer  score 7 : integer
        need_discard 8 : integer  log 9 : *string  passives 10 : *passive
        player 11 : fighter  boss 12 : fighter  result 13 : run_result  shop 14 : shop  allies 15 : *fighter  bonds 16 : *passive  peek_hand 17 : *card  skill_used 18 : boolean  killer 19 : string
    }
}
`;

const S2C_TEXT = `
.package {
    type 0 : integer
    session 1 : integer
}
heartbeat 1 {}
notification 2 {
    request { message 0 : string }
}
`;

// host 用 s2c：dispatch 服务器推送（heartbeat / notification）
// attach(c2s)：编码浏览器发出的 register / login / lobby
const c2sSproto = new Sproto(SprotoParser.parse(C2S_TEXT));
const s2cSproto = new Sproto(SprotoParser.parse(S2C_TEXT));
const clientHost = s2cSproto.host("package");
const sendRequest = clientHost.attach(c2sSproto);

let session = 0;
const pending = {};

const GENERAL_VIEW = {
  sunwukong: {
    name: "孙悟空", title: "齐天大圣", tags: ["西天行者", "齐天战将"], seal: "悟", portrait: "wukong.jpg",
    skill: { name: "棒喝", desc: "你使用的【杀】无法被【闪】抵消。" },
  },
  tangseng: {
    name: "唐僧", title: "圣僧金蝉", tags: ["西天行者", "慈航普度"], seal: "僧", portrait: "tangseng.jpg",
    skill: { name: "紧箍", desc: "你的【杀】命中后，弃置首领 1 张手牌。" },
  },
  bajie: {
    name: "猪八戒", title: "天蓬元帅", tags: ["西天行者", "天庭仙班"], seal: "戒", portrait: "bajie.jpg",
    skill: { name: "食肠", desc: "你的回合开始时额外摸 1 张牌。" },
  },
  shaseng: {
    name: "沙僧", title: "卷帘大将", tags: ["西天行者", "慈航普度"], seal: "沙", portrait: "shaseng.jpg",
    skill: { name: "铁杆", desc: "你的体力上限 +1。" },
  },
  nezha: {
    name: "哪吒", title: "三坛海会", tags: ["天庭仙班", "齐天战将"], seal: "吒", portrait: "nezha.jpg",
    skill: { name: "三头", desc: "你每回合可额外使用 1 次【杀】。" },
  },
  yangjian: {
    name: "杨戬", title: "二郎真君", tags: ["天庭仙班", "齐天战将"], seal: "戬", portrait: "yangjian.jpg",
    skill: { id: "tianyan", name: "天眼", kind: "look_discard", desc: "出牌阶段限一次：观看首领手牌，并弃置其中 1 张。" },
  },
  guanyin: {
    name: "观音", title: "南海菩萨", tags: ["慈航普度"], seal: "音", portrait: "guanyin.jpg",
    skill: { name: "甘露", desc: "你使用【桃】时额外回复 1 点，并摸 1 张牌。" },
  },
  aolie: {
    name: "白龙马", title: "西海三太子", tags: ["西天行者", "龙宫借宝"], seal: "龙", portrait: "aolie.jpg",
    skill: { name: "龙马", desc: "你的手牌上限 +1。" },
  },
  longwang: {
    name: "敖广", title: "东海龙王", tags: ["龙宫借宝", "天庭仙班"], seal: "广", portrait: "longwang.jpg",
    skill: { name: "龙宫", desc: "每关开始时你额外摸 2 张牌。" },
  },
};

const ui = {
  login: document.getElementById("screen-login"),
  lobby: document.getElementById("screen-lobby"),
  game: document.getElementById("screen-game"),
  username: document.getElementById("username"),
  password: document.getElementById("password"),
  authStatus: document.getElementById("auth-status"),
  lobbyUser: document.getElementById("lobby-user"),
  generals: document.getElementById("generals"),
  teamTray: document.getElementById("team-tray"),
  bondPreview: document.getElementById("bond-preview"),
  bondBook: document.getElementById("bond-book"),
  teamSkills: document.getElementById("team-skills"),
  rankList: document.getElementById("rank-list"),
  rankSelf: document.getElementById("rank-self"),
  btnRank: document.getElementById("btn-rank"),
  meta: document.getElementById("meta"),
  overlay: document.getElementById("overlay"),
  toast: document.getElementById("toast"),
};

let ws = null;
let connected = false;
let authed = false;
let lobby = null;
let battle = null;
let selectedGeneral = "sunwukong";
let selectedAllies = [];  // 助战 id，最多 3 个，不能和主驾重复
let selectedCards = new Set();
let rankOpen = false;

function show(screen) {
  ui.login.classList.toggle("hidden", screen !== "login");
  ui.lobby.classList.toggle("hidden", screen !== "lobby");
  ui.game.classList.toggle("hidden", screen !== "game");
}

function toast(msg) {
  ui.toast.textContent = msg;
  ui.toast.classList.remove("hidden");
  clearTimeout(toast._t);
  toast._t = setTimeout(() => ui.toast.classList.add("hidden"), 2400);
}

function notReady() {
  toast("对局服务尚未接入");
}

// name: 协议名，例如 "login"。args: 对应 request 字段表。
// session 用来把 RESPONSE 对回这次请求；回包里没有 cmd。
function send(name, args) {
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    toast("尚未连上服务器");
    return;
  }
  session += 1;
  pending[session] = name;
  const buf = sendRequest(name, args || {}, session);
  ws.send(buf);
}

function toPlain(obj) {
  if (!obj) return obj;
  const out = {};
  for (const k in obj) {
    const v = obj[k];
    if (typeof v === "bigint") out[k] = Number(v);
    else if (Array.isArray(v)) out[k] = v.map((item) => (typeof item === "object" ? toPlain(item) : item));
    else if (v && typeof v === "object") out[k] = toPlain(v);
    else out[k] = v;
  }
  return out;
}

function hpText(cur, max) {
  const filled = "●".repeat(Math.max(0, cur));
  const empty = "○".repeat(Math.max(0, max - cur));
  return `${filled}${empty}  ${cur}/${max}`;
}

function posClass(rank) {
  if (rank === 1) return "pos gold";
  if (rank === 2) return "pos silver";
  if (rank === 3) return "pos bronze";
  return "pos";
}

function rankRowsHtml(list, selfName) {
  if (!list || !list.length) {
    return `<li class="rank-empty">暂无人上榜。</li>`;
  }
  return list.map((row) => {
    const rank = row.rank || row.pos;
    const name = row.username || "";
    const me = row.is_self || (selfName && name === selfName);
    return `<li class="${me ? "me" : ""}">
      <span class="${posClass(rank)}">${rank}</span>
      <span class="name">${name}${me ? "（你）" : ""}</span>
      <span class="score">${row.score || 0}</span>
    </li>`;
  }).join("");
}

function applyRank(msg) {
  if (!lobby) lobby = {};
  if (msg.rank) lobby.rank = msg.rank;
  if (msg.my_rank != null) lobby.my_rank = msg.my_rank;
  if (msg.best_score != null) lobby.best_score = msg.best_score;
  renderRank();
  if (rankOpen) renderRankOverlay();
}

function rankSelfText() {
  if (!lobby) return "登录后按历史最高分计入功德榜。";
  const score = lobby.best_score || 0;
  if (!lobby.my_rank || score <= 0) {
    return `${lobby.username || ""}　尚未上榜（最高分 ${score}）`;
  }
  return `${lobby.username}　第 ${lobby.my_rank} 名　最高分 ${score}`;
}

function renderRank() {
  ui.rankSelf.textContent = rankSelfText();
  const name = lobby && lobby.username;
  ui.rankList.innerHTML = rankRowsHtml(lobby && lobby.rank, name);
}

function renderRankOverlay() {
  const name = lobby && lobby.username;
  ui.overlay.classList.remove("hidden");
  ui.overlay.innerHTML = `
    <div class="modal rank-modal">
      <h2>功德榜</h2>
      <p class="hint">${rankSelfText()}</p>
      <ol class="rank-list">${rankRowsHtml(lobby && lobby.rank, name)}</ol>
      <div class="row">
        <button type="button" id="btn-rank-reload">刷新</button>
        <button type="button" class="ghost" id="btn-rank-close">关闭</button>
      </div>
    </div>`;
  ui.overlay.querySelector("#btn-rank-reload").onclick = () => send("rank", {});
  ui.overlay.querySelector("#btn-rank-close").onclick = () => {
    rankOpen = false;
    if (battle && (battle.phase === "shop" || (battle.phase === "ended" && battle.result))) {
      renderOverlay();
      return;
    }
    ui.overlay.classList.add("hidden");
    ui.overlay.innerHTML = "";
  };
}

function connect() {
  if (ws) {
    ws.onclose = null;
    ws.onerror = null;
    ws.onmessage = null;
    if (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING) {
      ws.close();
    }
  }
  ui.authStatus.textContent = "正在接通登录通道…";
  ws = new WebSocket(WS_URL);
  ws.binaryType = "arraybuffer";
  ws.onopen = () => {
    connected = true;
    ui.authStatus.textContent = "已连接，请登录或注册";
  };
  ws.onclose = () => {
    connected = false;
    authed = false;
    ui.btnRank.classList.add("hidden");
    ui.authStatus.textContent = "连接断开，正在重试…";
    show("login");
    setTimeout(connect, 1200);
  };
  ws.onerror = () => {
    ui.authStatus.textContent = "连接失败，请确认服务端已启动";
  };
  ws.onmessage = (ev) => {
    let result;
    try {
      result = clientHost.dispatch(new Uint8Array(ev.data));
    } catch (e) {
      toast("协议解码失败");
      return;
    }
    onSproto(result);
  };
}

function onSproto(result) {
  if (result.type === "REQUEST") {
    if (result.name === "heartbeat") return;
    if (result.name === "notification") {
      const req = toPlain(result.request);
      ui.authStatus.textContent = (req && req.message) || "已连接";
    }
    return;
  }
  if (result.type !== "RESPONSE") return;

  const sid = typeof result.session === "bigint" ? Number(result.session) : result.session;
  const name = pending[sid];
  delete pending[sid];
  const msg = toPlain(result.response) || {};

  if (!msg.ok) {
    toast(msg.err || "请求失败");
    if (!authed) ui.authStatus.textContent = msg.err || "请求失败";
    return;
  }

  if (name === "register") {
    ui.authStatus.textContent = "注册成功，请登录";
    return;
  }
  if (name === "login") {
    authed = true;
    ui.btnRank.classList.remove("hidden");
    send("lobby", {});
    return;
  }
  if (name === "lobby") {
    stopPlayback();
    playbackHold = false;
    killHold = false;
    pendingBattle = null;
    lobby = msg;
    battle = null;
    rankOpen = false;
    ui.overlay.classList.add("hidden");
    ui.overlay.innerHTML = "";
    if (msg.generals && msg.generals[0] && msg.generals[0].id) {
      selectedGeneral = msg.generals[0].id;
    }
    renderLobby();
    show("lobby");
    send("rank", {});
    return;
  }
  if (name === "rank") {
    applyRank(msg);
    return;
  }
  if (name === "start_run" || name === "play_card" || name === "end_play" || name === "discard"
      || name === "respond" || name === "buy" || name === "next_stage" || name === "resume_run"
      || name === "use_skill") {
    applyBattleState(msg, name);
  }
}

let playbackHold = false;
let killHold = false;
let pendingBattle = null;
let logCursor = 0;
let logPlayTimer = 0;
const LOG_PLAY_MS = 480;

function stopPlayback() {
  if (logPlayTimer) clearTimeout(logPlayTimer);
  logPlayTimer = 0;
}

function isKillPacket(msg) {
  return !!(msg && msg.killer && (msg.phase === "shop" || (msg.phase === "ended" && msg.result)));
}

// 服务端会丢掉最旧战报，数组长度可能不变。用重叠算出真正新增了几行。
function countNewLogLines(prev, next) {
  prev = prev || [];
  next = next || [];
  if (!next.length) return 0;
  if (!prev.length) return next.length;
  for (let drop = 0; drop <= prev.length; drop++) {
    const kept = prev.slice(drop);
    if (kept.length > next.length) continue;
    let match = true;
    for (let i = 0; i < kept.length; i++) {
      if (kept[i] !== next[i]) {
        match = false;
        break;
      }
    }
    if (match) return next.length - kept.length;
  }
  return next.length;
}

function applyBattleState(msg, name) {
  stopPlayback();
  const prevLog = (battle && battle.log) || [];
  const logs = msg.log || [];
  const added = countNewLogLines(prevLog, logs);
  const fresh = !battle || name === "start_run" || name === "next_stage" || name === "resume_run" || name === "buy";
  const shouldPlay = !fresh && added > 0 && (isKillPacket(msg) || name === "end_play" || name === "discard");

  rankOpen = false;
  selectedCards = new Set();
  show("game");

  if (!shouldPlay) {
    pendingBattle = msg;
    finishPlayback(fresh);
    return;
  }

  pendingBattle = msg;
  playbackHold = true;
  killHold = false;
  logCursor = Math.max(0, logs.length - added);
  battle = Object.assign({}, msg, {
    log: logs.slice(0, logCursor),
    shop: null,
    result: null,
  });
  ui.overlay.classList.add("hidden");
  ui.overlay.innerHTML = "";
  renderBattle();
  tickLogPlay();
}

function tickLogPlay() {
  const full = (pendingBattle && pendingBattle.log) || [];
  if (logCursor >= full.length) {
    finishPlayback(false);
    return;
  }
  logCursor += 1;
  battle = Object.assign({}, pendingBattle, {
    log: full.slice(0, logCursor),
    shop: null,
    result: null,
  });
  renderBattle();
  logPlayTimer = setTimeout(tickLogPlay, LOG_PLAY_MS);
}

function finishPlayback(skipKill) {
  stopPlayback();
  playbackHold = false;
  const msg = pendingBattle;
  pendingBattle = null;
  if (!msg) return;
  battle = msg;
  if (!skipKill && isKillPacket(msg)) {
    killHold = true;
    renderBattle();
    return;
  }
  killHold = false;
  renderBattle();
}

function skipPlayback() {
  stopPlayback();
  if (pendingBattle) finishPlayback(false);
  else if (killHold) {
    killHold = false;
    renderBattle();
  }
}

function findGeneral(id) {
  return (lobby && lobby.generals || []).find((g) => g.id === id);
}

function viewOf(g) {
  return GENERAL_VIEW[g && g.id] || { title: "", tags: [], seal: (g && g.name && g.name[0]) || "将", portrait: "", skill: null };
}

function skillOfUnit(u) {
  if (!u) return null;
  if (u.id && GENERAL_VIEW[u.id] && GENERAL_VIEW[u.id].skill) return GENERAL_VIEW[u.id].skill;
  const name = u.name;
  if (!name) return null;
  for (const v of Object.values(GENERAL_VIEW)) {
    if (v.name === name) return v.skill;
  }
  return null;
}

// 有 kind 的才是主动技（出牌阶段出按钮）；被动技只配 name/desc
function activeSkillOf(u) {
  const s = skillOfUnit(u);
  if (!s || !s.kind || !s.id) return null;
  return s;
}

function imgPath(file) {
  return file ? `/img/${file}` : "";
}

function portraitHtml(file, name) {
  if (!file) return `<div class="portrait-ph">${(name && name[0]) || "将"}</div>`;
  return `<img src="${imgPath(file)}" alt="${name || ""}" onerror="this.style.display='none'" />`;
}

function sgCardHtml(u, kind) {
  u = u || {};
  const img = u.portrait
    ? `<img src="${imgPath(u.portrait)}" alt="${u.name || ""}" />`
    : `<div class="portrait-ph">${(u.name && u.name[0]) || "将"}</div>`;
  const role = kind === "boss" ? "首领" : kind === "ally" ? "助战" : "主将";
  const hand = kind === "boss"
    ? `<span class="sg-hand">手牌 ${u.hand_count || 0}</span>`
    : "";
  const cur = Math.max(0, Number(u.hp) || 0);
  const max = Math.max(1, Number(u.max_hp) || 1);
  const pct = Math.min(100, (cur / max) * 100);
  const skill = kind === "boss" ? null : skillOfUnit(u);
  const skillHtml = skill
    ? `<div class="sg-skill" title="${skill.desc}">${skill.name}</div>`
    : "";
  return `${img}<div class="sg-shade"></div>
    <span class="sg-role">${role}</span>
    ${hand}
    <div class="sg-title">${u.title || ""}</div>
    <div class="sg-name">${u.name || ""}</div>
    ${skillHtml}
    <div class="sg-hp"><i style="width:${pct}%"></i><span>${cur}/${max}</span></div>`;
}

function fillSgCard(el, u, kind) {
  if (!el) return;
  el.className = `sg-card ${kind === "boss" ? "boss-card" : kind === "player" ? "player-card" : ""}${((u && u.hp) || 0) <= 0 ? " down" : ""}`;
  el.innerHTML = sgCardHtml(u, kind);
}

function renderTeamTray() {
  const leader = findGeneral(selectedGeneral);
  const view = viewOf(leader);
  const slots = [{ role: "主驾", g: leader, leader: true, view }];
  selectedAllies.forEach((id) => {
    const g = findGeneral(id);
    slots.push({ role: "助战", g, leader: false, view: viewOf(g) });
  });
  for (let i = selectedAllies.length; i < 3; i++) {
    slots.push({ role: "助战", g: null, leader: false });
  }
  ui.teamTray.innerHTML = slots.map((s) => {
    if (!s.g) {
      return `<div class="slot"><span class="role">${s.role}</span><span class="who muted">空位</span></div>`;
    }
    const bg = s.view.portrait ? ` style="background-image:url('${imgPath(s.view.portrait)}')"` : "";
    return `<div class="slot has${s.leader ? " leader" : ""}"${bg} title="${s.view.skill ? s.view.skill.name + "：" + s.view.skill.desc : ""}">
      <span class="role">${s.role}</span>
      <span class="who">${s.g.name}</span>
    </div>`;
  }).join("");
}

const BOND_RULES = [
  {
    name: "西天行者", tag: "西天行者", lore: "师徒同心，西行不止。",
    heroes: "孙悟空、唐僧、猪八戒、沙僧、白龙马",
    thresholds: [
      { count: 3, desc: "心有灵犀：全体每回合额外摸 1 张牌" },
      { count: 4, desc: "真经在握：体力上限 +1，每回合多摸 1 张，手牌上限 +1" },
    ],
  },
  {
    name: "齐天战将", tag: "齐天战将", lore: "棒、枪、三尖两刃刀，专斩妖邪。",
    heroes: "孙悟空、哪吒、杨戬",
    thresholds: [
      { count: 2, desc: "神通初显：【杀】伤害 +1" },
      { count: 3, desc: "连斩破阵：【杀】伤害 +1，打出【杀】后摸 1 张牌" },
    ],
  },
  {
    name: "慈航普度", tag: "慈航普度", lore: "莲台高坐，杨枝洒遍西天路。",
    heroes: "唐僧、沙僧、观音",
    thresholds: [
      { count: 2, desc: "杨枝甘露：【桃】额外回复 1 点体力" },
      { count: 3, desc: "莲台护体：【桃】额外回复 1 点，手牌上限 +1" },
    ],
  },
  {
    name: "天庭仙班", tag: "天庭仙班", lore: "旧日仙籍未销，神威仍在。",
    heroes: "猪八戒、哪吒、杨戬、敖广",
    thresholds: [
      { count: 2, desc: "天兵加持：全体每回合可额外打出 1 次【杀】" },
      { count: 3, desc: "天威降临：额外出杀，且【杀】伤害 +1" },
    ],
  },
  {
    name: "龙宫借宝", tag: "龙宫借宝", lore: "东海曾借定海神针，西海仍余龙息。",
    heroes: "白龙马、敖广",
    thresholds: [
      { count: 2, desc: "龙藏四海：开局手牌 +2，全体体力上限 +1" },
    ],
  },
];

function renderBondPreview() {
  const ids = [selectedGeneral].concat(selectedAllies);
  const count = {};
  ids.forEach((id) => {
    (viewOf(findGeneral(id)).tags || []).forEach((t) => {
      count[t] = (count[t] || 0) + 1;
    });
  });
  ui.bondPreview.innerHTML = BOND_RULES.map((r) => {
    const n = count[r.tag] || 0;
    const max = r.thresholds[r.thresholds.length - 1].count;
    const best = [...r.thresholds].reverse().find((th) => n >= th.count);
    return `<span class="chip${best ? "" : " dim"}">${r.name} ${n}/${max}${best ? "　" + best.desc : ""}</span>`;
  }).join("");
}

function renderTeamSkills() {
  if (!ui.teamSkills) return;
  const ids = [selectedGeneral].concat(selectedAllies);
  ui.teamSkills.innerHTML = ids.map((id) => {
    const g = findGeneral(id);
    const v = viewOf(g);
    if (!v.skill) return "";
    return `<span class="chip" title="${v.skill.desc}">${(g && g.name) || v.name} · ${v.skill.name}</span>`;
  }).join("");
}

function renderBondBook() {
  ui.bondBook.innerHTML = BOND_RULES.map((r) => `
    <article class="bond-item">
      <strong>${r.name}</strong>
      <div class="lore">${r.lore || ""}</div>
      <div class="heroes">${r.heroes}</div>
      <ul>${r.thresholds.map((th) => `<li>${th.count}：${th.desc}</li>`).join("")}</ul>
    </article>`).join("");
}

function renderLobby() {
  ui.lobbyUser.textContent = `${lobby.username}　历史最高分 ${lobby.best_score || 0}　点将：先定主驾，再点助战入队。仙术仅本人生效。`;
  renderTeamTray();
  renderTeamSkills();
  renderBondPreview();
  renderBondBook();
  ui.generals.innerHTML = "";
  (lobby.generals || []).forEach((g) => {
    const view = viewOf(g);
    const el = document.createElement("div");
    el.className = "general" + (g.id === selectedGeneral ? " selected-leader" : "");
    el.innerHTML = `
      ${portraitHtml(view.portrait, g.name)}
      <div class="body">
        <div class="title">${view.title}　${g.max_hp} 血</div>
        <strong>${g.name}</strong>
        <div class="desc">${g.desc || ""}</div>
        <div class="skill-line" title="${(view.skill && view.skill.desc) || ""}">${view.skill ? "仙术 · " + view.skill.name + "：" + view.skill.desc : ""}</div>
        <div class="tags">${(view.tags || []).map((t) => `<span class="tag">${t}</span>`).join("")}</div>
      </div>
      <div class="pick">
        <button type="button" data-lead="${g.id}">主驾</button>
        <button type="button" class="ghost" data-ally="${g.id}">助战</button>
      </div>`;
    el.querySelector("[data-lead]").onclick = (ev) => {
      ev.stopPropagation();
      selectedGeneral = g.id;
      selectedAllies = selectedAllies.filter((id) => id !== g.id);
      renderLobby();
    };
    el.querySelector("[data-ally]").onclick = (ev) => {
      ev.stopPropagation();
      const i = selectedAllies.indexOf(g.id);
      if (i >= 0) {
        selectedAllies.splice(i, 1);
      } else if (g.id === selectedGeneral) {
        toast("主驾不能同时作为助战");
      } else if (selectedAllies.length >= 3) {
        toast("助战最多 3 人");
      } else {
        selectedAllies.push(g.id);
      }
      renderLobby();
    };
    el.onclick = () => {
      selectedGeneral = g.id;
      renderLobby();
    };
    ui.generals.appendChild(el);
  });
  document.getElementById("btn-resume").disabled = !lobby.has_run;
  renderRank();
}

function renderMeta() {
  if (!battle) {
    ui.meta.classList.add("hidden");
    return;
  }
  ui.meta.classList.remove("hidden");
  ui.meta.textContent = `第 ${battle.stage}/${battle.max_stage} 关　　银两 ${battle.silver}　　分数 ${battle.score}`;
}

function canClickCard(card) {
  if (!battle || playbackHold || killHold) return false;
  if (battle.phase === "discard") return true;
  if (battle.phase === "play") {
    if (card.type === "sha") return !battle.player.sha_used;
    if (card.type === "tao") return battle.player.hp < battle.player.max_hp;
    return false;
  }
  if (battle.phase === "respond") return card.type === "shan";
  if (battle.phase === "dying") return card.type === "tao";
  return false;
}

function onCardClick(card) {
  if (playbackHold || killHold) return;
  if (!canClickCard(card)) return;
  const cid = Number(card.id);
  if (battle.phase === "discard") {
    if (selectedCards.has(cid)) selectedCards.delete(cid);
    else selectedCards.add(cid);
    renderBattle();
    return;
  }
  if (battle.phase === "play") {
    send("play_card", { card_id: cid });
    return;
  }
  if (battle.phase === "respond" || battle.phase === "dying") {
    send("respond", { card_id: cid });
  }
}

function renderHand() {
  const box = document.getElementById("hand");
  box.innerHTML = "";
  (battle.player.hand || []).forEach((card) => {
    const el = document.createElement("button");
    el.type = "button";
    el.className = `card ${card.type}`;
    if (selectedCards.has(Number(card.id))) el.classList.add("selected");
    if (!canClickCard(card)) el.classList.add("disabled");
    el.innerHTML = `<small>${card.type.toUpperCase()}</small><b>${card.name}</b><small>西游</small>`;
    el.onclick = () => onCardClick(card);
    box.appendChild(el);
  });
}

function renderActions() {
  const box = document.getElementById("actions");
  box.innerHTML = "";
  const add = (label, fn, ghost) => {
    const b = document.createElement("button");
    b.type = "button";
    b.textContent = label;
    if (ghost) b.className = "ghost";
    b.onclick = fn;
    box.appendChild(b);
  };
  if (playbackHold || killHold) {
    add("跳过", skipPlayback);
    add("返回大厅", () => send("lobby", {}), true);
    return;
  }
  if (battle.phase === "play") {
    const sk = activeSkillOf(battle.player);
    if (sk && !battle.skill_used) {
      add("发动" + sk.name, () => send("use_skill", { skill_id: sk.id, card_id: 0 }));
    }
    add("结束出牌", () => send("end_play", {}));
  }
  if (battle.phase === "discard") {
    add(`确认弃牌（${selectedCards.size}/${battle.need_discard}）`, () => {
      send("discard", { card_ids: Array.from(selectedCards) });
    });
  }
  if (battle.phase === "respond") {
    add("承受伤害", () => send("respond", { card_id: 0 }), true);
  }
  if (battle.phase === "dying") {
    add("确认死亡", () => send("respond", { card_id: 0 }), true);
  }
  add("返回大厅", () => send("lobby", {}), true);
}

function renderOverlay() {
  if (rankOpen) {
    renderRankOverlay();
    return;
  }
  if (playbackHold) {
    ui.overlay.classList.add("hidden");
    ui.overlay.innerHTML = "";
    return;
  }
  if (killHold && battle && battle.killer) {
    const bossName = (battle.boss && battle.boss.name) || "首领";
    const win = battle.phase === "shop" || (battle.result && battle.result.win);
    ui.overlay.classList.remove("hidden");
    ui.overlay.innerHTML = `
      <div class="modal kill-modal">
        <h2>${win ? "降服" : "落败"}</h2>
        <p class="kill-line">${battle.killer} 击败了 ${win ? bossName : ((battle.player && battle.player.name) || "你")}</p>
        <p class="hint">${win ? "请宝加持后再赶下一程。" : (battle.result && battle.result.reason) || ""}</p>
        <button type="button" id="btn-kill-ok">继续</button>
      </div>`;
    ui.overlay.querySelector("#btn-kill-ok").onclick = skipPlayback;
    return;
  }
  if (battle.phase === "peek") {
    const sk = activeSkillOf(battle.player);
    const cards = battle.peek_hand || [];
    ui.overlay.classList.remove("hidden");
    ui.overlay.innerHTML = `
      <div class="modal">
        <h2>${(sk && sk.name) || "技能"}</h2>
        <p class="hint">${battle.prompt || "观看手牌，点选一张。"}</p>
        <div class="hand">
          ${cards.length ? cards.map((c) => `
            <button type="button" class="card ${c.type}" data-peek="${c.id}">
              <small>${(c.type || "").toUpperCase()}</small><b>${c.name}</b><small>首领</small>
            </button>`).join("") : `<p class="hint">没有可点选的牌。</p>`}
        </div>
      </div>`;
    ui.overlay.querySelectorAll("[data-peek]").forEach((btn) => {
      btn.onclick = () => send("use_skill", {
        skill_id: (sk && sk.id) || "",
        card_id: Number(btn.getAttribute("data-peek")),
      });
    });
    return;
  }
  if (battle.phase === "shop") {
    const items = (battle.shop && battle.shop.items) || [];
    ui.overlay.classList.remove("hidden");
    ui.overlay.innerHTML = `
      <div class="modal">
        <h2>路边野庙</h2>
        <p class="hint">银两 ${battle.silver}。请宝加持后再赶下一程。</p>
        <div class="shop-list">
          ${items.length ? items.map((it) => `
            <div class="shop-item">
              <div><strong>${it.name}</strong><div class="muted">${it.desc || ""}</div></div>
              <button type="button" data-buy="${it.id}" ${it.affordable ? "" : "disabled"}>${it.cost} 两</button>
            </div>`).join("") : `<p class="hint">没有可请的法宝了。</p>`}
        </div>
        <button type="button" id="btn-next">进入下一关</button>
      </div>`;
    ui.overlay.querySelectorAll("[data-buy]").forEach((btn) => {
      btn.onclick = () => send("buy", { item_id: btn.getAttribute("data-buy") });
    });
    ui.overlay.querySelector("#btn-next").onclick = () => send("next_stage", {});
    return;
  }
  if (battle.phase === "ended" && battle.result) {
    ui.overlay.classList.remove("hidden");
    const r = battle.result;
    ui.overlay.innerHTML = `
      <div class="modal">
        <h2>${r.win ? "西天有望" : "功亏一篑"}</h2>
        <p>${r.reason}</p>
        <p class="hint">分数 ${r.score || battle.score || 0}</p>
        <div class="row">
          <button type="button" id="btn-again">再走一遭</button>
          <button type="button" class="ghost" id="btn-back">返回大厅</button>
        </div>
      </div>`;
    ui.overlay.querySelector("#btn-again").onclick = () => send("start_run", { general_id: selectedGeneral, ally_ids: selectedAllies });
    ui.overlay.querySelector("#btn-back").onclick = () => send("lobby", {});
    return;
  }
  ui.overlay.classList.add("hidden");
  ui.overlay.innerHTML = "";
}

function renderBattle() {
  renderMeta();
  fillSgCard(document.getElementById("boss-card"), battle.boss, "boss");
  fillSgCard(document.getElementById("player-card"), battle.player, "player");
  const alliesBox = document.getElementById("allies");
  if (alliesBox) {
    alliesBox.innerHTML = (battle.allies || []).map((a) => {
      const down = (a.hp || 0) <= 0 ? " down" : "";
      return `<div class="sg-card${down}">${sgCardHtml(a, "ally")}</div>`;
    }).join("");
  }
  document.getElementById("passives").textContent = (battle.passives || []).map((p) => p.name).join(" · ") || "无强化";
  const bondsEl = document.getElementById("active-bonds");
  if (bondsEl) {
    const bonds = battle.bonds || [];
    bondsEl.textContent = bonds.length ? bonds.map((b) => b.name).join(" · ") : "";
  }
  document.getElementById("prompt").textContent = playbackHold
    ? "助战回合"
    : (battle.prompt || "");
  const log = document.getElementById("log");
  log.innerHTML = (battle.log || []).map((line) => `<li>${line}</li>`).join("");
  log.scrollTop = log.scrollHeight;
  renderHand();
  renderActions();
  renderOverlay();
}

document.getElementById("btn-login").onclick = () => {
  send("login", { username: ui.username.value.trim(), password: ui.password.value });
};
document.getElementById("btn-register").onclick = () => {
  send("register", { username: ui.username.value.trim(), password: ui.password.value });
};
document.getElementById("btn-start").onclick = () => {
  send("start_run", { general_id: selectedGeneral, ally_ids: selectedAllies });
};
document.getElementById("btn-resume").onclick = () => send("resume_run", {});
document.getElementById("btn-rank-refresh").onclick = () => send("rank", {});
ui.btnRank.onclick = () => {
  rankOpen = true;
  renderRankOverlay();
  send("rank", {});
};

connect();
