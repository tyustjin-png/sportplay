# FitPet 设计文档

**日期**：2026-04-02  
**状态**：已确认，待实现

---

## 背景与目标

用户每天有固定运动计划（俯卧撑、深蹲、站桩、仰卧起坐、凯格尔），希望通过一个桌面应用完成：

1. **运动观察**：摄像头实时检测运动动作，自动计数/计时
2. **运动陪伴**：桌面常驻像素风宠物，体现每日完成度
3. **长期激励**：宠物成长系统，完成度越高宠物越强，无上限成长

---

## 技术栈

- **框架**：Electron（主进程 + 渲染进程）
- **姿态识别**：`@mediapipe/tasks-vision`（WASM，在渲染进程运行，无需后端）
- **数据库**：SQLite（via `better-sqlite3`）
- **前端**：HTML + CSS + 原生 JS（像素风 UI）
- **像素动画**：CSS Sprite Animation 或 Canvas

---

## 应用架构

```
FitPet (Electron)
├── 主窗口（运动模式）
│   ├── 摄像头画面 + MediaPipe 姿态骨架叠加
│   ├── 当次运动计划清单（各项目进度）
│   └── 实时计数 / 计时 + 姿势反馈
├── 悬浮窗（始终置顶，桌面右下角）
│   ├── 像素宠物 Sprite 动画
│   ├── 今日完成度进度条
│   └── 点击展开：计划详情、连续打卡天数、"开始运动"按钮
└── 数据层（本地 SQLite）
    ├── workout_plans（运动计划配置）
    ├── daily_sessions（每次运动记录）
    ├── pet_state（宠物当前状态）
    └── daily_summary（每日汇总，用于计算级别）
```

---

## 运动检测

### 支持的运动项目

| 项目 | 检测方式 | 关键指标 |
|------|---------|---------|
| 俯卧撑 | MediaPipe Pose，肘关节角度 | 肘角 < 90° → 向下；> 160° → 完成一次 |
| 深蹲 | MediaPipe Pose，膝/髋关节角度 | 膝角 < 100° → 到位；恢复 > 160° → 完成一次 |
| 站桩 | MediaPipe Pose，静态姿势检测 | 检测到标准站姿开始计时，姿势崩溃暂停 |
| 仰卧起坐 | MediaPipe Pose，躯干与水平夹角 | 躯干抬起 > 30° → 完成一次 |
| 凯格尔 | 无摄像头检测（内部动作） | 手动按"开始一组"，10 秒倒计时自动计数 |

### 运动会话流程

1. 用户点击"开始运动"（主窗口或悬浮窗按钮）
2. 主窗口弹出，显示今日计划
3. 用户逐项完成，摄像头自动检测并计数
4. 每项完成后标记 ✅，进度更新到悬浮窗
5. 所有项目完成（或用户结束）→ 保存记录，计算当日完成率
6. 完成率影响宠物级别，播放对应动画

---

## 宠物成长系统

### 境界 & 级别规则

- **境界**：每 27 级升入下一境界，境界永久不退
- **级别**：在当前境界内，根据近 7 日平均完成率浮动
  - 完成率 ≥ 80%：当日 +1 级（不超过当前境界上限 27 级）
  - 完成率 50–79%：级别不变
  - 完成率 < 50%：当日 -1 级（不低于当前境界起始级）
- **升境界条件**：连续 27 天平均完成率 ≥ 80%

### 境界数量

无上限，当前版本预定义前 3 个境界形象：

| 境界 | 等级范围 | 宠物形象（像素风） |
|------|---------|--------------|
| 第一境界 | 1–27 | 小蛋 → 幼崽（逐渐破壳） |
| 第二境界 | 28–54 | 少年武者，有装备 |
| 第三境界 | 55–81 | 全套盔甲，光环特效 |
| 第四境界+ | 82+ | 预留，后续设计 |

### 宠物状态反馈

- 当日完成率 ≥ 80%：宠物活跃动画，庆祝特效
- 当日完成率 30–79%：正常待机动画
- 当日完成率 < 30%：萎靡动画（低头、打盹）

---

## 悬浮窗设计

**技术**：`BrowserWindow`，`alwaysOnTop: true`、`transparent: true`、`frame: false`  
**交互**：非宠物区域鼠标穿透（`setIgnoreMouseEvents`），点击宠物图标切换展开/收起

**收起状态**（默认）：
- 宠物 Sprite 动画（约 80×80px）
- 境界 · 级别文字
- 今日完成度进度条

**展开状态**（点击后）：
- 今日各项目完成情况
- 连续打卡天数
- "开始运动"按钮

---

## 数据库结构

```sql
-- 运动计划配置
CREATE TABLE workout_plans (
  id INTEGER PRIMARY KEY,
  exercise TEXT NOT NULL,      -- 'pushup' | 'squat' | 'zhan_zhuang' | 'situp' | 'kegel'
  sets INTEGER,
  reps INTEGER,                -- NULL 表示计时类
  duration_seconds INTEGER,    -- NULL 表示计次类
  display_order INTEGER
);

-- 每日运动会话记录
CREATE TABLE daily_sessions (
  id INTEGER PRIMARY KEY,
  date TEXT NOT NULL,          -- 'YYYY-MM-DD'
  exercise TEXT NOT NULL,
  completed_sets INTEGER,
  total_sets INTEGER,
  notes TEXT
);

-- 宠物状态（单行）
CREATE TABLE pet_state (
  id INTEGER PRIMARY KEY DEFAULT 1,
  current_realm INTEGER DEFAULT 1,
  current_level INTEGER DEFAULT 1,
  streak_days INTEGER DEFAULT 0,
  last_active_date TEXT
);

-- 每日汇总
CREATE TABLE daily_summary (
  date TEXT PRIMARY KEY,
  completion_rate REAL,        -- 0.0 ~ 1.0
  streak_at_date INTEGER
);
```

---

## 两种模式说明

- **观察模式**（当前版本）：摄像头检测动作，自动计数/计时，无游戏元素
- **互动模式**（未来版本）：运动动作映射到游戏操控（如视频中的哑铃控制方块），先做观察模式验证体验后再设计

---

## 验证方案

1. **姿态检测准确性**：对着摄像头做各项运动，验证计数是否准确
2. **悬浮窗功能**：确认置顶、鼠标穿透、拖拽、展开/收起正常
3. **宠物级别计算**：模拟多天数据，验证升降级逻辑正确
4. **凯格尔定时器**：验证手动计时流程流畅
5. **完整一次运动流程**：从悬浮窗点击开始，完成所有项目，验证数据正确写入

---

## 开发优先级（MVP）

1. Electron 项目骨架 + 两个窗口（主窗口 + 悬浮窗）
2. MediaPipe 集成，实现俯卧撑/深蹲计数
3. 运动计划展示 + 完成标记
4. SQLite 数据存储 + 每日完成率计算
5. 宠物基础动画（3帧像素 Sprite）+ 级别显示
6. 凯格尔手动定时器
7. 站桩/仰卧起坐检测
8. 宠物成长逻辑完整实现
