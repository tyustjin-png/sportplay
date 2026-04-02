import Foundation
import SwiftData

struct WorkoutService {
    static func seedDefaultPlans(context: ModelContext) {
        let defaults: [(String, Int, Int?, Int?)] = [
            ("pushup",      3, 15,  nil),
            ("squat",       3, 20,  nil),
            ("situp",       3, 20,  nil),
            ("zhan_zhuang", 1, nil, 300),
            ("kegel",       3, nil, 10),
        ]
        for (i, (exercise, sets, reps, dur)) in defaults.enumerated() {
            let plan = WorkoutPlan(exercise: exercise, sets: sets, reps: reps,
                                  durationSeconds: dur, sortOrder: i)
            context.insert(plan)
        }
        try? context.save()
    }

    static var today: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    static func completionRate(sessions: [DailySession], plans: [WorkoutPlan], date: String) -> Double {
        let todaySessions = sessions.filter { $0.date == date }
        guard !plans.isEmpty else { return 0 }
        let total = plans.reduce(0) { $0 + $1.sets }
        let completed = todaySessions.reduce(0) { $0 + min($1.completedSets, $1.totalSets) }
        return Double(completed) / Double(total)
    }

    static func consecutiveHighDays(summaries: [DailySummary], before date: String) -> Int {
        let sorted = summaries
            .filter { $0.date < date }
            .sorted { $0.date > $1.date }
        var count = 0
        for summary in sorted {
            if summary.completionRate >= 0.8 { count += 1 } else { break }
        }
        return count
    }
}
