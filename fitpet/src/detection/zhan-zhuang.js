// src/detection/zhan-zhuang.js — 站桩计时器（静态姿势检测 + 累计计时）
import { calcAngle } from './pose-detector.js';

const LEFT_HIP   = 23;
const LEFT_KNEE  = 25;
const LEFT_ANKLE = 27;
const RIGHT_HIP   = 24;
const RIGHT_KNEE  = 26;
const RIGHT_ANKLE = 28;

// 站桩有效膝角范围：微曲但不能蹲太低
const MIN_KNEE_ANGLE = 120;
const MAX_KNEE_ANGLE = 175;

function isValidStance(landmarks) {
  const leftAngle  = calcAngle(landmarks[LEFT_HIP],  landmarks[LEFT_KNEE],  landmarks[LEFT_ANKLE]);
  const rightAngle = calcAngle(landmarks[RIGHT_HIP], landmarks[RIGHT_KNEE], landmarks[RIGHT_ANKLE]);
  const avgAngle = (leftAngle + rightAngle) / 2;
  return avgAngle >= MIN_KNEE_ANGLE && avgAngle <= MAX_KNEE_ANGLE;
}

/**
 * 创建站桩计时器
 * update(landmarks, timestamp) — timestamp 为外部传入的毫秒时间戳
 * getState() — 返回 { elapsed: number, isHolding: boolean }
 */
export function createZhanZhuangTimer() {
  let totalElapsed  = 0;   // 累计有效毫秒
  let isHolding     = false;
  let holdStartTime = null;
  let lastTimestamp = 0;
  let prevTimestamp = 0;   // 上一帧时间戳，崩溃时用于截止计时

  function update(landmarks, timestamp) {
    if (!landmarks) return;
    prevTimestamp = lastTimestamp;
    lastTimestamp = timestamp;

    const valid = isValidStance(landmarks);

    if (valid && !isHolding) {
      // 开始计时
      isHolding     = true;
      holdStartTime = timestamp;
    } else if (!valid && isHolding) {
      // 姿势崩溃，累加到上一帧（不含崩溃帧）
      totalElapsed += prevTimestamp - holdStartTime;
      isHolding     = false;
      holdStartTime = null;
    }
    // valid && isHolding → 继续持续，getState 时再算
    // !valid && !isHolding → 无操作
  }

  function getState() {
    const currentElapsed = (isHolding && holdStartTime != null)
      ? totalElapsed + (lastTimestamp - holdStartTime)
      : totalElapsed;
    return { elapsed: currentElapsed, isHolding };
  }

  function reset() {
    totalElapsed  = 0;
    isHolding     = false;
    holdStartTime = null;
    lastTimestamp = 0;
    prevTimestamp = 0;
  }

  return { update, getState, reset };
}
