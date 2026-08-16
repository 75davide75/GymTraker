//
//  RegistryTests.swift
//  Gym TrakerTests
//
//  Acceptance check from design/SPEC.md §7: changing a weight, a rep count, a
//  set count or a rest time each produce exactly one registry entry with the
//  correct old and new value.
//

import Testing
import Foundation
import SwiftData
@testable import Gym_Traker

@MainActor
struct RegistryTests {

    /// A throwaway in-memory store so tests never touch the real database.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: UserProfile.self, Exercise.self, Plan.self, PlanDay.self,
            PlanItem.self, WorkoutSession.self, SessionEntry.self, ChangeRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeItem() -> PlanItem {
        PlanItem(
            order: 1,
            exerciseID: "bench-press",
            exerciseName: "Bench Press",
            targetSets: [SetTarget(reps: 8), SetTarget(reps: 8), SetTarget(reps: 6)],
            workingWeightKg: 70,
            stepKg: 2.5,
            restSeconds: 90
        )
    }

    @Test func weightIncreaseWritesOneUpwardRecord() throws {
        let context = try makeContext()
        let item = makeItem()

        Registry.weightChanged(item: item, from: 70, to: 72.5, units: .kg, in: context)

        let records = Registry.all(in: context)
        #expect(records.count == 1)
        let record = try #require(records.first)
        #expect(record.field == .weight)
        #expect(record.fromValue == "70 kg")
        #expect(record.toValue == "72.5 kg")
        #expect(record.direction == .up)
        #expect(record.exerciseName == "Bench Press")
    }

    @Test func weightDecreaseIsRecordedAsDownward() throws {
        let context = try makeContext()
        Registry.weightChanged(item: makeItem(), from: 70, to: 65, units: .kg, in: context)
        #expect(try #require(Registry.all(in: context).first).direction == .down)
    }

    @Test func anUnchangedValueWritesNothing() throws {
        let context = try makeContext()
        let item = makeItem()

        Registry.weightChanged(item: item, from: 70, to: 70, units: .kg, in: context)
        Registry.repsChanged(item: item, setIndex: 0, from: 8, to: 8, in: context)
        Registry.setsChanged(item: item, from: 3, to: 3, in: context)
        Registry.restChanged(item: item, from: 90, to: 90, in: context)

        #expect(Registry.all(in: context).isEmpty)
    }

    @Test func repsRecordCarriesTheSetIndex() throws {
        let context = try makeContext()
        Registry.repsChanged(item: makeItem(), setIndex: 2, from: 6, to: 8, in: context)

        let record = try #require(Registry.all(in: context).first)
        #expect(record.field == .reps)
        #expect(record.fromValue == "Set 3 · 6 reps")
        #expect(record.toValue == "Set 3 · 8 reps")
        #expect(record.direction == .up)
    }

    @Test func setCountAndRestAreRecorded() throws {
        let context = try makeContext()
        let item = makeItem()

        Registry.setsChanged(item: item, from: 3, to: 4, in: context)
        Registry.restChanged(item: item, from: 90, to: 120, in: context)

        let records = Registry.all(in: context)
        #expect(records.count == 2)
        #expect(records.contains { $0.field == .sets && $0.toValue == "4 sets" })
        #expect(records.contains { $0.field == .rest && $0.fromValue == "1m 30s" && $0.toValue == "2m" })
    }

    @Test func recordsAreWrittenInTheUsersUnits() throws {
        let context = try makeContext()
        Registry.weightChanged(item: makeItem(), from: 70, to: 72.5, units: .lb, in: context)

        let record = try #require(Registry.all(in: context).first)
        #expect(record.fromValue == "154.5 lb")
        #expect(record.toValue == "160 lb")
    }

    @Test func removingAnExerciseAppendsRatherThanDeletes() throws {
        let context = try makeContext()
        let item = makeItem()

        Registry.weightChanged(item: item, from: 70, to: 72.5, units: .kg, in: context)
        Registry.exerciseRemoved(
            exerciseID: item.exerciseID,
            exerciseName: item.exerciseName,
            dayTitle: "Push",
            in: context
        )

        let records = Registry.all(in: context)
        #expect(records.count == 2)
        // The weight history survives the removal.
        #expect(records.contains { $0.field == .weight })
        #expect(records.contains { $0.field == .removed && $0.toValue == "Removed from Push" })
    }

    @Test func progressionFlagIsRecordedBothWays() throws {
        let context = try makeContext()
        let item = makeItem()

        Registry.progressionToggled(item: item, armed: true, targetKg: 72.5, units: .kg, in: context)
        Registry.progressionToggled(item: item, armed: false, targetKg: 72.5, units: .kg, in: context)

        let records = Registry.all(in: context)
        #expect(records.count == 2)
        #expect(records.contains { $0.toValue == "Armed · 72.5 kg next" })
        #expect(records.contains { $0.field == .progression && $0.toValue == "Off" })
    }

    @Test func tierChangesAreRecorded() throws {
        let context = try makeContext()
        Registry.tierChanged(
            exerciseID: "bench-press",
            exerciseName: "Bench Press",
            from: "Intermediate III",
            to: "Advanced I",
            promoted: true,
            in: context
        )

        let record = try #require(Registry.all(in: context).first)
        #expect(record.field == .tier)
        #expect(record.summary == "Tier · Intermediate III → Advanced I")
    }

    @Test func perExerciseFilterExcludesOtherExercises() throws {
        let context = try makeContext()
        let bench = makeItem()
        let squat = PlanItem(order: 2, exerciseID: "back-squat", exerciseName: "Back Squat", workingWeightKg: 100)

        Registry.weightChanged(item: bench, from: 70, to: 72.5, units: .kg, in: context)
        Registry.weightChanged(item: squat, from: 100, to: 105, units: .kg, in: context)
        try context.save()

        let benchOnly = Registry.forExercise("bench-press", in: context)
        #expect(benchOnly.count == 1)
        #expect(benchOnly.first?.exerciseName == "Bench Press")
    }

    @Test func newestRecordIsTheMostRecentOne() throws {
        let context = try makeContext()
        let item = makeItem()

        Registry.record(.weight, exerciseID: item.exerciseID, exerciseName: item.exerciseName,
                        from: "60 kg", to: "65 kg", direction: .up, in: context)
        let later = Registry.record(.weight, exerciseID: item.exerciseID, exerciseName: item.exerciseName,
                                    from: "65 kg", to: "70 kg", direction: .up, in: context)
        later.date = .now.addingTimeInterval(60)
        try context.save()

        #expect(Registry.newest(in: context)?.toValue == "70 kg")
    }
}
