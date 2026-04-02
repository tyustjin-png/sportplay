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
            let ls = lm["leftShoulder"],  ls.confidence >= minVisibility,
            let lh = lm["leftHip"],       lh.confidence >= minVisibility,
            let la = lm["leftAnkle"],     la.confidence >= minVisibility
        else { return .unknown }

        let shoulderToHip = Double(lh.point.y - ls.point.y)
        let hipToAnkle    = Double(la.point.y - lh.point.y)

        if shoulderToHip > 0.1 && hipToAnkle > 0.1 { return .upright }

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
            let lh = lm["leftHip"],   lh.confidence >= minVisibility,
            let lk = lm["leftKnee"],  lk.confidence >= minVisibility,
            let la = lm["leftAnkle"], la.confidence >= minVisibility
        else { return false }
        let angle = calcAngle(lh.point, lk.point, la.point)
        return angle < 150
    }

    private func hasMinimumLandmarks(_ lm: [String: (point: CGPoint, confidence: Float)]) -> Bool {
        let required = ["leftShoulder", "leftHip", "leftAnkle"]
        return required.allSatisfy { key in
            (lm[key]?.confidence ?? 0) >= minVisibility
        }
    }
}
