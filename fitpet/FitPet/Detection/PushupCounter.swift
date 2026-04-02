import CoreGraphics

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
