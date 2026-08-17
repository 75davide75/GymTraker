//
//  BackupTests.swift
//  Gym TrakerTests
//
//  A backup is only a backup if it comes back. These export a populated store,
//  wipe it, restore into a fresh one and compare — the bug worth catching is a
//  field added to a model and never added to the archive, which loses data
//  silently and only at the moment someone needs it most.
//

import Testing
import Foundation
import SwiftData
@testable import Gym_Traker

@MainActor
struct BackupTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: UserProfile.self, Exercise.self, Plan.self, PlanDay.self,
            PlanItem.self, WorkoutSession.self, SessionEntry.self, ChangeRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// One of everything, with the fields that a lazy archive would drop:
    /// height, avatar, appearance, the session's own identifiers.
    private func populate(_ context: ModelContext) {
        let profile = UserProfile(name: "Davide", sex: .male, birthYear: 1990,
                                  bodyweightKg: 78.5, units: .kg)
        profile.heightCm = 181
        profile.avatarData = Data([0x01, 0x02, 0x03])
        profile.appearance = .light
        profile.experience = .intermediate
        profile.restAlert = .hapticsOnly
        profile.celebratedPromotions = ["bench-press:3"]
        profile.bodyweightHistory = [BodyweightEntry(date: .now, kg: 78.5)]
        context.insert(profile)

        let custom = Exercise(id: "my-lift", name: "My Lift", primaryMuscle: "Chest",
                              equipment: .dumbbell, isCustom: true, notes: "elbows in")
        context.insert(custom)

        let plan = Plan(name: "Test plan")
        plan.weekAssignmentsRaw = ["A", "", "B", "", "A", "", ""]
        context.insert(plan)
        let day = PlanDay(letter: "A", title: "Push", order: 0)
        day.plan = plan
        context.insert(day)
        let item = PlanItem(
            order: 1,
            exerciseID: "my-lift",
            exerciseName: "My Lift",
            targetSets: [SetTarget(reps: 8), SetTarget(reps: 6), SetTarget(reps: 5)],
            workingWeightKg: 42.5,
            stepKg: 0.5,
            restSeconds: 75
        )
        item.progressionArmed = true
        item.day = day
        context.insert(item)

        let session = WorkoutSession(planDayLetter: "A", planDayTitle: "Push")
        session.endedAt = session.startedAt.addingTimeInterval(3600)
        session.sourceName = "Watch"
        session.energyKcal = 412
        session.averageHeartRate = 131
        session.maxHeartRate = 168
        session.distanceMeters = 1450
        session.activityName = "Strength training"
        context.insert(session)
        let entry = SessionEntry(order: 1, exerciseID: "my-lift", exerciseName: "My Lift",
                                 restSeconds: 75,
                                 sets: [PerformedSet(reps: 8, weightKg: 42.5, targetReps: 8, completedAt: .now)])
        entry.session = session
        context.insert(entry)

        context.insert(ChangeRecord(exerciseID: "my-lift", exerciseName: "My Lift",
                                    field: .weight, fromValue: "40", toValue: "42.5",
                                    direction: .up))
        try? context.save()
    }

    @Test func aBackupRestoresIntoAnEmptyStore() throws {
        let source = ModelContext(try makeContainer())
        populate(source)

        let data = try Backup.encode(Backup.archive(from: source))

        let target = ModelContext(try makeContainer())
        let summary = try Backup.restore(try Backup.decode(data), into: target)

        #expect(summary.hasProfile)
        #expect(summary.plans == 1)
        #expect(summary.sessions == 1)
        #expect(summary.records == 1)

        let profile = try #require(Store.profile(in: target))
        #expect(profile.name == "Davide")
        #expect(profile.heightCm == 181)
        #expect(profile.avatarData == Data([0x01, 0x02, 0x03]))
        #expect(profile.appearance == .light)
        #expect(profile.experience == .intermediate)
        #expect(profile.restAlert == .hapticsOnly)
        #expect(profile.celebratedPromotions == ["bench-press:3"])
        #expect(profile.bodyweightHistory.count == 1)

        let plan = try #require(try target.fetch(FetchDescriptor<Plan>()).first)
        #expect(plan.weekAssignmentsRaw == ["A", "", "B", "", "A", "", ""])
        let item = try #require(plan.orderedDays.first?.orderedItems.first)
        // The three uneven targets are the whole point of the data model.
        #expect(item.targetSets.map(\.reps) == [8, 6, 5])
        #expect(item.stepKg == 0.5)
        #expect(item.progressionArmed)

        let restored = try #require(Store.sessions(in: target).first)
        #expect(restored.sourceName == "Watch")
        // Everything Health told us, which the import used to drop on the floor.
        #expect(restored.energyKcal == 412)
        #expect(restored.averageHeartRate == 131)
        #expect(restored.maxHeartRate == 168)
        #expect(restored.distanceMeters == 1450)
        #expect(restored.activityName == "Strength training")
        #expect(restored.orderedEntries.first?.sets.first?.weightKg == 42.5)

        let custom = try #require(Store.allExercises(in: target).first { $0.id == "my-lift" })
        #expect(custom.isCustom)
        #expect(custom.notes == "elbows in")
    }

    /// The session UUID is what ties a workout to the copy Health already
    /// holds. Lose it and a restore re-imports every workout as a duplicate.
    @Test func sessionIdentityIsPreserved() throws {
        let source = ModelContext(try makeContainer())
        populate(source)
        let originalUUID = try #require(Store.sessions(in: source).first).uuid

        let data = try Backup.encode(Backup.archive(from: source))
        let target = ModelContext(try makeContainer())
        try Backup.restore(try Backup.decode(data), into: target)

        #expect(Store.sessions(in: target).first?.uuid == originalUUID)
    }

    @Test func restoringReplacesRatherThanAppends() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        populate(context)

        let data = try Backup.encode(Backup.archive(from: context))
        try Backup.restore(try Backup.decode(data), into: context)

        #expect(try context.fetch(FetchDescriptor<Plan>()).count == 1)
        #expect(Store.sessions(in: context).count == 1)
        #expect(Registry.all(in: context).count == 1)
        #expect(try context.fetch(FetchDescriptor<UserProfile>()).count == 1)
    }

    @Test func anythingElseIsRejectedRatherThanHalfRead() throws {
        #expect(throws: Backup.Failure.self) {
            try Backup.decode(Data("{\"hello\":\"world\"}".utf8))
        }
    }
}
