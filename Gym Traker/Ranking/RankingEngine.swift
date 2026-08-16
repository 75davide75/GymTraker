//
//  RankingEngine.swift
//  Gym Traker
//
//  Pure functions. Feed it a lift and a lifter, get a tier back. The maths is
//  documented in design/RANKING.md §3 and §4 and pinned by unit tests.
//

import Foundation

enum RankingEngine {

    /// Epley estimate, valid to roughly twelve reps. Reps are capped at ten so
    /// a long endurance set cannot inflate a strength tier.
    static func e1RM(weightKg: Double, reps: Int) -> Double {
        weightKg * (1 + Double(min(max(reps, 0), 10)) / 30)
    }

    // MARK: - Scoring

    /// Piecewise-linear 0–100 score against a five-step threshold table.
    /// Meeting a standard exactly lands at the bottom of that tier.
    static func score(value: Double, thresholds th: [Double]) -> Double {
        guard th.count == 5, th[0] > 0 else { return 0 }

        if value <= th[0] {
            return max(0, value / th[0] * 20)
        }
        for i in 0..<4 where value >= th[i] && value < th[i + 1] {
            let span = th[i + 1] - th[i]
            guard span > 0 else { return Double(i) * 20 }
            return Double(i) * 20 + (value - th[i]) / span * 20
        }
        // Elite band: 100 at 25 % beyond the Elite threshold.
        return min(100, 80 + (value - th[4]) / th[4] * 80)
    }

    /// Wraps a raw score into a full result. Used by the global level and by
    /// the division tests.
    static func result(forScore score: Double, value: Double = 0, nextThreshold: Double? = nil, isRepBased: Bool = false) -> RankResult? {
        guard score.isFinite else { return nil }
        let clamped = min(100, max(0, score))
        let tier = Tier.forScore(clamped)
        return RankResult(
            score: clamped,
            tier: tier,
            division: division(forScore: clamped, tier: tier),
            value: value,
            nextThreshold: nextThreshold,
            isRepBased: isRepBased
        )
    }

    /// I / II / III over the tier's inner thirds.
    private static func division(forScore score: Double, tier: Tier) -> Int {
        let progress = (score - Double(tier.rawValue) * 20) / 20
        if progress >= 1 { return 3 }
        return min(3, max(1, Int(progress * 3) + 1))
    }

    // MARK: - Per-exercise rank

    /// Scores one lift. Returns nil for exercises with no anchor — accessory
    /// work is tracked and charted but never given a tier.
    static func rank(
        anchor: RankAnchor?,
        weightKg: Double,
        reps: Int,
        lifter: LifterProfile,
        exerciseID: String? = nil,
        tables: RankingTables = .shared
    ) -> RankResult? {
        guard let anchor else { return nil }

        if anchor == .bw {
            return rankBodyweight(loadKg: weightKg, reps: reps, lifter: lifter, exerciseID: exerciseID, tables: tables)
        }

        guard let thresholds = tables.thresholds(anchor: anchor, lifter: lifter) else { return nil }
        let value = e1RM(weightKg: weightKg, reps: reps)
        let raw = score(value: value, thresholds: thresholds)
        return result(
            forScore: raw,
            value: value,
            nextThreshold: nextThreshold(after: value, in: thresholds),
            isRepBased: false
        )
    }

    /// Bodyweight work is ranked on reps. Added load converts to effective reps
    /// so a weighted pull-up still moves the tier.
    private static func rankBodyweight(
        loadKg: Double,
        reps: Int,
        lifter: LifterProfile,
        exerciseID: String?,
        tables: RankingTables
    ) -> RankResult? {
        let thresholds = tables.bodyweightThresholds(exerciseID: exerciseID, sex: lifter.sex)
        let bodyweight = max(1, lifter.bodyweightKg)
        let effective = tables.isTimeBased(exerciseID: exerciseID)
            ? Double(reps)  // seconds held
            : Double(reps) * (bodyweight + max(0, loadKg)) / bodyweight
        let raw = score(value: effective, thresholds: thresholds)
        return result(
            forScore: raw,
            value: effective,
            nextThreshold: nextThreshold(after: effective, in: thresholds),
            isRepBased: true
        )
    }

    /// The value that would open the next tier, nil once past Elite.
    private static func nextThreshold(after value: Double, in thresholds: [Double]) -> Double? {
        thresholds.first { $0 > value }
    }

    // MARK: - Global level

    /// Mean of the four big lifts that have data, plus a consistency bonus.
    /// Fewer than two trained lifts reads as Unranked.
    static func globalLevel(anchorScores: [RankAnchor: Double], sessionsLast4Weeks: Int) -> RankResult? {
        let bigFour: [RankAnchor] = [.squat, .bench, .deadlift, .ohp]
        let scores = bigFour.compactMap { anchorScores[$0] }
        guard scores.count >= 2 else { return nil }

        let base = scores.reduce(0, +) / Double(scores.count)
        let consistency = min(5, Double(max(0, sessionsLast4Weeks)) / 16 * 5)
        return result(forScore: min(100, base + consistency))
    }

    /// Convenience for the You screen: how many sessions still separate the
    /// lifter from the full consistency bonus.
    static func sessionsToFullConsistency(_ sessionsLast4Weeks: Int) -> Int {
        max(0, 16 - sessionsLast4Weeks)
    }
}
