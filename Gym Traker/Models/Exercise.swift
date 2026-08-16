//
//  Exercise.swift
//  Gym Traker
//
//  One row of the archive. Bundled entries and user-created entries share this
//  type; `isCustom` keeps archive updates from clobbering the user's own work.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    #Unique<Exercise>([\.id])

    var id: String = ""                 // slug, e.g. "bench-press"
    var name: String = ""
    var primaryMuscle: String = ""
    var equipmentRaw: String = Equipment.barbell.rawValue
    var rankAnchorRaw: String?
    var trackingRaw: String = Tracking.weightReps.rawValue
    var glyphShape: String = "bar"
    var glyphHue: Int = 268
    var isCustom: Bool = false
    var notes: String?
    var createdAt: Date = Date.now
    /// Bundle image names, start position first. Empty for user-created
    /// exercises, which fall back to the generated glyph.
    var imageNames: [String] = []
    /// Step-by-step form cues from the archive.
    var instructions: [String] = []
    var level: String?

    // Cached ranking output, recomputed on session save and on profile edit.
    var cachedScore: Double?
    var cachedTierIndex: Int?
    var cachedScoredAt: Date?

    init(
        id: String,
        name: String,
        primaryMuscle: String,
        equipment: Equipment,
        rankAnchor: RankAnchor? = nil,
        tracking: Tracking = .weightReps,
        glyphShape: String? = nil,
        glyphHue: Int? = nil,
        isCustom: Bool = false,
        notes: String? = nil,
        imageNames: [String] = [],
        instructions: [String] = [],
        level: String? = nil
    ) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.equipmentRaw = equipment.rawValue
        self.rankAnchorRaw = rankAnchor?.rawValue
        self.trackingRaw = tracking.rawValue
        self.glyphShape = glyphShape ?? equipment.glyphShape
        self.glyphHue = glyphHue ?? equipment.glyphHue
        self.isCustom = isCustom
        self.notes = notes
        self.createdAt = .now
        self.imageNames = imageNames
        self.instructions = instructions
        self.level = level
    }

    /// True when the archive shipped photographs for this exercise.
    var hasPhotos: Bool { !imageNames.isEmpty }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .barbell }
        set { equipmentRaw = newValue.rawValue }
    }

    var rankAnchor: RankAnchor? {
        get { rankAnchorRaw.flatMap(RankAnchor.init(rawValue:)) }
        set { rankAnchorRaw = newValue?.rawValue }
    }

    var tracking: Tracking {
        get { Tracking(rawValue: trackingRaw) ?? .weightReps }
        set { trackingRaw = newValue.rawValue }
    }

    var subtitle: String { "\(primaryMuscle) · \(equipmentRaw)" }

    var defaultStepKg: Double { equipment.defaultStepKg }

    /// Matches the archive search field against name and muscle.
    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return name.lowercased().contains(q) || primaryMuscle.lowercased().contains(q)
    }

    /// Turns a user-typed name into a stable, unique-ish slug.
    static func slug(from name: String) -> String {
        let base = name
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return base.isEmpty ? "custom-\(UUID().uuidString.prefix(8))" : base
    }
}
