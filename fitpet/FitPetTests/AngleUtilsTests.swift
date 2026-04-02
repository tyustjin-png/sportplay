import XCTest
@testable import FitPet

final class AngleUtilsTests: XCTestCase {
    func test_straightLine_returns180() {
        let a = CGPoint(x: 0, y: 0)
        let b = CGPoint(x: 1, y: 0)
        let c = CGPoint(x: 2, y: 0)
        XCTAssertEqual(calcAngle(a, b, c), 180, accuracy: 0.01)
    }

    func test_rightAngle_returns90() {
        let a = CGPoint(x: 0, y: 0)
        let b = CGPoint(x: 1, y: 0)
        let c = CGPoint(x: 1, y: 1)
        XCTAssertEqual(calcAngle(a, b, c), 90, accuracy: 0.01)
    }

    func test_symmetricAcuteAngle() {
        let a = CGPoint(x: 0, y: 0)
        let b = CGPoint(x: 1, y: 0)
        let c = CGPoint(x: 0.5, y: sqrt(3)/2)
        XCTAssertEqual(calcAngle(a, b, c), 60, accuracy: 0.1)
    }
}
