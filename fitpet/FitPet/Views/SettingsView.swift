import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutPlan.sortOrder) private var plans: [WorkoutPlan]

    var body: some View {
        NavigationStack {
            List {
                Section("每日运动目标") {
                    ForEach(plans) { plan in
                        PlanEditRow(plan: plan)
                    }
                }

                Section {
                    Text("完成度 ≥ 80% 宠物升级，< 50% 降级")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("目标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct PlanEditRow: View {
    @Bindable var plan: WorkoutPlan
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.displayName)
                .font(.headline)

            HStack(spacing: 16) {
                // 组数
                VStack(alignment: .leading, spacing: 2) {
                    Text("组数").font(.caption).foregroundStyle(.secondary)
                    Stepper("\(plan.sets) 组", value: $plan.sets, in: 1...10)
                        .labelsHidden()
                    Text("\(plan.sets) 组").font(.subheadline)
                }

                Divider()

                // 每组目标（次数或时长）
                if plan.reps != nil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("每组次数").font(.caption).foregroundStyle(.secondary)
                        Stepper("", value: Binding(
                            get: { plan.reps ?? 10 },
                            set: { plan.reps = $0; try? context.save() }
                        ), in: 1...100, step: 5)
                        .labelsHidden()
                        Text("\(plan.reps ?? 10) 个").font(.subheadline)
                    }
                } else if plan.durationSeconds != nil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("每组时长").font(.caption).foregroundStyle(.secondary)
                        Stepper("", value: Binding(
                            get: { plan.durationSeconds ?? 60 },
                            set: { plan.durationSeconds = $0; try? context.save() }
                        ), in: 10...3600, step: 30)
                        .labelsHidden()
                        Text("\(plan.durationSeconds ?? 60) 秒").font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 4)
        .onChange(of: plan.sets) { _, _ in try? context.save() }
    }
}
