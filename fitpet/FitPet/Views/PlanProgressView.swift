import SwiftUI
import SwiftData

struct PlanProgressView: View {
    let plans: [WorkoutPlan]
    let sessions: [DailySession]
    let today: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(plans.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.exercise) { plan in
                HStack {
                    Text(plan.displayName)
                        .font(.system(.body, design: .rounded))
                    Spacer()
                    Text(progressText(for: plan))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(isCompleted(plan) ? .green : .secondary)
                    if isCompleted(plan) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }

    private func completedSets(for plan: WorkoutPlan) -> Int {
        sessions.first(where: { $0.date == today && $0.exercise == plan.exercise })?.completedSets ?? 0
    }

    private func isCompleted(_ plan: WorkoutPlan) -> Bool {
        completedSets(for: plan) >= plan.sets
    }

    private func progressText(for plan: WorkoutPlan) -> String {
        "\(completedSets(for: plan))/\(plan.sets)组"
    }
}
