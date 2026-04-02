import SwiftData

@Model
final class PetState {
    var currentRealm: Int      // 境界（1 起）
    var currentLevel: Int      // 全局级别（1 起）
    var streakDays: Int
    var lastActiveDate: String // "2026-04-02" 或 ""

    init() {
        self.currentRealm = 1
        self.currentLevel = 1
        self.streakDays = 0
        self.lastActiveDate = ""
    }
}
