// src/pet/growth.js — 宠物成长系统纯函数（无 DB 依赖）

const LEVELS_PER_REALM = 27;

// 境界信息配置
const REALM_INFO = [
  { name: '第一境界', desc: '小蛋 → 幼崽（逐渐破壳）' },
  { name: '第二境界', desc: '少年武者，有装备' },
  { name: '第三境界', desc: '全套盔甲，光环特效' },
];

/**
 * 根据总级别计算所在境界（从1开始）
 * @param {number} level - 总级别（>=1）
 * @returns {number} 境界编号
 */
export function getRealmForLevel(level) {
  return Math.ceil(level / LEVELS_PER_REALM);
}

/**
 * 获取在当前境界内的相对级别（1~27）
 * @param {number} level - 总级别
 * @returns {number}
 */
export function getLevelInRealm(level) {
  return ((level - 1) % LEVELS_PER_REALM) + 1;
}

/**
 * 根据完成率计算新的总级别
 * @param {number} currentRealm - 当前境界
 * @param {number} currentLevel - 当前总级别
 * @param {number} completionRate - 今日完成率 (0~1)
 * @param {number} [consecutiveHighDays=0] - 连续高完成率天数（用于判断升境界）
 * @returns {{ level: number, realm: number }}
 */
export function calculateNewLevel(currentRealm, currentLevel, completionRate, consecutiveHighDays = 0) {
  const realmStart = (currentRealm - 1) * LEVELS_PER_REALM + 1;
  const realmEnd = currentRealm * LEVELS_PER_REALM;

  let newLevel = currentLevel;

  if (completionRate >= 0.8) {
    newLevel = currentLevel + 1;
  } else if (completionRate < 0.5) {
    newLevel = currentLevel - 1;
  }

  // 不低于当前境界起始级
  if (newLevel < realmStart) {
    newLevel = realmStart;
  }

  // 如果到达境界上限
  if (newLevel > realmEnd) {
    if (consecutiveHighDays >= LEVELS_PER_REALM) {
      // 升境界
      return { level: realmEnd + 1, realm: currentRealm + 1 };
    }
    newLevel = realmEnd; // 卡在上限
  }

  return { level: newLevel, realm: getRealmForLevel(newLevel) };
}

/**
 * 获取境界信息
 * @param {number} realm - 境界编号（从1开始）
 * @returns {{ name: string, desc: string }}
 */
export function getRealmInfo(realm) {
  if (realm <= REALM_INFO.length) {
    return REALM_INFO[realm - 1];
  }
  return { name: `第${realm}境界`, desc: '未知领域，等待探索' };
}

/**
 * 根据完成率返回宠物心情状态
 * @param {number} completionRate - 0~1
 * @returns {'active' | 'normal' | 'tired'}
 */
export function getPetMood(completionRate) {
  if (completionRate >= 0.8) return 'active';
  if (completionRate >= 0.3) return 'normal';
  return 'tired';
}
