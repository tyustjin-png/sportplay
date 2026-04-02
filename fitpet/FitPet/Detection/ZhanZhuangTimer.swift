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

    private func isPoseValid(_ landmarks: [String: (point: CGPoint, confidence: Float)]) -> Bool {
        let required = ["leftShoulder", "rightShoulder", "leftHip", "rightHip"]
        for key in required {
            guard let lm = landmarks[key], lm.confidence >= minVisibility else { return false }
        }
        guard let ls = landmarks["leftShoulder"], let lh = landmarks["leftHip"] else { return false }
        return ls.point.y < lh.point.y
    }
}
