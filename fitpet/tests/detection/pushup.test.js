// tests/detection/pushup.test.js — 俯卧撑计数器测试
import { describe, it, expect } from 'vitest';
import { createPushupCounter } from '../../src/detection/pushup.js';

// 模拟 landmarks：用三角函数构造指定肘角的真实几何坐标
// calcAngle(shoulder, elbow, wrist) 将精确等于 elbowAngle
// 11=左肩, 13=左肘, 15=左腕, 12=右肩, 14=右肘, 16=右腕
function makeLandmarks(elbowAngle) {
  const landmarks = new Array(33).fill({ x: 0, y: 0, z: 0, visibility: 0.9 });
  const elbow = { x: 0.5, y: 0.5 };
  const dist = 0.2;
  const shoulder = { x: elbow.x, y: elbow.y - dist }; // 肩在肘正上方
  const shoulderDir = Math.atan2(shoulder.y - elbow.y, shoulder.x - elbow.x); // -π/2
  const wristDir = shoulderDir + elbowAngle * Math.PI / 180;
  const wrist = { x: elbow.x + dist * Math.cos(wristDir), y: elbow.y + dist * Math.sin(wristDir) };

  landmarks[11] = { ...shoulder, z: 0, visibility: 0.9 };
  landmarks[13] = { ...elbow,   z: 0, visibility: 0.9 };
  landmarks[15] = { ...wrist,   z: 0, visibility: 0.9 };
  landmarks[12] = { x: shoulder.x + 0.1, y: shoulder.y, z: 0, visibility: 0.9 };
  landmarks[14] = { x: elbow.x   + 0.1, y: elbow.y,   z: 0, visibility: 0.9 };
  landmarks[16] = { x: wrist.x   + 0.1, y: wrist.y,   z: 0, visibility: 0.9 };

  return landmarks;
}

describe('PushupCounter', () => {
  it('初始状态计数为0', () => {
    const counter = createPushupCounter();
    expect(counter.getState().count).toBe(0);
    expect(counter.getState().phase).toBe('up');
  });

  it('肘角从大变小再变大算一次俯卧撑', () => {
    const counter = createPushupCounter();
    counter.update(makeLandmarks(170));
    expect(counter.getState().phase).toBe('up');
    counter.update(makeLandmarks(70));
    expect(counter.getState().phase).toBe('down');
    counter.update(makeLandmarks(170));
    expect(counter.getState().phase).toBe('up');
    expect(counter.getState().count).toBe(1);
  });

  it('连续3个俯卧撑', () => {
    const counter = createPushupCounter();
    for (let i = 0; i < 3; i++) {
      counter.update(makeLandmarks(170));
      counter.update(makeLandmarks(70));
      counter.update(makeLandmarks(170));
    }
    expect(counter.getState().count).toBe(3);
  });

  it('reset 清零', () => {
    const counter = createPushupCounter();
    counter.update(makeLandmarks(170));
    counter.update(makeLandmarks(70));
    counter.update(makeLandmarks(170));
    counter.reset();
    expect(counter.getState().count).toBe(0);
  });
});
