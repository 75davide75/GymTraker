//
//  PersistenceTests.swift
//  Gym TrakerTests
//
//  Acceptance check from design/SPEC.md §7: sets within one exercise can hold
//  different rep counts and survive relaunch. The risk here is the Codable
//  arrays — SetTarget and PerformedSet round-trip through SwiftData's encoding,
//  not through columns, so they are worth pinning.
//

import Testing
import Foundation
import SwiftData
@testable import Gym_Traker

@MainActor
struct PersistenceTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: UserProfile.self, Exercise.self, Plan.self, PlanDay.self,
            PlanItem.self, WorkoutSession.self, SessionEntry.self, ChangeRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func unevenSetsSurviveAReload() throws {
        let container = try makeContainer()
        let writing = ModelContext(container)

        let plan = Plan(name: "Test plan")
        writing.insert(plan)
        let day = PlanDay(letter: "A", title: "Push", order: 0)
        day.plan = plan
        writing.insert(day)

        let item = PlanItem(
            order: 1,
            exerciseID: "bench-press",
            exerciseName: "Bench Press",
            targetSets: [SetTarget(reps: 8), SetTarget(reps: 8), SetTarget(reps: 6), SetTarget(reps: 6)],
            workingWeightKg: 72.5,
            stepKg: 2.5,
            restSeconds: 90
        )
        item.day = day
        writing.insert(item)
        try writing.save()

        // A separate context stands in for a relaunch.
        let reading = ModelContext(container)
        let reloaded = try #require(try reading.fetch(FetchDescriptor<PlanItem>()).first)

        #expect(reloaded.targetSets.map(\.reps) == [8, 8, 6, 6])
        #expect(reloaded.repsSummary == "8/8/6/6")
        #expect(reloaded.workingWeightKg == 72.5)
    }

    @Test func performedSetsKeepTheirOwnValues() throws {
        let container = try makeContainer()
        let writing = ModelContext(container)

        let session = WorkoutSession(planDayLetter: "A", planDayTitle: "Push")
        writing.insert(session)
        let entry = SessionEntry(
            order: 1,
            exerciseID: "bench-press",
            exerciseName: "Bench Press",
            restSeconds: 90,
            sets: [
                PerformedSet(reps: 8, weightKg: 70, targetReps: 8, completedAt: .now),
                PerformedSet(reps: 6, weightKg: 72.5, targetReps: 8, completedAt: .now),
                PerformedSet(reps: 5, weightKg: 72.5, targetReps: 6, completedAt: nil)
            ]
        )
        entry.session = session
        writing.insert(entry)
        try writing.save()

        let reading = ModelContext(container)
        let reloaded = try #require(try reading.fetch(FetchDescriptor<SessionEntry>()).first)

        #expect(reloaded.sets.map(\.reps) == [8, 6, 5])
        #expect(reloaded.sets.map(\.weightKg) == [70, 72.5, 72.5])
        // The incomplete set is excluded from what actually happened.
        #expect(reloaded.completedSets.count == 2)
        let expectedVolume: Double = 995  // 70 × 8 + 72.5 × 6
        #expect(reloaded.volumeKg == expectedVolume)
    }

    @Test func aTemplateAssignedToTwoWeekdaysResolvesToTheSameDay() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let plan = Plan(name: "Upper / Lower")
        context.insert(plan)
        let dayA = PlanDay(letter: "A", title: "Upper", order: 0)
        dayA.plan = plan
        context.insert(dayA)
        let item = PlanItem(order: 1, exerciseID: "bench-press", exerciseName: "Bench Press")
        item.day = dayA
        context.insert(item)

        // Monday and Thursday both run template A.
        plan.weekAssignmentsRaw = ["A", "", "", "A", "", "", ""]
        try context.save()

        let reading = ModelContext(container)
        let reloaded = try #require(try reading.fetch(FetchDescriptor<Plan>()).first)

        #expect(reloaded.letter(forWeekdayIndex: 0) == "A")
        #expect(reloaded.letter(forWeekdayIndex: 3) == "A")
        #expect(reloaded.letter(forWeekdayIndex: 1) == nil)

        let monday = try #require(reloaded.day(withLetter: "A"))
        #expect(monday.orderedItems.count == 1)
        #expect(monday.orderedItems.first?.exerciseName == "Bench Press")
    }

    @Test func nextScheduledSkipsRestDaysAndWrapsTheWeek() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let plan = Plan(name: "PPL")
        context.insert(plan)
        for (index, letter) in ["A", "B", "C"].enumerated() {
            let day = PlanDay(letter: letter, title: "Day \(letter)", order: index)
            day.plan = plan
            context.insert(day)
        }
        plan.weekAssignmentsRaw = ["A", "", "B", "", "C", "", ""]
        try context.save()

        let calendar = Calendar.current
        // Pick a known Sunday: 2026-08-16.
        let sunday = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 16)))
        #expect(Plan.mondayBasedIndex(for: sunday) == 6)

        // A rest day still points at the next session rather than nothing.
        let next = try #require(plan.nextScheduled(from: sunday))
        #expect(next.day.letter == "A")
        #expect(next.daysAhead == 1)

        let wednesday = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 19)))
        let sameDay = try #require(plan.nextScheduled(from: wednesday))
        #expect(sameDay.day.letter == "B")
        #expect(sameDay.daysAhead == 0)
    }

    @Test func archiveSeedingIsIdempotent() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        // Pinned to the bundle rather than a literal, so growing the archive
        // does not break the test that guards against double-seeding.
        let bundled = try ArchiveSeeder.bundledCount()
        #expect(bundled > 250, "The archive shrank unexpectedly: \(bundled)")

        let firstPass = try ArchiveSeeder.seedIfNeeded(context, force: true)
        #expect(firstPass == bundled)

        // A second run inserts nothing and leaves the archive intact.
        let secondPass = try ArchiveSeeder.seedIfNeeded(context, force: true)
        #expect(secondPass == 0)
        #expect(try context.fetch(FetchDescriptor<Exercise>()).count == bundled)
    }

    /// Every archive exercise must carry line art — that is the whole point of
    /// swapping to an illustrated set.
    @Test func everyArchiveExerciseCarriesIllustrations() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try ArchiveSeeder.seedIfNeeded(context, force: true)

        let all = try context.fetch(FetchDescriptor<Exercise>())
        let bare = all.filter { !$0.hasIllustrations }
        #expect(bare.isEmpty, "\(bare.count) archive exercises have no illustration")

        // And the files those names point at are actually in the bundle.
        let sample = try #require(all.first { $0.id == "barbell-squat" })
        #expect(sample.illustrationNames.count == 2, "Expected a two-phase demonstration")
        for name in sample.illustrationNames {
            #expect(ExerciseArtwork.illustration(name) != nil, "Missing bundled artwork \(name)")
        }
    }

    /// Photographs are optional, but any name referenced must resolve.
    @Test func referencedPhotosExistInTheBundle() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try ArchiveSeeder.seedIfNeeded(context, force: true)

        let withPhotos = try context.fetch(FetchDescriptor<Exercise>()).filter(\.hasPhotos)
        #expect(!withPhotos.isEmpty, "No exercise offers a reference gallery")

        for exercise in withPhotos.prefix(20) {
            for name in exercise.photoNames {
                #expect(ExerciseArtwork.photo(name) != nil, "Missing bundled photo \(name)")
            }
        }
    }

    /// Every id the presets and the ranking anchors point at must exist.
    @Test func presetAndAnchorIDsResolve() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try ArchiveSeeder.seedIfNeeded(context, force: true)

        for preset in PlanPreset.all {
            for day in preset.days {
                for id in day.exerciseIDs {
                    #expect(Store.exercise(id: id, in: context) != nil,
                            "\(preset.name) references missing exercise \(id)")
                }
            }
        }

        for anchor in [RankAnchor.bench, .squat, .deadlift, .ohp, .row] {
            #expect(Store.anchorExercise(anchor, in: context) != nil,
                    "No archive exercise represents \(anchor.displayName)")
        }
    }

    @Test func seedingNeverClobbersACustomExercise() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try ArchiveSeeder.seedIfNeeded(context, force: true)

        // A user exercise that collides with an archive id must survive.
        let custom = Exercise(
            id: "bench-press",
            name: "My Bench Variation",
            primaryMuscle: "Chest",
            equipment: .dumbbell,
            isCustom: true
        )
        // Replace the seeded row so the ids genuinely collide.
        if let seeded = Store.exercise(id: "bench-press", in: context) {
            context.delete(seeded)
        }
        context.insert(custom)
        try context.save()

        try ArchiveSeeder.seedIfNeeded(context, force: true)

        let reloaded = try #require(Store.exercise(id: "bench-press", in: context))
        #expect(reloaded.name == "My Bench Variation")
        #expect(reloaded.isCustom)
    }
}
