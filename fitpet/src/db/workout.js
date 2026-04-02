// src/db/workout.js — 运动计划和每日会话的 CRUD 操作

/**
 * 获取所有运动计划，按 display_order 排序
 * @param {import('better-sqlite3').Database} db
 * @returns {Array}
 */
export function getWorkoutPlans(db) {
  return db.prepare('SELECT * FROM workout_plans ORDER BY display_order').all();
}

/**
 * 保存一次运动会话记录
 * @param {import('better-sqlite3').Database} db
 * @param {{ date: string, exercise: string, completed_sets: number, total_sets: number, notes?: string }} session
 * @returns {number} 新记录 ID
 */
export function saveSession(db, session) {
  const result = db.prepare(
    'INSERT INTO daily_sessions (date, exercise, completed_sets, total_sets, notes) VALUES (?, ?, ?, ?, ?)'
  ).run(session.date, session.exercise, session.completed_sets, session.total_sets, session.notes || null);
  return result.lastInsertRowid;
}

/**
 * 获取指定日期的所有运动记录
 * @param {import('better-sqlite3').Database} db
 * @param {string} date - 'YYYY-MM-DD'
 * @returns {Array}
 */
export function getSessionsByDate(db, date) {
  return db.prepare('SELECT * FROM daily_sessions WHERE date = ?').all(date);
}

/**
 * 计算指定日期的完成率（已完成组数 / 总组数）
 * @param {import('better-sqlite3').Database} db
 * @param {string} date - 'YYYY-MM-DD'
 * @returns {number} 0.0 ~ 1.0
 */
export function getCompletionRate(db, date) {
  const row = db.prepare(
    'SELECT COALESCE(SUM(completed_sets), 0) as done, COALESCE(SUM(total_sets), 0) as total FROM daily_sessions WHERE date = ?'
  ).get(date);
  if (row.total === 0) return 0;
  return row.done / row.total;
}
