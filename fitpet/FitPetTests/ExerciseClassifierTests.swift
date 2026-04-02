import XCTest
@testable import FitPet

final class ExerciseClassifierTests: XCTestCase {
    private func pt(_ x: Double, _ y: Double, _ conf: Float = 0.9) -> (point: CGPoint, confidence: Float) {
        (CGPoint(x: x, y: y), conf)
    }

    private var uprightLandmarks: [String: (point: CGPoint, confidence: Float)] {
        ["leftShoulder": pt(0.5, 0.8), "leftHip": pt(0.5, 0.5), "leftAnkle": pt(0.5, 0.1),
         "leftKnee": pt(0.5, 0.3), "rightShoulder": pt(0.6, 0.8), "rightHip": pt(0.6, 0.5),
         "rightKnee": pt(0.6, 0.3), "rightAnkle": pt(0.6, 0.1), "nose": pt(0.5, 0.9)]
    }

    private var proneLandmarks: [String: (point: CGPoint, confidence: Float)] {
        ["leftShoulder": pt(0.2, 0.5), "leftHip": pt(0.5, 0.5), "leftAnkle": pt(0.8, 0.5),
         "leftKnee": pt(0.65, 0.5), "nose": pt(0.05, 0.45)]
    }

    func test_confirmationRequired() {
        var classifier = ExerciseClassifier()
        classifier.confirmationFrames = 3
        classifier.update(landmarks: uprightLandmarks)
        classifier.update(landmarks: uprightLandmarks)
        XCTAssertEqual(classifier.currentExercise, .unknown)
        classifier.update(landmarks: uprightLandmarks)
        XCTAssertEqual(classifier.currentExercise, .zhanZhuang)
    }

    func test_proneDetectedAsPushup() {
        var classifier = ExerciseClassifier()
        classifier.confirmationFrames = 1
        classifier.update(landmarks: proneLandmarks)
        XCTAssertEqual(classifier.currentExercise, .pushup)
    }

    func test_squatDetectedWhenKneeFlexed() {
        var classifier = ExerciseClassifier()
        classifier.confirmationFrames = 1
        var lm = uprightLandmarks
        lm["leftKnee"]  = pt(0.5, 0.2)
        lm["leftHip"]   = pt(0.5, 0.4)
        lm["leftAnkle"] = pt(0.5, 0.1)
        classifier.update(landmarks: lm)
        XCTAssertEqual(classifier.currentExercise, .squat)
    }

    func test_resetClearsState() {
        var classifier = ExerciseClassifier()
        classifier.confirmationFrames = 1
        classifier.update(landmarks: proneLandmarks)
        classifier.reset()
        XCTAssertEqual(classifier.currentExercise, .unknown)
    }
}
