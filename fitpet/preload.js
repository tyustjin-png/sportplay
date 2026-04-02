// preload.js — contextBridge 暴露安全的 IPC 接口给渲染进程
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('fitpet', {
  showWorkout: () => ipcRenderer.send('show-workout'),
  workoutCompleted: (data) => ipcRenderer.send('workout-completed', data),
  setIgnoreMouse: (ignore) => ipcRenderer.send('set-ignore-mouse', ignore),
  onPetUpdate: (callback) => {
    // 先清除旧监听器，防止重复注册
    ipcRenderer.removeAllListeners('pet-update');
    ipcRenderer.on('pet-update', (_e, data) => callback(data));
  },
});
