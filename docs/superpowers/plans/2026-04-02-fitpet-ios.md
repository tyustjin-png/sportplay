# FitPet iOS 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 SwiftUI + Vision framework 构建 FitPet iPhone 原生 App，实现自动运动检测计数 + 小龙宠物成长系统。

**Architecture:** SwiftUI 单 App，AVFoundation 采集摄像头帧，Vision `VNDetectHumanBodyPoseRequest` 识别关节点，纯 Swift 状态机计数器判断动作完成，SwiftData 持久化数据。

**Tech Stack:** Swift 5.9+, SwiftUI, Vision framework, AVFoundation, SwiftData, UserNotifications, XCTest, Xcode 15+, iOS 16+

---

## 文件结构

```
FitPet/
├── FitPetApp.swift
├── ContentView.swift
├── Models/
│   ├── WorkoutPlan.swift
│   ├── DailySession.swift
│   ├── PetState.swift
│   └── DailySummary.swift
├── Detection/
│   ├── AngleUtils.swift          # calcAngle 纯函数
│   ├── PushupCounter.swift
│   ├── SquatCounter.swift
│   ├── SitupCounter.swift
│   ├── ZhanZhuangTimer.swift
│   └── ExerciseClassifier.swift  # 自动识别动作类型
├── Camera/
│   ├── PoseDetector.swift        # AVFoundation + Vision 封装
│   └── CameraPreviewView.swift   # UIViewRepresentable 相机预览
├── Services/
│   ├── WorkoutService.swift
│   ├── PetGrowthService.swift
│   └── NotificationManager.swift
└── Views/
    ├── HomeView.swift
    ├── WorkoutView.swift
    ├── DragonView.swift
    └── PlanProgressView.swift

FitPetTests/
├── AngleUtilsTests.swift
├── PushupCounterTests.swift
├── SquatCounterTests.swift
├── SitupCounterTests.swift
├── ZhanZhuangTimerTests.swift
├── ExerciseClassifierTests.swift
└── PetGrowthServiceTests.swift
```

---

## Task 1: Xcode 项目创建

**Files:**
- Create: `FitPet/` (Xcode 项目根目录，由 Xcode GUI 生成)

- [ ] **Step 1: 打开 Xcode，创建新项目**

  File → New → Project → iOS → App
  - Product Name: `FitPet`
  - Team: None（暂时）
  - Organization Identifier: `com.fitpet`
  - Interface: SwiftUI
  - Storage: SwiftData
  - Language: Swift
  - 取消勾选 "Include Tests"（我们手动添加）
  - 保存到：`/Users/qianzhao/Documents/quant/运动陪伴项目/FitPet`

- [ ] **Step 2: 添加 Unit Test Target**

  File → New → Target → Unit Testing Bundle
  - Product Name: `FitPetTests`
  - Target to be Tested: FitPet

- [ ] **Step 3: 在 Info.plist 添加摄像头和通知权限描述**

  在项目 Navigator 中选中 `FitPet` target → Info → 添加以下 key：
  - `NSCameraUsageDescription` → `"FitPet 需要摄像头来检测你的运动动作"`
  - `NSMotionUsageDescription` → `"FitPet 需要分析你的运动姿态"`

- [ ] **Step 4: 创建文件夹结构**

  在 Xcode Project Navigator 中右键 → New Group，创建：
  `Models`, `Detection`, `Camera`, `Services`, `Views`

- [ ] **Step 5: 验证项目能编译**

  按 `Cmd+B`，Expected: Build Succeeded

- [ ] **Step 6: 提交**

  ```bash
  cd /Users/qianzhao/Documents/quant/运动陪伴项目
  git add FitPet/
  git commit -m "feat: 创建 FitPet Xcode 项目骨架"
  ```

---

## Task 2: SwiftData 数据模型

**Files:**
- Create: `FitPet/Models/WorkoutPlan.swift`
- Create: `FitPet/Models/DailySession.swift`
- Create: `FitPet/Models/PetState.swift`
- Create: `FitPet/Models/DailySummary.swift`
- Modify: `FitPet/FitPetApp.swift`

- [ ] **Step 1: 创建 WorkoutPlan.swift**

  ```swift
  import SwiftData

  @Model
  final class WorkoutPlan {
      var exercise: String       // "pushup" | "squat" | "situp" | "zhan_zhuang" | "kegel"
      var sets: Int
      var reps: Int?
      var durationSeconds: Int?
      var sortOrder: Int

      init(exercise: String, sets: Int, reps: Int? = nil, durationSeconds: Int? = nil, sortOrder: Int = 0) {
          self.exercise = exercise
          self.sets = sets
          self.reps = reps
          self.durationSeconds = durationSeconds
          self.sortOrder = sortOrder
      }

      static let exerciseNames: [String: String] = [
          "pushup": "俯卧撑",
          "squat": "深蹲",
          "situp": "仰卧起坐",
          "zhan_zhuang": "站桩",
          "kegel": "凯格尔",
      ]

      var displayName: String { WorkoutPlan.exerciseNames[exercise] ?? exercise }

      var targetDescription: String {
          if let reps { return "\(sets)组 × \(reps)个" }
          if let dur = durationSeconds { return "\(sets)组 × \(dur)秒" }
          return "\(sets)组"
      }
  }
  ```

- [ ] **Step 2: 创建 DailySession.swift**

  ```swift
  import SwiftData

  @Model
  final class DailySession {
      var date: String           // "2026-04-02"
      var exercise: String
      var completedSets: Int
      var totalSets: Int

      init(date: String, exercise: String, completedSets: Int, totalSets: Int) {
          self.date = date
          self.exercise = exercise
          self.completedSets = completedSets
          self.totalSets = totalSets
      }
  }
  ```

- [ ] **Step 3: 创建 PetState.swift**

  ```swift
  import SwiftData

  @Model
  final class PetState {
      var currentRealm: Int      // 境界（1 起）
      var currentLevel: Int      // 全局级别（1 起）
      var streakDays: Int
      var lastActiveDate: String // "2026-04-02" 或 ""

      init() {
          self.currentRealm = 1
          self.currentLevel = 1
          self.streakDays = 0
          self.lastActiveDate = ""
      }
  }
  ```

- [ ] **Step 4: 创建 DailySummary.swift**

  ```swift
  import SwiftData

  @Model
  final class DailySummary {
      var date: String
      var completionRate: Double  // 0.0 - 1.0
      var streakDays: Int

      init(date: String, completionRate: Double, streakDays: Int) {
          self.date = date
          self.completionRate = completionRate
          self.streakDays = streakDays
      }
  }
  ```

- [ ] **Step 5: 修改 FitPetApp.swift，注册所有模型**

  ```swift
  import SwiftUI
  import SwiftData

  @main
  struct FitPetApp: App {
      var body: some Scene {
          WindowGroup {
              ContentView()
          }
          .modelContainer(for: [
              WorkoutPlan.self,
              DailySession.self,
              PetState.self,
              DailySummary.self,
          ])
      }
  }
  ```

- [ ] **Step 6: 编译验证**

  `Cmd+B` → Build Succeeded

- [ ] **Step 7: 提交**

  ```bash
  git add FitPet/Models/ FitPet/FitPetApp.swift
  git commit -m "feat: SwiftData 数据模型"
  ```

---

## Task 3: AngleUtils + 运动计数器（纯逻辑，可单元测试）

**Files:**
- Create: `FitPet/Detection/AngleUtils.swift`
- Create: `FitPet/Detection/PushupCounter.swift`
- Create: `FitPet/Detection/SquatCounter.swift`
- Create: `FitPet/Detection/SitupCounter.swift`
- Create: `FitPet/Detection/ZhanZhuangTimer.swift`
- Create: `FitPetTests/AngleUtilsTests.swift`
- Create: `FitPetTests/PushupCounterTests.swift`

- [ ] **Step 1: 创建 AngleUtils.swift**

  ```swift
  import Foundation
  import CoreGraphics

  /// 计算三点形成的夹角（度数，0-180）
  /// - Parameters:
  ///   - a: 起点
  ///   - b: 顶点（夹角顶点）
  ///   - c: 终点
  func calcAngle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
      let radians = atan2(Double(c.y - b.y), Double(c.x - b.x))
                  - atan2(Double(a.y - b.y), Double(a.x - b.x))
      var angle = abs(radians * 180 / .pi)
      if angle > 180 { angle = 360 - angle }
      return angle
  }
  ```

- [ ] **Step 2: 写 AngleUtilsTests.swift 的失败测试**

  ```swift
  import XCTest
  @testable import FitPet

  final class AngleUtilsTests: XCTestCase {
      func test_straightLine_returns180() {
          // 三点共线，角度应为 180
          let a = CGPoint(x: 0, y: 0)
          let b = CGPoint(x: 1, y: 0)
          let c = CGPoint(x: 2, y: 0)
          XCTAssertEqual(calcAngle(a, b, c), 180, accuracy: 0.01)
      }

      func test_rightAngle_returns90() {
          let a = CGPoint(x: 0, y: 0)
          let b = CGPoint(x: 1, y: 0)
          let c = CGPoint(x: 1, y: 1)
          XCTAssertEqual(calcAngle(a, b, c), 90, accuracy: 0.01)
      }

      func test_symmetricAcuteAngle() {
          // 等边三角形顶角 = 60°
          let a = CGPoint(x: 0, y: 0)
          let b = CGPoint(x: 1, y: 0)
          let c = CGPoint(x: 0.5, y: sqrt(3)/2)
          XCTAssertEqual(calcAngle(a, b, c), 60, accuracy: 0.1)
      }
  }
  ```

- [ ] **Step 3: 运行测试，确认失败（函数还没加进测试 target）**

  `Cmd+U` → 确认 AngleUtilsTests 全部 FAIL（找不到 calcAngle）
  
  在 Xcode 中选中 `AngleUtils.swift`，在 Target Membership 勾选 `FitPetTests`

- [ ] **Step 4: 再次运行，确认通过**

  `Cmd+U` → AngleUtilsTests: 3 tests passed

- [ ] **Step 5: 创建 PushupCounter.swift**

  ```swift
  import CoreGraphics

  // Vision 关节点索引（VNHumanBodyPoseObservation.JointName 对应位置）
  // 实际使用时通过 PoseDetector 传入 CGPoint 字典，key 为关节名字符串
  struct PushupCounter {
      private(set) var count = 0
      private var phase: Phase = .up

      private enum Phase { case up, down }

      private let downThreshold: Double = 90
      private let upThreshold: Double = 160
      private let minVisibility: Float = 0.6

      mutating func update(landmarks: [String: (point: CGPoint, confidence: Float)]) {
          guard
              let ls = landmarks["leftShoulder"],  ls.confidence >= minVisibility,
              let le = landmarks["leftElbow"],      le.confidence >= minVisibility,
              let lw = landmarks["leftWrist"],      lw.confidence >= minVisibility,
              let rs = landmarks["rightShoulder"],  rs.confidence >= minVisibility,
              let re = landmarks["rightElbow"],     re.confidence >= minVisibility,
              let rw = landmarks["rightWrist"],     rw.confidence >= minVisibility
          else { return }

          let leftAngle  = calcAngle(ls.point, le.point, lw.point)
          let rightAngle = calcAngle(rs.point, re.point, rw.point)
          let avg = (leftAngle + rightAngle) / 2

          switch phase {
          case .up   where avg < downThreshold: phase = .down
          case .down where avg > upThreshold:   phase = .up; count += 1
          default: break
          }
      }

      mutating func reset() { count = 0; phase = .up }
  }
  ```

- [ ] **Step 6: 写 PushupCounterTests.swift**

  ```swift
  import XCTest
  @testable import FitPet

  final class PushupCounterTests: XCTestCase {
      // 构造高置信度关节点，肘角为指定角度
      private func landmarks(elbowAngle: Double) -> [String: (point: CGPoint, confidence: Float)] {
          // 肩在(0,0)，肘在(1,0)，腕根据角度计算
          let rad = elbowAngle * .pi / 180
          let wristX = 1 + cos(rad)
          let wristY = sin(rad)
          let pt: (CGPoint, Float) -> (point: CGPoint, confidence: Float) = { ($0, $1) }
          return [
              "leftShoulder":  pt(CGPoint(x: 0, y: 0), 0.9),
              "leftElbow":     pt(CGPoint(x: 1, y: 0), 0.9),
              "leftWrist":     pt(CGPoint(x: wristX, y: wristY), 0.9),
              "rightShoulder": pt(CGPoint(x: 0, y: 0), 0.9),
              "rightElbow":    pt(CGPoint(x: 1, y: 0), 0.9),
              "rightWrist":    pt(CGPoint(x: wristX, y: wristY), 0.9),
          ]
      }

      func test_oneRepCounted() {
          var counter = PushupCounter()
          counter.update(landmarks: landmarks(elbowAngle: 170)) // up (>160)
          counter.update(landmarks: landmarks(elbowAngle: 80))  // down (<90)
          counter.update(landmarks: landmarks(elbowAngle: 170)) // up again → count = 1
          XCTAssertEqual(counter.count, 1)
      }

      func test_noCountWithoutFullRange() {
          var counter = PushupCounter()
          counter.update(landmarks: landmarks(elbowAngle: 130)) // 中间角度，不触发
          counter.update(landmarks: landmarks(elbowAngle: 120))
          XCTAssertEqual(counter.count, 0)
      }

      func test_lowConfidenceIgnored() {
          var counter = PushupCounter()
          var lm = landmarks(elbowAngle: 80)
          lm["leftElbow"] = (lm["leftElbow"]!.point, 0.3) // 低置信度
          counter.update(landmarks: lm)
          XCTAssertEqual(counter.count, 0)
      }

      func test_resetClearsCount() {
          var counter = PushupCounter()
          counter.update(landmarks: landmarks(elbowAngle: 170))
          counter.update(landmarks: landmarks(elbowAngle: 80))
          counter.update(landmarks: landmarks(elbowAngle: 170))
          counter.reset()
          XCTAssertEqual(counter.count, 0)
      }
  }
  ```

- [ ] **Step 7: 创建 SquatCounter.swift**

  ```swift
  import CoreGraphics

  struct SquatCounter {
      private(set) var count = 0
      private var phase: Phase = .standing

      private enum Phase { case standing, squatting }

      private let downThreshold: Double = 100
      private let upThreshold: Double = 160
      private let minVisibility: Float = 0.6

      mutating func update(landmarks: [String: (point: CGPoint, confidence: Float)]) {
          guard
              let lh = landmarks["leftHip"],    lh.confidence >= minVisibility,
              let lk = landmarks["leftKnee"],   lk.confidence >= minVisibility,
              let la = landmarks["leftAnkle"],  la.confidence >= minVisibility,
              let rh = landmarks["rightHip"],   rh.confidence >= minVisibility,
              let rk = landmarks["rightKnee"],  rk.confidence >= minVisibility,
              let ra = landmarks["rightAnkle"], ra.confidence >= minVisibility
          else { return }

          let leftAngle  = calcAngle(lh.point, lk.point, la.point)
          let rightAngle = calcAngle(rh.point, rk.point, ra.point)
          let avg = (leftAngle + rightAngle) / 2

          switch phase {
          case .standing  where avg < downThreshold: phase = .squatting
          case .squatting where avg > upThreshold:   phase = .standing; count += 1
          default: break
          }
      }

      mutating func reset() { count = 0; phase = .standing }
  }
  ```

- [ ] **Step 8: 创建 SitupCounter.swift**

  ```swift
  import CoreGraphics

  struct SitupCounter {
      private(set) var count = 0
      private var phase: Phase = .down

      private enum Phase { case down, up }

      // 躯干与水平线夹角：>30° 为 up，<10° 为 down
      private let upThreshold: Double = 30
      private let downThreshold: Double = 10
      private let minVisibility: Float = 0.6

      mutating func update(landmarks: [String: (point: CGPoint, confidence: Float)]) {
          guard
              let ls = landmarks["leftShoulder"],  ls.confidence >= minVisibility,
              let rs = landmarks["rightShoulder"],  rs.confidence >= minVisibility,
              let lh = landmarks["leftHip"],        lh.confidence >= minVisibility,
              let rh = landmarks["rightHip"],       rh.confidence >= minVisibility
          else { return }

          // 肩部中点与髋部中点连线与水平线的夹角
          let shoulderMid = CGPoint(x: (ls.point.x + rs.point.x) / 2,
                                    y: (ls.point.y + rs.point.y) / 2)
          let hipMid      = CGPoint(x: (lh.point.x + rh.point.x) / 2,
                                    y: (lh.point.y + rh.point.y) / 2)
          let dx = Double(shoulderMid.x - hipMid.x)
          let dy = Double(shoulderMid.y - hipMid.y)
          let angle = abs(atan2(dy, dx) * 180 / .pi)
          // Vision 坐标 y 轴向上，夹角偏差补正
          let torsoAngle = angle > 90 ? 180 - angle : angle

          switch phase {
          case .down where torsoAngle > upThreshold:   phase = .up
          case .up   where torsoAngle < downThreshold: phase = .down; count += 1
          default: break
          }
      }

      mutating func reset() { count = 0; phase = .down }
  }
  ```

- [ ] **Step 9: 创建 ZhanZhuangTimer.swift**

  ```swift
  import CoreGraphics
  import Foundation

  struct ZhanZhuangTimer {
      private(set) var elapsedSeconds: Double = 0
      private var isActive = false
      private var lastTimestamp: Date?
      private let minVisibility: Float = 0.6

      mutating func update(landmarks: [String: (point: CGPoint, confidence: Float)], now: Date = Date()) {
          let poseValid = isPoseValid(landmarks)
          if poseValid {
              if isActive, let last = lastTimestamp {
                  elapsedSeconds += now.timeIntervalSince(last)
              }
              isActive = true
          } else {
              isActive = false
          }
          lastTimestamp = now
      }

      mutating func reset() { elapsedSeconds = 0; isActive = false; lastTimestamp = nil }

      // 简单判断：双肩、双髋可见且身体直立
      private func isPoseValid(_ landmarks: [String: (point: CGPoint, confidence: Float)]) -> Bool {
          let required = ["leftShoulder", "rightShoulder", "leftHip", "rightHip"]
          for key in required {
              guard let lm = landmarks[key], lm.confidence >= minVisibility else { return false }
          }
          // 肩部 y 值应高于（Vision 坐标中小于）髋部 y 值（直立判断）
          guard let ls = landmarks["leftShoulder"], let lh = landmarks["leftHip"] else { return false }
          return ls.point.y < lh.point.y  // Vision: y=0 在底部，y=1 在顶部
      }
  }
  ```

- [ ] **Step 10: 运行所有测试**

  `Cmd+U` → 确认所有测试通过

- [ ] **Step 11: 提交**

  ```bash
  git add FitPet/Detection/ FitPetTests/
  git commit -m "feat: AngleUtils + 四种运动计数器 + 单元测试"
  ```

---

## Task 4: ExerciseClassifier（自动识别当前动作）

**Files:**
- Create: `FitPet/Detection/ExerciseClassifier.swift`
- Create: `FitPetTests/ExerciseClassifierTests.swift`

- [ ] **Step 1: 创建 ExerciseClassifier.swift**

  ```swift
  import CoreGraphics

  enum ExerciseType: String, Equatable {
      case pushup     = "pushup"
      case squat      = "squat"
      case situp      = "situp"
      case zhanZhuang = "zhan_zhuang"
      case kegel      = "kegel"
      case unknown    = "unknown"
  }

  /// 根据骨架关节点自动识别当前运动类型
  /// 连续 confirmationFrames 帧一致才确认切换，防止误触发
  struct ExerciseClassifier {
      private(set) var currentExercise: ExerciseType = .unknown

      var confirmationFrames: Int = 15
      private var candidateExercise: ExerciseType = .unknown
      private var candidateCount: Int = 0

      private let minVisibility: Float = 0.5

      mutating func update(landmarks: [String: (point: CGPoint, confidence: Float)]) {
          let detected = classify(landmarks)

          if detected == candidateExercise {
              candidateCount += 1
              if candidateCount >= confirmationFrames {
                  currentExercise = candidateExercise
              }
          } else {
              candidateExercise = detected
              candidateCount = 1
          }
      }

      mutating func reset() {
          currentExercise = .unknown
          candidateExercise = .unknown
          candidateCount = 0
      }

      // MARK: - 内部分类逻辑

      private func classify(_ lm: [String: (point: CGPoint, confidence: Float)]) -> ExerciseType {
          guard hasMinimumLandmarks(lm) else { return .unknown }

          let orientation = bodyOrientation(lm)

          switch orientation {
          case .prone:   return .pushup
          case .supine:  return .situp
          case .upright:
              if isKneeFlexing(lm) { return .squat }
              return .zhanZhuang
          case .unknown: return .unknown
          }
      }

      private enum BodyOrientation { case prone, supine, upright, unknown }

      private func bodyOrientation(_ lm: [String: (point: CGPoint, confidence: Float)]) -> BodyOrientation {
          guard
              let ls = lm["leftShoulder"],  ls.confidence >= minVisibility,
              let lh = lm["leftHip"],       lh.confidence >= minVisibility,
              let la = lm["leftAnkle"],     la.confidence >= minVisibility
          else { return .unknown }

          // Vision 坐标系：y=0 底部，y=1 顶部
          // 直立时：肩部 y > 髋部 y > 踝部 y（差值明显）
          let shoulderToHip = Double(lh.point.y - ls.point.y)  // 直立时 > 0（髋在肩下）
          let hipToAnkle    = Double(la.point.y - lh.point.y)  // 直立时 > 0（踝在髋下）

          // 直立：竖向分布
          if shoulderToHip > 0.1 && hipToAnkle > 0.1 { return .upright }

          // 水平：横向分布（肩髋在差不多同一 y 高度）
          if abs(shoulderToHip) < 0.1 {
              // 区分趴下（prone）vs 仰躺（supine）
              // 用鼻子/眼睛相对肩部的位置来判断朝向
              if let nose = lm["nose"], nose.confidence >= minVisibility {
                  // prone（趴下）：鼻子 y 值接近肩部或偏低
                  // supine（仰卧）：鼻子 y 值高于肩部
                  return nose.point.y > ls.point.y ? .supine : .prone
              }
              return .prone // 默认趴下
          }

          return .unknown
      }

      private func isKneeFlexing(_ lm: [String: (point: CGPoint, confidence: Float)]) -> Bool {
          guard
              let lh = lm["leftHip"],   lh.confidence >= minVisibility,
              let lk = lm["leftKnee"],  lk.confidence >= minVisibility,
              let la = lm["leftAnkle"], la.confidence >= minVisibility
          else { return false }
          let angle = calcAngle(lh.point, lk.point, la.point)
          return angle < 150  // 膝盖有明显弯曲
      }

      private func hasMinimumLandmarks(_ lm: [String: (point: CGPoint, confidence: Float)]) -> Bool {
          let required = ["leftShoulder", "leftHip", "leftAnkle"]
          return required.allSatisfy { key in
              (lm[key]?.confidence ?? 0) >= minVisibility
          }
      }
  }
  ```

- [ ] **Step 2: 写 ExerciseClassifierTests.swift**

  ```swift
  import XCTest
  @testable import FitPet

  final class ExerciseClassifierTests: XCTestCase {
      private func pt(_ x: Double, _ y: Double, _ conf: Float = 0.9) -> (point: CGPoint, confidence: Float) {
          (CGPoint(x: x, y: y), conf)
      }

      // 直立姿势：肩(0.5, 0.8) 髋(0.5, 0.5) 踝(0.5, 0.1)
      private var uprightLandmarks: [String: (point: CGPoint, confidence: Float)] {
          ["leftShoulder": pt(0.5, 0.8), "leftHip": pt(0.5, 0.5), "leftAnkle": pt(0.5, 0.1),
           "leftKnee": pt(0.5, 0.3), "rightShoulder": pt(0.6, 0.8), "rightHip": pt(0.6, 0.5),
           "rightKnee": pt(0.6, 0.3), "rightAnkle": pt(0.6, 0.1), "nose": pt(0.5, 0.9)]
      }

      // 趴下：肩髋同高
      private var proneLandmarks: [String: (point: CGPoint, confidence: Float)] {
          ["leftShoulder": pt(0.2, 0.5), "leftHip": pt(0.5, 0.5), "leftAnkle": pt(0.8, 0.5),
           "leftKnee": pt(0.65, 0.5), "nose": pt(0.05, 0.45)]
      }

      func test_confirmationRequired() {
          var classifier = ExerciseClassifier()
          classifier.confirmationFrames = 3
          // 不足 3 帧不切换
          classifier.update(landmarks: uprightLandmarks)
          classifier.update(landmarks: uprightLandmarks)
          XCTAssertEqual(classifier.currentExercise, .unknown)
          // 第 3 帧确认
          classifier.update(landmarks: uprightLandmarks)
          XCTAssertEqual(classifier.currentExercise, .zhanZhuang)
      }

      func test_proneDetectedAsPushup() {
          var classifier = ExerciseClassifier()
          classifier.confirmationFrames = 1
          classifier.update(landmarks: proneLandmarks)
          XCTAssertEqual(classifier.currentExercise, .pushup)
      }

      func test_squatDetectedWhenKneeFlexed() {
          var classifier = ExerciseClassifier()
          classifier.confirmationFrames = 1
          var lm = uprightLandmarks
          // 膝盖弯曲：膝 y 值与踝相近
          lm["leftKnee"]  = pt(0.5, 0.2)
          lm["leftHip"]   = pt(0.5, 0.4)
          lm["leftAnkle"] = pt(0.5, 0.1)
          classifier.update(landmarks: lm)
          XCTAssertEqual(classifier.currentExercise, .squat)
      }

      func test_resetClearsState() {
          var classifier = ExerciseClassifier()
          classifier.confirmationFrames = 1
          classifier.update(landmarks: proneLandmarks)
          classifier.reset()
          XCTAssertEqual(classifier.currentExercise, .unknown)
      }
  }
  ```

- [ ] **Step 3: 运行测试**

  `Cmd+U` → 4 tests passed

- [ ] **Step 4: 提交**

  ```bash
  git add FitPet/Detection/ExerciseClassifier.swift FitPetTests/ExerciseClassifierTests.swift
  git commit -m "feat: ExerciseClassifier 自动识别动作类型 + 确认帧防抖"
  ```

---

## Task 5: PoseDetector + CameraPreviewView

**Files:**
- Create: `FitPet/Camera/PoseDetector.swift`
- Create: `FitPet/Camera/CameraPreviewView.swift`

注意：此模块涉及摄像头，无法单元测试，在模拟器中以空数据运行。

- [ ] **Step 1: 创建 PoseDetector.swift**

  ```swift
  import AVFoundation
  import Vision
  import CoreGraphics
  import Combine

  typealias PoseLandmarks = [String: (point: CGPoint, confidence: Float)]

  final class PoseDetector: NSObject, ObservableObject {
      @Published var landmarks: PoseLandmarks = [:]

      let captureSession = AVCaptureSession()
      private let videoOutput    = AVCaptureVideoDataOutput()
      private let queue = DispatchQueue(label: "com.fitpet.posedetect", qos: .userInitiated)

      // Vision 关节名映射（Vision JointName → 我们内部 key）
      private static let jointMap: [VNHumanBodyPoseObservation.JointName: String] = [
          .leftShoulder:  "leftShoulder",
          .rightShoulder: "rightShoulder",
          .leftElbow:     "leftElbow",
          .rightElbow:    "rightElbow",
          .leftWrist:     "leftWrist",
          .rightWrist:    "rightWrist",
          .leftHip:       "leftHip",
          .rightHip:      "rightHip",
          .leftKnee:      "leftKnee",
          .rightKnee:     "rightKnee",
          .leftAnkle:     "leftAnkle",
          .rightAnkle:    "rightAnkle",
          .nose:          "nose",
      ]

      func startSession() {
          queue.async { [weak self] in self?.configureAndStart() }
      }

      func stopSession() {
          captureSession.stopRunning()
      }

      private func configureAndStart() {
          captureSession.beginConfiguration()
          captureSession.sessionPreset = .vga640x480

          guard
              let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input  = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input)
          else { captureSession.commitConfiguration(); return }

          captureSession.addInput(input)
          videoOutput.setSampleBufferDelegate(self, queue: queue)
          videoOutput.alwaysDiscardsLateVideoFrames = true
          guard captureSession.canAddOutput(videoOutput) else { captureSession.commitConfiguration(); return }
          captureSession.addOutput(videoOutput)

          // 前置摄像头镜像
          if let connection = videoOutput.connection(with: .video) {
              connection.videoRotationAngle = 90
              if connection.isVideoMirroringSupported { connection.isVideoMirrored = true }
          }

          captureSession.commitConfiguration()
          captureSession.startRunning()
      }

      var previewLayer: AVCaptureVideoPreviewLayer {
          let layer = AVCaptureVideoPreviewLayer(session: captureSession)
          layer.videoGravity = .resizeAspectFill
          return layer
      }
  }

  extension PoseDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
      func captureOutput(_ output: AVCaptureOutput,
                         didOutput sampleBuffer: CMSampleBuffer,
                         from connection: AVCaptureConnection) {
          guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

          let request = VNDetectHumanBodyPoseRequest()
          let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                              orientation: .up,
                                              options: [:])
          try? handler.perform([request])

          guard let observation = request.results?.first else {
              DispatchQueue.main.async { self.landmarks = [:] }
              return
          }

          var result: PoseLandmarks = [:]
          for (jointName, key) in Self.jointMap {
              if let point = try? observation.recognizedPoint(jointName),
                 point.confidence > 0 {
                  // Vision 坐标：y=0 底部。转为 UIKit 坐标（y=0 顶部）
                  result[key] = (CGPoint(x: point.x, y: 1 - point.y), point.confidence)
              }
          }

          DispatchQueue.main.async { self.landmarks = result }
      }
  }
  ```

- [ ] **Step 2: 创建 CameraPreviewView.swift**

  ```swift
  import SwiftUI
  import AVFoundation

  struct CameraPreviewView: UIViewRepresentable {
      let session: AVCaptureSession

      func makeUIView(context: Context) -> PreviewUIView {
          let view = PreviewUIView()
          view.previewLayer.session = session
          view.previewLayer.videoGravity = .resizeAspectFill
          return view
      }

      func updateUIView(_ uiView: PreviewUIView, context: Context) {}

      class PreviewUIView: UIView {
          override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
          var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
      }
  }
  ```

- [ ] **Step 3: 编译验证**

  `Cmd+B` → Build Succeeded（模拟器上摄像头不可用但代码能编译）

- [ ] **Step 4: 提交**

  ```bash
  git add FitPet/Camera/
  git commit -m "feat: PoseDetector AVFoundation+Vision封装 + CameraPreviewView"
  ```

---

## Task 6: PetGrowthService

**Files:**
- Create: `FitPet/Services/PetGrowthService.swift`
- Create: `FitPetTests/PetGrowthServiceTests.swift`

- [ ] **Step 1: 创建 PetGrowthService.swift**

  ```swift
  import Foundation

  struct PetGrowthService {
      static let levelsPerRealm = 27

      /// 根据全局级别计算所在境界（1起）
      static func realm(for level: Int) -> Int {
          (level - 1) / levelsPerRealm + 1
      }

      /// 在当前境界内的级别（1-27）
      static func levelInRealm(for level: Int) -> Int {
          (level - 1) % levelsPerRealm + 1
      }

      /// 计算新级别
      /// - Parameters:
      ///   - currentLevel: 当前全局级别
      ///   - completionRate: 当日完成率 0.0-1.0
      ///   - consecutiveHighDays: 连续高完成率天数（用于升境界）
      /// - Returns: 新的全局级别（境界永不退，级别在境界内浮动）
      static func newLevel(currentLevel: Int, completionRate: Double, consecutiveHighDays: Int) -> Int {
          let currentRealm = realm(for: currentLevel)
          let realmStart   = (currentRealm - 1) * levelsPerRealm + 1
          let realmEnd     = currentRealm * levelsPerRealm

          var newLevel = currentLevel
          if completionRate >= 0.8 {
              newLevel = min(currentLevel + 1, realmEnd)
          } else if completionRate < 0.5 {
              newLevel = max(currentLevel - 1, realmStart)
          }

          // 连续 7 天完成率 >= 80% 则升境界
          if consecutiveHighDays >= 7 && completionRate >= 0.8 && currentLevel == realmEnd {
              newLevel = realmEnd + 1
          }

          return max(newLevel, 1)
      }

      /// 宠物形态（根据境界）
      enum DragonForm {
          case egg       // 境界 1
          case hatchling // 境界 2
          case young     // 境界 3
          case divine    // 境界 4+
      }

      static func dragonForm(for level: Int) -> DragonForm {
          switch realm(for: level) {
          case 1:  return .egg
          case 2:  return .hatchling
          case 3:  return .young
          default: return .divine
          }
      }

      /// 宠物心情（根据今日完成率）
      enum PetMood { case happy, neutral, sad }

      static func mood(completionRate: Double, daysSinceActive: Int) -> PetMood {
          if daysSinceActive >= 3 { return .sad }
          if completionRate >= 0.8 { return .happy }
          if completionRate >= 0.5 { return .neutral }
          return .sad
      }
  }
  ```

- [ ] **Step 2: 写 PetGrowthServiceTests.swift**

  ```swift
  import XCTest
  @testable import FitPet

  final class PetGrowthServiceTests: XCTestCase {
      func test_realmCalculation() {
          XCTAssertEqual(PetGrowthService.realm(for: 1),  1)
          XCTAssertEqual(PetGrowthService.realm(for: 27), 1)
          XCTAssertEqual(PetGrowthService.realm(for: 28), 2)
          XCTAssertEqual(PetGrowthService.realm(for: 54), 2)
          XCTAssertEqual(PetGrowthService.realm(for: 55), 3)
      }

      func test_levelInRealm() {
          XCTAssertEqual(PetGrowthService.levelInRealm(for: 1),  1)
          XCTAssertEqual(PetGrowthService.levelInRealm(for: 27), 27)
          XCTAssertEqual(PetGrowthService.levelInRealm(for: 28), 1)
          XCTAssertEqual(PetGrowthService.levelInRealm(for: 29), 2)
      }

      func test_levelIncreasesOnHighCompletion() {
          let newLvl = PetGrowthService.newLevel(currentLevel: 5, completionRate: 0.9, consecutiveHighDays: 1)
          XCTAssertEqual(newLvl, 6)
      }

      func test_levelDecreasesOnLowCompletion() {
          let newLvl = PetGrowthService.newLevel(currentLevel: 5, completionRate: 0.3, consecutiveHighDays: 0)
          XCTAssertEqual(newLvl, 4)
      }

      func test_levelDoesNotDropBelowRealmStart() {
          // 境界 2 起始级别是 28，不能降到 27
          let newLvl = PetGrowthService.newLevel(currentLevel: 28, completionRate: 0.1, consecutiveHighDays: 0)
          XCTAssertEqual(newLvl, 28)
      }

      func test_levelCapAtRealmEndNormallyNoPromotion() {
          // 27 级，完成率高但连续天数不足，不升境界
          let newLvl = PetGrowthService.newLevel(currentLevel: 27, completionRate: 0.9, consecutiveHighDays: 3)
          XCTAssertEqual(newLvl, 27)
      }

      func test_realmPromotionAfter7HighDays() {
          let newLvl = PetGrowthService.newLevel(currentLevel: 27, completionRate: 0.9, consecutiveHighDays: 7)
          XCTAssertEqual(newLvl, 28)
      }

      func test_dragonForms() {
          XCTAssertEqual(PetGrowthService.dragonForm(for: 1),  .egg)
          XCTAssertEqual(PetGrowthService.dragonForm(for: 28), .hatchling)
          XCTAssertEqual(PetGrowthService.dragonForm(for: 55), .young)
          XCTAssertEqual(PetGrowthService.dragonForm(for: 82), .divine)
      }
  }
  ```

- [ ] **Step 3: 运行测试**

  `Cmd+U` → 8 tests passed

- [ ] **Step 4: 提交**

  ```bash
  git add FitPet/Services/PetGrowthService.swift FitPetTests/PetGrowthServiceTests.swift
  git commit -m "feat: PetGrowthService 境界/级别计算 + 单元测试"
  ```

---

## Task 7: WorkoutService

**Files:**
- Create: `FitPet/Services/WorkoutService.swift`

- [ ] **Step 1: 创建 WorkoutService.swift**

  ```swift
  import Foundation
  import SwiftData

  struct WorkoutService {
      /// 插入默认运动计划（首次启动时调用）
      static func seedDefaultPlans(context: ModelContext) {
          let defaults: [(String, Int, Int?, Int?)] = [
              ("pushup",      3, 15,  nil),
              ("squat",       3, 20,  nil),
              ("situp",       3, 20,  nil),
              ("zhan_zhuang", 1, nil, 300),
              ("kegel",       3, nil, 10),
          ]
          for (i, (exercise, sets, reps, dur)) in defaults.enumerated() {
              let plan = WorkoutPlan(exercise: exercise, sets: sets, reps: reps,
                                    durationSeconds: dur, sortOrder: i)
              context.insert(plan)
          }
          try? context.save()
      }

      /// 今日日期字符串
      static var today: String {
          let fmt = DateFormatter()
          fmt.dateFormat = "yyyy-MM-dd"
          return fmt.string(from: Date())
      }

      /// 计算今日完成率
      static func completionRate(sessions: [DailySession], plans: [WorkoutPlan], date: String) -> Double {
          let todaySessions = sessions.filter { $0.date == date }
          guard !plans.isEmpty else { return 0 }
          let total = plans.reduce(0) { $0 + $1.sets }
          let completed = todaySessions.reduce(0) { $0 + min($1.completedSets, $1.totalSets) }
          return Double(completed) / Double(total)
      }

      /// 计算连续高完成率天数（>= 80%）
      static func consecutiveHighDays(summaries: [DailySummary], before date: String) -> Int {
          let sorted = summaries
              .filter { $0.date < date }
              .sorted { $0.date > $1.date }
          var count = 0
          for summary in sorted {
              if summary.completionRate >= 0.8 { count += 1 } else { break }
          }
          return count
      }
  }
  ```

- [ ] **Step 2: 编译验证**

  `Cmd+B` → Build Succeeded

- [ ] **Step 3: 提交**

  ```bash
  git add FitPet/Services/WorkoutService.swift
  git commit -m "feat: WorkoutService 计划播种 + 完成率计算"
  ```

---

## Task 8: NotificationManager

**Files:**
- Create: `FitPet/Services/NotificationManager.swift`

- [ ] **Step 1: 创建 NotificationManager.swift**

  ```swift
  import UserNotifications
  import Foundation

  final class NotificationManager {
      static let shared = NotificationManager()
      private init() {}

      /// 请求通知权限，并在获准后安排每日提醒
      func requestPermissionAndSchedule(hour: Int = 20, minute: Int = 0) {
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
              guard granted else { return }
              self.scheduleDailyReminder(hour: hour, minute: minute)
          }
      }

      func scheduleDailyReminder(hour: Int, minute: Int) {
          UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["fitpet.daily"])

          let content = UNMutableNotificationContent()
          content.title = "FitPet"
          content.body  = "该去运动了，小龙在等你 🐉"
          content.sound = .default

          var dateComponents = DateComponents()
          dateComponents.hour   = hour
          dateComponents.minute = minute

          let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
          let request = UNNotificationRequest(identifier: "fitpet.daily", content: content, trigger: trigger)

          UNUserNotificationCenter.current().add(request)
      }
  }
  ```

- [ ] **Step 2: 编译验证**

  `Cmd+B` → Build Succeeded

- [ ] **Step 3: 提交**

  ```bash
  git add FitPet/Services/NotificationManager.swift
  git commit -m "feat: NotificationManager 每日运动提醒"
  ```

---

## Task 9: DragonView（小龙矢量图形）

**Files:**
- Create: `FitPet/Views/DragonView.swift`

- [ ] **Step 1: 创建 DragonView.swift**

  ```swift
  import SwiftUI

  struct DragonView: View {
      let form: PetGrowthService.DragonForm
      let mood: PetGrowthService.PetMood
      let isWorkingOut: Bool

      @State private var breathScale: CGFloat = 1.0
      @State private var jumpOffset: CGFloat  = 0

      var body: some View {
          ZStack {
              dragonShape
                  .scaleEffect(breathScale)
                  .offset(y: jumpOffset)
          }
          .frame(width: 160, height: 160)
          .onAppear { startAnimations() }
          .onChange(of: isWorkingOut) { _, working in
              if working { startJumpAnimation() } else { startBreathAnimation() }
          }
      }

      // MARK: - 形态渲染

      @ViewBuilder
      private var dragonShape: some View {
          switch form {
          case .egg:       EggShape(mood: mood)
          case .hatchling: HatchlingShape(mood: mood)
          case .young:     YoungDragonShape(mood: mood)
          case .divine:    DivineDragonShape(mood: mood)
          }
      }

      // MARK: - 动画

      private func startAnimations() {
          if isWorkingOut { startJumpAnimation() } else { startBreathAnimation() }
      }

      private func startBreathAnimation() {
          withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
              breathScale = 1.05
          }
          jumpOffset = 0
      }

      private func startJumpAnimation() {
          breathScale = 1.0
          withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
              jumpOffset = -12
          }
      }
  }

  // MARK: - 龙蛋

  struct EggShape: View {
      let mood: PetGrowthService.PetMood

      var body: some View {
          ZStack {
              Ellipse()
                  .fill(moodGradient)
                  .frame(width: 100, height: 120)
              // 裂纹
              Path { p in
                  p.move(to: CGPoint(x: 50, y: 20))
                  p.addLine(to: CGPoint(x: 45, y: 50))
                  p.addLine(to: CGPoint(x: 55, y: 70))
              }
              .stroke(Color.white.opacity(0.6), lineWidth: 2)
              .frame(width: 100, height: 120)
              // 眼睛
              HStack(spacing: 14) {
                  Circle().fill(Color.white).frame(width: 12, height: 12)
                  Circle().fill(Color.white).frame(width: 12, height: 12)
              }
              .offset(y: 10)
          }
      }

      private var moodGradient: LinearGradient {
          switch mood {
          case .happy:   return LinearGradient(colors: [.green, .teal],  startPoint: .top, endPoint: .bottom)
          case .neutral: return LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
          case .sad:     return LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom)
          }
      }
  }

  // MARK: - 幼龙

  struct HatchlingShape: View {
      let mood: PetGrowthService.PetMood

      var body: some View {
          ZStack {
              // 身体
              Ellipse()
                  .fill(bodyGradient)
                  .frame(width: 80, height: 90)
              // 头
              Circle()
                  .fill(bodyGradient)
                  .frame(width: 60, height: 60)
                  .offset(y: -55)
              // 眼睛
              HStack(spacing: 10) {
                  Circle().fill(Color.white).frame(width: 14, height: 14)
                      .overlay(Circle().fill(Color.black).frame(width: 7, height: 7))
                  Circle().fill(Color.white).frame(width: 14, height: 14)
                      .overlay(Circle().fill(Color.black).frame(width: 7, height: 7))
              }
              .offset(y: -58)
              // 小角
              HStack(spacing: 30) {
                  Triangle().fill(Color.orange).frame(width: 10, height: 14).rotationEffect(.degrees(-20))
                  Triangle().fill(Color.orange).frame(width: 10, height: 14).rotationEffect(.degrees(20))
              }
              .offset(y: -80)
          }
      }

      private var bodyGradient: LinearGradient {
          switch mood {
          case .happy:   return LinearGradient(colors: [Color(red:0.2,green:0.8,blue:0.4), Color(red:0.1,green:0.6,blue:0.3)], startPoint: .top, endPoint: .bottom)
          case .neutral: return LinearGradient(colors: [Color(red:0.3,green:0.5,blue:0.9), Color(red:0.2,green:0.3,blue:0.7)], startPoint: .top, endPoint: .bottom)
          case .sad:     return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom)
          }
      }
  }

  // MARK: - 成长龙

  struct YoungDragonShape: View {
      let mood: PetGrowthService.PetMood

      var body: some View {
          ZStack {
              // 翅膀（左）
              WingShape()
                  .fill(wingColor.opacity(0.7))
                  .frame(width: 60, height: 50)
                  .offset(x: -55, y: -10)
                  .rotationEffect(.degrees(-20), anchor: .trailing)
              // 翅膀（右）
              WingShape()
                  .fill(wingColor.opacity(0.7))
                  .frame(width: 60, height: 50)
                  .offset(x: 55, y: -10)
                  .scaleEffect(x: -1)
                  .rotationEffect(.degrees(20), anchor: .leading)
              // 身体
              Ellipse()
                  .fill(bodyGradient)
                  .frame(width: 70, height: 85)
              // 头
              Circle()
                  .fill(bodyGradient)
                  .frame(width: 55, height: 55)
                  .offset(y: -55)
              // 眼睛
              HStack(spacing: 10) {
                  dragonEye
                  dragonEye
              }
              .offset(y: -58)
          }
      }

      private var dragonEye: some View {
          Circle().fill(Color.white).frame(width: 14, height: 14)
              .overlay(Circle().fill(mood == .happy ? Color.green : Color.blue).frame(width: 8, height: 8))
      }

      private var bodyGradient: LinearGradient {
          LinearGradient(colors: [Color(red:0.1,green:0.7,blue:0.5), Color(red:0.0,green:0.5,blue:0.3)], startPoint: .top, endPoint: .bottom)
      }

      private var wingColor: Color { mood == .sad ? .gray : Color(red:0.2, green:0.8, blue:0.6) }
  }

  // MARK: - 神龙

  struct DivineDragonShape: View {
      let mood: PetGrowthService.PetMood
      @State private var glowRadius: CGFloat = 8

      var body: some View {
          ZStack {
              // 发光效果
              Circle()
                  .fill(Color.yellow.opacity(0.3))
                  .frame(width: 130, height: 130)
                  .blur(radius: glowRadius)
              // 翅膀
              WingShape()
                  .fill(Color.yellow.opacity(0.8))
                  .frame(width: 70, height: 55)
                  .offset(x: -60, y: -10)
                  .rotationEffect(.degrees(-25), anchor: .trailing)
              WingShape()
                  .fill(Color.yellow.opacity(0.8))
                  .frame(width: 70, height: 55)
                  .offset(x: 60, y: -10)
                  .scaleEffect(x: -1)
                  .rotationEffect(.degrees(25), anchor: .leading)
              // 身体
              Ellipse()
                  .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom))
                  .frame(width: 75, height: 90)
              // 头
              Circle()
                  .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom))
                  .frame(width: 58, height: 58)
                  .offset(y: -58)
              // 眼睛（金色）
              HStack(spacing: 10) {
                  Circle().fill(Color.white).frame(width: 14, height: 14)
                      .overlay(Circle().fill(Color(red:1,green:0.8,blue:0)).frame(width: 8, height: 8))
                  Circle().fill(Color.white).frame(width: 14, height: 14)
                      .overlay(Circle().fill(Color(red:1,green:0.8,blue:0)).frame(width: 8, height: 8))
              }
              .offset(y: -60)
          }
          .onAppear {
              withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                  glowRadius = 20
              }
          }
      }
  }

  // MARK: - 辅助形状

  struct Triangle: Shape {
      func path(in rect: CGRect) -> Path {
          Path { p in
              p.move(to: CGPoint(x: rect.midX, y: rect.minY))
              p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
              p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
              p.closeSubpath()
          }
      }
  }

  struct WingShape: Shape {
      func path(in rect: CGRect) -> Path {
          Path { p in
              p.move(to: CGPoint(x: rect.maxX, y: rect.midY))
              p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                             control: CGPoint(x: rect.midX, y: rect.minY - 10))
              p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                             control: CGPoint(x: rect.minX, y: rect.maxY))
          }
      }
  }
  ```

- [ ] **Step 2: 在 Xcode Canvas 预览验证**

  在 DragonView.swift 底部添加：
  ```swift
  #Preview {
      VStack(spacing: 20) {
          DragonView(form: .egg,       mood: .happy,   isWorkingOut: false)
          DragonView(form: .hatchling, mood: .neutral, isWorkingOut: false)
          DragonView(form: .young,     mood: .sad,     isWorkingOut: true)
          DragonView(form: .divine,    mood: .happy,   isWorkingOut: false)
      }
      .padding()
      .background(Color.black)
  }
  ```
  按 `Cmd+Option+Return` 打开 Canvas，确认四种形态正常显示。

- [ ] **Step 3: 提交**

  ```bash
  git add FitPet/Views/DragonView.swift
  git commit -m "feat: DragonView 四阶段小龙矢量图形 + 动画"
  ```

---

## Task 10: HomeView + PlanProgressView

**Files:**
- Create: `FitPet/Views/PlanProgressView.swift`
- Create: `FitPet/Views/HomeView.swift`

- [ ] **Step 1: 创建 PlanProgressView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct PlanProgressView: View {
      let plans: [WorkoutPlan]
      let sessions: [DailySession]
      let today: String

      var body: some View {
          VStack(alignment: .leading, spacing: 8) {
              ForEach(plans.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.exercise) { plan in
                  HStack {
                      Text(plan.displayName)
                          .font(.system(.body, design: .rounded))
                      Spacer()
                      Text(progressText(for: plan))
                          .font(.system(.caption, design: .monospaced))
                          .foregroundStyle(isCompleted(plan) ? .green : .secondary)
                      if isCompleted(plan) {
                          Image(systemName: "checkmark.circle.fill")
                              .foregroundStyle(.green)
                      }
                  }
                  .padding(.vertical, 4)
                  Divider()
              }
          }
      }

      private func completedSets(for plan: WorkoutPlan) -> Int {
          sessions.first(where: { $0.date == today && $0.exercise == plan.exercise })?.completedSets ?? 0
      }

      private func isCompleted(_ plan: WorkoutPlan) -> Bool {
          completedSets(for: plan) >= plan.sets
      }

      private func progressText(for plan: WorkoutPlan) -> String {
          "\(completedSets(for: plan))/\(plan.sets)组"
      }
  }
  ```

- [ ] **Step 2: 创建 HomeView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct HomeView: View {
      @Environment(\.modelContext) private var context
      @Query private var plans: [WorkoutPlan]
      @Query private var sessions: [DailySession]
      @Query private var petStates: [PetState]
      @Query private var summaries: [DailySummary]

      @State private var showWorkout = false

      private var today: String { WorkoutService.today }

      private var petState: PetState {
          if let state = petStates.first { return state }
          let state = PetState()
          context.insert(state)
          return state
      }

      private var completionRate: Double {
          WorkoutService.completionRate(sessions: sessions, plans: plans, date: today)
      }

      private var dragonForm: PetGrowthService.DragonForm {
          PetGrowthService.dragonForm(for: petState.currentLevel)
      }

      private var daysSinceActive: Int {
          guard !petState.lastActiveDate.isEmpty,
                let last = ISO8601DateFormatter().date(from: petState.lastActiveDate + "T00:00:00Z"),
                let todayDate = ISO8601DateFormatter().date(from: today + "T00:00:00Z")
          else { return 0 }
          return Calendar.current.dateComponents([.day], from: last, to: todayDate).day ?? 0
      }

      private var mood: PetGrowthService.PetMood {
          PetGrowthService.mood(completionRate: completionRate, daysSinceActive: daysSinceActive)
      }

      var body: some View {
          NavigationStack {
              ScrollView {
                  VStack(spacing: 24) {
                      // 小龙
                      DragonView(form: dragonForm, mood: mood, isWorkingOut: false)
                          .padding(.top, 20)

                      // 境界/级别
                      VStack(spacing: 4) {
                          Text("境界 \(PetGrowthService.realm(for: petState.currentLevel)) · 第 \(PetGrowthService.levelInRealm(for: petState.currentLevel)) 级")
                              .font(.headline)
                          Text("连续打卡 \(petState.streakDays) 天")
                              .font(.subheadline)
                              .foregroundStyle(.secondary)
                      }

                      // 今日完成率
                      VStack(spacing: 8) {
                          HStack {
                              Text("今日完成")
                              Spacer()
                              Text("\(Int(completionRate * 100))%")
                                  .bold()
                          }
                          ProgressView(value: completionRate)
                              .tint(completionRate >= 0.8 ? .green : .blue)
                      }
                      .padding(.horizontal)

                      // 计划进度
                      VStack(alignment: .leading, spacing: 8) {
                          Text("今日计划")
                              .font(.headline)
                              .padding(.horizontal)
                          PlanProgressView(plans: plans, sessions: sessions, today: today)
                              .padding(.horizontal)
                      }

                      // 开始运动
                      Button(action: { showWorkout = true }) {
                          Label("开始运动", systemImage: "figure.run")
                              .font(.title3.bold())
                              .frame(maxWidth: .infinity)
                              .padding()
                              .background(Color.blue)
                              .foregroundStyle(.white)
                              .cornerRadius(16)
                      }
                      .padding(.horizontal)
                      .padding(.bottom, 20)
                  }
              }
              .navigationTitle("FitPet")
          }
          .fullScreenCover(isPresented: $showWorkout) {
              WorkoutView()
          }
          .onAppear {
              if plans.isEmpty { WorkoutService.seedDefaultPlans(context: context) }
              NotificationManager.shared.requestPermissionAndSchedule()
          }
      }
  }
  ```

- [ ] **Step 3: 编译验证**

  `Cmd+B` → Build Succeeded

- [ ] **Step 4: 提交**

  ```bash
  git add FitPet/Views/HomeView.swift FitPet/Views/PlanProgressView.swift
  git commit -m "feat: HomeView + PlanProgressView 首页 UI"
  ```

---

## Task 11: WorkoutView（运动页，摄像头 + 自动检测）

**Files:**
- Create: `FitPet/Views/WorkoutView.swift`

- [ ] **Step 1: 创建 WorkoutView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct WorkoutView: View {
      @Environment(\.dismiss) private var dismiss
      @Environment(\.modelContext) private var context
      @Query private var plans: [WorkoutPlan]
      @Query private var sessions: [DailySession]

      @StateObject private var poseDetector = PoseDetector()
      @State private var classifier     = ExerciseClassifier()
      @State private var pushupCounter  = PushupCounter()
      @State private var squatCounter   = SquatCounter()
      @State private var situpCounter   = SitupCounter()
      @State private var zhanTimer      = ZhanZhuangTimer()
      @State private var kegelSecondsLeft: Int? = nil
      @State private var kegelTimer: Timer?

      private var today: String { WorkoutService.today }

      // MARK: - 当前运动状态

      private var currentExercise: ExerciseType { classifier.currentExercise }

      private var counterText: String {
          switch currentExercise {
          case .pushup:     return "俯卧撑 × \(pushupCounter.count)"
          case .squat:      return "深蹲 × \(squatCounter.count)"
          case .situp:      return "仰卧起坐 × \(situpCounter.count)"
          case .zhanZhuang:
              let s = Int(zhanTimer.elapsedSeconds)
              return "站桩 \(s/60):\(String(format:"%02d", s%60))"
          case .kegel:      return "凯格尔"
          case .unknown:    return "等待检测..."
          }
      }

      var body: some View {
          ZStack {
              // 摄像头预览
              CameraPreviewView(session: poseDetector.captureSession)
                  .ignoresSafeArea()

              // 骨架叠加层
              SkeletonOverlayView(landmarks: poseDetector.landmarks)
                  .ignoresSafeArea()

              VStack {
                  // 顶部：关闭 + 检测状态
                  HStack {
                      Button(action: { dismiss() }) {
                          Image(systemName: "xmark.circle.fill")
                              .font(.title)
                              .foregroundStyle(.white)
                              .shadow(radius: 4)
                      }
                      Spacer()
                      Text(currentExercise == .unknown ? "移动到摄像头前" : "检测中")
                          .font(.caption)
                          .padding(6)
                          .background(.ultraThinMaterial)
                          .cornerRadius(8)
                  }
                  .padding()

                  Spacer()

                  // 凯格尔手动面板
                  if currentExercise == .kegel {
                      kegelPanel
                          .padding()
                  }

                  // 计数器 + 完成本组按钮
                  VStack(spacing: 12) {
                      Text(counterText)
                          .font(.system(size: 36, weight: .bold, design: .rounded))
                          .foregroundStyle(.white)
                          .shadow(radius: 4)

                      Button("完成本组") { completeSet() }
                          .padding(.horizontal, 32)
                          .padding(.vertical, 12)
                          .background(Color.green)
                          .foregroundStyle(.white)
                          .cornerRadius(12)
                          .font(.headline)
                  }
                  .padding()
                  .background(.ultraThinMaterial)
                  .cornerRadius(20)
                  .padding(.horizontal)
                  .padding(.bottom, 40)
              }
          }
          .onAppear  { poseDetector.startSession() }
          .onDisappear { poseDetector.stopSession() }
          .onChange(of: poseDetector.landmarks) { _, lm in
              guard !lm.isEmpty else { return }
              classifier.update(landmarks: lm)
              updateCounters(landmarks: lm)
          }
          .onChange(of: currentExercise) { old, new in
              if old != new { resetCurrentCounter(for: old) }
          }
      }

      // MARK: - 凯格尔面板

      private var kegelPanel: some View {
          VStack(spacing: 12) {
              Text(kegelSecondsLeft.map { "\($0)" } ?? "10")
                  .font(.system(size: 72, weight: .bold, design: .rounded))
                  .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
              Button("开始一组") { startKegel() }
                  .padding(.horizontal, 24)
                  .padding(.vertical, 10)
                  .background(Color(red: 0.9, green: 0.3, blue: 0.3))
                  .foregroundStyle(.white)
                  .cornerRadius(12)
                  .disabled(kegelSecondsLeft != nil)
          }
          .padding()
          .background(.ultraThinMaterial)
          .cornerRadius(16)
      }

      // MARK: - 逻辑

      private func updateCounters(landmarks: PoseLandmarks) {
          switch currentExercise {
          case .pushup:     pushupCounter.update(landmarks: landmarks)
          case .squat:      squatCounter.update(landmarks: landmarks)
          case .situp:      situpCounter.update(landmarks: landmarks)
          case .zhanZhuang: zhanTimer.update(landmarks: landmarks)
          default: break
          }
      }

      private func resetCurrentCounter(for exercise: ExerciseType) {
          switch exercise {
          case .pushup:     pushupCounter.reset()
          case .squat:      squatCounter.reset()
          case .situp:      situpCounter.reset()
          case .zhanZhuang: zhanTimer.reset()
          default: break
          }
      }

      private func completeSet() {
          let exercise = currentExercise.rawValue
          guard exercise != "unknown", exercise != "kegel" else { return }

          let today = WorkoutService.today
          if let existing = sessions.first(where: { $0.date == today && $0.exercise == exercise }) {
              existing.completedSets += 1
          } else {
              let plan = plans.first(where: { $0.exercise == exercise })
              let session = DailySession(date: today, exercise: exercise,
                                        completedSets: 1, totalSets: plan?.sets ?? 1)
              context.insert(session)
          }
          try? context.save()
          resetCurrentCounter(for: currentExercise)
      }

      private func startKegel() {
          kegelSecondsLeft = 10
          kegelTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
              guard let s = kegelSecondsLeft else { return }
              if s <= 1 {
                  kegelTimer?.invalidate()
                  kegelTimer = nil
                  kegelSecondsLeft = nil
                  // 记录完成
                  let today = WorkoutService.today
                  if let existing = sessions.first(where: { $0.date == today && $0.exercise == "kegel" }) {
                      existing.completedSets += 1
                  } else {
                      let plan = plans.first(where: { $0.exercise == "kegel" })
                      let session = DailySession(date: today, exercise: "kegel",
                                                completedSets: 1, totalSets: plan?.sets ?? 3)
                      context.insert(session)
                  }
                  try? context.save()
              } else {
                  kegelSecondsLeft = s - 1
              }
          }
      }
  }

  // MARK: - 骨架叠加

  struct SkeletonOverlayView: View {
      let landmarks: PoseLandmarks

      var body: some View {
          GeometryReader { geo in
              ForEach(Array(landmarks.keys), id: \.self) { key in
                  if let lm = landmarks[key], lm.confidence > 0.5 {
                      Circle()
                          .fill(Color.green)
                          .frame(width: 8, height: 8)
                          .position(x: lm.point.x * geo.size.width,
                                    y: lm.point.y * geo.size.height)
                  }
              }
          }
      }
  }
  ```

- [ ] **Step 2: 编译验证**

  `Cmd+B` → Build Succeeded

- [ ] **Step 3: 提交**

  ```bash
  git add FitPet/Views/WorkoutView.swift
  git commit -m "feat: WorkoutView 摄像头+自动检测+计数+凯格尔面板"
  ```

---

## Task 12: ContentView + 首次启动宠物状态初始化

**Files:**
- Modify: `FitPet/ContentView.swift`

- [ ] **Step 1: 修改 ContentView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct ContentView: View {
      var body: some View {
          HomeView()
      }
  }
  ```

- [ ] **Step 2: 在模拟器运行**

  选择模拟器（iPhone 15 或 16），`Cmd+R`
  
  预期：
  - 首页显示龙蛋 + "今日计划"列表
  - 点击"开始运动"进入运动页
  - 运动页显示摄像头（模拟器上为黑屏，正常）
  - 计数器显示"等待检测..."

- [ ] **Step 3: 在真机运行（有 Developer 账号后）**

  Xcode → Signing & Capabilities → Team 选择自己账号
  连接 iPhone → `Cmd+R`
  
  预期：
  - 首次启动弹出摄像头权限和通知权限请求
  - 站到摄像头前，绿点骨架点正确叠加
  - 做俯卧撑时自动识别并计数

- [ ] **Step 4: 完整运行测试**

  `Cmd+U` → 所有单元测试通过

- [ ] **Step 5: 最终提交**

  ```bash
  git add FitPet/ContentView.swift
  git commit -m "feat: ContentView 完成 FitPet iOS MVP"
  ```
