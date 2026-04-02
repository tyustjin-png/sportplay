// src/detection/situp.js — 仰卧起坐计数器（躯干角度检测）

const LEFT_SHOULDER  = 11;
const RIGHT_SHOULDER = 12;
const LEFT_HIP       = 23;
const RIGHT_HIP      = 24;

const UP_THRESHOLD   = 30; // 躯干角 > 30° → 抬起
const DOWN_THRESHOLD = 15; // 躯干角 < 15° → 躺回

/**
 * 计算躯干与水平面的夹角（度）
 */
function getTorsoAngle(landmarks) {
  const shoulderMidX = (landmarks[LEFT_SHOULDER].x + landmarks[RIGHT_SHOULDER].x) / 2;
  const shoulderMidY = (landmarks[LEFT_SHOULDER].y + landmarks[RIGHT_SHOULDER].y) / 2;
  const hipMidX      = (landmarks[LEFT_HIP].x  + landmarks[RIGHT_HIP].x)  / 2;
  const hipMidY      = (landmarks[LEFT_HIP].y  + landmarks[RIGHT_HIP].y)  / 2;

  const dx = shoulderMidX - hipMidX;
  const dy = hipMidY - shoulderMidY; // 屏幕坐标Y向下，髋Y大于肩Y时dy>0表示肩在上
  return Math.abs(Math.atan2(dy, Math.abs(dx) + 1e-6)) * 180 / Math.PI;
}

export function createSitupCounter() {
  let count = 0;
  let phase = 'down'; // 'down' | 'up'

  function update(landmarks) {
    if (!landmarks) return;
    const angle = getTorsoAngle(landmarks);

    if (phase === 'down' && angle > UP_THRESHOLD) {
      phase = 'up';
    } else if (phase === 'up' && angle < DOWN_THRESHOLD) {
      phase = 'down';
      count++;
    }
  }

  function getState() { return { count, phase }; }
  function reset()    { count = 0; phase = 'down'; }

  return { update, getState, reset };
}
