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

    init() {
        do {
            let container = try ModelContainer(
                for: UserProfile.self,
                Exercise.self,
                Plan.self,
                PlanDay.self,
                PlanItem.self,
                WorkoutSession.self,
                SessionEntry.self,
                ChangeRecord.self
            )
            try ArchiveSeeder.seedIfNeeded(container.mainContext)
            self.container = container
        } catch {
            fatalError("Could not start the data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
