// src/renderer/workout/workout.js — 运动主窗口逻辑（渲染进程）

import { initPoseDetector, detectPose } from '../../detection/pose-detector.js';
import { createPushupCounter } from '../../detection/pushup.js';
import { createSquatCounter } from '../../detection/squat.js';
import { createSitupCounter } from '../../detection/situp.js';
import { createZhanZhuangTimer } from '../../detection/zhan-zhuang.js';

// 运动检测器工厂映射
const DETECTORS = {
  pushup: createPushupCounter,
  squat: createSquatCounter,
  situp: createSitupCounter,
  zhan_zhuang: createZhanZhuangTimer,
};

// 运动中文名
const EXERCISE_NAMES = {
  pushup: '俯卧撑',
  squat: '深蹲',
  zhan_zhuang: '站桩',
  situp: '仰卧起坐',
  kegel: '凯格尔',
};

let currentExercise = null;
let currentDetector = null;
let poseLandmarker = null;
let plans = [];
let sessions = {};
let animFrameId = null;
let loopRunning = false;

// ===== 初始化 =====
async function init() {
  // 尝试从主进程获取计划，失败时用默认值
  let dbPlans = null;
  try {
    dbPlans = await window.fitpet.getWorkoutPlans();
  } catch (e) {
    console.warn('无法从DB获取计划，使用默认值');
  }

  plans = (dbPlans && dbPlans.length > 0) ? dbPlans : [
    { exercise: 'pushup',      sets: 3, reps: 15,   duration_seconds: null },
    { exercise: 'squat',       sets: 3, reps: 20,   duration_seconds: null },
    { exercise: 'zhan_zhuang', sets: 1, reps: null,  duration_seconds: 300 },
    { exercise: 'situp',       sets: 3, reps: 20,   duration_seconds: null },
    { exercise: 'kegel',       sets: 3, reps: null,  duration_seconds: 10  },
  ];

  plans.forEach(p => {
    sessions[p.exercise] = { completedSets: 0, totalSets: p.sets };
  });

  renderPlanList();
  await startCamera();

  // 异步初始化 MediaPipe（不阻塞 UI）
  initPoseDetector().then(lm => {
    poseLandmarker = lm;
    console.log('MediaPipe 初始化完成');
  }).catch(err => console.error('MediaPipe 初始化失败:', err));
}

// ===== 摄像头 =====
async function startCamera() {
  const video = document.getElementById('camera');
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { width: 640, height: 480, facingMode: 'user' },
    });
    video.srcObject = stream;
    await video.play();
  } catch (err) {
    console.error('摄像头启动失败:', err);
    document.getElementById('counter').textContent = '摄像头不可用';
  }
}

// ===== 检测循环 =====
function startDetectionLoop() {
  if (loopRunning) return; // 防止重复启动
  loopRunning = true;

  const video = document.getElementById('camera');
  const canvas = document.getElementById('skeleton');
  const ctx = canvas.getContext('2d');
  const counterEl = document.getElementById('counter');

  function loop() {
    if (!loopRunning) return;

    // 用显示尺寸而非原始分辨率，避免 object-fit:cover 导致坐标偏移
    const displayW = video.clientWidth  || video.offsetWidth;
    const displayH = video.clientHeight || video.offsetHeight;
    if (displayW > 0 && displayH > 0) {
      canvas.width  = displayW;
      canvas.height = displayH;
    }

    const landmarks = poseLandmarker ? detectPose(poseLandmarker, video, performance.now()) : null;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    if (landmarks) {
      // 绘制骨架关键点
      ctx.fillStyle = '#00ff88';
      landmarks.forEach(lm => {
        if (lm.visibility > 0.5) {
          ctx.beginPath();
          ctx.arc(lm.x * canvas.width, lm.y * canvas.height, 4, 0, 2 * Math.PI);
          ctx.fill();
        }
      });

      // 更新当前检测器
      if (currentDetector) {
        if (currentExercise === 'zhan_zhuang') {
          currentDetector.update(landmarks, performance.now());
          const state = currentDetector.getState();
          const secs = Math.floor(state.elapsed / 1000);
          counterEl.textContent = `站桩 ${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, '0')}`;
        } else {
          currentDetector.update(landmarks);
          const state = currentDetector.getState();
          counterEl.textContent = `${EXERCISE_NAMES[currentExercise] || currentExercise} × ${state.count}`;
        }
      }
    }

    animFrameId = requestAnimationFrame(loop);
  }

  loop();
}

// ===== 计划列表渲染 =====
function renderPlanList() {
  const listEl = document.getElementById('plan-list');
  listEl.innerHTML = '';

  plans.forEach(plan => {
    const div = document.createElement('div');
    div.className = 'exercise-item';
    const sess = sessions[plan.exercise];
    if (sess.completedSets >= plan.sets) div.classList.add('completed');
    if (currentExercise === plan.exercise) div.classList.add('active');

    const target = plan.reps
      ? `${plan.sets}组 × ${plan.reps}个`
      : `${plan.sets}组 × ${plan.duration_seconds}秒`;

    div.innerHTML = `
      <div class="name">${EXERCISE_NAMES[plan.exercise] || plan.exercise}</div>
      <div class="progress">${sess.completedSets}/${plan.sets} 组 | 目标：${target}</div>
    `;
    div.addEventListener('click', () => selectExercise(plan.exercise));
    listEl.appendChild(div);
  });
}

// ===== 选择运动项目 =====
function selectExercise(exercise) {
  currentExercise = exercise;

  if (exercise === 'kegel') {
    document.getElementById('kegel-panel').style.display = 'block';
    currentDetector = null;
    loopRunning = false;
    if (animFrameId) cancelAnimationFrame(animFrameId);
  } else {
    document.getElementById('kegel-panel').style.display = 'none';
    const factory = DETECTORS[exercise];
    if (factory) {
      currentDetector = factory();
      loopRunning = false; // 重置，让 startDetectionLoop 重新启动
      startDetectionLoop();
    }
  }

  renderPlanList();
}

// ===== 凯格尔定时器 =====
document.getElementById('kegel-start-btn').addEventListener('click', () => {
  let remaining = 10;
  const countdownEl = document.getElementById('kegel-countdown');
  const btn = document.getElementById('kegel-start-btn');
  btn.disabled = true;

  const timer = setInterval(() => {
    remaining--;
    countdownEl.textContent = remaining;

    if (remaining <= 0) {
      clearInterval(timer);
      btn.disabled = false;
      countdownEl.textContent = '✅';
      sessions.kegel.completedSets++;
      renderPlanList();
      checkAllCompleted();
      setTimeout(() => { countdownEl.textContent = '10'; }, 1000);
    }
  }, 1000);
});

// ===== 完成检查 =====
function checkAllCompleted() {
  const allDone = plans.every(p => sessions[p.exercise].completedSets >= p.sets);
  if (allDone) {
    const today = new Date().toISOString().slice(0, 10);
    window.fitpet.workoutCompleted({
      date: today,
      sessions: Object.entries(sessions).map(([exercise, s]) => ({
        exercise,
        completed_sets: s.completedSets,
        total_sets: s.totalSets,
      })),
    });
  }
}

// 启动
init().catch(err => console.error('初始化失败:', err));
