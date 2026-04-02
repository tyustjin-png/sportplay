import XCTest
@testable import FitPet

final class PushupCounterTests: XCTestCase {
    private func landmarks(elbowAngle: Double) -> [String: (point: CGPoint, confidence: Float)] {
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
        counter.update(landmarks: landmarks(elbowAngle: 170))
        counter.update(landmarks: landmarks(elbowAngle: 80))
        counter.update(landmarks: landmarks(elbowAngle: 170))
        XCTAssertEqual(counter.count, 1)
    }

    func test_noCountWithoutFullRange() {
        var counter = PushupCounter()
        counter.update(landmarks: landmarks(elbowAngle: 130))
        counter.update(landmarks: landmarks(elbowAngle: 120))
        XCTAssertEqual(counter.count, 0)
    }

    func test_lowConfidenceIgnored() {
        var counter = PushupCounter()
        var lm = landmarks(elbowAngle: 80)
        lm["leftElbow"] = (lm["leftElbow"]!.point, 0.3)
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
