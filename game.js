'use strict';

/* ============================================================
   MERGE KEEP — fully offline merge game, no server / no DB.
   All state lives in localStorage. Single file, no build step.
   ============================================================ */

const SAVE_KEY = 'mergekeep_save_v1';
const COLS = 5, ROWS = 6, CELLS = COLS * ROWS;
const MAX_TIER = 10;

const TIERS = [
  null, // 1-indexed
  { name: 'Seedling',      emoji: '🌱' },
  { name: 'Sprout',        emoji: '🌿' },
  { name: 'Clover',        emoji: '🍀' },
  { name: 'Sapling',       emoji: '🌳' },
  { name: 'Ancient Tree',  emoji: '🌲' },
  { name: 'Gemstone',      emoji: '💎' },
  { name: 'Crystal',       emoji: '🔮' },
  { name: 'Star Shard',    emoji: '⭐' },
  { name: 'Radiant Star',  emoji: '🌟' },
  { name: 'Crown Jewel',   emoji: '👑' },
];

const BUILDINGS = [
  { id: 'gate',      name: 'Gate',       icon: '🚪', desc: '+2 max energy per level',
    baseCost: 40,  costMult: 1.9, maxLevel: 5 },
  { id: 'tower',     name: 'Watchtower', icon: '🗼', desc: '-8% energy regen time per level',
    baseCost: 60,  costMult: 2.0, maxLevel: 5 },
  { id: 'market',    name: 'Market',     icon: '🏪', desc: '+15% coin value per level',
    baseCost: 80,  costMult: 2.1, maxLevel: 5 },
  { id: 'garden',    name: 'Garden',     icon: '🌷', desc: '-8% coin trickle time per level',
    baseCost: 70,  costMult: 2.0, maxLevel: 5 },
  { id: 'treasury',  name: 'Treasury',   icon: '🏦', desc: '+1h offline earnings cap per level',
    baseCost: 100, costMult: 2.2, maxLevel: 5 },
];

const ACHIEVEMENTS = [
  { id: 'first_merge', icon: '✨', name: 'First Merge',    desc: 'Merge two creatures', check: s => s.stats.merges >= 1 },
  { id: 'tier5',        icon: '🌲', name: 'Growing Strong', desc: 'Reach Ancient Tree (tier 5)', check: s => s.stats.highestTier >= 5 },
  { id: 'tier10',       icon: '👑', name: 'Crown Jewel',    desc: 'Discover the full Bestiary', check: s => s.stats.highestTier >= 10 },
  { id: 'board_full',   icon: '📦', name: 'No Vacancy',     desc: 'Fill the entire board', check: s => s.stats.boardFilled },
  { id: 'streak3',      icon: '🔥', name: '3-Day Streak',   desc: 'Log in 3 days in a row', check: s => s.streak >= 3 },
  { id: 'streak7',      icon: '🔥', name: 'Week of Wonder', desc: 'Log in 7 days in a row', check: s => s.streak >= 7 },
  { id: 'coins1000',    icon: '🪙', name: 'Coin Collector', desc: 'Earn 1,000 coins total', check: s => s.stats.totalCoinsEarned >= 1000 },
  { id: 'coins10000',   icon: '💰', name: 'Treasurer',      desc: 'Earn 10,000 coins total', check: s => s.stats.totalCoinsEarned >= 10000 },
  { id: 'castle10',     icon: '🏰', name: 'Castle Rising',  desc: 'Reach 10 total castle levels', check: s => totalBuildingLevels(s) >= 10 },
  { id: 'combo5',       icon: '⚡', name: 'Combo Master',   desc: 'Reach a x5 merge combo', check: s => s.stats.bestCombo >= 5 },
];

/* ---------------- State ---------------- */

function freshState() {
  return {
    board: new Array(CELLS).fill(null),
    nextTileId: 1,
    coins: 0,
    energy: 5,
    energyMax: 5,
    lastEnergyTs: Date.now(),
    lastSaveTs: Date.now(),
    streak: 0,
    lastLoginDate: null,
    buildings: { gate: 0, tower: 0, market: 0, garden: 0, treasury: 0 },
    achievements: {},
    muted: false,
    stats: {
      merges: 0,
      highestTier: 0,
      boardFilled: false,
      totalCoinsEarned: 0,
      bestCombo: 1,
    },
  };
}

let state = load();

function load() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return freshState();
    const parsed = JSON.parse(raw);
    const fresh = freshState();
    return Object.assign(fresh, parsed, {
      buildings: Object.assign(fresh.buildings, parsed.buildings || {}),
      stats: Object.assign(fresh.stats, parsed.stats || {}),
    });
  } catch (e) {
    console.warn('Save corrupted, starting fresh', e);
    return freshState();
  }
}

function save() {
  state.lastSaveTs = Date.now();
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(state)); } catch (e) { /* storage full/unavailable: ignore */ }
}

/* ---------------- Derived stats from buildings ---------------- */

function buildingLevel(id) { return state.buildings[id] || 0; }
function totalBuildingLevels(s) {
  return Object.values(s.buildings).reduce((a, b) => a + b, 0);
}
function buildingCost(def, level) {
  return Math.round(def.baseCost * Math.pow(def.costMult, level));
}
function energyMax() { return 5 + buildingLevel('gate') * 2; }
function energyRegenMs() {
  const reduction = Math.pow(0.92, buildingLevel('tower'));
  return Math.max(20000, Math.round(60000 * reduction));
}
function coinMultiplier() { return 1 + buildingLevel('market') * 0.15; }
function coinIntervalMs(tier) {
  const base = Math.max(4000, 13000 - tier * 400);
  const reduction = Math.pow(0.92, buildingLevel('garden'));
  return Math.max(2500, Math.round(base * reduction));
}
function offlineCapMs() { return (3 + buildingLevel('treasury')) * 3600000; }

/* ---------------- Board helpers ---------------- */

function emptyIndices() {
  const out = [];
  for (let i = 0; i < CELLS; i++) if (!state.board[i]) out.push(i);
  return out;
}

function makeTile(tier) {
  return { id: state.nextTileId++, tier, lastCoinTs: Date.now(), coinReady: false };
}

/* ---------------- DOM refs ---------------- */

const boardEl = document.getElementById('board');
const fxLayer = document.getElementById('fxLayer');
const coinValEl = document.getElementById('coinVal');
const energyValEl = document.getElementById('energyVal');
const energyTimerEl = document.getElementById('energyTimer');
const streakValEl = document.getElementById('streakVal');
const nestBtn = document.getElementById('nestBtn');
const comboWrap = document.getElementById('comboWrap');
const comboText = document.getElementById('comboText');
const castlePowerEl = document.getElementById('castlePower');
const castleArtEl = document.getElementById('castleArt');
const buildingsListEl = document.getElementById('buildingsList');
const bestiaryEl = document.getElementById('bestiary');
const achievementsEl = document.getElementById('achievements');
const toastEl = document.getElementById('toast');
const modalOverlay = document.getElementById('modalOverlay');
const modalTitle = document.getElementById('modalTitle');
const modalBody = document.getElementById('modalBody');
const modalClose = document.getElementById('modalClose');
const muteBtn = document.getElementById('muteBtn');
const muteIcon = document.getElementById('muteIcon');

/* ---------------- Cells setup ---------------- */

const cellEls = [];
for (let i = 0; i < CELLS; i++) {
  const c = document.createElement('div');
  c.className = 'cell';
  c.dataset.index = i;
  boardEl.appendChild(c);
  cellEls.push(c);
}

const tileEls = new Map(); // tile id -> element

/* ---------------- Sound (procedural, no assets) ---------------- */

let actx = null;
function ensureAudio() {
  if (!actx) {
    try { actx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { /* unsupported */ }
  }
  if (actx && actx.state === 'suspended') actx.resume();
}
function beep(freq, dur, type = 'sine', vol = 0.15) {
  if (state.muted || !actx) return;
  const osc = actx.createOscillator();
  const gain = actx.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  gain.gain.value = vol;
  osc.connect(gain).connect(actx.destination);
  const now = actx.currentTime;
  gain.gain.setValueAtTime(vol, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + dur);
  osc.start(now);
  osc.stop(now + dur);
}
function sfxSpawn() { beep(520, 0.12, 'triangle'); }
function sfxMerge(tier) { beep(300 + tier * 40, 0.18, 'sawtooth', 0.12); beep(600 + tier * 40, 0.15, 'sine', 0.08); }
function sfxCoin() { beep(880, 0.1, 'square', 0.07); }
function sfxUpgrade() { beep(440, 0.1, 'sine'); setTimeout(() => beep(660, 0.15, 'sine'), 90); }
function sfxError() { beep(140, 0.15, 'square', 0.1); }

function vibrate(pattern) {
  if (state.muted) return;
  if (navigator.vibrate) { try { navigator.vibrate(pattern); } catch (e) { /* ignore */ } }
}

/* ---------------- Toast ---------------- */

let toastTimer = null;
function toast(msg) {
  clearTimeout(toastTimer);
  toastEl.textContent = msg;
  toastEl.classList.add('show');
  toastTimer = setTimeout(() => toastEl.classList.remove('show'), 1800);
}

/* ---------------- FX ---------------- */

function burstParticles(x, y, emoji, count = 8) {
  for (let i = 0; i < count; i++) {
    const p = document.createElement('span');
    p.className = 'particle';
    p.textContent = emoji;
    const angle = (Math.PI * 2 * i) / count + Math.random() * 0.5;
    const dist = 30 + Math.random() * 30;
    p.style.setProperty('--dx', `${Math.cos(angle) * dist}px`);
    p.style.setProperty('--dy', `${Math.sin(angle) * dist}px`);
    p.style.left = `${x}px`;
    p.style.top = `${y}px`;
    fxLayer.appendChild(p);
    setTimeout(() => p.remove(), 650);
  }
}

function floatText(x, y, text) {
  const f = document.createElement('div');
  f.className = 'floatup';
  f.textContent = text;
  f.style.left = `${x}px`;
  f.style.top = `${y}px`;
  fxLayer.appendChild(f);
  setTimeout(() => f.remove(), 950);
}

function screenShake() {
  const wrap = document.querySelector('.board-wrap');
  wrap.classList.remove('shake-screen');
  void wrap.offsetWidth;
  wrap.classList.add('shake-screen');
}

/* ---------------- Layout / geometry ---------------- */

function cellRect(index) {
  const cell = cellEls[index];
  const cRect = cell.getBoundingClientRect();
  const bRect = boardEl.getBoundingClientRect();
  return {
    left: cRect.left - bRect.left,
    top: cRect.top - bRect.top,
    width: cRect.width,
    height: cRect.height,
  };
}

function positionTileEl(el, index, animate) {
  const r = cellRect(index);
  el.style.width = `${r.width}px`;
  el.style.height = `${r.height}px`;
  if (animate) el.classList.add('snap-back');
  el.style.left = `${r.left}px`;
  el.style.top = `${r.top}px`;
  el.style.transform = 'translate(0,0)';
  if (animate) setTimeout(() => el.classList.remove('snap-back'), 220);
}

/* ---------------- Rendering ---------------- */

function tileValue(tier) {
  return Math.round(tier * coinMultiplier());
}

function renderTile(index, justCreated, justMerged) {
  const t = state.board[index];
  if (!t) return;
  let el = tileEls.get(t.id);
  const isNew = !el;
  if (isNew) {
    el = document.createElement('div');
    el.className = 'tile';
    el.dataset.id = t.id;
    boardEl.parentElement.querySelector('.board').appendChild(el);
    el.innerHTML = `<span class="emoji"></span><span class="tierlabel"></span><span class="coin-badge" hidden>🪙</span>`;
    attachDrag(el);
    tileEls.set(t.id, el);
  }
  const info = TIERS[t.tier];
  el.querySelector('.emoji').textContent = info.emoji;
  el.querySelector('.tierlabel').textContent = info.name;
  el.querySelector('.coin-badge').hidden = !t.coinReady;
  positionTileEl(el, index, false);
  if (justCreated) { el.classList.remove('spawn-pop'); void el.offsetWidth; el.classList.add('spawn-pop'); }
  if (justMerged) { el.classList.remove('merge-pop'); void el.offsetWidth; el.classList.add('merge-pop'); }
}

function removeTileEl(tileId) {
  const el = tileEls.get(tileId);
  if (el) { el.remove(); tileEls.delete(tileId); }
}

function renderBoard() {
  const liveIds = new Set();
  for (let i = 0; i < CELLS; i++) {
    const t = state.board[i];
    if (t) { liveIds.add(t.id); renderTile(i, false, false); }
  }
  for (const id of Array.from(tileEls.keys())) {
    if (!liveIds.has(id)) removeTileEl(id);
  }
}

function renderTopbar() {
  coinValEl.textContent = formatNum(state.coins);
  energyValEl.textContent = `${state.energy}/${energyMax()}`;
  streakValEl.textContent = state.streak;
  if (state.energy >= energyMax()) {
    energyTimerEl.textContent = 'full';
  } else {
    const remain = energyRegenMs() - (Date.now() - state.lastEnergyTs);
    energyTimerEl.textContent = formatDuration(Math.max(0, remain));
  }
  nestBtn.disabled = state.energy < 1 || emptyIndices().length === 0;
}

function formatNum(n) {
  if (n < 1000) return String(Math.floor(n));
  if (n < 1000000) return (n / 1000).toFixed(n < 10000 ? 1 : 0) + 'k';
  return (n / 1000000).toFixed(1) + 'm';
}
function formatDuration(ms) {
  const s = Math.ceil(ms / 1000);
  if (s < 60) return `${s}s`;
  return `${Math.floor(s / 60)}m ${s % 60}s`;
}

function bumpStat(el) {
  el.classList.remove('bump');
  void el.offsetWidth;
  el.classList.add('bump');
  setTimeout(() => el.classList.remove('bump'), 160);
}

/* ---------------- Castle screen render ---------------- */

function castleArtFor(total) {
  if (total >= 21) return '🏯';
  if (total >= 15) return '🏰';
  if (total >= 9) return '🏡';
  if (total >= 4) return '🏠';
  return '🏚️';
}

function renderCastle() {
  const total = totalBuildingLevels(state);
  castlePowerEl.textContent = total * 10;
  castleArtEl.textContent = castleArtFor(total);

  buildingsListEl.innerHTML = '';
  for (const def of BUILDINGS) {
    const level = buildingLevel(def.id);
    const maxed = level >= def.maxLevel;
    const cost = maxed ? null : buildingCost(def, level);
    const card = document.createElement('div');
    card.className = 'building-card';
    card.innerHTML = `
      <div class="building-icon">${def.icon}</div>
      <div class="building-info">
        <div class="building-name">${def.name} <span style="color:var(--text-dim);font-weight:400;">Lv.${level}/${def.maxLevel}</span></div>
        <div class="building-desc">${def.desc}</div>
        <div class="building-bar"><div class="building-bar-fill" style="width:${(level / def.maxLevel) * 100}%"></div></div>
      </div>
      <button class="building-upgrade ${maxed ? 'maxed' : ''}" data-id="${def.id}" ${maxed || state.coins < cost ? 'disabled' : ''}>
        ${maxed ? 'MAX' : `🪙 ${formatNum(cost)}`}
      </button>
    `;
    buildingsListEl.appendChild(card);
  }

  bestiaryEl.innerHTML = '';
  for (let tier = 1; tier <= MAX_TIER; tier++) {
    const seen = state.stats.highestTier >= tier;
    const info = TIERS[tier];
    const slot = document.createElement('div');
    slot.className = 'bestiary-slot' + (seen ? '' : ' locked');
    slot.innerHTML = seen
      ? `<span>${info.emoji}</span><span class="bname">${info.name}</span>`
      : `<span>❔</span>`;
    bestiaryEl.appendChild(slot);
  }

  achievementsEl.innerHTML = '';
  for (const a of ACHIEVEMENTS) {
    const unlocked = !!state.achievements[a.id];
    const row = document.createElement('div');
    row.className = 'ach-row' + (unlocked ? ' unlocked' : '');
    row.innerHTML = `
      <div class="ach-icon">${unlocked ? a.icon : '🔒'}</div>
      <div>
        <div class="ach-name">${a.name}</div>
        <div class="ach-desc">${a.desc}</div>
      </div>
    `;
    achievementsEl.appendChild(row);
  }
}

buildingsListEl.addEventListener('click', (e) => {
  const btn = e.target.closest('.building-upgrade');
  if (!btn || btn.disabled) return;
  const def = BUILDINGS.find(b => b.id === btn.dataset.id);
  const level = buildingLevel(def.id);
  if (level >= def.maxLevel) return;
  const cost = buildingCost(def, level);
  if (state.coins < cost) { sfxError(); return; }
  state.coins -= cost;
  state.buildings[def.id] = level + 1;
  sfxUpgrade();
  vibrate([20, 30, 20]);
  toast(`${def.name} upgraded to Lv.${level + 1}!`);
  renderCastle();
  renderTopbar();
  checkAchievements();
  save();
});

/* ---------------- Achievements ---------------- */

function checkAchievements() {
  for (const a of ACHIEVEMENTS) {
    if (!state.achievements[a.id] && a.check(state)) {
      state.achievements[a.id] = true;
      toast(`🏆 Achievement: ${a.name}`);
      vibrate([15, 40, 15, 40, 15]);
    }
  }
}

/* ---------------- Merge logic ---------------- */

let comboCount = 0;
let comboTimer = null;

function registerMerge() {
  comboCount++;
  state.stats.bestCombo = Math.max(state.stats.bestCombo, comboCount);
  clearTimeout(comboTimer);
  if (comboCount >= 2) {
    comboWrap.hidden = false;
    comboText.textContent = `Combo x${comboCount}`;
  }
  comboTimer = setTimeout(() => { comboCount = 0; comboWrap.hidden = true; }, 2200);
}

function comboMultiplier() {
  return Math.min(3, 1 + (comboCount - 1) * 0.25);
}

function doMerge(fromIndex, toIndex) {
  const a = state.board[fromIndex];
  const b = state.board[toIndex];
  if (!a || !b || a.tier !== b.tier) return false;
  if (a.tier >= MAX_TIER) return false;

  const newTier = a.tier + 1;
  removeTileEl(a.id);
  removeTileEl(b.id);
  state.board[fromIndex] = null;
  const newTile = makeTile(newTier);
  state.board[toIndex] = newTile;

  state.stats.merges++;
  state.stats.highestTier = Math.max(state.stats.highestTier, newTier);
  registerMerge();

  const reward = Math.round(tileValue(newTier) * 1.5 * comboMultiplier());
  addCoins(reward, toIndex, true);

  const rect = cellRect(toIndex);
  const cx = rect.left + rect.width / 2, cy = rect.top + rect.height / 2;
  burstParticles(cx, cy, TIERS[newTier].emoji, Math.min(12, 6 + newTier));
  sfxMerge(newTier);
  vibrate(newTier >= MAX_TIER ? [30, 60, 30, 60, 60] : [25]);
  if (newTier === MAX_TIER) { screenShake(); toast('👑 Crown Jewel forged!'); }

  renderTile(toIndex, false, true);
  checkAchievements();
  return true;
}

function addCoins(amount, atIndex, floaty) {
  state.coins += amount;
  state.stats.totalCoinsEarned += amount;
  if (floaty && atIndex != null) {
    const rect = cellRect(atIndex);
    floatText(rect.left + rect.width / 2 - 10, rect.top, `+${amount}`);
  }
  bumpStat(document.getElementById('coinStat'));
  renderTopbar();
}

/* ---------------- Spawner ---------------- */

nestBtn.addEventListener('click', () => {
  ensureAudio();
  if (state.energy < 1) { sfxError(); toast('Out of energy — wait for it to refill.'); return; }
  const empties = emptyIndices();
  if (empties.length === 0) {
    sfxError();
    toast('Board is full! Merge some creatures.');
    nestBtn.classList.remove('shake');
    void nestBtn.offsetWidth;
    nestBtn.classList.add('shake');
    return;
  }
  state.energy -= 1;
  const idx = empties[Math.floor(Math.random() * empties.length)];
  state.board[idx] = makeTile(1);
  sfxSpawn();
  vibrate(15);
  renderTile(idx, true, false);
  if (emptyIndices().length === 0) {
    state.stats.boardFilled = true;
    checkAchievements();
  }
  renderTopbar();
  save();
});

/* ---------------- Drag & drop merge ---------------- */

let drag = null; // {id, fromIndex, startX, startY, el, moved}

function attachDrag(el) {
  el.addEventListener('pointerdown', onPointerDown);
}

function tileIndexById(id) {
  return state.board.findIndex(t => t && t.id === Number(id));
}

function onPointerDown(e) {
  ensureAudio();
  const el = e.currentTarget;
  const id = Number(el.dataset.id);
  const fromIndex = tileIndexById(id);
  if (fromIndex === -1) return;
  el.setPointerCapture(e.pointerId);
  drag = {
    id, fromIndex, el,
    startClientX: e.clientX, startClientY: e.clientY,
    baseLeft: parseFloat(el.style.left), baseTop: parseFloat(el.style.top),
    moved: false,
  };
  el.classList.add('dragging');
  el.addEventListener('pointermove', onPointerMove);
  el.addEventListener('pointerup', onPointerUp);
  el.addEventListener('pointercancel', onPointerUp);
}

function onPointerMove(e) {
  if (!drag) return;
  const dx = e.clientX - drag.startClientX;
  const dy = e.clientY - drag.startClientY;
  if (Math.abs(dx) > 4 || Math.abs(dy) > 4) drag.moved = true;
  drag.el.style.transform = `translate(${dx}px, ${dy}px)`;
  drag.lastClientX = e.clientX;
  drag.lastClientY = e.clientY;
}

function onPointerUp(e) {
  if (!drag) return;
  const d = drag;
  drag = null;
  d.el.classList.remove('dragging');
  d.el.removeEventListener('pointermove', onPointerMove);
  d.el.removeEventListener('pointerup', onPointerUp);
  d.el.removeEventListener('pointercancel', onPointerUp);

  if (!d.moved) {
    handleTap(d.fromIndex);
    positionTileEl(d.el, d.fromIndex, false);
    return;
  }

  const clientX = e.clientX, clientY = e.clientY;
  const targetIndex = cellIndexAtPoint(clientX, clientY);

  if (targetIndex == null || targetIndex === d.fromIndex) {
    positionTileEl(d.el, d.fromIndex, true);
    return;
  }

  const targetTile = state.board[targetIndex];
  if (!targetTile) {
    state.board[targetIndex] = state.board[d.fromIndex];
    state.board[d.fromIndex] = null;
    positionTileEl(d.el, targetIndex, true);
    save();
    return;
  }

  if (targetTile.tier === state.board[d.fromIndex].tier && targetTile.tier < MAX_TIER) {
    doMerge(d.fromIndex, targetIndex);
    renderTopbar();
    save();
    return;
  }

  // occupied by different tier / maxed tile: snap back
  positionTileEl(d.el, d.fromIndex, true);
}

function cellIndexAtPoint(x, y) {
  for (let i = 0; i < CELLS; i++) {
    const r = cellEls[i].getBoundingClientRect();
    if (x >= r.left && x <= r.right && y >= r.top && y <= r.bottom) return i;
  }
  return null;
}

function handleTap(index) {
  const t = state.board[index];
  if (!t) return;
  if (t.coinReady) {
    const reward = tileValue(t.tier);
    t.coinReady = false;
    t.lastCoinTs = Date.now();
    addCoins(reward, index, true);
    sfxCoin();
    vibrate(10);
    renderTile(index, false, false);
    save();
  }
}

/* ---------------- Ticking (coin trickle + energy regen + timers) ---------------- */

function tick() {
  const now = Date.now();

  // coin readiness
  let anyReadyChanged = false;
  for (let i = 0; i < CELLS; i++) {
    const t = state.board[i];
    if (!t) continue;
    if (!t.coinReady && now - t.lastCoinTs >= coinIntervalMs(t.tier)) {
      t.coinReady = true;
      anyReadyChanged = true;
      renderTile(i, false, false);
    }
  }

  // energy regen
  const regenMs = energyRegenMs();
  let energyChanged = false;
  while (state.energy < energyMax() && now - state.lastEnergyTs >= regenMs) {
    state.energy += 1;
    state.lastEnergyTs += regenMs;
    energyChanged = true;
  }
  if (state.energy >= energyMax()) state.lastEnergyTs = now;

  renderTopbar();
  if (energyChanged) bumpStat(document.getElementById('energyStat'));
  if (anyReadyChanged || energyChanged) save();
}

/* ---------------- Navigation ---------------- */

document.querySelectorAll('.navbtn[data-screen]').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.navbtn[data-screen]').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById(btn.dataset.screen).classList.add('active');
    if (btn.dataset.screen === 'castleScreen') renderCastle();
    if (btn.dataset.screen === 'mergeScreen') renderBoard();
  });
});

muteBtn.addEventListener('click', () => {
  state.muted = !state.muted;
  muteIcon.textContent = state.muted ? '🔇' : '🔊';
  save();
});

/* ---------------- Daily streak + offline earnings ---------------- */

function dateStr(d) { return d.toDateString(); }

function handleDailyLoginAndOffline() {
  const now = Date.now();
  const elapsedSinceSave = now - (state.lastSaveTs || now);
  const todayStr = dateStr(new Date());

  // offline coin trickle (capped by treasury level)
  let offlineCoins = 0;
  if (elapsedSinceSave > 15000) {
    const cappedMs = Math.min(elapsedSinceSave, offlineCapMs());
    let boardValue = 0;
    for (const t of state.board) if (t) boardValue += tileValue(t.tier);
    const avgIntervalMs = 9000;
    offlineCoins = Math.round(boardValue * (cappedMs / avgIntervalMs) * 0.5);
    if (offlineCoins > 0) addCoins(offlineCoins, null, false);
  }

  let isNewDay = false;
  let rewardCoins = 0;
  if (state.lastLoginDate !== todayStr) {
    isNewDay = true;
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    if (state.lastLoginDate === dateStr(yesterday)) {
      state.streak += 1;
    } else {
      state.streak = 1;
    }
    state.lastLoginDate = todayStr;
    rewardCoins = 20 + state.streak * 15;
    addCoins(rewardCoins, null, false);
    state.energy = energyMax();
    state.lastEnergyTs = now;
    checkAchievements();
  }

  if (isNewDay) {
    modalTitle.textContent = `🔥 Day ${state.streak} Streak!`;
    let body = `+${rewardCoins} coins and full energy!`;
    if (offlineCoins > 0) body += ` Plus +${offlineCoins} coins earned while away.`;
    modalBody.textContent = body;
    modalOverlay.hidden = false;
  } else if (offlineCoins > 0) {
    toast(`Welcome back! +${offlineCoins} coins earned while away.`);
  }

  save();
}

modalClose.addEventListener('click', () => {
  modalOverlay.hidden = true;
  ensureAudio();
});

/* ---------------- Resize handling ---------------- */

window.addEventListener('resize', () => renderBoard());

/* ---------------- Service worker (offline caching) ---------------- */

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('sw.js').catch(() => { /* offline-first best effort */ });
  });
}

/* ---------------- Init ---------------- */

function init() {
  muteIcon.textContent = state.muted ? '🔇' : '🔊';
  renderBoard();
  renderTopbar();
  renderCastle();
  handleDailyLoginAndOffline();
  renderTopbar();
  renderBoard();

  setInterval(tick, 1000);
  setInterval(save, 15000);
  window.addEventListener('beforeunload', save);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') save();
    else handleDailyLoginAndOffline();
  });
}

init();
