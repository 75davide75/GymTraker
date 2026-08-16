//
//  RankingTables.swift
//  Gym Traker
//
//  The threshold tables live in a bundled JSON so they can be tuned without a
//  code change. Loaded once, cached for the process lifetime.
//

import Foundation

/// Everything the ranking maths needs about a lifter, decoupled from SwiftData
/// so the engine stays testable as a pure function.
struct LifterProfile: Hashable {
    let sex: Sex
    let age: Int
    let bodyweightKg: Double

    init(sex: Sex, age: Int, bodyweightKg: Double) {
        self.sex = sex
        self.age = age
        self.bodyweightKg = bodyweightKg
    }
}

extension UserProfile {
    var lifter: LifterProfile {
        LifterProfile(sex: sex, age: age, bodyweightKg: bodyweightKg)
    }
}

struct RankingTables: Decodable {

    struct AgeBand: Decodable {
        let maxAge: Int
        let factor: Double
    }

    struct BodyweightStandard: Decodable {
        let male: [Double]
        let female: [Double]
        let unit: String?
        let aliases: [String]?

        func thresholds(for sex: Sex) -> [Double] {
            switch sex {
            case .male: male
            case .female: female
            }
        }
    }

    let version: Int
    let ageFactors: [AgeBand]
    let standards: [String: [String: [Double]]]
    let bodyweightDefault: String
    let bodyweight: [String: BodyweightStandard]

    // MARK: - Loading

    static let shared: RankingTables = {
        guard let url = Bundle.main.url(forResource: "ranking", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tables = try? JSONDecoder().decode(RankingTables.self, from: data)
        else {
            fatalError("ranking.json is missing from the bundle")
        }
        return tables
    }()

    // MARK: - Lookup

    /// Masters-style age coefficient, rounded conservatively into bands.
    /// Under 18 uses 1.00.
    func ageFactor(for age: Int) -> Double {
        guard age >= 18 else { return 1.0 }
        for band in ageFactors.sorted(by: { $0.maxAge < $1.maxAge }) where age <= band.maxAge {
            return band.factor
        }
        return ageFactors.last?.factor ?? 1.0
    }

    /// Estimated-1RM thresholds in kilograms for a barbell anchor.
    func thresholds(anchor: RankAnchor, lifter: LifterProfile) -> [Double]? {
        guard anchor != .bw,
              let table = standards[lifter.sex.rawValue],
              let ratios = table[anchor.rawValue]
        else { return nil }
        let factor = ageFactor(for: lifter.age)
        return ratios.map { $0 * lifter.bodyweightKg * factor }
    }

    /// Rep thresholds for a bodyweight exercise, resolved through the alias map.
    func bodyweightThresholds(exerciseID: String?, sex: Sex) -> [Double] {
        let key = bodyweightKey(for: exerciseID)
        let standard = bodyweight[key] ?? bodyweight[bodyweightDefault]
        return standard?.thresholds(for: sex) ?? [8, 20, 35, 50, 70]
    }

    /// True when the exercise is measured in seconds rather than repetitions.
    func isTimeBased(exerciseID: String?) -> Bool {
        bodyweight[bodyweightKey(for: exerciseID)]?.unit == "seconds"
    }

    private func bodyweightKey(for exerciseID: String?) -> String {
        guard let id = exerciseID else { return bodyweightDefault }
        if bodyweight[id] != nil { return id }
        for (key, standard) in bodyweight where standard.aliases?.contains(id) == true {
            return key
        }
        return bodyweightDefault
    }
}
