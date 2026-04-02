import SwiftData

@Model
final class DailySummary {
    var date: String
    var completionRate: Double  // 0.0 - 1.0
    var streakDays: Int

    init(date: String, completionRate: Double, streakDays: Int) {
        self.date = date
        self.completionRate = completionRate
        self.streakDays = streakDays
    }
}
