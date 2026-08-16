//
//  ArchiveSeeder.swift
//  Gym Traker
//
//  Loads the bundled exercise archive on first launch and upserts it when the
//  bundle version moves. User-created exercises are never touched.
//

import Foundation
import SwiftData

enum ArchiveSeeder {

    private static let versionKey = "archiveVersion"

    private struct ArchiveFile: Decodable {
        let version: Int
        let exercises: [ArchiveEntry]
    }

    private struct ArchiveEntry: Decodable {
        let id: String
        let name: String
        let primaryMuscle: String
        let equipment: String
        let rankAnchor: String?
        let tracking: String
        let glyph: Glyph
        let images: [String]?
        let instructions: [String]?
        let level: String?

        struct Glyph: Decodable {
            let shape: String
            let hue: Int
        }
    }

    enum SeedError: Error {
        case bundleResourceMissing
    }

    /// Inserts missing archive rows and refreshes changed ones. Safe to call on
    /// every launch: it does nothing once the store matches the bundle version.
    @discardableResult
    static func seedIfNeeded(_ context: ModelContext, force: Bool = false) throws -> Int {
        let file = try loadBundledArchive()
        let storedVersion = UserDefaults.standard.integer(forKey: versionKey)

        let existing = try context.fetch(FetchDescriptor<Exercise>())
        let isEmpty = existing.isEmpty

        guard force || isEmpty || storedVersion < file.version else { return 0 }

        var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var written = 0

        for entry in file.exercises {
            if let row = byID[entry.id] {
                // Never clobber the user's own rows, even on an id collision.
                guard !row.isCustom else { continue }
                row.name = entry.name
                row.primaryMuscle = entry.primaryMuscle
                row.equipmentRaw = entry.equipment
                row.rankAnchorRaw = entry.rankAnchor
                row.trackingRaw = entry.tracking
                row.glyphShape = entry.glyph.shape
                row.glyphHue = entry.glyph.hue
                row.imageNames = entry.images ?? []
                row.instructions = entry.instructions ?? []
                row.level = entry.level
            } else {
                let exercise = Exercise(
                    id: entry.id,
                    name: entry.name,
                    primaryMuscle: entry.primaryMuscle,
                    equipment: Equipment(rawValue: entry.equipment) ?? .barbell,
                    rankAnchor: entry.rankAnchor.flatMap(RankAnchor.init(rawValue:)),
                    tracking: Tracking(rawValue: entry.tracking) ?? .weightReps,
                    glyphShape: entry.glyph.shape,
                    glyphHue: entry.glyph.hue,
                    isCustom: false,
                    imageNames: entry.images ?? [],
                    instructions: entry.instructions ?? [],
                    level: entry.level
                )
                context.insert(exercise)
                byID[entry.id] = exercise
                written += 1
            }
        }

        try context.save()
        UserDefaults.standard.set(file.version, forKey: versionKey)
        return written
    }

    /// Number of exercises in the bundled archive, without touching the store.
    static func bundledCount() throws -> Int {
        try loadBundledArchive().exercises.count
    }

    private static func loadBundledArchive() throws -> ArchiveFile {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            throw SeedError.bundleResourceMissing
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ArchiveFile.self, from: data)
    }
}
