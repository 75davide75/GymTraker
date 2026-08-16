//
//  Registry.swift
//  Gym Traker
//
//  The only writer of ChangeRecord. Every user-visible parameter change goes
//  through one of these helpers, in the same transaction as the change itself,
//  so the log can never disagree with the data.
//
//  Nothing here updates or deletes. Removing a plan item writes a `removed`
//  record; the history of an exercise outlives the exercise.
//

import Foundation
import SwiftData

enum Registry {

    // MARK: - Core

    @discardableResult
    static func record(
        _ field: ChangeField,
        exerciseID: String,
        exerciseName: String,
        from: String,
        to: String,
        direction: ChangeDirection,
        sessionUUID: UUID? = nil,
        in context: ModelContext
    ) -> ChangeRecord {
        let entry = ChangeRecord(
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            field: field,
            fromValue: from,
            toValue: to,
            direction: direction,
            sessionUUID: sessionUUID
        )
        context.insert(entry)
        return entry
    }

    // MARK: - Typed helpers

    /// Working weight moved. Writes nothing when the value is unchanged, so a
    /// stepper tapped up and back down leaves one pair of records, not noise.
    @discardableResult
    static func weightChanged(
        item: PlanItem,
        from oldKg: Double,
        to newKg: Double,
        units: Units,
        sessionUUID: UUID? = nil,
        in context: ModelContext
    ) -> ChangeRecord? {
        guard abs(oldKg - newKg) > 0.001 else { return nil }
        return record(
            .weight,
            exerciseID: item.exerciseID,
            exerciseName: item.exerciseName,
            from: UnitFormatter.weight(oldKg, in: units),
            to: UnitFormatter.weight(newKg, in: units),
            direction: newKg > oldKg ? .up : .down,
            sessionUUID: sessionUUID,
            in: context
        )
    }

    /// A single set's rep target moved. The set index is part of the record so
    /// "Set 3 went from 6 to 8" survives in the log.
    @discardableResult
    static func repsChanged(
        item: PlanItem,
        setIndex: Int,
        from oldReps: Int,
        to newReps: Int,
        sessionUUID: UUID? = nil,
        in context: ModelContext
    ) -> ChangeRecord? {
        guard oldReps != newReps else { return nil }
        return record(
            .reps,
            exerciseID: item.exerciseID,
            exerciseName: item.exerciseName,
            from: "Set \(setIndex + 1) · \(oldReps) reps",
            to: "Set \(setIndex + 1) · \(newReps) reps",
            direction: newReps > oldReps ? .up : .down,
            sessionUUID: sessionUUID,
            in: context
        )
    }

    @discardableResult
    static func setsChanged(
        item: PlanItem,
        from oldCount: Int,
        to newCount: Int,
        sessionUUID: UUID? = nil,
        in context: ModelContext
    ) -> ChangeRecord? {
        guard oldCount != newCount else { return nil }
        return record(
            .sets,
            exerciseID: item.exerciseID,
            exerciseName: item.exerciseName,
            from: "\(oldCount) sets",
            to: "\(newCount) sets",
            direction: newCount > oldCount ? .up : .down,
            sessionUUID: sessionUUID,
            in: context
        )
    }

    /// The "remind me to go up next time" flag. Recorded because the whole
    /// point of the flag is to be remembered.
    @discardableResult
    static func progressionToggled(
        item: PlanItem,
        armed: Bool,
        targetKg: Double,
        units: Units,
        in context: ModelContext
    ) -> ChangeRecord {
        record(
            .progression,
            exerciseID: item.exerciseID,
            exerciseName: item.exerciseName,
            from: armed ? "Off" : "Armed",
            to: armed ? "Armed · \(UnitFormatter.weight(targetKg, in: units)) next" : "Off",
            direction: armed ? .up : .neutral,
            in: context
        )
    }

    /// Tier movement — this is what answers "why did my rank move".
    @discardableResult
    static func tierChanged(
        exerciseID: String,
        exerciseName: String,
        from oldLabel: String,
        to newLabel: String,
        promoted: Bool,
        sessionUUID: UUID? = nil,
        in context: ModelContext
    ) -> ChangeRecord {
        record(
            .tier,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            from: oldLabel,
            to: newLabel,
            direction: promoted ? .up : .down,
            sessionUUID: sessionUUID,
            in: context
        )
    }

    @discardableResult
    static func exerciseAdded(
        exerciseID: String,
        exerciseName: String,
        dayTitle: String,
        in context: ModelContext
    ) -> ChangeRecord {
        record(
            .added,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            from: "",
            to: "Added to \(dayTitle)",
            direction: .neutral,
            in: context
        )
    }

    @discardableResult
    static func exerciseRemoved(
        exerciseID: String,
        exerciseName: String,
        dayTitle: String,
        in context: ModelContext
    ) -> ChangeRecord {
        record(
            .removed,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            from: "",
            to: "Removed from \(dayTitle)",
            direction: .neutral,
            in: context
        )
    }

    // MARK: - Reading

    static func all(in context: ModelContext, limit: Int? = nil) -> [ChangeRecord] {
        var descriptor = FetchDescriptor<ChangeRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        if let limit { descriptor.fetchLimit = limit }
        return (try? context.fetch(descriptor)) ?? []
    }

    static func newest(in context: ModelContext) -> ChangeRecord? {
        all(in: context, limit: 1).first
    }

    static func forExercise(_ exerciseID: String, in context: ModelContext, limit: Int? = nil) -> [ChangeRecord] {
        var descriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { $0.exerciseID == exerciseID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }
        return (try? context.fetch(descriptor)) ?? []
    }
}
