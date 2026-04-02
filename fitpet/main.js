// main.js — Electron 主进程：创建运动主窗口 + 宠物悬浮窗
const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');

let workoutWindow = null;
let petWindow = null;

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
  workoutWindow.on('closed', () => { workoutWindow = null; });
}

app.whenReady().then(() => {
  createPetWindow();
  createWorkoutWindow();
});

ipcMain.on('show-workout', () => {
  if (!workoutWindow) createWorkoutWindow();
  workoutWindow.show();
  workoutWindow.focus();
});

ipcMain.on('workout-completed', (_event, data) => {
  if (petWindow) {
    petWindow.webContents.send('pet-update', data);
  }
});

ipcMain.on('set-ignore-mouse', (_event, ignore) => {
  if (petWindow) {
    petWindow.setIgnoreMouseEvents(ignore, { forward: true });
  }
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
