// src/db/pet.js — 宠物状态和每日汇总的数据库操作

/**
 * 获取宠物当前状态
 * @param {import('better-sqlite3').Database} db
 */
export function getPetState(db) {
  return db.prepare('SELECT * FROM pet_state WHERE id = 1').get();
}

/**
 * 更新宠物状态
 * @param {import('better-sqlite3').Database} db
 * @param {{ current_realm: number, current_level: number, streak_days: number, last_active_date: string }} state
 */
export function updatePetState(db, state) {
  db.prepare(
    'UPDATE pet_state SET current_realm = ?, current_level = ?, streak_days = ?, last_active_date = ? WHERE id = 1'
  ).run(state.current_realm, state.current_level, state.streak_days, state.last_active_date);
}

/**
 * 保存每日汇总
 * @param {import('better-sqlite3').Database} db
 * @param {string} date
 * @param {number} completionRate
 * @param {number} streakAtDate
 */
export function saveDailySummary(db, date, completionRate, streakAtDate) {
  db.prepare(
    'INSERT OR REPLACE INTO daily_summary (date, completion_rate, streak_at_date) VALUES (?, ?, ?)'
  ).run(date, completionRate, streakAtDate);
}

/**
 * 获取最近 N 天的每日汇总，按日期降序
 * @param {import('better-sqlite3').Database} db
 * @param {number} days
 */
export function getRecentSummaries(db, days) {
  return db.prepare(
    'SELECT * FROM daily_summary ORDER BY date DESC LIMIT ?'
  ).all(days);
}

/**
 * 从指定日期向前计算连续高完成率（>= 0.8）的天数
 * @param {import('better-sqlite3').Database} db
 * @param {string} fromDate - 'YYYY-MM-DD'
 * @returns {number}
 */
export function getConsecutiveHighDays(db, fromDate) {
  const summaries = db.prepare(
    'SELECT date, completion_rate FROM daily_summary WHERE date <= ? ORDER BY date DESC'
  ).all(fromDate);

  let count = 0;
  for (const s of summaries) {
    if (s.completion_rate >= 0.8) {
      count++;
    } else {
      break;
    }
  }
  return count;
}
