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
        } else {
            candidateExercise = detected
            candidateCount = 1
        }
        if candidateCount >= confirmationFrames {
            currentExercise = candidateExercise
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
            let ls = lm["leftShoulder"], ls.confidence >= minVisibility,
            let lh = lm["leftHip"],      lh.confidence >= minVisibility
        else { return .unknown }

        let shoulderToHip = Double(lh.point.y - ls.point.y)

        // 肩膀明显高于髋部 → 直立
        if shoulderToHip > 0.1 {
            // 用膝盖辅助确认（踝关节可能不在画面内）
            if let lk = lm["leftKnee"], lk.confidence >= minVisibility {
                let hipToKnee = Double(lk.point.y - lh.point.y)
                if hipToKnee > 0.05 { return .upright }
            }
            return .upright
        }

        // 肩髋近乎水平 → 俯卧或仰卧
        if abs(shoulderToHip) < 0.1 {
            if let nose = lm["nose"], nose.confidence >= minVisibility {
                return nose.point.y > ls.point.y ? .supine : .prone
            }
            return .prone
        }

        return .unknown
    }

    private func isKneeFlexing(_ lm: [String: (point: CGPoint, confidence: Float)]) -> Bool {
        guard
            let lh = lm["leftHip"],  lh.confidence >= minVisibility,
            let lk = lm["leftKnee"], lk.confidence >= minVisibility
        else { return false }

        // 有踝关节时用角度判断，否则用髋-膝垂直距离比例判断
        if let la = lm["leftAnkle"], la.confidence >= minVisibility {
            let angle = calcAngle(lh.point, lk.point, la.point)
            return angle < 150
        }
        // 深蹲时膝盖明显低于髋部，且髋-膝距离缩短（弯曲时投影变小）
        let hipKneeY = Double(lk.point.y - lh.point.y)
        return hipKneeY < 0.15
    }

    private func hasMinimumLandmarks(_ lm: [String: (point: CGPoint, confidence: Float)]) -> Bool {
        let required = ["leftShoulder", "leftHip"]
        return required.allSatisfy { key in
            (lm[key]?.confidence ?? 0) >= minVisibility
        }
    }
}
