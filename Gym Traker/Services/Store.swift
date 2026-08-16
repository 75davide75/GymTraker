//
//  Store.swift
//  Gym Traker
//
//  Small fetch helpers shared by the feature screens, so no view has to write
//  a FetchDescriptor by hand.
//

import Foundation
import SwiftData

enum Store {

    // MARK: - Profile

    static func profile(in context: ModelContext) -> UserProfile? {
        try? context.fetch(FetchDescriptor<UserProfile>()).first
    }

    static func units(in context: ModelContext) -> Units {
        profile(in: context)?.units ?? .kg
    }

    // MARK: - Plan

    static func activePlan(in context: ModelContext) -> Plan? {
        let plans = (try? context.fetch(FetchDescriptor<Plan>())) ?? []
        return plans.first(where: \.isActive) ?? plans.first
    }

    // MARK: - Archive

    static func exercise(id: String, in context: ModelContext) -> Exercise? {
        var descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    static func allExercises(in context: ModelContext) -> [Exercise] {
        (try? context.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)]))) ?? []
    }

    // MARK: - Sessions

    static func sessions(in context: ModelContext, limit: Int? = nil) -> [WorkoutSession] {
        var descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        if let limit { descriptor.fetchLimit = limit }
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Finished sessions in the trailing four weeks — the consistency window.
    static func sessionsLast4Weeks(in context: ModelContext) -> [WorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now
        return sessions(in: context).filter { $0.isFinished && $0.startedAt >= cutoff }
    }

    /// The most recent finished entries for one exercise, oldest first, for the
    /// detail chart.
    static func history(for exerciseID: String, in context: ModelContext, limit: Int = 8) -> [SessionEntry] {
        let finished = sessions(in: context).filter(\.isFinished)
        let entries = finished.compactMap { session in
            session.orderedEntries.first { $0.exerciseID == exerciseID }
        }
        return Array(entries.prefix(limit)).reversed()
    }

    // MARK: - Ranking

    /// Scores one exercise from its best recent set. Returns nil when the
    /// exercise has no anchor or no history.
    static func rank(for exercise: Exercise, in context: ModelContext) -> RankResult? {
        guard let anchor = exercise.rankAnchor, let profile = profile(in: context) else { return nil }
        guard let best = history(for: exercise.id, in: context, limit: 1).last?.bestSet else { return nil }
        return RankingEngine.rank(
            anchor: anchor,
            weightKg: best.weightKg,
            reps: best.reps,
            lifter: profile.lifter,
            exerciseID: exercise.id
        )
    }

    /// Best score per anchor across the whole archive — feeds the global level
    /// and the per-lift bars on the You screen.
    static func anchorScores(in context: ModelContext) -> [RankAnchor: RankResult] {
        var best: [RankAnchor: RankResult] = [:]
        for exercise in allExercises(in: context) {
            guard let anchor = exercise.rankAnchor, let result = rank(for: exercise, in: context) else { continue }
            if let existing = best[anchor], existing.score >= result.score { continue }
            best[anchor] = result
        }
        return best
    }

    static func globalLevel(in context: ModelContext) -> RankResult? {
        let scores = anchorScores(in: context).mapValues(\.score)
        return RankingEngine.globalLevel(
            anchorScores: scores,
            sessionsLast4Weeks: sessionsLast4Weeks(in: context).count
        )
    }

    /// The archive exercise that best represents an anchor lift, for the You
    /// screen's per-lift rows.
    static func anchorExercise(_ anchor: RankAnchor, in context: ModelContext) -> Exercise? {
        let canonical: [RankAnchor: String] = [
            .bench: "bench-press",
            .squat: "back-squat",
            .deadlift: "conventional-deadlift",
            .ohp: "overhead-press",
            .row: "barbell-row"
        ]
        if let id = canonical[anchor], let exercise = exercise(id: id, in: context) { return exercise }
        return allExercises(in: context).first { $0.rankAnchor == anchor }
    }
}
