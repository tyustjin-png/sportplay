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
