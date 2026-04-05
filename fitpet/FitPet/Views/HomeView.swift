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

    private var daysSinceActive: Int {
        guard !petState.lastActiveDate.isEmpty,
              let last = ISO8601DateFormatter().date(from: petState.lastActiveDate + "T00:00:00Z"),
              let todayDate = ISO8601DateFormatter().date(from: today + "T00:00:00Z")
        else { return 0 }
        return Calendar.current.dateComponents([.day], from: last, to: todayDate).day ?? 0
    }

    private var mood: PetMood {
        PetGrowthService.mood(completionRate: completionRate, daysSinceActive: daysSinceActive)
    }

    private func updatePetAfterWorkout() {
        let state = petState
        let rate = WorkoutService.completionRate(sessions: sessions, plans: plans, date: today)
        let highDays = WorkoutService.consecutiveHighDays(summaries: Array(summaries), before: today)
        let newLvl = PetGrowthService.newLevel(
            currentLevel: state.currentLevel,
            completionRate: rate,
            consecutiveHighDays: highDays
        )

        // 连续打卡计算
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let yesterdayStr = yesterday.map { fmt.string(from: $0) } ?? ""
        let newStreak: Int
        if state.lastActiveDate == yesterdayStr {
            newStreak = state.streakDays + 1
        } else if state.lastActiveDate == today {
            newStreak = state.streakDays
        } else {
            newStreak = 1
        }

        state.currentRealm = PetGrowthService.realm(for: newLvl)
        state.currentLevel = newLvl
        state.streakDays = newStreak
        state.lastActiveDate = today

        // 保存每日汇总
        if summaries.first(where: { $0.date == today }) == nil {
            let summary = DailySummary(date: today, completionRate: rate, streakDays: newStreak)
            context.insert(summary)
        }
        try? context.save()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    DragonView(form: dragonForm, mood: mood, isWorkingOut: false)
                        .padding(.top, 20)

                    VStack(spacing: 4) {
                        Text("境界 \(PetGrowthService.realm(for: petState.currentLevel)) · 第 \(PetGrowthService.levelInRealm(for: petState.currentLevel)) 级")
                            .font(.headline)
                        Text("连续打卡 \(petState.streakDays) 天")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 8) {
                        HStack {
                            Text("今日完成")
                            Spacer()
                            Text("\(Int(completionRate * 100))%")
                                .bold()
                        }
                        ProgressView(value: completionRate)
                            .tint(completionRate >= 0.8 ? .green : .blue)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日计划")
                            .font(.headline)
                            .padding(.horizontal)
                        PlanProgressView(plans: plans, sessions: sessions, today: today)
                            .padding(.horizontal)
                    }

                    Button(action: { showWorkout = true }) {
                        Label("开始运动", systemImage: "figure.run")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)

                    Button(action: { showChat = true }) {
                        Label("和小火说话", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
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
