// src/renderer/pet-overlay/pet.js — 宠物悬浮窗逻辑（渲染进程）

const petSprite   = document.getElementById('pet-sprite');
const expandPanel = document.getElementById('expand-panel');
const realmLevelEl = document.getElementById('realm-level');
const progressFill = document.getElementById('progress-fill');
const streakEl    = document.getElementById('streak');
const todayRateEl = document.getElementById('today-rate');
const startBtn    = document.getElementById('start-workout-btn');

let expanded = false;

const REALM_NAMES = ['第一境界', '第二境界', '第三境界'];
function getRealmName(realm) {
  return REALM_NAMES[realm - 1] || `第${realm}境界`;
}

// ===== 鼠标穿透控制 =====
petSprite.addEventListener('mouseenter', () => {
  window.fitpet.setIgnoreMouse(false);
});

petSprite.addEventListener('mouseleave', () => {
  if (!expanded) window.fitpet.setIgnoreMouse(true);
});

petSprite.addEventListener('click', () => {
  expanded = !expanded;
  expandPanel.classList.toggle('visible', expanded);
  window.fitpet.setIgnoreMouse(!expanded);
});

expandPanel.addEventListener('mouseenter', () => {
  window.fitpet.setIgnoreMouse(false);
});

expandPanel.addEventListener('mouseleave', () => {
  if (!expanded) window.fitpet.setIgnoreMouse(true);
});

// ===== 开始运动按钮 =====
startBtn.addEventListener('click', () => {
  window.fitpet.showWorkout();
});

// ===== 接收宠物状态更新 =====
window.fitpet.onPetUpdate((data) => {
  realmLevelEl.textContent = `${getRealmName(data.realm)} · Lv.${data.levelInRealm}`;

  const pct = Math.round((data.completionRate || 0) * 100);
  progressFill.style.width = `${pct}%`;
  todayRateEl.textContent  = `${pct}%`;
  streakEl.textContent     = data.streak || 0;

  // 更新宠物心情动画
  petSprite.className = 'pet-sprite egg';
  if (data.mood === 'active') petSprite.classList.add('active');
  else if (data.mood === 'tired') petSprite.classList.add('tired');

  // 更新运动详情
  if (data.exercises) {
    const detailsEl = document.getElementById('exercise-details');
    detailsEl.innerHTML = data.exercises.map(e =>
      `<div class="detail-item">${e.done ? '✅' : '⬜'} ${e.name}: ${e.completedSets}/${e.totalSets}组</div>`
    ).join('');
  }
});
