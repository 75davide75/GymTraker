//
//  Backup.swift
//  Gym Traker
//
//  Everything the app knows, in one file you can put somewhere safe and read
//  back later.
//
//  This replaced an export that only wrote data out. An export you cannot
//  restore is a report, not a backup: it left the profile's height, photo and
//  appearance behind, kept only custom exercises, and dropped the identifiers
//  that tie a session to the workout Health already holds. Everything here is
//  round-trippable, and the restore is checked by a test that exports, wipes,
//  imports and compares.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - The archive

struct BackupArchive: Codable {
    /// Raised only when an older file can no longer be read as written.
    static let currentVersion = 1

    var version = BackupArchive.currentVersion
    var exportedAt = Date.now
    var appVersion: String?
    var profile: Profile?
    var exercises: [Exercise] = []
    var plans: [Plan] = []
    var sessions: [Session] = []
    var registry: [Record] = []

    struct Profile: Codable {
        var name: String
        var sexRaw: String
        var birthYear: Int
        var bodyweightKg: Double
        var unitsRaw: String
        var appearanceRaw: String
        var createdAt: Date
        var bodyweightHistory: [BodyweightEntry]
        var celebratedPromotions: [String]
        var notificationsEnabled: Bool
        var restAlertRaw: String
        var heightCm: Double?
        var experienceRaw: String
        var avatarData: Data?
        var languageRaw: String?
    }

    struct Exercise: Codable {
        var id: String
        var name: String
        var primaryMuscle: String
        var equipmentRaw: String
        var rankAnchorRaw: String?
        var trackingRaw: String
        var glyphShape: String
        var glyphHue: Int
        var isCustom: Bool
        var notes: String?
        var createdAt: Date
        var illustrationNames: [String]
        var photoNames: [String]
        var instructions: [String]
        var tips: [String]
        var primer: String?
        var level: String?
    }

    struct Plan: Codable {
        var name: String
        var isActive: Bool
        var createdAt: Date
        var weekAssignmentsRaw: [String]
        var days: [Day]
    }

    struct Day: Codable {
        var letter: String
        var title: String
        var order: Int
        var items: [Item]
    }

    struct Item: Codable {
        var order: Int
        var exerciseID: String
        var exerciseName: String
        var targetReps: [Int]
        var workingWeightKg: Double
        var stepKg: Double
        var restSeconds: Int
        var progressionArmed: Bool
        var suggestedWeightKg: Double?
    }

    struct Session: Codable {
        var uuid: UUID
        var startedAt: Date
        var endedAt: Date?
        var planDayLetter: String
        var planDayTitle: String
        var healthKitUUID: UUID?
        var sourceName: String?
        var energyKcal: Double?
        var averageHeartRate: Double?
        var maxHeartRate: Double?
        var distanceMeters: Double?
        var activityName: String?
        var entries: [Entry]
    }

    struct Entry: Codable {
        var order: Int
        var exerciseID: String
        var exerciseName: String
        var restSeconds: Int
        var sets: [PerformedSet]
    }

    struct Record: Codable {
        var date: Date
        var exerciseID: String
        var exerciseName: String
        var fieldRaw: String
        var fromValue: String
        var toValue: String
        var directionRaw: String
        var sessionUUID: UUID?
    }
}

// MARK: - Reading and writing

enum Backup {

    enum Failure: LocalizedError {
        case unreadable
        case tooNew(Int)

        var errorDescription: String? {
            switch self {
            case .unreadable:
                "That file is not a Gym Tracker backup."
            case .tooNew(let version):
                "That backup was written by a newer version of the app (format \(version))."
            }
        }
    }

    /// What a restore put back, so the user is told rather than left guessing.
    struct Summary {
        var exercises = 0
        var plans = 0
        var sessions = 0
        var records = 0
        var hasProfile = false
    }

    private static var coder: (JSONEncoder, JSONDecoder) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (encoder, decoder)
    }

    // MARK: Export

    static func archive(from context: ModelContext) -> BackupArchive {
        var archive = BackupArchive()
        archive.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        if let profile = Store.profile(in: context) {
            archive.profile = BackupArchive.Profile(
                name: profile.name,
                sexRaw: profile.sexRaw,
                birthYear: profile.birthYear,
                bodyweightKg: profile.bodyweightKg,
                unitsRaw: profile.unitsRaw,
                appearanceRaw: profile.appearanceRaw,
                createdAt: profile.createdAt,
                bodyweightHistory: profile.bodyweightHistory,
                celebratedPromotions: profile.celebratedPromotions,
                notificationsEnabled: profile.notificationsEnabled,
                restAlertRaw: profile.restAlertRaw,
                heightCm: profile.heightCm,
                experienceRaw: profile.experienceRaw,
                avatarData: profile.avatarData,
                languageRaw: profile.languageRaw
            )
        }

        // Every exercise, not only the custom ones. The bundled archive is
        // reseeded on a fresh install, but an edited name or a changed rest
        // belongs to the user and would be quietly lost otherwise.
        archive.exercises = Store.allExercises(in: context).map { exercise in
            BackupArchive.Exercise(
                id: exercise.id,
                name: exercise.name,
                primaryMuscle: exercise.primaryMuscle,
                equipmentRaw: exercise.equipmentRaw,
                rankAnchorRaw: exercise.rankAnchorRaw,
                trackingRaw: exercise.trackingRaw,
                glyphShape: exercise.glyphShape,
                glyphHue: exercise.glyphHue,
                isCustom: exercise.isCustom,
                notes: exercise.notes,
                createdAt: exercise.createdAt,
                illustrationNames: exercise.illustrationNames,
                photoNames: exercise.photoNames,
                instructions: exercise.instructions,
                tips: exercise.tips,
                primer: exercise.primer,
                level: exercise.level
            )
        }

        let plans = (try? context.fetch(FetchDescriptor<Plan>())) ?? []
        archive.plans = plans.map { plan in
            BackupArchive.Plan(
                name: plan.name,
                isActive: plan.isActive,
                createdAt: plan.createdAt,
                weekAssignmentsRaw: plan.weekAssignmentsRaw,
                days: plan.orderedDays.map { day in
                    BackupArchive.Day(
                        letter: day.letter,
                        title: day.title,
                        order: day.order,
                        items: day.orderedItems.map { item in
                            BackupArchive.Item(
                                order: item.order,
                                exerciseID: item.exerciseID,
                                exerciseName: item.exerciseName,
                                targetReps: item.targetSets.map(\.reps),
                                workingWeightKg: item.workingWeightKg,
                                stepKg: item.stepKg,
                                restSeconds: item.restSeconds,
                                progressionArmed: item.progressionArmed,
                                suggestedWeightKg: item.suggestedWeightKg
                            )
                        }
                    )
                }
            )
        }

        archive.sessions = Store.sessions(in: context).map { session in
            BackupArchive.Session(
                uuid: session.uuid,
                startedAt: session.startedAt,
                endedAt: session.endedAt,
                planDayLetter: session.planDayLetter,
                planDayTitle: session.planDayTitle,
                healthKitUUID: session.healthKitUUID,
                sourceName: session.sourceName,
                energyKcal: session.energyKcal,
                averageHeartRate: session.averageHeartRate,
                maxHeartRate: session.maxHeartRate,
                distanceMeters: session.distanceMeters,
                activityName: session.activityName,
                entries: session.orderedEntries.map { entry in
                    BackupArchive.Entry(
                        order: entry.order,
                        exerciseID: entry.exerciseID,
                        exerciseName: entry.exerciseName,
                        restSeconds: entry.restSeconds,
                        sets: entry.sets
                    )
                }
            )
        }

        archive.registry = Registry.all(in: context).map { record in
            BackupArchive.Record(
                date: record.date,
                exerciseID: record.exerciseID,
                exerciseName: record.exerciseName,
                fieldRaw: record.fieldRaw,
                fromValue: record.fromValue,
                toValue: record.toValue,
                directionRaw: record.directionRaw,
                sessionUUID: record.sessionUUID
            )
        }

        return archive
    }

    static func encode(_ archive: BackupArchive) throws -> Data {
        try coder.0.encode(archive)
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        guard let archive = try? coder.1.decode(BackupArchive.self, from: data) else {
            throw Failure.unreadable
        }
        guard archive.version <= BackupArchive.currentVersion else {
            throw Failure.tooNew(archive.version)
        }
        return archive
    }

    /// Writes the backup somewhere it can be shared from, under a name that
    /// says what it is and when it was taken.
    static func writeTemporaryFile(from context: ModelContext) throws -> URL {
        let data = try encode(archive(from: context))
        let stamp = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Gym Tracker Backup \(stamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Restore

    /// Replaces everything with the contents of the archive.
    ///
    /// A restore is a replacement, not a merge. Merging would have to decide
    /// what to do with two profiles, two active plans and a session logged in
    /// both — questions with no right answer that the user never asked.
    @discardableResult
    static func restore(_ archive: BackupArchive, into context: ModelContext) throws -> Summary {
        var summary = Summary()

        for record in Registry.all(in: context) { context.delete(record) }
        for session in Store.sessions(in: context) { context.delete(session) }
        for plan in (try? context.fetch(FetchDescriptor<Plan>())) ?? [] { context.delete(plan) }
        for profile in (try? context.fetch(FetchDescriptor<UserProfile>())) ?? [] { context.delete(profile) }
        for exercise in Store.allExercises(in: context) where exercise.isCustom {
            context.delete(exercise)
        }

        if let stored = archive.profile {
            let profile = UserProfile(
                name: stored.name,
                sex: Sex(rawValue: stored.sexRaw) ?? .male,
                birthYear: stored.birthYear,
                bodyweightKg: stored.bodyweightKg,
                units: Units(rawValue: stored.unitsRaw) ?? .kg
            )
            profile.appearanceRaw = stored.appearanceRaw
            profile.createdAt = stored.createdAt
            profile.bodyweightHistory = stored.bodyweightHistory
            profile.celebratedPromotions = stored.celebratedPromotions
            profile.notificationsEnabled = stored.notificationsEnabled
            profile.restAlertRaw = stored.restAlertRaw
            profile.heightCm = stored.heightCm
            profile.experienceRaw = stored.experienceRaw
            profile.avatarData = stored.avatarData
            profile.languageRaw = stored.languageRaw ?? AppLanguage.system.rawValue
            context.insert(profile)
            summary.hasProfile = true
        }

        // Bundled exercises are already present after a reinstall, so they are
        // updated in place; anything the archive has and this install does not
        // is inserted.
        var existing: [String: Exercise] = [:]
        for exercise in Store.allExercises(in: context) { existing[exercise.id] = exercise }

        for stored in archive.exercises {
            let exercise = existing[stored.id] ?? {
                let created = Exercise(
                    id: stored.id,
                    name: stored.name,
                    primaryMuscle: stored.primaryMuscle,
                    equipment: Equipment(rawValue: stored.equipmentRaw) ?? .barbell
                )
                context.insert(created)
                return created
            }()
            exercise.name = stored.name
            exercise.primaryMuscle = stored.primaryMuscle
            exercise.equipmentRaw = stored.equipmentRaw
            exercise.rankAnchorRaw = stored.rankAnchorRaw
            exercise.trackingRaw = stored.trackingRaw
            exercise.glyphShape = stored.glyphShape
            exercise.glyphHue = stored.glyphHue
            exercise.isCustom = stored.isCustom
            exercise.notes = stored.notes
            exercise.createdAt = stored.createdAt
            exercise.illustrationNames = stored.illustrationNames
            exercise.photoNames = stored.photoNames
            exercise.instructions = stored.instructions
            exercise.tips = stored.tips
            exercise.primer = stored.primer
            exercise.level = stored.level
            // The cached rank refers to a bodyweight that has just been
            // replaced, so it is dropped and recomputed rather than shown wrong.
            exercise.cachedScore = nil
            exercise.cachedTierIndex = nil
            exercise.cachedScoredAt = nil
            summary.exercises += 1
        }

        for stored in archive.plans {
            let plan = Plan(name: stored.name, isActive: stored.isActive)
            plan.createdAt = stored.createdAt
            plan.weekAssignmentsRaw = stored.weekAssignmentsRaw
            context.insert(plan)

            for storedDay in stored.days {
                let day = PlanDay(letter: storedDay.letter, title: storedDay.title, order: storedDay.order)
                day.plan = plan
                context.insert(day)

                for storedItem in storedDay.items {
                    let item = PlanItem(
                        order: storedItem.order,
                        exerciseID: storedItem.exerciseID,
                        exerciseName: storedItem.exerciseName,
                        targetSets: storedItem.targetReps.map { SetTarget(reps: $0) },
                        workingWeightKg: storedItem.workingWeightKg,
                        stepKg: storedItem.stepKg,
                        restSeconds: storedItem.restSeconds
                    )
                    item.progressionArmed = storedItem.progressionArmed
                    item.suggestedWeightKg = storedItem.suggestedWeightKg
                    item.day = day
                    context.insert(item)
                }
            }
            summary.plans += 1
        }

        for stored in archive.sessions {
            let session = WorkoutSession(planDayLetter: stored.planDayLetter, planDayTitle: stored.planDayTitle)
            session.uuid = stored.uuid
            session.startedAt = stored.startedAt
            session.endedAt = stored.endedAt
            session.healthKitUUID = stored.healthKitUUID
            session.sourceName = stored.sourceName
            session.energyKcal = stored.energyKcal
            session.averageHeartRate = stored.averageHeartRate
            session.maxHeartRate = stored.maxHeartRate
            session.distanceMeters = stored.distanceMeters
            session.activityName = stored.activityName
            context.insert(session)

            for storedEntry in stored.entries {
                let entry = SessionEntry(
                    order: storedEntry.order,
                    exerciseID: storedEntry.exerciseID,
                    exerciseName: storedEntry.exerciseName,
                    restSeconds: storedEntry.restSeconds,
                    sets: storedEntry.sets
                )
                entry.session = session
                context.insert(entry)
            }
            summary.sessions += 1
        }

        for stored in archive.registry {
            let record = ChangeRecord(
                exerciseID: stored.exerciseID,
                exerciseName: stored.exerciseName,
                field: ChangeField(rawValue: stored.fieldRaw) ?? .weight,
                fromValue: stored.fromValue,
                toValue: stored.toValue,
                direction: ChangeDirection(rawValue: stored.directionRaw) ?? .neutral
            )
            record.date = stored.date
            record.sessionUUID = stored.sessionUUID
            context.insert(record)
            summary.records += 1
        }

        try context.save()
        return summary
    }

    static func restore(contentsOf url: URL, into context: ModelContext) throws -> Summary {
        // A file handed over by the document picker lives outside the sandbox
        // until access is asked for explicitly.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        return try restore(try decode(data), into: context)
    }
}
