// tests/db/schema.test.js — 数据库初始化测试
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import Database from 'better-sqlite3';
import { initDatabase } from '../../src/db/schema.js';

describe('initDatabase', () => {
  let db;

  beforeEach(() => {
    db = new Database(':memory:');
  });

  afterEach(() => {
    db.close();
  });

  it('应创建所有必要的表', () => {
    initDatabase(db);
    const tables = db.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    ).all().map(r => r.name);
    expect(tables).toContain('workout_plans');
    expect(tables).toContain('daily_sessions');
    expect(tables).toContain('pet_state');
    expect(tables).toContain('daily_summary');
  });

  it('应插入默认运动计划（5 项）', () => {
    initDatabase(db);
    const plans = db.prepare('SELECT * FROM workout_plans ORDER BY display_order').all();
    expect(plans).toHaveLength(5);
    expect(plans[0].exercise).toBe('pushup');
  });

  it('应初始化宠物状态为境界1级别1', () => {
    initDatabase(db);
    const pet = db.prepare('SELECT * FROM pet_state WHERE id = 1').get();
    expect(pet.current_realm).toBe(1);
    expect(pet.current_level).toBe(1);
    expect(pet.streak_days).toBe(0);
  });

  it('重复调用不应报错（IF NOT EXISTS）', () => {
    initDatabase(db);
    expect(() => initDatabase(db)).not.toThrow();
  });
});
