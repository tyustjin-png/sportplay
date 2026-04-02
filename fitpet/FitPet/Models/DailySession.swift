import SwiftData

@Model
final class DailySession {
    var date: String           // "2026-04-02"
    var exercise: String
    var completedSets: Int
    var totalSets: Int

    init(date: String, exercise: String, completedSets: Int, totalSets: Int) {
        self.date = date
        self.exercise = exercise
        self.completedSets = completedSets
        self.totalSets = totalSets
    }
}
