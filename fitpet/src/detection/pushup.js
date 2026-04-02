// src/detection/pushup.js — 俯卧撑计数器（状态机：up ↔ down）
import { calcAngle } from './pose-detector.js';

const LEFT_SHOULDER = 11;
const LEFT_ELBOW    = 13;
const LEFT_WRIST    = 15;
const RIGHT_SHOULDER = 12;
const RIGHT_ELBOW   = 14;
const RIGHT_WRIST   = 16;

const DOWN_THRESHOLD = 90;  // 肘角 < 90° → 到底
const UP_THRESHOLD   = 160; // 肘角 > 160° → 完成一次

/**
 * 创建俯卧撑计数器（工厂函数）
 */
export function createPushupCounter() {
  let count = 0;
  let phase = 'up'; // 'up' | 'down'

  function update(landmarks) {
    if (!landmarks) return;
    // 关键点可见度不足时跳过，避免噪声误计
    const pts = [LEFT_SHOULDER, LEFT_ELBOW, LEFT_WRIST, RIGHT_SHOULDER, RIGHT_ELBOW, RIGHT_WRIST];
    if (pts.some(i => (landmarks[i]?.visibility ?? 0) < 0.6)) return;
    const leftAngle  = calcAngle(landmarks[LEFT_SHOULDER],  landmarks[LEFT_ELBOW],  landmarks[LEFT_WRIST]);
    const rightAngle = calcAngle(landmarks[RIGHT_SHOULDER], landmarks[RIGHT_ELBOW], landmarks[RIGHT_WRIST]);
    const avgAngle = (leftAngle + rightAngle) / 2;

    if (phase === 'up' && avgAngle < DOWN_THRESHOLD) {
      phase = 'down';
    } else if (phase === 'down' && avgAngle > UP_THRESHOLD) {
      phase = 'up';
      count++;
    }
  }

  function getState() { return { count, phase }; }
  function reset()    { count = 0; phase = 'up'; }

  return { update, getState, reset };
}
