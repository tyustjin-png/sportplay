import CoreGraphics

struct SitupCounter {
    private(set) var count = 0
    private var phase: Phase = .down

    private enum Phase { case down, up }

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

        let shoulderMid = CGPoint(x: (ls.point.x + rs.point.x) / 2,
                                  y: (ls.point.y + rs.point.y) / 2)
        let hipMid      = CGPoint(x: (lh.point.x + rh.point.x) / 2,
                                  y: (lh.point.y + rh.point.y) / 2)
        let dx = Double(shoulderMid.x - hipMid.x)
        let dy = Double(shoulderMid.y - hipMid.y)
        let angle = abs(atan2(dy, dx) * 180 / .pi)
        let torsoAngle = angle > 90 ? 180 - angle : angle

        switch phase {
        case .down where torsoAngle > upThreshold:   phase = .up
        case .up   where torsoAngle < downThreshold: phase = .down; count += 1
        default: break
        }
    }

    mutating func reset() { count = 0; phase = .down }
}
