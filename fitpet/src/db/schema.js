// src/db/schema.js — 数据库初始化：建表 + 默认数据
import Database from 'better-sqlite3';

/**
 * 初始化数据库表结构和默认数据
 * @param {import('better-sqlite3').Database} db - better-sqlite3 实例
 */
export function initDatabase(db) {
  // 运动计划配置表
  db.exec(`
    CREATE TABLE IF NOT EXISTS workout_plans (
      id INTEGER PRIMARY KEY,
      exercise TEXT NOT NULL,
      sets INTEGER,
      reps INTEGER,
      duration_seconds INTEGER,
      display_order INTEGER
    )
  `);

  // 每日运动记录表
  db.exec(`
    CREATE TABLE IF NOT EXISTS daily_sessions (
      id INTEGER PRIMARY KEY,
      date TEXT NOT NULL,
      exercise TEXT NOT NULL,
      completed_sets INTEGER,
      total_sets INTEGER,
      notes TEXT
    )
  `);

  // 宠物状态表（单行）
  db.exec(`
    CREATE TABLE IF NOT EXISTS pet_state (
      id INTEGER PRIMARY KEY DEFAULT 1,
      current_realm INTEGER DEFAULT 1,
      current_level INTEGER DEFAULT 1,
      streak_days INTEGER DEFAULT 0,
      last_active_date TEXT
    )
  `);

  // 每日汇总表
  db.exec(`
    CREATE TABLE IF NOT EXISTS daily_summary (
      date TEXT PRIMARY KEY,
      completion_rate REAL,
      streak_at_date INTEGER
    )
  `);

  // 插入默认运动计划（仅当表为空时）
  const count = db.prepare('SELECT COUNT(*) as c FROM workout_plans').get().c;
  if (count === 0) {
    const insert = db.prepare(
      'INSERT INTO workout_plans (exercise, sets, reps, duration_seconds, display_order) VALUES (?, ?, ?, ?, ?)'
    );
    const defaultPlans = [
      ['pushup',      3, 15, null, 1],   // 俯卧撑：3组×15个
      ['squat',       3, 20, null, 2],   // 深蹲：3组×20个
      ['zhan_zhuang', 1, null, 300, 3],  // 站桩：1组×5分钟
      ['situp',       3, 20, null, 4],   // 仰卧起坐：3组×20个
      ['kegel',       3, null, 10,  5],  // 凯格尔：3组×10秒
    ];
    const insertMany = db.transaction((plans) => {
      for (const p of plans) insert.run(...p);
    });
    insertMany(defaultPlans);
  }

  // 初始化宠物状态（仅当表为空时）
  const petCount = db.prepare('SELECT COUNT(*) as c FROM pet_state').get().c;
  if (petCount === 0) {
    db.prepare(
      'INSERT INTO pet_state (id, current_realm, current_level, streak_days) VALUES (1, 1, 1, 0)'
    ).run();
  }
}

/**
 * 创建并初始化一个数据库实例
 * @param {string} dbPath - 数据库文件路径
 * @returns {import('better-sqlite3').Database}
 */
export function createDatabase(dbPath) {
  const db = new Database(dbPath);
  db.pragma('journal_mode = WAL');
  initDatabase(db);
  return db;
}
