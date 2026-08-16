//
//  Gym_TrakerApp.swift
//  Gym Traker
//
//  Created by Davide Sogos on 16/08/2026.
//

import SwiftUI
import SwiftData

@main
struct Gym_TrakerApp: App {

    let container: ModelContainer
    @State private var health = HealthStore()

    init() {
        // UI tests pass -resetStore so every run starts at onboarding.
        let isResetting = ProcessInfo.processInfo.arguments.contains("-resetStore")

        do {
            let container = try ModelContainer(
                for: UserProfile.self,
                Exercise.self,
                Plan.self,
                PlanDay.self,
                PlanItem.self,
                WorkoutSession.self,
                SessionEntry.self,
                ChangeRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: isResetting)
            )
            try ArchiveSeeder.seedIfNeeded(container.mainContext, force: isResetting)
            self.container = container
        } catch {
            fatalError("Could not start the data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(health)
        }
        .modelContainer(container)
    }
}
