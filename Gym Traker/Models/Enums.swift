//
//  Enums.swift
//  Gym Traker
//
//  Shared vocabulary for the whole app. Every raw value that reaches SwiftData
//  is a String so the store stays readable and migration-friendly.
//

import Foundation
import SwiftUI

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        }
    }
}

enum Units: String, Codable, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var displayName: String { rawValue }
    /// Multiplier applied to a kilogram value to reach this unit.
    var factor: Double {
        switch self {
        case .kg: 1
        case .lb: 2.20462
        }
    }
}

enum Appearance: String, Codable, CaseIterable, Identifiable {
    case dark, light, system
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        case .system: "System"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
}

/// How an exercise is measured. Drives which controls the session screen shows.
enum Tracking: String, Codable, CaseIterable {
    case weightReps        // barbell/dumbbell/machine work
    case repsOptionalLoad  // bodyweight, optionally weighted
    case time              // planks, holds
    case timeDistance      // cardio
}

/// The lift an exercise is ranked against. `nil` means the exercise is tracked
/// but never contributes a tier, which keeps the ladder meaningful.
enum RankAnchor: String, Codable, CaseIterable, Identifiable {
    case bench, squat, deadlift, ohp, row, bw
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .bench: "Bench press"
        case .squat: "Back squat"
        case .deadlift: "Deadlift"
        case .ohp: "Overhead press"
        case .row: "Barbell row"
        case .bw: "Bodyweight"
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case cardio = "Cardio"
    case mobility = "Mobility"

    var id: String { rawValue }

    /// The glyph primitive this equipment draws with.
    var glyphShape: String {
        switch self {
        case .barbell: "bar"
        case .dumbbell: "dumbbell"
        case .machine: "frame"
        case .cable: "cable"
        case .bodyweight: "ring"
        case .kettlebell: "bell"
        case .cardio: "wave"
        case .mobility: "arc"
        }
    }

    var glyphHue: Int {
        switch self {
        case .barbell: 268
        case .dumbbell: 200
        case .machine: 260
        case .cable: 150
        case .bodyweight: 40
        case .kettlebell: 20
        case .cardio: 330
        case .mobility: 100
        }
    }

    /// Default stepper increment in kilograms.
    var defaultStepKg: Double {
        switch self {
        case .barbell: 2.5
        case .dumbbell, .cable: 2
        case .machine: 5
        case .kettlebell: 4
        case .bodyweight, .cardio, .mobility: 1
        }
    }
}

enum Muscle: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case glutes = "Glutes"
    case core = "Core"
    case fullBody = "Full body"
    case cardio = "Cardio"
    case mobility = "Mobility"
    var id: String { rawValue }
}

/// Every parameter whose change is written to the registry.
enum ChangeField: String, Codable, CaseIterable, Identifiable {
    case weight, reps, sets, rest, progression, tier, added, removed
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .weight: "Weight"
        case .reps: "Reps"
        case .sets: "Sets"
        case .rest: "Rest"
        case .progression: "Progression"
        case .tier: "Tier"
        case .added: "Added"
        case .removed: "Removed"
        }
    }
}

enum ChangeDirection: String, Codable {
    case up, down, neutral

    var glyph: String {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .neutral: "circle.fill"
        }
    }
}
