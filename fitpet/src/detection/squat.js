// src/detection/squat.js — 深蹲计数器（状态机：standing ↔ squatting）
import { calcAngle } from './pose-detector.js';

const LEFT_HIP   = 23;
const LEFT_KNEE  = 25;
const LEFT_ANKLE = 27;
const RIGHT_HIP   = 24;
const RIGHT_KNEE  = 26;
const RIGHT_ANKLE = 28;

const DOWN_THRESHOLD = 100; // 膝角 < 100° → 蹲到位
const UP_THRESHOLD   = 160; // 膝角 > 160° → 站起来

export function createSquatCounter() {
  let count = 0;
  let phase = 'standing'; // 'standing' | 'squatting'

  function update(landmarks) {
    if (!landmarks) return;
    const leftAngle  = calcAngle(landmarks[LEFT_HIP],  landmarks[LEFT_KNEE],  landmarks[LEFT_ANKLE]);
    const rightAngle = calcAngle(landmarks[RIGHT_HIP], landmarks[RIGHT_KNEE], landmarks[RIGHT_ANKLE]);
    const avgAngle = (leftAngle + rightAngle) / 2;

    if (phase === 'standing' && avgAngle < DOWN_THRESHOLD) {
      phase = 'squatting';
    } else if (phase === 'squatting' && avgAngle > UP_THRESHOLD) {
      phase = 'standing';
      count++;
    }
  }

  function getState() { return { count, phase }; }
  function reset()    { count = 0; phase = 'standing'; }

  return { update, getState, reset };
}
