// tests/db/pet.test.js — 宠物状态数据库操作测试
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import Database from 'better-sqlite3';
import { initDatabase } from '../../src/db/schema.js';
import {
  getPetState,
  updatePetState,
  saveDailySummary,
  getRecentSummaries,
  getConsecutiveHighDays,
} from '../../src/db/pet.js';

describe('pet DB 操作', () => {
  let db;

  beforeEach(() => {
    db = new Database(':memory:');
    initDatabase(db);
  });

  afterEach(() => { db.close(); });

  it('getPetState 返回初始状态', () => {
    const state = getPetState(db);
    expect(state.current_realm).toBe(1);
    expect(state.current_level).toBe(1);
  });

  it('updatePetState 更新境界和级别', () => {
    updatePetState(db, { current_realm: 1, current_level: 5, streak_days: 3, last_active_date: '2026-04-02' });
    const state = getPetState(db);
    expect(state.current_level).toBe(5);
    expect(state.streak_days).toBe(3);
  });

  it('saveDailySummary 写入每日汇总', () => {
    saveDailySummary(db, '2026-04-02', 0.85, 5);
    const row = db.prepare('SELECT * FROM daily_summary WHERE date = ?').get('2026-04-02');
    expect(row.completion_rate).toBeCloseTo(0.85);
    expect(row.streak_at_date).toBe(5);
  });

  it('getRecentSummaries 返回最近N天的汇总', () => {
    saveDailySummary(db, '2026-04-01', 0.90, 1);
    saveDailySummary(db, '2026-04-02', 0.85, 2);
    const summaries = getRecentSummaries(db, 7);
    expect(summaries).toHaveLength(2);
    expect(summaries[0].date).toBe('2026-04-02');
  });

  it('getConsecutiveHighDays 统计连续高完成率天数', () => {
    saveDailySummary(db, '2026-03-31', 0.90, 1);
    saveDailySummary(db, '2026-04-01', 0.85, 2);
    saveDailySummary(db, '2026-04-02', 0.50, 3);
    expect(getConsecutiveHighDays(db, '2026-04-02')).toBe(0);
  });

  it('getConsecutiveHighDays 连续3天高完成率', () => {
    saveDailySummary(db, '2026-03-31', 0.80, 1);
    saveDailySummary(db, '2026-04-01', 0.85, 2);
    saveDailySummary(db, '2026-04-02', 0.90, 3);
    expect(getConsecutiveHighDays(db, '2026-04-02')).toBe(3);
  });
});
