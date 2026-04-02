import AVFoundation
import Vision
import CoreGraphics
import Combine

typealias PoseLandmarks = [String: (point: CGPoint, confidence: Float)]

final class PoseDetector: NSObject, ObservableObject {
    @Published var landmarks: PoseLandmarks = [:]

    let captureSession = AVCaptureSession()
    private let videoOutput    = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.fitpet.posedetect", qos: .userInitiated)

    private static let jointMap: [VNHumanBodyPoseObservation.JointName: String] = [
        .leftShoulder:  "leftShoulder",
        .rightShoulder: "rightShoulder",
        .leftElbow:     "leftElbow",
        .rightElbow:    "rightElbow",
        .leftWrist:     "leftWrist",
        .rightWrist:    "rightWrist",
        .leftHip:       "leftHip",
        .rightHip:      "rightHip",
        .leftKnee:      "leftKnee",
        .rightKnee:     "rightKnee",
        .leftAnkle:     "leftAnkle",
        .rightAnkle:    "rightAnkle",
        .nose:          "nose",
    ]

    func startSession() {
        queue.async { [weak self] in self?.configureAndStart() }
    }

    func stopSession() {
        captureSession.stopRunning()
    }

    private func configureAndStart() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input  = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else { captureSession.commitConfiguration(); return }

        captureSession.addInput(input)
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        guard captureSession.canAddOutput(videoOutput) else { captureSession.commitConfiguration(); return }
        captureSession.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            if connection.isVideoMirroringSupported { connection.isVideoMirrored = true }
        }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
}

extension PoseDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .up,
                                            options: [:])
        try? handler.perform([request])

        guard let observation = request.results?.first else {
            DispatchQueue.main.async { self.landmarks = [:] }
            return
        }

        var result: PoseLandmarks = [:]
        for (jointName, key) in Self.jointMap {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > 0 {
                result[key] = (CGPoint(x: point.x, y: 1 - point.y), point.confidence)
            }
        }

        DispatchQueue.main.async { self.landmarks = result }
    }
}
