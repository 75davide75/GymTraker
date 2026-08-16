//
//  HealthStore.swift
//  Gym Traker
//
//  Reads body data from Health so the tiers are measured against real numbers,
//  imports finished workouts — including the ones recorded on an Apple Watch —
//  and writes back the sessions logged here.
//
//  Note on timing: HealthKit only publishes a workout once it has been saved,
//  which for a Watch workout means when it ends. Live mirroring of a session in
//  progress would need a watchOS companion app, which this build does not have.
//

import Foundation
import HealthKit
import SwiftData

@Observable
final class HealthStore {

    enum Availability {
        case unavailable
        case notRequested
        case ready
    }

    private let store = HKHealthStore()

    private(set) var availability: Availability = HKHealthStore.isHealthDataAvailable() ? .notRequested : .unavailable
    private(set) var lastImportCount: Int = 0
    private(set) var lastError: String?

    /// What the app asks to read and to write.
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(bodyMass) }
        if let sex = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex) { types.insert(sex) }
        if let dob = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) { types.insert(dob) }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(bodyMass) }
        return types
    }

    var isAvailable: Bool { availability != .unavailable }

    // MARK: - Authorisation

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            availability = .unavailable
            return false
        }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            availability = .ready
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Reading body data

    struct BodyData {
        var bodyweightKg: Double?
        var sex: Sex?
        var birthYear: Int?
    }

    /// Pulls whatever Health is willing to give. Anything denied comes back nil
    /// and the profile keeps the value the user typed.
    func readBodyData() async -> BodyData {
        var data = BodyData()

        if let sex = try? store.biologicalSex().biologicalSex {
            switch sex {
            case .male: data.sex = .male
            case .female: data.sex = .female
            default: break
            }
        }

        if let components = try? store.dateOfBirthComponents(), let year = components.year {
            data.birthYear = year
        }

        data.bodyweightKg = await latestBodyMassKg()
        return data
    }

    private func latestBodyMassKg() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    // MARK: - Importing workouts

    /// A finished workout from Health that the app has not recorded itself.
    struct ImportedWorkout {
        let uuid: UUID
        let start: Date
        let end: Date
        let source: String
        let energyKcal: Double?
    }

    /// Strength-shaped workouts from the trailing window, newest first.
    func recentWorkouts(days: Int = 30) async -> [ImportedWorkout] {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let timeRange = HKQuery.predicateForSamples(withStart: start, end: .now)

        let strengthTypes: [HKWorkoutActivityType] = [
            .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining, .crossTraining
        ]
        let activity = NSCompoundPredicate(orPredicateWithSubpredicates:
            strengthTypes.map { HKQuery.predicateForWorkouts(with: $0) })
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timeRange, activity])

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                    ImportedWorkout(
                        uuid: workout.uuid,
                        start: workout.startDate,
                        end: workout.endDate,
                        source: workout.sourceRevision.source.name,
                        energyKcal: workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
                            .sumQuantity()?.doubleValue(for: .kilocalorie())
                    )
                }
                continuation.resume(returning: workouts)
            }
            store.execute(query)
        }
    }

    /// Creates a WorkoutSession for every Health workout the app has not seen,
    /// so a session started on the Watch shows up in the history here.
    @MainActor
    @discardableResult
    func importWorkouts(into context: ModelContext) async -> Int {
        guard availability == .ready else { return 0 }

        let existing = Set(Store.sessions(in: context).compactMap(\.healthKitUUID))
        let workouts = await recentWorkouts()
        var imported = 0

        for workout in workouts where !existing.contains(workout.uuid) {
            let session = WorkoutSession(planDayLetter: "—", planDayTitle: "Imported workout")
            session.startedAt = workout.start
            session.endedAt = workout.end
            session.healthKitUUID = workout.uuid
            session.sourceName = workout.source
            context.insert(session)
            imported += 1
        }

        if imported > 0 { try? context.save() }
        lastImportCount = imported
        return imported
    }

    // MARK: - Writing

    /// Saves a logged session to Health as a strength-training workout.
    func save(session: WorkoutSession) async {
        guard availability == .ready, let end = session.endedAt else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        do {
            try await builder.beginCollection(at: session.startedAt)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            lastError = error.localizedDescription
        }
    }
}
