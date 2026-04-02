// main.js — Electron 主进程：双窗口 + DB 集成 + IPC 处理
const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');

let workoutWindow = null;
let petWindow = null;
let db = null;

// DB 和业务模块（动态导入，因为是 ESM）
let dbWorkout, dbPet, petGrowth, dbSchema;

function createPetWindow() {
  const { width, height } = screen.getPrimaryDisplay().workAreaSize;

  petWindow = new BrowserWindow({
    width: 200,
    height: 240,
    x: width - 220,
    y: height - 260,
    alwaysOnTop: true,
    transparent: true,
    frame: false,
    resizable: false,
    skipTaskbar: true,
    hasShadow: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  petWindow.loadFile('src/renderer/pet-overlay/index.html');
  petWindow.setIgnoreMouseEvents(true, { forward: true });
  petWindow.on('closed', () => { petWindow = null; });
}

function createWorkoutWindow() {
  workoutWindow = new BrowserWindow({
    width: 960,
    height: 720,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  workoutWindow.loadFile('src/renderer/workout/index.html');

  // 页面加载完成后才显示，避免白屏
  workoutWindow.once('ready-to-show', () => {
    workoutWindow.show();
  });

  workoutWindow.on('closed', () => { workoutWindow = null; });
}

app.whenReady().then(async () => {
  // 动态导入 ESM 模块
  dbSchema  = await import('./src/db/schema.js');
  dbWorkout = await import('./src/db/workout.js');
  dbPet     = await import('./src/db/pet.js');
  petGrowth = await import('./src/pet/growth.js');

  // 初始化数据库（存放在用户数据目录）
  const dbPath = path.join(app.getPath('userData'), 'fitpet.db');
  db = dbSchema.createDatabase(dbPath);

  createPetWindow();
  createWorkoutWindow();

  // 启动时发送初始宠物状态
  setTimeout(() => sendPetStatus(), 1500);
});

// ===== IPC 处理 =====

// 显示运动窗口
ipcMain.on('show-workout', () => {
  if (!workoutWindow) {
    createWorkoutWindow();
  } else {
    workoutWindow.show();
    workoutWindow.focus();
  }
});

// 运动完成 → 保存记录 → 更新宠物
ipcMain.on('workout-completed', (_event, data) => {
  if (!db) return;
  const { date, sessions } = data;

  // 保存每项运动记录
  for (const s of sessions) {
    dbWorkout.saveSession(db, {
      date,
      exercise: s.exercise,
      completed_sets: s.completed_sets,
      total_sets: s.total_sets,
    });
  }

  // 计算完成率
  const completionRate = dbWorkout.getCompletionRate(db, date);

  // 获取当前宠物状态
  const petState = dbPet.getPetState(db);

  // 连续高完成率天数（用于升境界判断）
  const consecutiveHighDays = dbPet.getConsecutiveHighDays(db, date);

  // 计算新级别
  const { level: newLevel, realm: newRealm } = petGrowth.calculateNewLevel(
    petState.current_realm,
    petState.current_level,
    completionRate,
    consecutiveHighDays
  );

  // 计算连续打卡天数
  const yesterday = new Date(date);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().slice(0, 10);
  const streak = petState.last_active_date === yesterdayStr
    ? petState.streak_days + 1
    : (petState.last_active_date === date ? petState.streak_days : 1);

  // 更新宠物状态
  dbPet.updatePetState(db, {
    current_realm: newRealm,
    current_level: newLevel,
    streak_days: streak,
    last_active_date: date,
  });

  // 保存每日汇总
  dbPet.saveDailySummary(db, date, completionRate, streak);

  // 通知悬浮窗更新
  sendPetStatus();
});

// 悬浮窗切换鼠标穿透
ipcMain.on('set-ignore-mouse', (_event, ignore) => {
  if (petWindow) {
    petWindow.setIgnoreMouseEvents(ignore, { forward: true });
  }
});

// 渲染进程请求运动计划
ipcMain.handle('get-workout-plans', () => {
  if (!db) return [];
  return dbWorkout.getWorkoutPlans(db);
});

// 发送宠物状态到悬浮窗
function sendPetStatus() {
  if (!petWindow || !db) return;

  const petState = dbPet.getPetState(db);
  const today = new Date().toISOString().slice(0, 10);
  const completionRate = dbWorkout.getCompletionRate(db, today);
  const mood = petGrowth.getPetMood(completionRate);
  const plans = dbWorkout.getWorkoutPlans(db);

  petWindow.webContents.send('pet-update', {
    realm: petState.current_realm,
    level: petState.current_level,
    levelInRealm: petGrowth.getLevelInRealm(petState.current_level),
    completionRate,
    streak: petState.streak_days,
    mood,
    exercises: plans.map(p => ({
      name: p.exercise,
      completedSets: 0,
      totalSets: p.sets,
      done: false,
    })),
  });
}

// macOS：点击 Dock 图标时重建窗口
app.on('activate', () => {
  if (!petWindow) createPetWindow();
  if (!workoutWindow) createWorkoutWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
