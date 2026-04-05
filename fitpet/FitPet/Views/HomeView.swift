import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [WorkoutPlan]
    @Query private var sessions: [DailySession]
    @Query private var petStates: [PetState]
    @Query private var summaries: [DailySummary]

    @State private var showWorkout = false
    @State private var showChat = false
    @State private var showSettings = false

    private var today: String { WorkoutService.today }

    private var petState: PetState {
        if let state = petStates.first { return state }
        let state = PetState()
        context.insert(state)
        return state
    }

    private var completionRate: Double {
        WorkoutService.completionRate(sessions: sessions, plans: plans, date: today)
    }

    private var dragonForm: DragonForm {
        PetGrowthService.dragonForm(for: petState.currentLevel)
    }

    private var mood: PetMood {
        let daysSince = PetGrowthService.calcDaysSinceActive(lastActiveDate: petState.lastActiveDate)
        return PetGrowthService.mood(
            completionRate: completionRate,
            daysSinceActive: daysSince,
            isBurstDay: completionRate >= 1.5
        )
    }

    private var expProgress: Double {
        let needed = PetGrowthService.expToNextLevel(petState.currentLevel)
        guard needed > 0 else { return 1.0 }
        return min(Double(petState.currentExp) / Double(needed), 1.0)
    }

    private func updatePetAfterWorkout() {
        let state = petState
        let rate = WorkoutService.completionRate(sessions: sessions, plans: plans, date: today)
        let highDays = WorkoutService.consecutiveHighDays(summaries: Array(summaries), before: today)

        // 当日完成了几种不同运动
        let exerciseTypes = Set(sessions.filter { $0.date == today && $0.completedSets > 0 }.map { $0.exercise }).count

        let result = PetGrowthService.processEndOfDay(
            state: state,
            completionRate: rate,
            completedExerciseTypes: exerciseTypes,
            consecutiveHighDays: highDays
        )

        // 连击计算
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let yesterdayStr = Calendar.current.date(byAdding: .day, value: -1, to: Date()).map { fmt.string(from: $0) } ?? ""
        if state.lastActiveDate == yesterdayStr {
            state.streakDays += 1
        } else if state.lastActiveDate != today {
            state.streakDays = 1
        }

        state.currentLevel = result.newLevel
        state.currentRealm = result.newRealm
        state.currentExp = result.remainingExp
        state.totalExp += result.expEarned
        state.lastActiveDate = today
        if result.isBurstDay { state.burstDayCount += 1 }
        if result.isResonance { state.resonanceCount += 1 }

        // 解锁成就
        for id in result.newAchievements {
            state.unlockAchievement(id)
            // 成就奖励经验
            if let ach = PetGrowthService.achievements.first(where: { $0.id == id }) {
                state.currentExp += ach.expReward
                state.totalExp += ach.expReward
            }
        }

        // 每日汇总
        if summaries.first(where: { $0.date == today }) == nil {
            let summary = DailySummary(
                date: today,
                completionRate: rate,
                streakDays: state.streakDays,
                expEarned: result.expEarned,
                isBurstDay: result.isBurstDay,
                isResonance: result.isResonance
            )
            context.insert(summary)
        }
        try? context.save()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 小龙 + 状态
                    HStack(alignment: .center, spacing: 16) {
                        DragonView(form: dragonForm, mood: mood, isWorkingOut: false)
                            .frame(width: 100, height: 100)
                            .scaleEffect(0.65)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(PetGrowthService.realmEnum(for: petState.currentLevel).name) · 第 \(PetGrowthService.levelInRealm(for: petState.currentLevel)) 级")
                                .font(.headline)
                            Text(dragonForm.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Text("经验")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                ProgressView(value: expProgress)
                                    .tint(.purple)
                                Text("\(petState.currentExp)/\(PetGrowthService.expToNextLevel(petState.currentLevel))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 8) {
                                Label("\(petState.streakDays)天", systemImage: "flame.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("今日 \(Int(min(completionRate, 1.0) * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(completionRate >= 0.8 ? .green : .secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // 今日完成度条
                    VStack(spacing: 4) {
                        ProgressView(value: min(completionRate, 1.0))
                            .tint(completionRate >= 1.5 ? .yellow : completionRate >= 0.8 ? .green : .blue)
                            .padding(.horizontal)
                        if completionRate >= 1.5 {
                            Text("🔥 爆发日！经验翻倍").font(.caption).foregroundStyle(.orange)
                        } else if completionRate >= 0.8 {
                            Text("✓ 优秀").font(.caption).foregroundStyle(.green)
                        }
                    }

                    // 今日计划
                    VStack(alignment: .leading, spacing: 6) {
                        Text("今日计划").font(.headline).padding(.horizontal)
                        PlanProgressView(plans: plans, sessions: sessions, today: today)
                            .padding(.horizontal)
                    }

                    // 按钮区
                    HStack(spacing: 12) {
                        Button(action: { showWorkout = true }) {
                            Label("开始运动", systemImage: "figure.run")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(14)
                        }
                        Button(action: { showChat = true }) {
                            Label("和小火说话", systemImage: "bubble.left.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("FitPet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showWorkout, onDismiss: updatePetAfterWorkout) {
            WorkoutView()
        }
        .sheet(isPresented: $showChat) {
            DragonChatView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            if plans.isEmpty { WorkoutService.seedDefaultPlans(context: context) }
            NotificationManager.shared.requestPermissionAndSchedule()
        }
    }
}
