//
//  MuscleGroup.swift
//  Gym Traker
//
//  The eleven groups the app ranks and colours by.
//
//  The archive's own `primaryMuscle` is coarser than that — "Arms" covers a
//  hundred exercises, biceps and triceps together, and "Legs" covers quads,
//  hamstrings and calves as one. That is fine for a filter chip and useless for
//  a rank: it cannot tell you that your calves are behind.
//
//  The finer group is written into the archive at build time by a classifier
//  over the exercise names, not guessed at runtime. The rules and their output
//  are in the repository, so a misfiled exercise is a data fix rather than a
//  code change.
//

import SwiftUI

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case traps, delts, chest, back, biceps, triceps
    case abs, glutes, quads, hamstrings, calves
    /// Neck work and anything the name does not place.
    case fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .traps: "Traps"
        case .delts: "Delts"
        case .chest: "Chest"
        case .back: "Back"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .abs: "Abs"
        case .glutes: "Glutes"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .calves: "Calves"
        case .fullBody: "Full body"
        }
    }

    /// Ranked groups, in the order a body reads top to bottom. `fullBody` is
    /// not one of them: it is the bucket for what has no group.
    static var ranked: [MuscleGroup] {
        [.traps, .delts, .chest, .back, .biceps, .triceps,
         .abs, .glutes, .quads, .hamstrings, .calves]
    }

    /// One hue per group, walked evenly around the wheel so no two neighbours
    /// in a list collide, at a saturation that keeps eleven of them on one
    /// screen from looking like a paint chart.
    var tint: Color {
        switch self {
        case .traps: Color(hue: 0.60, saturation: 0.62, brightness: 0.95)
        case .delts: Color(hue: 0.53, saturation: 0.62, brightness: 0.92)
        case .chest: Color(hue: 0.97, saturation: 0.58, brightness: 0.97)
        case .back: Color(hue: 0.66, saturation: 0.58, brightness: 0.97)
        case .biceps: Color(hue: 0.75, saturation: 0.55, brightness: 0.97)
        case .triceps: Color(hue: 0.82, saturation: 0.52, brightness: 0.96)
        case .abs: Color(hue: 0.13, saturation: 0.70, brightness: 0.97)
        case .glutes: Color(hue: 0.90, saturation: 0.52, brightness: 0.95)
        case .quads: Color(hue: 0.07, saturation: 0.68, brightness: 0.98)
        case .hamstrings: Color(hue: 0.02, saturation: 0.62, brightness: 0.96)
        case .calves: Color(hue: 0.45, saturation: 0.58, brightness: 0.88)
        case .fullBody: Color(hue: 0.70, saturation: 0.25, brightness: 0.85)
        }
    }

    /// Which of the coarse archive muscles this belongs under, for filters and
    /// for anything still written in the old terms.
    var coarse: Muscle {
        switch self {
        case .traps, .delts: .shoulders
        case .chest: .chest
        case .back: .back
        case .biceps, .triceps: .arms
        case .abs: .core
        case .glutes: .glutes
        case .quads, .hamstrings, .calves: .legs
        case .fullBody: .fullBody
        }
    }
}
