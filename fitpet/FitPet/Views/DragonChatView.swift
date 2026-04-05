import SwiftUI
import SwiftData

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct DragonChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var plans: [WorkoutPlan]
    @Query private var sessions: [DailySession]
    @Query private var petStates: [PetState]
    @Query private var summaries: [DailySummary]

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    private var petState: PetState? { petStates.first }
    private var today: String { WorkoutService.today }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .padding(12)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(16)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    TextField("跟小火说说今天练了什么...", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(inputText.isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle("小火 🐉")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .onAppear {
            // 小龙开场白
            let level = petState?.currentLevel ?? 1
            let streak = petState?.streakDays ?? 0
            let greeting = streak > 0
                ? "嘿嘿，连续打卡\(streak)天了！今天也要动起来哦～"
                : "哇，你来啦！今天练了什么，快告诉我！"
            messages.append(ChatMessage(text: greeting, isUser: false))
            _ = level
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""
        isLoading = true

        let level = petState?.currentLevel ?? 1
        let realm = petState?.currentRealm ?? 1
        let streak = petState?.streakDays ?? 0

        Task {
            do {
                let response = try await GeminiService.chat(
                    userMessage: text,
                    petLevel: level,
                    petRealm: realm,
                    streakDays: streak
                )
                await MainActor.run {
                    isLoading = false
                    messages.append(ChatMessage(text: response.reply, isUser: false))
                    if !response.workouts.isEmpty {
                        saveWorkouts(response.workouts)
                        updatePet()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    messages.append(ChatMessage(text: "嗷...网络好像出问题了，待会儿再说？", isUser: false))
                }
            }
        }
    }

    private func saveWorkouts(_ workouts: [GeminiService.WorkoutEntry]) {
        for w in workouts {
            if let existing = sessions.first(where: { $0.date == today && $0.exercise == w.exercise }) {
                existing.completedSets += 1
            } else {
                let plan = plans.first(where: { $0.exercise == w.exercise })
                let session = DailySession(
                    date: today,
                    exercise: w.exercise,
                    completedSets: 1,
                    totalSets: plan?.sets ?? 1
                )
                context.insert(session)
            }
        }
        try? context.save()
    }

    private func updatePet() {
        guard let state = petState else { return }
        let rate = WorkoutService.completionRate(sessions: sessions, plans: plans, date: today)
        let highDays = WorkoutService.consecutiveHighDays(summaries: Array(summaries), before: today)
        let newLvl = PetGrowthService.newLevel(
            currentLevel: state.currentLevel,
            completionRate: rate,
            consecutiveHighDays: highDays
        )

        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let yesterdayStr = Calendar.current.date(byAdding: .day, value: -1, to: Date()).map { fmt.string(from: $0) } ?? ""
        if state.lastActiveDate == yesterdayStr {
            state.streakDays += 1
        } else if state.lastActiveDate != today {
            state.streakDays = 1
        }

        state.currentLevel = newLvl
        state.currentRealm = PetGrowthService.realm(for: newLvl)
        state.lastActiveDate = today

        if summaries.first(where: { $0.date == today }) == nil {
            let summary = DailySummary(date: today, completionRate: rate, streakDays: state.streakDays)
            context.insert(summary)
        }
        try? context.save()
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundStyle(message.isUser ? .white : .primary)
                .cornerRadius(18)
            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
    }
}
