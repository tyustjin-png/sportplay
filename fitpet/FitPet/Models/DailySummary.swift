import SwiftData

@Model
final class DailySummary {
    var date: String
    var completionRate: Double
    var streakDays: Int
    var expEarned: Int
    var isBurstDay: Bool
    var isResonance: Bool

    init(date: String, completionRate: Double, streakDays: Int,
         expEarned: Int = 0, isBurstDay: Bool = false, isResonance: Bool = false) {
        self.date = date
        self.completionRate = completionRate
        self.streakDays = streakDays
        self.expEarned = expEarned
        self.isBurstDay = isBurstDay
        self.isResonance = isResonance
    }
}
