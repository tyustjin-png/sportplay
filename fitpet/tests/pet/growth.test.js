// tests/pet/growth.test.js — 宠物成长逻辑测试
import { describe, it, expect } from 'vitest';
import {
  getRealmForLevel,
  getLevelInRealm,
  calculateNewLevel,
  getRealmInfo,
  getPetMood,
} from '../../src/pet/growth.js';

describe('境界计算', () => {
  it('级别1-27属于第一境界', () => {
    expect(getRealmForLevel(1)).toBe(1);
    expect(getRealmForLevel(27)).toBe(1);
  });

  it('级别28属于第二境界', () => {
    expect(getRealmForLevel(28)).toBe(2);
  });

  it('级别55属于第三境界', () => {
    expect(getRealmForLevel(55)).toBe(3);
  });

  it('getLevelInRealm 返回境界内的相对级别', () => {
    expect(getLevelInRealm(1)).toBe(1);
    expect(getLevelInRealm(27)).toBe(27);
    expect(getLevelInRealm(28)).toBe(1);
    expect(getLevelInRealm(30)).toBe(3);
  });
});

describe('级别浮动', () => {
  it('完成率 >= 80%：+1级', () => {
    const result = calculateNewLevel(1, 10, 0.85);
    expect(result.level).toBe(11);
    expect(result.realm).toBe(1);
  });

  it('完成率 50-79%：级别不变', () => {
    const result = calculateNewLevel(1, 10, 0.60);
    expect(result.level).toBe(10);
  });

  it('完成率 < 50%：-1级', () => {
    const result = calculateNewLevel(1, 10, 0.30);
    expect(result.level).toBe(9);
  });

  it('不能降到当前境界起始级以下', () => {
    const result = calculateNewLevel(1, 1, 0.10);
    expect(result.level).toBe(1);
  });

  it('不能超过当前境界上限（需要升境界条件才能突破）', () => {
    const result = calculateNewLevel(1, 27, 0.90);
    expect(result.level).toBe(27);
    expect(result.realm).toBe(1);
  });

  it('满足升境界条件时突破到下一境界', () => {
    const result = calculateNewLevel(1, 27, 0.90, 27);
    expect(result.level).toBe(28);
    expect(result.realm).toBe(2);
  });

  it('第二境界降级不低于28', () => {
    const result = calculateNewLevel(2, 28, 0.10);
    expect(result.level).toBe(28);
  });
});

describe('宠物状态反馈', () => {
  it('完成率 >= 80% 返回 active', () => {
    expect(getPetMood(0.85)).toBe('active');
  });

  it('完成率 30-79% 返回 normal', () => {
    expect(getPetMood(0.50)).toBe('normal');
  });

  it('完成率 < 30% 返回 tired', () => {
    expect(getPetMood(0.20)).toBe('tired');
  });
});

describe('getRealmInfo', () => {
  it('返回境界名称和描述', () => {
    const info = getRealmInfo(1);
    expect(info.name).toBeTruthy();
  });
});
