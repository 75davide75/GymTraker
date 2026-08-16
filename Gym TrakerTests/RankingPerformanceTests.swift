//
//  RankingPerformanceTests.swift
//  Gym TrakerTests
//
//  The ranking snapshot runs when a screen appears, so it has to be quick.
//  It has been the cause of a freeze once already.
//

import Testing
import Foundation
import SwiftData
@testable import Gym_Traker

@MainActor
struct RankingPerformanceTests {

    private func seeded() throws -> ModelContext {
        let container = try ModelContainer(
            for: UserProfile.self, Exercise.self, Plan.self, PlanDay.self,
            PlanItem.self, WorkoutSession.self, SessionEntry.self, ChangeRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        try ArchiveSeeder.seedIfNeeded(context, force: true)
        context.insert(UserProfile(name: "Test", sex: .male, birthYear: 1998, bodyweightKg: 78))

        // Twenty sessions of six exercises: a realistic few months of training.
        let exercises = Array(Store.allExercises(in: context).prefix(6))
        for index in 0..<20 {
            let session = WorkoutSession(planDayLetter: "A", planDayTitle: "Push")
            session.startedAt = .now.addingTimeInterval(TimeInterval(-index * 86_400))
            session.endedAt = session.startedAt.addingTimeInterval(3600)
            context.insert(session)
            for (order, exercise) in exercises.enumerated() {
                let entry = SessionEntry(
                    order: order + 1, exerciseID: exercise.id, exerciseName: exercise.name,
                    restSeconds: 90,
                    sets: (0..<4).map { _ in
                        PerformedSet(reps: 8, weightKg: 60, targetReps: 8, completedAt: .now)
                    }
                )
                entry.session = session
                context.insert(entry)
            }
        }
        try context.save()
        return context
    }

    @Test func snapshotIsFastEnoughToRunOnAppear() throws {
        let context = try seeded()

        let started = Date.now
        let snapshot = Store.rankingSnapshot(in: context)
        let elapsed = Date.now.timeIntervalSince(started)

        #expect(!snapshot.perExercise.isEmpty, "Nothing was ranked")
        #expect(elapsed < 0.5, "Snapshot took \(String(format: "%.2f", elapsed))s")
    }

    @Test func muscleRanksAreFastEnough() throws {
        let context = try seeded()
        let snapshot = Store.rankingSnapshot(in: context)

        let started = Date.now
        _ = Store.muscleRanks(in: context, snapshot: snapshot)
        let elapsed = Date.now.timeIntervalSince(started)

        #expect(elapsed < 0.3, "Muscle ranks took \(String(format: "%.2f", elapsed))s")
    }

    @Test func standardsLookupIsFastAcrossTheWholeArchive() throws {
        let context = try seeded()
        let all = Store.allExercises(in: context)

        let started = Date.now
        for exercise in all { _ = ExerciseStandards.assignment(for: exercise) }
        let elapsed = Date.now.timeIntervalSince(started)

        #expect(elapsed < 0.2, "Resolving \(all.count) assignments took \(String(format: "%.2f", elapsed))s")
    }
}
