//
//  ExerciseStandards.swift
//  Gym Traker
//
//  Gives every exercise a tier, not just the big four.
//
//  Published bodyweight-relative standards exist for the main barbell lifts.
//  For everything else the honest move is to derive: each exercise is pinned to
//  the closest anchor lift and carries a coefficient — how much of that lift a
//  trained person handles on it. An incline press sits at roughly 0.78 of a flat
//  bench, a strict barbell curl at roughly 0.40, and so on. The thresholds are
//  then the anchor's thresholds scaled by that coefficient.
//
//  Sources for the ratios are the same strength-standards literature behind
//  design/RANKING.md, plus the commonly published incline-to-flat (0.70–0.85)
//  and curl-to-bench (0.35–0.45) ranges. They are estimates, and the app says
//  so — nothing here is presented as a measurement.
//

import Foundation

enum ExerciseStandards {

    /// An exercise scored against an anchor lift, scaled.
    struct Assignment: Equatable {
        let anchor: RankAnchor
        /// Fraction of the anchor lift this exercise is expected to move.
        let coefficient: Double
    }

    // MARK: - Name-pattern rules

    /// Ordered: the first rule whose terms all appear in the name wins, so the
    /// specific ones sit above the general ones.
    private struct Rule {
        let terms: [String]
        let anchor: RankAnchor
        let coefficient: Double
    }

    private static let rules: [Rule] = [
        // — Pressing —
        Rule(terms: ["decline", "bench press"], anchor: .bench, coefficient: 1.02),
        Rule(terms: ["close-grip", "bench"], anchor: .bench, coefficient: 0.85),
        Rule(terms: ["close grip", "bench"], anchor: .bench, coefficient: 0.85),
        Rule(terms: ["incline", "bench press"], anchor: .bench, coefficient: 0.78),
        Rule(terms: ["incline", "press"], anchor: .bench, coefficient: 0.70),
        Rule(terms: ["dumbbell", "bench press"], anchor: .bench, coefficient: 0.80),
        Rule(terms: ["machine", "bench"], anchor: .bench, coefficient: 0.95),
        Rule(terms: ["bench press"], anchor: .bench, coefficient: 1.0),
        Rule(terms: ["chest press"], anchor: .bench, coefficient: 0.90),
        Rule(terms: ["chest", "fly"], anchor: .bench, coefficient: 0.38),
        Rule(terms: ["pec deck"], anchor: .bench, coefficient: 0.42),
        Rule(terms: ["pullover"], anchor: .bench, coefficient: 0.38),

        // — Overhead —
        Rule(terms: ["military press"], anchor: .ohp, coefficient: 1.0),
        Rule(terms: ["shoulder press"], anchor: .ohp, coefficient: 0.95),
        Rule(terms: ["push press"], anchor: .ohp, coefficient: 1.15),
        Rule(terms: ["arnold press"], anchor: .ohp, coefficient: 0.75),
        Rule(terms: ["lateral raise"], anchor: .ohp, coefficient: 0.22),
        Rule(terms: ["lateral"], anchor: .ohp, coefficient: 0.22),
        Rule(terms: ["front raise"], anchor: .ohp, coefficient: 0.25),
        Rule(terms: ["rear delt"], anchor: .ohp, coefficient: 0.22),
        Rule(terms: ["upright row"], anchor: .ohp, coefficient: 0.55),
        Rule(terms: ["shrug"], anchor: .deadlift, coefficient: 0.65),

        // — Pulling —
        Rule(terms: ["t-bar"], anchor: .row, coefficient: 1.0),
        Rule(terms: ["bent over", "row"], anchor: .row, coefficient: 1.0),
        Rule(terms: ["seated", "row"], anchor: .row, coefficient: 0.95),
        Rule(terms: ["one arm", "row"], anchor: .row, coefficient: 0.45),
        Rule(terms: ["one-arm", "row"], anchor: .row, coefficient: 0.45),
        Rule(terms: ["pull down"], anchor: .row, coefficient: 0.85),
        Rule(terms: ["pulldown"], anchor: .row, coefficient: 0.85),
        Rule(terms: ["row"], anchor: .row, coefficient: 0.90),
        Rule(terms: ["face pull"], anchor: .row, coefficient: 0.30),

        // — Arms —
        Rule(terms: ["preacher"], anchor: .bench, coefficient: 0.32),
        Rule(terms: ["hammer curl"], anchor: .bench, coefficient: 0.34),
        Rule(terms: ["curl"], anchor: .bench, coefficient: 0.40),
        Rule(terms: ["skull"], anchor: .bench, coefficient: 0.35),
        Rule(terms: ["triceps extension"], anchor: .bench, coefficient: 0.33),
        Rule(terms: ["triceps press"], anchor: .bench, coefficient: 0.45),
        Rule(terms: ["pushdown"], anchor: .bench, coefficient: 0.42),
        Rule(terms: ["kickback"], anchor: .bench, coefficient: 0.18),
        Rule(terms: ["wrist"], anchor: .bench, coefficient: 0.20),

        // — Lower body —
        Rule(terms: ["front squat"], anchor: .squat, coefficient: 0.82),
        Rule(terms: ["hack squat"], anchor: .squat, coefficient: 1.0),
        Rule(terms: ["split squat"], anchor: .squat, coefficient: 0.45),
        Rule(terms: ["squat"], anchor: .squat, coefficient: 1.0),
        Rule(terms: ["leg press"], anchor: .squat, coefficient: 1.8),
        Rule(terms: ["leg extension"], anchor: .squat, coefficient: 0.45),
        Rule(terms: ["leg curl"], anchor: .squat, coefficient: 0.35),
        Rule(terms: ["calf"], anchor: .squat, coefficient: 0.75),
        Rule(terms: ["lunge"], anchor: .squat, coefficient: 0.50),
        Rule(terms: ["step up"], anchor: .squat, coefficient: 0.45),
        Rule(terms: ["romanian"], anchor: .deadlift, coefficient: 0.80),
        Rule(terms: ["stiff", "leg"], anchor: .deadlift, coefficient: 0.78),
        Rule(terms: ["good morning"], anchor: .deadlift, coefficient: 0.55),
        Rule(terms: ["hip thrust"], anchor: .deadlift, coefficient: 0.95),
        Rule(terms: ["hip raise"], anchor: .deadlift, coefficient: 0.60),
        Rule(terms: ["hyperextension"], anchor: .deadlift, coefficient: 0.30),
        Rule(terms: ["dead lift"], anchor: .deadlift, coefficient: 1.0),
        Rule(terms: ["deadlift"], anchor: .deadlift, coefficient: 1.0),
        Rule(terms: ["clean"], anchor: .deadlift, coefficient: 0.65),
        Rule(terms: ["snatch"], anchor: .deadlift, coefficient: 0.50),
    ]

    /// Muscle-group fallback for anything the rules do not name.
    private static func fallback(for muscle: Muscle) -> Assignment {
        switch muscle {
        case .chest: Assignment(anchor: .bench, coefficient: 0.55)
        case .back: Assignment(anchor: .row, coefficient: 0.60)
        case .shoulders: Assignment(anchor: .ohp, coefficient: 0.45)
        case .arms: Assignment(anchor: .bench, coefficient: 0.35)
        case .legs: Assignment(anchor: .squat, coefficient: 0.55)
        case .glutes: Assignment(anchor: .deadlift, coefficient: 0.60)
        case .core, .mobility, .cardio, .fullBody: Assignment(anchor: .bw, coefficient: 1.0)
        }
    }

    // MARK: - Resolution

    /// Works out which anchor an exercise is scored against, and how much of it
    /// counts. Bodyweight movements keep their rep-based scoring.
    static func assignment(name: String, muscle: Muscle, equipment: Equipment,
                           declaredAnchor: RankAnchor?) -> Assignment {
        // A bodyweight exercise is ranked on reps, not load.
        if declaredAnchor == .bw || equipment == .bodyweight {
            return Assignment(anchor: .bw, coefficient: 1.0)
        }

        let lowered = name.lowercased()
        for rule in rules where rule.terms.allSatisfy({ lowered.contains($0) }) {
            return Assignment(anchor: rule.anchor, coefficient: rule.coefficient)
        }

        // A declared anchor with no matching rule is the lift itself.
        if let declaredAnchor, declaredAnchor != .bw {
            return Assignment(anchor: declaredAnchor, coefficient: 1.0)
        }
        return fallback(for: muscle)
    }

    static func assignment(for exercise: Exercise) -> Assignment {
        assignment(
            name: exercise.name,
            muscle: exercise.muscleGroup,
            equipment: exercise.equipment,
            declaredAnchor: exercise.rankAnchor
        )
    }
}
