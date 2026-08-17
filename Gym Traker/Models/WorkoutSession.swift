//
//  WorkoutSession.swift
//  Gym Traker
//
//  What actually happened, kept independent of the plan's current scheme so
//  history never changes retroactively.
//

import Foundation
import SwiftData

struct PerformedSet: Codable, Hashable, Identifiable {
    var id = UUID()
    var reps: Int
    var weightKg: Double
    var targetReps: Int
    var completedAt: Date?
    var isWarmup: Bool

    init(reps: Int, weightKg: Double, targetReps: Int, completedAt: Date? = nil, isWarmup: Bool = false) {
        self.id = UUID()
        self.reps = reps
        self.weightKg = weightKg
        self.targetReps = targetReps
        self.completedAt = completedAt
        self.isWarmup = isWarmup
    }

    var isCompleted: Bool { completedAt != nil }
    var volumeKg: Double { weightKg * Double(reps) }
    var metTarget: Bool { reps >= targetReps }
}

@Model
final class WorkoutSession {
    var uuid: UUID = UUID()
    var startedAt: Date = Date.now
    var endedAt: Date?
    var planDayLetter: String = "A"
    var planDayTitle: String = "Workout"
    /// Set when the session came from Health rather than being logged here —
    /// an Apple Watch workout, typically. Keeps imports from duplicating.
    var healthKitUUID: UUID?
    var sourceName: String?

    /// What Health knows and the app cannot work out for itself. All optional:
    /// a session logged in the app has none of it, and an imported one has
    /// whatever the recording device bothered to measure.
    ///
    /// `energyKcal` was already being read at import and then thrown away.
    var energyKcal: Double?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var distanceMeters: Double?
    /// "Traditional strength training", "Running" — the workout's own kind.
    var activityName: String?

    @Relationship(deleteRule: .cascade, inverse: \SessionEntry.session)
    var entries: [SessionEntry]? = []

    init(planDayLetter: String, planDayTitle: String) {
        self.uuid = UUID()
        self.startedAt = .now
        self.planDayLetter = planDayLetter
        self.planDayTitle = planDayTitle
        self.entries = []
    }

    var orderedEntries: [SessionEntry] {
        (entries ?? []).sorted { $0.order < $1.order }
    }

    var completedSets: [PerformedSet] {
        orderedEntries.flatMap(\.sets).filter(\.isCompleted)
    }

    var totalVolumeKg: Double {
        completedSets.reduce(0) { $0 + $1.volumeKg }
    }

    var setCount: Int { completedSets.count }

    var duration: TimeInterval {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    var isFinished: Bool { endedAt != nil }

    /// True for rows that arrived from Health and carry no set data.
    var isImported: Bool { healthKitUUID != nil }
}

@Model
final class SessionEntry {
    var order: Int = 1
    var exerciseID: String = ""
    /// Denormalised so history survives archive edits.
    var exerciseName: String = ""
    var restSeconds: Int = 90
    var sets: [PerformedSet] = []
    var session: WorkoutSession?

    init(order: Int, exerciseID: String, exerciseName: String, restSeconds: Int, sets: [PerformedSet] = []) {
        self.order = order
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.restSeconds = restSeconds
        self.sets = sets
    }

    var completedSets: [PerformedSet] { sets.filter(\.isCompleted) }

    /// Epley, capped at 10 reps for scoring stability.
    var bestE1RM: Double {
        completedSets.map { $0.weightKg * (1 + Double(min($0.reps, 10)) / 30) }.max() ?? 0
    }

    /// The completed set with the highest estimated 1RM — what the ranking scores.
    var bestSet: PerformedSet? {
        completedSets.max { lhs, rhs in
            lhs.weightKg * (1 + Double(min(lhs.reps, 10)) / 30) < rhs.weightKg * (1 + Double(min(rhs.reps, 10)) / 30)
        }
    }

    var topWeightKg: Double { completedSets.map(\.weightKg).max() ?? 0 }

    var volumeKg: Double { completedSets.reduce(0) { $0 + $1.volumeKg } }

    /// True when every completed set reached its target — the trigger for an
    /// automatic weight suggestion.
    var allSetsMetTarget: Bool {
        let done = completedSets
        return !done.isEmpty && done.allSatisfy(\.metTarget)
    }
}
