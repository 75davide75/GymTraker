//
//  UserProfile.swift
//  Gym Traker
//

import Foundation
import SwiftData

struct BodyweightEntry: Codable, Hashable {
    var date: Date
    var kg: Double
}

@Model
final class UserProfile {
    var name: String = ""
    var sexRaw: String = Sex.male.rawValue
    var birthYear: Int = 1998
    var bodyweightKg: Double = 75
    var unitsRaw: String = Units.kg.rawValue
    var appearanceRaw: String = Appearance.dark.rawValue
    var createdAt: Date = Date.now
    var bodyweightHistory: [BodyweightEntry] = []
    /// Tier promotions already celebrated, keyed "exerciseID#tierIndex", so the
    /// promotion moment fires once per tier per exercise.
    var celebratedPromotions: [String] = []
    var notificationsEnabled: Bool = true

    init(
        name: String = "",
        sex: Sex = .male,
        birthYear: Int = 1998,
        bodyweightKg: Double = 75,
        units: Units = .kg,
        appearance: Appearance = .dark
    ) {
        self.name = name
        self.sexRaw = sex.rawValue
        self.birthYear = birthYear
        self.bodyweightKg = bodyweightKg
        self.unitsRaw = units.rawValue
        self.appearanceRaw = appearance.rawValue
        self.createdAt = .now
        self.bodyweightHistory = [BodyweightEntry(date: .now, kg: bodyweightKg)]
        self.celebratedPromotions = []
        self.notificationsEnabled = true
    }

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }

    var units: Units {
        get { Units(rawValue: unitsRaw) ?? .kg }
        set { unitsRaw = newValue.rawValue }
    }

    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRaw) ?? .dark }
        set { appearanceRaw = newValue.rawValue }
    }

    var age: Int {
        Calendar.current.component(.year, from: .now) - birthYear
    }

    /// Records a bodyweight change and keeps the history in step, because every
    /// tier is measured against it.
    func updateBodyweight(_ kg: Double) {
        guard abs(kg - bodyweightKg) > 0.001 else { return }
        bodyweightKg = kg
        bodyweightHistory.append(BodyweightEntry(date: .now, kg: kg))
    }
}
