# FitPet iOS 设计文档

**日期**：2026-04-02  
**状态**：已确认，待实现

---

## 背景与目标

将 FitPet 从 Electron 桌面应用重建为 iPhone 原生 App，核心功能不变：

1. **自动运动检测**：摄像头实时识别当前动作类型并自动计数/计时，无需手动选择
2. **宠物陪伴**：iOS 插画风小龙，体现每日完成度，境界随成长演化
3. **长期激励**：宠物成长系统 + 每日运动提醒通知

---

## 技术栈

- **框架**：SwiftUI（iOS 16+）
- **姿态识别**：Vision framework（`VNDetectHumanBodyPoseRequest`），系统内置，无需下载
- **相机**：AVFoundation（`AVCaptureSession`）
- **数据层**：SwiftData（苹果原生 ORM，替代 SQLite）
- **通知**：UserNotifications framework
- **动画**：SwiftUI 原生动画（无第三方依赖）

---

## 应用架构

```
FitPet iOS
├── HomeView（首页）
│   ├── 小龙展示区（SwiftUI 矢量图形 + 动画）
│   ├── 今日计划进度列表
│   ├── 连续打卡天数 + 当前境界/级别
│   └── "开始运动" 按钮
├── WorkoutView（运动页）
│   ├── AVCaptureSession 摄像头画面
│   ├── Vision 关节点叠加层（调试用，可关闭）
│   ├── 自动动作识别状态显示
│   ├── 当前运动计数器（大字显示）
│   ├── 凯格尔手动计时面板（特殊处理）
│   └── 完成本组按钮
├── 数据层（SwiftData）
│   ├── WorkoutPlan（运动计划配置）
│   ├── DailySession（每次运动记录）
│   ├── PetState（宠物当前状态）
│   └── DailySummary（每日汇总）
└── NotificationManager（每日提醒）
```

---

## 自动动作识别

### 识别逻辑

摄像头持续运行，每帧通过 Vision 获取关节点，根据以下特征判断当前动作：

| 动作 | 识别特征 | 计数触发条件 |
|------|---------|------------|
| 俯卧撑 | 身体水平（肩部 y ≈ 臀部 y），肘角周期变化 | 肘角 < 90° → down；> 160° → up，完成一次 |
| 深蹲 | 身体直立（肩部 y 远低于臀部），膝角周期变化 | 膝角 < 100° → down；> 160° → up，完成一次 |
| 仰卧起坐 | 身体水平仰卧（肩部 y ≈ 臀部 y，面朝上），躯干角度变化 | 躯干与水平夹角 > 30° → up；< 10° → down，完成一次 |
| 站桩 | 直立静止，双脚分开，双手自然下垂或抱球姿 | 检测到标准站姿后开始计时，姿势崩溃则暂停 |
| 凯格尔 | 无法摄像头检测 | 手动按"开始一组"，10 秒倒计时 |

### 防误触机制

- 连续 **15 帧**（约 0.5 秒）识别到同一动作类型才确认切换，避免偶发动作触发
- 动作切换时重置当前计数器
- visibility 置信度 < 0.6 的关节点不参与计算

### 动作识别优先级

1. 先判断身体姿态（水平趴 / 水平仰 / 直立）
2. 再判断关节角度变化模式
3. 静止直立且无明显周期运动 → 站桩模式

---

## 宠物设计

### 小龙形态演化

| 境界范围 | 形态 | 视觉特征 |
|---------|------|---------|
| 境界 1（1-27级） | 龙蛋 | 圆形蛋，有裂纹 |
| 境界 2（28-54级） | 幼龙 | 小小身体，大眼睛，无翅膀 |
| 境界 3（55-81级） | 成长龙 | 有翅膀，可以飞 |
| 境界 4+（82级+） | 神龙 | 金色/发光，威严 |

### 动画状态

- **待机**：轻微呼吸起伏（scale 动画，周期 3 秒）
- **运动中**：兴奋小跳（translateY 动画）
- **完成今日计划**：旋转 + 粒子效果
- **连续 3 天未运动**：耷拉尾巴，灰色调

### 实现方式

SwiftUI `Path` + `Shape` 绘制矢量小龙，用 `withAnimation` + `@State` 驱动状态切换，无需外部图片资源。

---

## 宠物成长系统

完全复用现有逻辑：

- 每 27 级升入下一境界，境界永久不退
- 当日完成率 ≥ 80%：+1 级
- 当日完成率 50–79%：级别不变
- 当日完成率 < 50%：-1 级（不低于当前境界起始级）
- 连续高完成率天数影响升境界判断

---

## 数据模型（SwiftData）

```swift
@Model class WorkoutPlan {
    var exercise: String       // "pushup" | "squat" | "situp" | "zhan_zhuang" | "kegel"
    var sets: Int
    var reps: Int?
    var durationSeconds: Int?
}

@Model class DailySession {
    var date: String           // "2026-04-02"
    var exercise: String
    var completedSets: Int
    var totalSets: Int
}

@Model class PetState {
    var currentRealm: Int      // 境界
    var currentLevel: Int      // 全局级别
    var streakDays: Int
    var lastActiveDate: String
}

@Model class DailySummary {
    var date: String
    var completionRate: Double  // 0.0 - 1.0
    var streakDays: Int
}
```

---

## 通知

- 用户首次打开 App 时请求通知权限
- 默认每天 **20:00** 发送提醒："该去运动了，小龙在等你 🐉"
- 用户可在设置中修改提醒时间或关闭

---

## 默认运动计划

```
俯卧撑：3组 × 15个
深蹲：3组 × 20个
站桩：1组 × 300秒
仰卧起坐：3组 × 20个
凯格尔：3组 × 10秒
```

---

## 项目结构

```
FitPetApp/
├── FitPetApp.swift              # App 入口
├── Models/
│   ├── WorkoutPlan.swift
│   ├── DailySession.swift
│   ├── PetState.swift
│   └── DailySummary.swift
├── Views/
│   ├── HomeView.swift           # 首页
│   ├── WorkoutView.swift        # 运动页（相机 + 检测）
│   ├── DragonView.swift         # 小龙渲染
│   └── PlanProgressView.swift   # 今日计划进度
├── Detection/
│   ├── PoseDetector.swift       # AVFoundation + Vision 封装
│   ├── ExerciseClassifier.swift # 动作自动识别逻辑
│   ├── PushupCounter.swift
│   ├── SquatCounter.swift
│   ├── SitupCounter.swift
│   └── ZhanZhuangTimer.swift
├── Services/
│   ├── WorkoutService.swift     # 计划与记录业务逻辑
│   ├── PetGrowthService.swift   # 宠物成长计算
│   └── NotificationManager.swift
└── ContentView.swift            # 根视图（TabView）
```
