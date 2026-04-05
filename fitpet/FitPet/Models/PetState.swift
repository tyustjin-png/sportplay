import SwiftData

@Model
final class PetState {
    var currentRealm: Int
    var currentLevel: Int
    var currentExp: Int         // 当前级别已积累经验
    var totalExp: Int           // 历史总经验
    var streakDays: Int
    var lastActiveDate: String

    // 特殊事件计数
    var burstDayCount: Int      // 累计爆发日次数
    var resonanceCount: Int     // 累计共鸣次数

    // 突破状态（到达境界末级后需要连续达标才能突破）
    var isInBreakthrough: Bool
    var breakthroughHighDays: Int

    // 已解锁成就ID（逗号分隔）
    var unlockedAchievements: String

    init() {
        self.currentRealm = 1
        self.currentLevel = 1
        self.currentExp = 0
        self.totalExp = 0
        self.streakDays = 0
        self.lastActiveDate = ""
        self.burstDayCount = 0
        self.resonanceCount = 0
        self.isInBreakthrough = false
        self.breakthroughHighDays = 0
        self.unlockedAchievements = ""
    }

    var unlockedAchievementIds: Set<String> {
        Set(unlockedAchievements.split(separator: ",").map(String.init))
    }

    func unlockAchievement(_ id: String) {
        var ids = unlockedAchievementIds
        ids.insert(id)
        unlockedAchievements = ids.joined(separator: ",")
    }
}
