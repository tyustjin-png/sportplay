import XCTest
@testable import FitPet

final class SitupCounterTests: XCTestCase {
    private func landmarks(torsoAngle: Double) -> [String: (point: CGPoint, confidence: Float)] {
        let rad = torsoAngle * .pi / 180
        let shoulderX = cos(rad)
        let shoulderY = -sin(rad)
        let pt: (CGPoint, Float) -> (point: CGPoint, confidence: Float) = { ($0, $1) }
        return [
            "leftShoulder":  pt(CGPoint(x: shoulderX, y: shoulderY), 0.9),
            "rightShoulder": pt(CGPoint(x: shoulderX, y: shoulderY), 0.9),
            "leftHip":       pt(CGPoint(x: 0, y: 0), 0.9),
            "rightHip":      pt(CGPoint(x: 0, y: 0), 0.9),
        ]
    }

    func test_oneRepCounted() {
        var counter = SitupCounter()
        counter.update(landmarks: landmarks(torsoAngle: 5))
        counter.update(landmarks: landmarks(torsoAngle: 40))
        counter.update(landmarks: landmarks(torsoAngle: 5))
        XCTAssertEqual(counter.count, 1)
    }

    func test_noCountWithoutFullRange() {
        var counter = SitupCounter()
        counter.update(landmarks: landmarks(torsoAngle: 15))
        counter.update(landmarks: landmarks(torsoAngle: 20))
        XCTAssertEqual(counter.count, 0)
    }

    func test_resetClearsCount() {
        var counter = SitupCounter()
        counter.update(landmarks: landmarks(torsoAngle: 5))
        counter.update(landmarks: landmarks(torsoAngle: 40))
        counter.update(landmarks: landmarks(torsoAngle: 5))
        counter.reset()
        XCTAssertEqual(counter.count, 0)
    }
}
