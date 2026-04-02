import SwiftUI
import SwiftData
import Combine

struct WorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var plans: [WorkoutPlan]
    @Query private var sessions: [DailySession]

    @StateObject private var poseDetector = PoseDetector()
    @State private var classifier     = ExerciseClassifier()
    @State private var pushupCounter  = PushupCounter()
    @State private var squatCounter   = SquatCounter()
    @State private var situpCounter   = SitupCounter()
    @State private var zhanTimer      = ZhanZhuangTimer()
    @State private var kegelSecondsLeft: Int? = nil
    @State private var kegelTimer: Timer?

    private var today: String { WorkoutService.today }

    private var currentExercise: ExerciseType { classifier.currentExercise }

    private var counterText: String {
        switch currentExercise {
        case .pushup:     return "俯卧撑 × \(pushupCounter.count)"
        case .squat:      return "深蹲 × \(squatCounter.count)"
        case .situp:      return "仰卧起坐 × \(situpCounter.count)"
        case .zhanZhuang:
            let s = Int(zhanTimer.elapsedSeconds)
            return "站桩 \(s/60):\(String(format:"%02d", s%60))"
        case .kegel:      return "凯格尔"
        case .unknown:    return "等待检测..."
        }
    }

    var body: some View {
        ZStack {
            CameraPreviewView(session: poseDetector.captureSession)
                .ignoresSafeArea()

            SkeletonOverlayView(landmarks: poseDetector.landmarks)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    Spacer()
                    Text(currentExercise == .unknown ? "移动到摄像头前" : "检测中")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                .padding()

                Spacer()

                if currentExercise == .kegel {
                    kegelPanel
                        .padding()
                }

                VStack(spacing: 12) {
                    Text(counterText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)

                    Button("完成本组") { completeSet() }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .font(.headline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .onAppear  { poseDetector.startSession() }
        .onDisappear {
            poseDetector.stopSession()
            kegelTimer?.invalidate()
            kegelTimer = nil
        }
        .onReceive(poseDetector.$landmarks) { lm in
            guard !lm.isEmpty else { return }
            classifier.update(landmarks: lm)
            updateCounters(landmarks: lm)
        }
        .onChange(of: currentExercise) { old, new in
            if old != new { resetCurrentCounter(for: old) }
        }
    }

    private var kegelPanel: some View {
        VStack(spacing: 12) {
            Text(kegelSecondsLeft.map { "\($0)" } ?? "10")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
            Button("开始一组") { startKegel() }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color(red: 0.9, green: 0.3, blue: 0.3))
                .foregroundStyle(.white)
                .cornerRadius(12)
                .disabled(kegelSecondsLeft != nil)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func updateCounters(landmarks: PoseLandmarks) {
        switch currentExercise {
        case .pushup:     pushupCounter.update(landmarks: landmarks)
        case .squat:      squatCounter.update(landmarks: landmarks)
        case .situp:      situpCounter.update(landmarks: landmarks)
        case .zhanZhuang: zhanTimer.update(landmarks: landmarks)
        default: break
        }
    }

    private func resetCurrentCounter(for exercise: ExerciseType) {
        switch exercise {
        case .pushup:     pushupCounter.reset()
        case .squat:      squatCounter.reset()
        case .situp:      situpCounter.reset()
        case .zhanZhuang: zhanTimer.reset()
        default: break
        }
    }

    private func completeSet() {
        // 站桩需要至少完成目标时长的 80% 才能算完成
        if currentExercise == .zhanZhuang {
            let plan = plans.first(where: { $0.exercise == "zhan_zhuang" })
            let targetSeconds = Double(plan?.durationSeconds ?? 300)
            guard zhanTimer.elapsedSeconds >= targetSeconds * 0.8 else { return }
        }

        let exercise = currentExercise.rawValue
        guard exercise != "unknown", exercise != "kegel" else { return }

        let today = WorkoutService.today
        if let existing = sessions.first(where: { $0.date == today && $0.exercise == exercise }) {
            existing.completedSets += 1
        } else {
            let plan = plans.first(where: { $0.exercise == exercise })
            let session = DailySession(date: today, exercise: exercise,
                                      completedSets: 1, totalSets: plan?.sets ?? 1)
            context.insert(session)
        }
        try? context.save()
        resetCurrentCounter(for: currentExercise)
    }

    private func startKegel() {
        kegelSecondsLeft = 10
        kegelTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let s = kegelSecondsLeft else { return }
            if s <= 1 {
                kegelTimer?.invalidate()
                kegelTimer = nil
                kegelSecondsLeft = nil
                let today = WorkoutService.today
                if let existing = sessions.first(where: { $0.date == today && $0.exercise == "kegel" }) {
                    existing.completedSets += 1
                } else {
                    let plan = plans.first(where: { $0.exercise == "kegel" })
                    let session = DailySession(date: today, exercise: "kegel",
                                              completedSets: 1, totalSets: plan?.sets ?? 3)
                    context.insert(session)
                }
                try? context.save()
            } else {
                kegelSecondsLeft = s - 1
            }
        }
    }
}

struct SkeletonOverlayView: View {
    let landmarks: PoseLandmarks

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(landmarks.keys), id: \.self) { key in
                if let lm = landmarks[key], lm.confidence > 0.5 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .position(x: lm.point.x * geo.size.width,
                                  y: lm.point.y * geo.size.height)
                }
            }
        }
    }
}
