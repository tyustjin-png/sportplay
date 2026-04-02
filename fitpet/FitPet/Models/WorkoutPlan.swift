import SwiftData

@Model
final class WorkoutPlan {
    var exercise: String       // "pushup" | "squat" | "situp" | "zhan_zhuang" | "kegel"
    var sets: Int
    var reps: Int?
    var durationSeconds: Int?
    var sortOrder: Int

    init(exercise: String, sets: Int, reps: Int? = nil, durationSeconds: Int? = nil, sortOrder: Int = 0) {
        self.exercise = exercise
        self.sets = sets
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.sortOrder = sortOrder
    }

    static let exerciseNames: [String: String] = [
        "pushup": "俯卧撑",
        "squat": "深蹲",
        "situp": "仰卧起坐",
        "zhan_zhuang": "站桩",
        "kegel": "凯格尔",
    ]

    var displayName: String { WorkoutPlan.exerciseNames[exercise] ?? exercise }

    var targetDescription: String {
        if let reps { return "\(sets)组 × \(reps)个" }
        if let dur = durationSeconds { return "\(sets)组 × \(dur)秒" }
        return "\(sets)组"
    }
}
