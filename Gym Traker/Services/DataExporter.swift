//
//  DataExporter.swift
//  Gym Traker
//
//  One JSON file holding profile, plan, exercises, sessions and registry.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI

enum DataExporter {

    // MARK: - Shapes

    private struct Export: Encodable {
        let exportedAt: Date
        let schemaVersion: Int
        let profile: ProfileDTO?
        let plans: [PlanDTO]
        let customExercises: [ExerciseDTO]
        let sessions: [SessionDTO]
        let registry: [RecordDTO]
    }

    private struct ProfileDTO: Encodable {
        let name: String
        let sex: String
        let age: Int
        let bodyweightKg: Double
        let units: String
        let createdAt: Date
        let bodyweightHistory: [BodyweightEntry]
    }

    private struct PlanDTO: Encodable {
        let name: String
        let isActive: Bool
        let weekAssignments: [String]
        let days: [DayDTO]
    }

    private struct DayDTO: Encodable {
        let letter: String
        let title: String
        let items: [ItemDTO]
    }

    private struct ItemDTO: Encodable {
        let order: Int
        let exerciseID: String
        let exerciseName: String
        let targetReps: [Int]
        let workingWeightKg: Double
        let stepKg: Double
        let restSeconds: Int
        let progressionArmed: Bool
    }

    private struct ExerciseDTO: Encodable {
        let id: String
        let name: String
        let primaryMuscle: String
        let equipment: String
        let rankAnchor: String?
        let tracking: String
        let glyphShape: String
        let glyphHue: Int
    }

    private struct SessionDTO: Encodable {
        let startedAt: Date
        let endedAt: Date?
        let planDayLetter: String
        let planDayTitle: String
        let totalVolumeKg: Double
        let entries: [EntryDTO]
    }

    private struct EntryDTO: Encodable {
        let order: Int
        let exerciseID: String
        let exerciseName: String
        let restSeconds: Int
        let sets: [SetDTO]
    }

    private struct SetDTO: Encodable {
        let reps: Int
        let weightKg: Double
        let targetReps: Int
        let completedAt: Date?
    }

    private struct RecordDTO: Encodable {
        let date: Date
        let exerciseID: String
        let exerciseName: String
        let field: String
        let from: String
        let to: String
        let direction: String
    }

    // MARK: - Building

    static func makeJSON(from context: ModelContext) throws -> Data {
        let profile = Store.profile(in: context)
        let plans = (try? context.fetch(FetchDescriptor<Plan>())) ?? []
        let exercises = Store.allExercises(in: context).filter(\.isCustom)
        let sessions = Store.sessions(in: context)
        let records = Registry.all(in: context)

        let export = Export(
            exportedAt: .now,
            schemaVersion: 1,
            profile: profile.map {
                ProfileDTO(
                    name: $0.name,
                    sex: $0.sexRaw,
                    age: $0.age,
                    bodyweightKg: $0.bodyweightKg,
                    units: $0.unitsRaw,
                    createdAt: $0.createdAt,
                    bodyweightHistory: $0.bodyweightHistory
                )
            },
            plans: plans.map { plan in
                PlanDTO(
                    name: plan.name,
                    isActive: plan.isActive,
                    weekAssignments: plan.weekAssignmentsRaw,
                    days: plan.orderedDays.map { day in
                        DayDTO(
                            letter: day.letter,
                            title: day.title,
                            items: day.orderedItems.map { item in
                                ItemDTO(
                                    order: item.order,
                                    exerciseID: item.exerciseID,
                                    exerciseName: item.exerciseName,
                                    targetReps: item.targetSets.map(\.reps),
                                    workingWeightKg: item.workingWeightKg,
                                    stepKg: item.stepKg,
                                    restSeconds: item.restSeconds,
                                    progressionArmed: item.progressionArmed
                                )
                            }
                        )
                    }
                )
            },
            customExercises: exercises.map {
                ExerciseDTO(
                    id: $0.id,
                    name: $0.name,
                    primaryMuscle: $0.primaryMuscle,
                    equipment: $0.equipmentRaw,
                    rankAnchor: $0.rankAnchorRaw,
                    tracking: $0.trackingRaw,
                    glyphShape: $0.glyphShape,
                    glyphHue: $0.glyphHue
                )
            },
            sessions: sessions.map { session in
                SessionDTO(
                    startedAt: session.startedAt,
                    endedAt: session.endedAt,
                    planDayLetter: session.planDayLetter,
                    planDayTitle: session.planDayTitle,
                    totalVolumeKg: session.totalVolumeKg,
                    entries: session.orderedEntries.map { entry in
                        EntryDTO(
                            order: entry.order,
                            exerciseID: entry.exerciseID,
                            exerciseName: entry.exerciseName,
                            restSeconds: entry.restSeconds,
                            sets: entry.sets.map {
                                SetDTO(reps: $0.reps, weightKg: $0.weightKg,
                                       targetReps: $0.targetReps, completedAt: $0.completedAt)
                            }
                        )
                    }
                )
            },
            registry: records.map {
                RecordDTO(
                    date: $0.date,
                    exerciseID: $0.exerciseID,
                    exerciseName: $0.exerciseName,
                    field: $0.fieldRaw,
                    from: $0.fromValue,
                    to: $0.toValue,
                    direction: $0.directionRaw
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    /// Writes the export to a temporary file so it can be handed to ShareLink.
    static func writeTemporaryFile(from context: ModelContext) throws -> URL {
        let data = try makeJSON(from: context)
        let name = "gym-tracker-\(Date.now.formatted(.iso8601.year().month().day())).json"
        let url = FileManager.default.temporaryDirectory.appending(path: name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
