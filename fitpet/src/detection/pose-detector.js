// src/detection/pose-detector.js — MediaPipe PoseLandmarker 封装
// 注意：initPoseDetector 和 detectPose 依赖浏览器环境，在渲染进程中使用
// calcAngle 是纯函数，可在 Node 测试环境中使用

/**
 * 初始化 MediaPipe PoseLandmarker（仅在渲染进程调用）
 * @param {string} [wasmPath] - WASM 文件目录，默认使用 CDN
 */
export async function initPoseDetector(wasmPath) {
  const { PoseLandmarker, FilesetResolver } = await import('https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/vision_bundle.mjs');

  const vision = await FilesetResolver.forVisionTasks(
    wasmPath || 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm'
  );

  const poseLandmarker = await PoseLandmarker.createFromOptions(vision, {
    baseOptions: {
      modelAssetPath: 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task',
      delegate: 'GPU',
    },
    runningMode: 'VIDEO',
    numPoses: 1,
  });

  return poseLandmarker;
}

/**
 * 对视频帧进行姿态检测（仅在渲染进程调用）
 * @param {object} poseLandmarker - PoseLandmarker 实例
 * @param {HTMLVideoElement} video
 * @param {number} timestamp - 毫秒
 * @returns {Array | null} landmarks 数组
 */
export function detectPose(poseLandmarker, video, timestamp) {
  if (!poseLandmarker) return null;
  const result = poseLandmarker.detectForVideo(video, timestamp);
  if (result.landmarks && result.landmarks.length > 0) {
    return result.landmarks[0];
  }
  return null;
}

/**
 * 计算三点形成的角度（度数）
 * 纯函数，可在 Node 环境测试
 * @param {{ x: number, y: number }} a
 * @param {{ x: number, y: number }} b - 顶点
 * @param {{ x: number, y: number }} c
 * @returns {number} 0-180
 */
export function calcAngle(a, b, c) {
  const radians = Math.atan2(c.y - b.y, c.x - b.x) - Math.atan2(a.y - b.y, a.x - b.x);
  let angle = Math.abs(radians * 180 / Math.PI);
  if (angle > 180) angle = 360 - angle;
  return angle;
}
