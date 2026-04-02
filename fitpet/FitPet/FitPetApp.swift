import SwiftUI
import SwiftData

@main
struct FitPetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            WorkoutPlan.self,
            DailySession.self,
            PetState.self,
            DailySummary.self,
        ])
    }
}
