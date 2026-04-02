// tests/detection/squat.test.js — 深蹲计数器测试
import { describe, it, expect } from 'vitest';
import { createSquatCounter } from '../../src/detection/squat.js';

// 23=左髋, 25=左膝, 27=左踝, 24=右髋, 26=右膝, 28=右踝
// calcAngle(hip, knee, ankle) 将精确等于 kneeAngle
function makeLandmarks(kneeAngle) {
  const landmarks = new Array(33).fill({ x: 0, y: 0, z: 0, visibility: 0.9 });
  const knee = { x: 0.4, y: 0.55 };
  const dist = 0.25;
  const hip = { x: knee.x, y: knee.y - dist }; // 髋在膝正上方
  const hipDir = Math.atan2(hip.y - knee.y, hip.x - knee.x); // -π/2
  const ankleDir = hipDir + kneeAngle * Math.PI / 180;
  const ankle = { x: knee.x + dist * Math.cos(ankleDir), y: knee.y + dist * Math.sin(ankleDir) };

  landmarks[23] = { ...hip,   z: 0, visibility: 0.9 };
  landmarks[25] = { ...knee,  z: 0, visibility: 0.9 };
  landmarks[27] = { ...ankle, z: 0, visibility: 0.9 };
  landmarks[24] = { x: hip.x   + 0.2, y: hip.y,   z: 0, visibility: 0.9 };
  landmarks[26] = { x: knee.x  + 0.2, y: knee.y,  z: 0, visibility: 0.9 };
  landmarks[28] = { x: ankle.x + 0.2, y: ankle.y, z: 0, visibility: 0.9 };

  return landmarks;
}

describe('SquatCounter', () => {
  it('初始计数为0', () => {
    const counter = createSquatCounter();
    expect(counter.getState().count).toBe(0);
  });

  it('膝角从大变小再变大算一次深蹲', () => {
    const counter = createSquatCounter();
    counter.update(makeLandmarks(170));
    counter.update(makeLandmarks(80));
    counter.update(makeLandmarks(170));
    expect(counter.getState().count).toBe(1);
  });

  it('连续3个深蹲', () => {
    const counter = createSquatCounter();
    for (let i = 0; i < 3; i++) {
      counter.update(makeLandmarks(170));
      counter.update(makeLandmarks(80));
      counter.update(makeLandmarks(170));
    }
    expect(counter.getState().count).toBe(3);
  });

  it('reset 清零', () => {
    const counter = createSquatCounter();
    counter.update(makeLandmarks(170));
    counter.update(makeLandmarks(80));
    counter.update(makeLandmarks(170));
    counter.reset();
    expect(counter.getState().count).toBe(0);
  });
});
