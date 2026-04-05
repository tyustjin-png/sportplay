import Foundation

// MARK: - 境界

enum Realm: Int, CaseIterable {
    case lingDong  = 1  // 灵动境
    case cuiSheng  = 2  // 催生境
    case poKe      = 3  // 破壳境
    case tengYun   = 4  // 腾云境
    case huaLin    = 5  // 化鳞境
    case ningDan   = 6  // 凝丹境
    case duJie     = 7  // 渡劫境
    case shenLong  = 8  // 神龙境

    var name: String {
        switch self {
        case .lingDong: return "灵动境"
        case .cuiSheng: return "催生境"
        case .poKe:     return "破壳境"
        case .tengYun:  return "腾云境"
        case .huaLin:   return "化鳞境"
        case .ningDan:  return "凝丹境"
        case .duJie:    return "渡劫境"
        case .shenLong: return "神龙境"
        }
    }

    /// 突破到下一境界需要的连续高完成率天数
    var breakthroughDaysRequired: Int {
        switch self {
        case .lingDong: return 3
        case .cuiSheng: return 5
        case .poKe:     return 7
        case .tengYun:  return 10
        case .huaLin:   return 14
        case .ningDan:  return 21
        case .duJie:    return 30
        case .shenLong: return 999
        }
    }
}

// MARK: - 龙形态（对应8境界）

enum DragonForm: Int, Equatable {
    case dormantEgg   = 1  // 灵动境：沉睡灵蛋
    case crackingEgg  = 2  // 催生境：裂纹灵蛋
    case hatchling    = 3  // 破壳境：幼龙
    case windDrake    = 4  // 腾云境：云翔幼龙
    case scaledDragon = 5  // 化鳞境：鳞甲龙
    case coreDragon   = 6  // 凝丹境：丹心龙
    case stormDragon  = 7  // 渡劫境：劫雷龙
    case celestial    = 8  // 神龙境：天神龙

    var displayName: String {
        switch self {
        case .dormantEgg:   return "沉睡灵蛋"
        case .crackingEgg:  return "裂纹灵蛋"
        case .hatchling:    return "幼龙"
        case .windDrake:    return "云翔幼龙"
        case .scaledDragon: return "鳞甲龙"
        case .coreDragon:   return "丹心龙"
        case .stormDragon:  return "劫雷龙"
        case .celestial:    return "天神龙"
        }
    }
}

// MARK: - 心情（7种）

enum PetMood: Equatable {
    case ecstatic   // 狂喜：爆发日/重大成就
    case happy      // 开心：完成率≥80%
    case content    // 满足：完成率≥60%
    case neutral    // 平静：完成率≥40%
    case bored      // 无聊：1天未运动
    case sad        // 难过：2天未运动或完成率<40%
    case dormant    // 冬眠：3天以上未运动

    var displayName: String {
        switch self {
        case .ecstatic: return "狂喜"
        case .happy:    return "开心"
        case .content:  return "满足"
        case .neutral:  return "平静"
        case .bored:    return "无聊"
        case .sad:      return "难过"
        case .dormant:  return "冬眠"
        }
    }

    /// 心情对经验值的影响倍率
    var expMultiplier: Double {
        switch self {
        case .ecstatic: return 1.5
        case .happy:    return 1.2
        case .content:  return 1.0
        case .neutral:  return 1.0
        case .bored:    return 0.8
        case .sad:      return 0.6
        case .dormant:  return 0.3
        }
    }
}

// MARK: - 每日结算结果

struct DailyGrowthResult {
    let expEarned: Int
    let newLevel: Int
    let newRealm: Int
    let remainingExp: Int
    let isBurstDay: Bool
    let isResonance: Bool
    let newAchievements: [String]
    let leveledUp: Bool
    let realmBrokeThrough: Bool
}

// MARK: - 成就定义

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let expReward: Int
}

// MARK: - PetGrowthService

struct PetGrowthService {
    static let levelsPerRealm = 27
    static let maxLevel = 216  // 8境界 × 27级

    // MARK: 境界与形态

    static func realmIndex(for level: Int) -> Int {
        (level - 1) / levelsPerRealm + 1
    }

    static func levelInRealm(for level: Int) -> Int {
        (level - 1) % levelsPerRealm + 1
    }

    static func realmEnum(for level: Int) -> Realm {
        Realm(rawValue: min(realmIndex(for: level), 8)) ?? .shenLong
    }

    static func dragonForm(for level: Int) -> DragonForm {
        DragonForm(rawValue: min(realmIndex(for: level), 8)) ?? .celestial
    }

    static func isAtRealmEnd(_ level: Int) -> Bool {
        level % levelsPerRealm == 0
    }

    // MARK: 经验值计算

    /// 升到下一级所需经验（完成度100% ≈ 5天升一级，初期；越高越慢）
    static func expToNextLevel(_ level: Int) -> Int {
        let r = realmIndex(for: level) - 1  // 0-based
        return 500 + level * 20 + r * r * 50
    }

    /// 每日经验计算（纯基于完成度）
    /// 基础：100分/天，按完成度比例
    /// 加成：连击、共鸣、爆发日、心情
    static func calcDailyExp(
        completionRate: Double,
        streakDays: Int,
        completedExerciseTypes: Int,  // 当日完成了几种不同运动
        mood: PetMood
    ) -> (exp: Int, isBurstDay: Bool, isResonance: Bool) {
        let baseExp = 100.0

        // 完成度加成（线性，超额最多算200%）
        let completionFactor = min(completionRate, 2.0)

        // 连击加成：每天+2%，上限+50%
        let streakBonus = 1.0 + min(Double(streakDays) * 0.02, 0.5)

        // 共鸣：完成3种以上运动
        let isResonance = completedExerciseTypes >= 3
        let resonanceBonus = isResonance ? 1.25 : 1.0

        // 爆发日：完成度≥150%
        let isBurstDay = completionRate >= 1.5
        let burstBonus = isBurstDay ? 2.0 : 1.0

        // 心情倍率
        let moodBonus = mood.expMultiplier

        let total = baseExp * completionFactor * streakBonus * resonanceBonus * burstBonus * moodBonus
        return (Int(total.rounded()), isBurstDay, isResonance)
    }

    // MARK: 心情计算

    static func mood(
        completionRate: Double,
        daysSinceActive: Int,
        isBurstDay: Bool
    ) -> PetMood {
        if daysSinceActive >= 3 { return .dormant }
        if daysSinceActive >= 2 { return .sad }
        if daysSinceActive >= 1 { return .bored }
        if isBurstDay            { return .ecstatic }
        if completionRate >= 0.8 { return .happy }
        if completionRate >= 0.6 { return .content }
        if completionRate >= 0.4 { return .neutral }
        return .sad
    }

    // MARK: 每日结算（主入口）

    static func processEndOfDay(
        state: PetState,
        completionRate: Double,
        completedExerciseTypes: Int,
        consecutiveHighDays: Int
    ) -> DailyGrowthResult {
        let daysSinceActive = calcDaysSinceActive(lastActiveDate: state.lastActiveDate)
        let currentMood = mood(
            completionRate: completionRate,
            daysSinceActive: daysSinceActive,
            isBurstDay: completionRate >= 1.5
        )

        let (earnedExp, isBurstDay, isResonance) = calcDailyExp(
            completionRate: completionRate,
            streakDays: state.streakDays,
            completedExerciseTypes: completedExerciseTypes,
            mood: currentMood
        )

        // 冬眠惩罚：经验衰减
        var adjustedExp = state.currentExp
        if daysSinceActive >= 3 {
            let decayDays = daysSinceActive - 2
            let decay = 1.0 - min(Double(decayDays) * 0.02, 0.5)
            adjustedExp = Int(Double(adjustedExp) * decay)
        }

        var exp = adjustedExp + earnedExp
        var level = state.currentLevel
        var newAchievements: [String] = []
        var leveledUp = false
        var realmBrokeThrough = false

        // 循环升级
        while level < maxLevel {
            let needed = expToNextLevel(level)
            guard exp >= needed else { break }

            if isAtRealmEnd(level) {
                // 境界末级需要突破条件
                let realm = realmEnum(for: level)
                guard consecutiveHighDays >= realm.breakthroughDaysRequired else { break }
                exp -= needed
                level += 1
                realmBrokeThrough = true
                leveledUp = true

                // 解锁境界成就
                let achieveId = "realm_\(realmIndex(for: level))"
                if !state.unlockedAchievementIds.contains(achieveId) {
                    newAchievements.append(achieveId)
                }
            } else {
                exp -= needed
                level += 1
                leveledUp = true
            }
        }

        // 冬眠7天以上降1级（不跨境界）
        if daysSinceActive >= 7 {
            let realmStart = (realmIndex(for: level) - 1) * levelsPerRealm + 1
            level = max(level - 1, realmStart)
        }

        // 连击/爆发/共鸣成就检查
        newAchievements += checkSpecialAchievements(
            state: state,
            streakDays: state.streakDays,
            isBurstDay: isBurstDay,
            isResonance: isResonance
        )

        return DailyGrowthResult(
            expEarned: earnedExp,
            newLevel: level,
            newRealm: realmIndex(for: level),
            remainingExp: exp,
            isBurstDay: isBurstDay,
            isResonance: isResonance,
            newAchievements: newAchievements,
            leveledUp: leveledUp,
            realmBrokeThrough: realmBrokeThrough
        )
    }

    // MARK: 成就检查

    static func checkSpecialAchievements(
        state: PetState,
        streakDays: Int,
        isBurstDay: Bool,
        isResonance: Bool
    ) -> [String] {
        var ids: [String] = []
        let unlocked = state.unlockedAchievementIds

        let streakMilestones = [(3, "streak_3"), (7, "streak_7"), (30, "streak_30"),
                                (100, "streak_100"), (365, "streak_365")]
        for (days, id) in streakMilestones {
            if streakDays >= days && !unlocked.contains(id) { ids.append(id) }
        }

        if isBurstDay && !unlocked.contains("burst_first") { ids.append("burst_first") }
        if isBurstDay && state.burstDayCount >= 9 && !unlocked.contains("burst_10") { ids.append("burst_10") }
        if isResonance && !unlocked.contains("resonance_first") { ids.append("resonance_first") }

        return ids
    }

    // MARK: 工具方法

    static func calcDaysSinceActive(lastActiveDate: String) -> Int {
        guard !lastActiveDate.isEmpty else { return 0 }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let last = fmt.date(from: lastActiveDate) else { return 0 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
    }

    // MARK: 成就列表

    static let achievements: [Achievement] = [
        .init(id: "streak_3",        name: "初露锋芒",  description: "连续打卡3天",       icon: "flame",                expReward: 50),
        .init(id: "streak_7",        name: "周周不息",  description: "连续打卡7天",       icon: "flame.fill",           expReward: 150),
        .init(id: "streak_30",       name: "月之守护者", description: "连续打卡30天",      icon: "moon.stars.fill",      expReward: 500),
        .init(id: "streak_100",      name: "百日铸龙",  description: "连续打卡100天",      icon: "star.fill",            expReward: 2000),
        .init(id: "streak_365",      name: "岁月如龙",  description: "连续打卡365天",      icon: "crown.fill",           expReward: 10000),
        .init(id: "realm_2",         name: "蛋壳龟裂",  description: "突破催生境",        icon: "bolt.fill",            expReward: 200),
        .init(id: "realm_3",         name: "破壳新生",  description: "突破破壳境",        icon: "sparkles",             expReward: 500),
        .init(id: "realm_4",         name: "御风而行",  description: "突破腾云境",        icon: "cloud.fill",           expReward: 1000),
        .init(id: "realm_5",         name: "龙鳞初成",  description: "突破化鳞境",        icon: "shield.fill",          expReward: 2000),
        .init(id: "realm_6",         name: "龙丹凝聚",  description: "突破凝丹境",        icon: "circle.inset.filled",  expReward: 3000),
        .init(id: "realm_7",         name: "天劫临身",  description: "突破渡劫境",        icon: "bolt.trianglebadge.exclamationmark.fill", expReward: 5000),
        .init(id: "realm_8",         name: "神龙天成",  description: "到达神龙境",        icon: "crown.fill",           expReward: 10000),
        .init(id: "burst_first",     name: "初次爆发",  description: "首次触发爆发日",     icon: "flame.circle.fill",    expReward: 300),
        .init(id: "burst_10",        name: "爆发十连",  description: "累计触发10次爆发日", icon: "flame.circle.fill",    expReward: 1500),
        .init(id: "resonance_first", name: "初次共鸣",  description: "首次触发元素共鸣",   icon: "waveform.circle.fill", expReward: 200),
    ]
}
