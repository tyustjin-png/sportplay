import Foundation

struct PetGrowthService {
    static let levelsPerRealm = 27

    static func realm(for level: Int) -> Int {
        (level - 1) / levelsPerRealm + 1
    }

    static func levelInRealm(for level: Int) -> Int {
        (level - 1) % levelsPerRealm + 1
    }

    static func newLevel(currentLevel: Int, completionRate: Double, consecutiveHighDays: Int) -> Int {
        let currentRealm = realm(for: currentLevel)
        let realmStart   = (currentRealm - 1) * levelsPerRealm + 1
        let realmEnd     = currentRealm * levelsPerRealm

        var newLevel = currentLevel
        if completionRate >= 0.8 {
            newLevel = min(currentLevel + 1, realmEnd)
        } else if completionRate < 0.5 {
            newLevel = max(currentLevel - 1, realmStart)
        }

        if consecutiveHighDays >= 7 && completionRate >= 0.8 && currentLevel == realmEnd {
            newLevel = realmEnd + 1
        }

        return max(newLevel, 1)
    }

    enum DragonForm {
        case egg
        case hatchling
        case young
        case divine
    }

    static func dragonForm(for level: Int) -> DragonForm {
        switch realm(for: level) {
        case 1:  return .egg
        case 2:  return .hatchling
        case 3:  return .young
        default: return .divine
        }
    }

    enum PetMood { case happy, neutral, sad }

    static func mood(completionRate: Double, daysSinceActive: Int) -> PetMood {
        if daysSinceActive >= 3 { return .sad }
        if completionRate >= 0.8 { return .happy }
        if completionRate >= 0.5 { return .neutral }
        return .sad
    }
}
