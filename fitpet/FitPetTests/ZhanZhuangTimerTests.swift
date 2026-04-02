import XCTest
@testable import FitPet

final class ZhanZhuangTimerTests: XCTestCase {
    private func validLandmarks() -> [String: (point: CGPoint, confidence: Float)] {
        let pt: (CGPoint, Float) -> (point: CGPoint, confidence: Float) = { ($0, $1) }
        return [
            "leftShoulder":  pt(CGPoint(x: 0, y: 0), 0.9),
            "rightShoulder": pt(CGPoint(x: 1, y: 0), 0.9),
            "leftHip":       pt(CGPoint(x: 0, y: 2), 0.9),
            "rightHip":      pt(CGPoint(x: 1, y: 2), 0.9),
        ]
    }

    func test_accumulatesTimeWhilePoseValid() {
        var timer = ZhanZhuangTimer()
        let now = Date()

        timer.update(landmarks: validLandmarks(), now: now)
        timer.update(landmarks: validLandmarks(), now: now.addingTimeInterval(1))
        timer.update(landmarks: validLandmarks(), now: now.addingTimeInterval(2))

        XCTAssertGreater(timer.elapsedSeconds, 1.5)
    }

    func test_stopsWhenPoseInvalid() {
        var timer = ZhanZhuangTimer()
        let now = Date()

        timer.update(landmarks: validLandmarks(), now: now)
        timer.update(landmarks: validLandmarks(), now: now.addingTimeInterval(1))
        let firstElapsed = timer.elapsedSeconds

        timer.update(landmarks: [:], now: now.addingTimeInterval(2))
        timer.update(landmarks: [:], now: now.addingTimeInterval(3))

        XCTAssertEqual(timer.elapsedSeconds, firstElapsed)
    }

    func test_resetClearsTime() {
        var timer = ZhanZhuangTimer()
        let now = Date()

        timer.update(landmarks: validLandmarks(), now: now)
        timer.update(landmarks: validLandmarks(), now: now.addingTimeInterval(1))
        timer.reset()

        XCTAssertEqual(timer.elapsedSeconds, 0)
    }

    func test_lowConfidenceInvalidatesPose() {
        var timer = ZhanZhuangTimer()
        let now = Date()

        var lm = validLandmarks()
        lm["leftShoulder"] = (lm["leftShoulder"]!.point, 0.3)

        timer.update(landmarks: lm, now: now)
        timer.update(landmarks: lm, now: now.addingTimeInterval(1))

        XCTAssertEqual(timer.elapsedSeconds, 0)
    }
}
