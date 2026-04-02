// tests/db/workout.test.js — 运动计划和会话记录的 CRUD 测试
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import Database from 'better-sqlite3';
import { initDatabase } from '../../src/db/schema.js';
import {
  getWorkoutPlans,
  saveSession,
  getSessionsByDate,
  getCompletionRate,
} from '../../src/db/workout.js';

describe('workout CRUD', () => {
  let db;

  beforeEach(() => {
    db = new Database(':memory:');
    initDatabase(db);
  });

  afterEach(() => { db.close(); });

  it('getWorkoutPlans 应返回5项默认计划', () => {
    const plans = getWorkoutPlans(db);
    expect(plans).toHaveLength(5);
    expect(plans[0].exercise).toBe('pushup');
    expect(plans[0].sets).toBe(3);
  });

  it('saveSession 应写入记录并返回 id', () => {
    const id = saveSession(db, {
      date: '2026-04-02',
      exercise: 'pushup',
      completed_sets: 3,
      total_sets: 3,
    });
    expect(id).toBeGreaterThan(0);
  });

  it('getSessionsByDate 应返回指定日期的所有记录', () => {
    saveSession(db, { date: '2026-04-02', exercise: 'pushup', completed_sets: 3, total_sets: 3 });
    saveSession(db, { date: '2026-04-02', exercise: 'squat', completed_sets: 2, total_sets: 3 });
    saveSession(db, { date: '2026-04-01', exercise: 'pushup', completed_sets: 1, total_sets: 3 });
    const sessions = getSessionsByDate(db, '2026-04-02');
    expect(sessions).toHaveLength(2);
  });

  it('getCompletionRate 应计算每日完成率（已完成组数/总组数）', () => {
    saveSession(db, { date: '2026-04-02', exercise: 'pushup', completed_sets: 3, total_sets: 3 });
    saveSession(db, { date: '2026-04-02', exercise: 'squat', completed_sets: 1, total_sets: 3 });
    const rate = getCompletionRate(db, '2026-04-02');
    expect(rate).toBeCloseTo(0.667, 2);
  });

  it('getCompletionRate 无记录时返回 0', () => {
    const rate = getCompletionRate(db, '2026-04-02');
    expect(rate).toBe(0);
  });
});
