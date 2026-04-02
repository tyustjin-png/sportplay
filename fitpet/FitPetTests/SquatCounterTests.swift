import XCTest
@testable import FitPet

final class SquatCounterTests: XCTestCase {
    private func landmarks(kneeAngle: Double) -> [String: (point: CGPoint, confidence: Float)] {
        let rad = kneeAngle * .pi / 180
        let ankleX = 1 - cos(rad)
        let ankleY = sin(rad)
        let pt: (CGPoint, Float) -> (point: CGPoint, confidence: Float) = { ($0, $1) }
        return [
            "leftHip":    pt(CGPoint(x: 0, y: 0), 0.9),
            "leftKnee":   pt(CGPoint(x: 1, y: 0), 0.9),
            "leftAnkle":  pt(CGPoint(x: ankleX, y: ankleY), 0.9),
            "rightHip":   pt(CGPoint(x: 0, y: 0), 0.9),
            "rightKnee":  pt(CGPoint(x: 1, y: 0), 0.9),
            "rightAnkle": pt(CGPoint(x: ankleX, y: ankleY), 0.9),
        ]
    }

    func test_oneRepCounted() {
        var counter = SquatCounter()
        counter.update(landmarks: landmarks(kneeAngle: 170))
        counter.update(landmarks: landmarks(kneeAngle: 80))
        counter.update(landmarks: landmarks(kneeAngle: 170))
        XCTAssertEqual(counter.count, 1)
    }

    func test_noCountWithoutFullRange() {
        var counter = SquatCounter()
        counter.update(landmarks: landmarks(kneeAngle: 130))
        counter.update(landmarks: landmarks(kneeAngle: 120))
        XCTAssertEqual(counter.count, 0)
    }

    func test_resetClearsCount() {
        var counter = SquatCounter()
        counter.update(landmarks: landmarks(kneeAngle: 170))
        counter.update(landmarks: landmarks(kneeAngle: 80))
        counter.update(landmarks: landmarks(kneeAngle: 170))
        counter.reset()
        XCTAssertEqual(counter.count, 0)
    }
}
