//
//  Tier.swift
//  Gym Traker
//
//  The five rungs of the ladder. Tier names use strength terminology so the
//  numbers stay legible to anyone who has read a standards table.
//

import SwiftUI

enum Tier: Int, CaseIterable, Identifiable, Codable {
    case beginner = 0
    case novice = 1
    case intermediate = 2
    case advanced = 3
    case elite = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .novice: "Novice"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        case .elite: "Elite"
        }
    }

    /// Ladder copy for the You screen.
    var note: String {
        switch self {
        case .beginner: "First weeks under the bar"
        case .novice: "3–6 months of steady work"
        case .intermediate: "1–2 years · bodyweight bench"
        case .advanced: "Several years of focus"
        case .elite: "Top 5 % of natural lifters"
        }
    }

    var scoreRange: ClosedRange<Int> {
        let lower = rawValue * 20
        return lower...(lower + 20)
    }

    var scoreRangeLabel: String { "\(rawValue * 20)–\(rawValue * 20 + 20)" }

    /// Beginner neutral, Novice cyan, Intermediate violet, Advanced amber,
    /// Elite magenta.
    var tint: Color {
        switch self {
        case .beginner: Color(red: 0.60, green: 0.62, blue: 0.68)
        case .novice: Color(red: 0.24, green: 0.74, blue: 0.82)
        case .intermediate: Color(red: 0.55, green: 0.44, blue: 0.95)
        case .advanced: Color(red: 0.95, green: 0.70, blue: 0.25)
        case .elite: Color(red: 0.93, green: 0.35, blue: 0.72)
        }
    }

    static func forScore(_ score: Double) -> Tier {
        Tier(rawValue: min(4, max(0, Int(score / 20)))) ?? .beginner
    }
}

/// One scored lift, or the global profile level.
struct RankResult: Hashable {
    let score: Double
    let tier: Tier
    /// 1, 2 or 3 — the thirds inside a tier, shown as I / II / III.
    let division: Int
    /// Estimated 1RM in kg. For bodyweight anchors this carries effective reps.
    let value: Double
    /// The value that would open the next tier, nil at Elite.
    let nextThreshold: Double?
    /// True when the anchor is scored on reps rather than load.
    let isRepBased: Bool

    var divisionNumeral: String {
        switch division {
        case 1: "I"
        case 2: "II"
        default: "III"
        }
    }

    /// "Intermediate I"
    var label: String { "\(tier.displayName) \(divisionNumeral)" }

    /// 0…1 progress through the current tier, for the bars and the ring.
    var progressInTier: Double {
        let lower = Double(tier.rawValue) * 20
        return min(1, max(0, (score - lower) / 20))
    }
}
