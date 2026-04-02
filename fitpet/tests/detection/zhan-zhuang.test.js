// tests/detection/zhan-zhuang.test.js — 站桩计时器测试
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createZhanZhuangTimer } from '../../src/detection/zhan-zhuang.js';

// calcAngle(hip, knee, ankle) 将精确等于 kneeAngle
function makeStandingLandmarks(kneeAngle = 150) {
  const landmarks = new Array(33).fill({ x: 0, y: 0, z: 0, visibility: 0.9 });
  const knee = { x: 0.4, y: 0.6 };
  const dist = 0.2;
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
  landmarks[11] = { x: 0.4, y: 0.25, z: 0, visibility: 0.9 };
  landmarks[12] = { x: 0.6, y: 0.25, z: 0, visibility: 0.9 };

  return landmarks;
}

describe('ZhanZhuangTimer', () => {
  beforeEach(() => { vi.useFakeTimers(); });
  afterEach(()  => { vi.useRealTimers(); });

  it('初始状态：未开始，时间为0', () => {
    const timer = createZhanZhuangTimer();
    expect(timer.getState().elapsed).toBe(0);
    expect(timer.getState().isHolding).toBe(false);
  });

  it('检测到标准姿势后开始计时', () => {
    const timer = createZhanZhuangTimer();
    const now = Date.now();
    timer.update(makeStandingLandmarks(150), now);
    expect(timer.getState().isHolding).toBe(true);
    timer.update(makeStandingLandmarks(150), now + 3000);
    expect(timer.getState().elapsed).toBe(3000);
  });

  it('姿势崩溃时暂停计时', () => {
    const timer = createZhanZhuangTimer();
    const now = Date.now();
    timer.update(makeStandingLandmarks(150), now);
    timer.update(makeStandingLandmarks(150), now + 3000);
    timer.update(makeStandingLandmarks(80),  now + 4000); // 崩溃
    expect(timer.getState().isHolding).toBe(false);
    timer.update(makeStandingLandmarks(80),  now + 6000);
    expect(timer.getState().elapsed).toBe(3000);
  });

  it('姿势恢复后继续计时', () => {
    const timer = createZhanZhuangTimer();
    const now = Date.now();
    timer.update(makeStandingLandmarks(150), now);
    timer.update(makeStandingLandmarks(150), now + 3000);
    timer.update(makeStandingLandmarks(80),  now + 4000); // 崩溃
    timer.update(makeStandingLandmarks(150), now + 5000); // 恢复
    timer.update(makeStandingLandmarks(150), now + 7000);
    expect(timer.getState().elapsed).toBe(5000); // 3秒 + 2秒
  });

  it('reset 清零', () => {
    const timer = createZhanZhuangTimer();
    const now = Date.now();
    timer.update(makeStandingLandmarks(150), now);
    timer.update(makeStandingLandmarks(150), now + 5000);
    timer.reset();
    expect(timer.getState().elapsed).toBe(0);
    expect(timer.getState().isHolding).toBe(false);
  });
});
