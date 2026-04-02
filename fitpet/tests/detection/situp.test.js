// tests/detection/situp.test.js — 仰卧起坐计数器测试
import { describe, it, expect } from 'vitest';
import { createSitupCounter } from '../../src/detection/situp.js';

// 11=左肩, 12=右肩, 23=左髋, 24=右髋
function makeLandmarks(torsoAngle) {
  const landmarks = new Array(33).fill({ x: 0, y: 0, z: 0, visibility: 0.9 });
  const hipX = 0.5;
  const hipY = 0.6;
  const rad = torsoAngle * Math.PI / 180;
  const shoulderX = hipX - 0.3 * Math.cos(rad);
  const shoulderY = hipY - 0.3 * Math.sin(rad);

  landmarks[11] = { x: shoulderX,       y: shoulderY, z: 0, visibility: 0.9 };
  landmarks[12] = { x: shoulderX + 0.1, y: shoulderY, z: 0, visibility: 0.9 };
  landmarks[23] = { x: hipX,            y: hipY,      z: 0, visibility: 0.9 };
  landmarks[24] = { x: hipX + 0.1,      y: hipY,      z: 0, visibility: 0.9 };
  landmarks[25] = { x: 0.5, y: 0.8, z: 0, visibility: 0.9 };
  landmarks[26] = { x: 0.6, y: 0.8, z: 0, visibility: 0.9 };

  return landmarks;
}

describe('SitupCounter', () => {
  it('初始计数为0', () => {
    const counter = createSitupCounter();
    expect(counter.getState().count).toBe(0);
  });

  it('躯干从平躺到抬起再回落算一次', () => {
    const counter = createSitupCounter();
    counter.update(makeLandmarks(5));
    counter.update(makeLandmarks(45));
    counter.update(makeLandmarks(5));
    expect(counter.getState().count).toBe(1);
  });

  it('连续3个仰卧起坐', () => {
    const counter = createSitupCounter();
    for (let i = 0; i < 3; i++) {
      counter.update(makeLandmarks(5));
      counter.update(makeLandmarks(45));
      counter.update(makeLandmarks(5));
    }
    expect(counter.getState().count).toBe(3);
  });

  it('reset 清零', () => {
    const counter = createSitupCounter();
    counter.update(makeLandmarks(5));
    counter.update(makeLandmarks(45));
    counter.update(makeLandmarks(5));
    counter.reset();
    expect(counter.getState().count).toBe(0);
  });
});
