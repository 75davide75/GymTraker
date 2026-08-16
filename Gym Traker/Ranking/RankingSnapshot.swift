//
//  RankingSnapshot.swift
//  Gym Traker
//
//  Every rank the UI needs, computed in one pass and handed over as a value.
//
//  The previous design exposed `anchorScores` as a computed property, which
//  meant each mention inside a view body walked all 270 archive exercises and
//  ran a full session fetch for each one. A screen that mentioned it seven
//  times issued the better part of two thousand table scans on the main
//  thread, and the app stopped responding. Nothing here touches the store more
//  than a fixed handful of times, and views hold the result in state rather
//  than recomputing it while drawing.
//

import Foundation
import SwiftData

struct RankingSnapshot: Equatable {
    /// exerciseID → rank, for every exercise with an anchor and a logged set.
    var perExercise: [String: RankResult] = [:]
    /// The best rank achieved for each anchor lift.
    var perAnchor: [RankAnchor: RankResult] = [:]
    /// Which exercise earned each anchor's best rank.
    var anchorExerciseIDs: [RankAnchor: String] = [:]
    /// The profile level, or nil while fewer than two big lifts have data.
    var global: RankResult?
    var sessionsLast4Weeks: Int = 0
    /// The set that produced each exercise's rank, for the "70 kg × 8" line.
    var bestSets: [String: PerformedSet] = [:]

    static let empty = RankingSnapshot()

    func rank(for exerciseID: String) -> RankResult? { perExercise[exerciseID] }
    func bestSet(for exerciseID: String) -> PerformedSet? { bestSets[exerciseID] }
}

extension Store {

    /// Builds the whole ranking picture with a fixed number of fetches:
    /// one for the profile, one for sessions, one for the archive.
    static func rankingSnapshot(in context: ModelContext) -> RankingSnapshot {
        guard let profile = profile(in: context) else { return .empty }

        let allSessions = sessions(in: context)
        let finished = allSessions.filter(\.isFinished)

        let cutoff = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now
        let recentCount = finished.filter { $0.startedAt >= cutoff }.count

        // Newest session wins: walk newest-first and keep the first hit per
        // exercise, which is the same rule the old per-exercise lookup used.
        var latestSet: [String: PerformedSet] = [:]
        for session in finished {
            for entry in session.orderedEntries where latestSet[entry.exerciseID] == nil {
                if let best = entry.bestSet { latestSet[entry.exerciseID] = best }
            }
        }

        guard !latestSet.isEmpty else {
            return RankingSnapshot(sessionsLast4Weeks: recentCount)
        }

        let lifter = profile.lifter
        var snapshot = RankingSnapshot(sessionsLast4Weeks: recentCount)
        snapshot.bestSets = latestSet

        for exercise in allExercises(in: context) {
            guard let anchor = exercise.rankAnchor,
                  let best = latestSet[exercise.id],
                  let result = RankingEngine.rank(
                      anchor: anchor,
                      weightKg: best.weightKg,
                      reps: best.reps,
                      lifter: lifter,
                      exerciseID: exercise.id
                  )
            else { continue }

            snapshot.perExercise[exercise.id] = result
            if let existing = snapshot.perAnchor[anchor], existing.score >= result.score { continue }
            snapshot.perAnchor[anchor] = result
            snapshot.anchorExerciseIDs[anchor] = exercise.id
        }

        snapshot.global = RankingEngine.globalLevel(
            anchorScores: snapshot.perAnchor.mapValues(\.score),
            sessionsLast4Weeks: recentCount
        )
        return snapshot
    }
}

// MARK: - View plumbing

/// Keeps a snapshot in state and refreshes it when the underlying data moves,
/// so no view body ever triggers the computation itself.
@Observable
final class RankingModel {
    private(set) var snapshot: RankingSnapshot = .empty
    private var lastRefresh: Date = .distantPast

    /// Recomputes at most a few times a second; SwiftUI calls `task` and
    /// `onChange` far more often than the numbers actually move.
    @MainActor
    func refresh(in context: ModelContext, force: Bool = false) {
        if !force, Date.now.timeIntervalSince(lastRefresh) < 0.5 { return }
        lastRefresh = .now
        snapshot = Store.rankingSnapshot(in: context)
    }
}
