//
//  TrainingPlan.swift
//  Gym Traker
//
//  A plan is a set of lettered day templates plus a weekly assignment. A letter
//  may appear on several weekdays — repetition within the week is expected.
//

import Foundation
import SwiftData

/// Per-set target. Sets inside one exercise are free to differ.
struct SetTarget: Codable, Hashable, Identifiable {
    var id = UUID()
    var reps: Int

    init(reps: Int) {
        self.id = UUID()
        self.reps = reps
    }
}

@Model
final class Plan {
    var name: String = "My plan"
    var isActive: Bool = true
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \PlanDay.plan)
    var days: [PlanDay]? = []

    /// index 0 = Monday … 6 = Sunday. An empty string means a rest day.
    /// Stored as `[String]` rather than `[String?]` because SwiftData handles
    /// arrays of non-optionals far more predictably.
    var weekAssignmentsRaw: [String] = ["", "", "", "", "", "", ""]

    init(name: String = "My plan", isActive: Bool = true) {
        self.name = name
        self.isActive = isActive
        self.createdAt = .now
        self.days = []
        self.weekAssignmentsRaw = Array(repeating: "", count: 7)
    }

    var orderedDays: [PlanDay] {
        (days ?? []).sorted { $0.order < $1.order }
    }

    /// Weekday index 0 = Monday … 6 = Sunday.
    func letter(forWeekdayIndex index: Int) -> String? {
        guard weekAssignmentsRaw.indices.contains(index) else { return nil }
        let value = weekAssignmentsRaw[index]
        return value.isEmpty ? nil : value
    }

    func setLetter(_ letter: String?, forWeekdayIndex index: Int) {
        guard weekAssignmentsRaw.indices.contains(index) else { return }
        weekAssignmentsRaw[index] = letter ?? ""
    }

    func day(withLetter letter: String) -> PlanDay? {
        orderedDays.first { $0.letter == letter }
    }

    /// The template scheduled today, or nil on a rest day.
    var todayDay: PlanDay? {
        guard let letter = letter(forWeekdayIndex: Self.mondayBasedIndex(for: .now)) else { return nil }
        return day(withLetter: letter)
    }

    /// The next scheduled template, starting with today and looking a week
    /// ahead. On a rest day this is what "up next" should mean — otherwise the
    /// app would offer nothing to do on four days out of seven.
    func nextScheduled(from date: Date = .now) -> (day: PlanDay, daysAhead: Int)? {
        let start = Self.mondayBasedIndex(for: date)
        for offset in 0..<7 {
            let index = (start + offset) % 7
            guard let letter = letter(forWeekdayIndex: index),
                  let day = day(withLetter: letter) else { continue }
            return (day, offset)
        }
        return nil
    }

    /// Converts Foundation's Sunday-first weekday into a Monday-first index.
    static func mondayBasedIndex(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date) // 1 = Sunday
        return (weekday + 5) % 7
    }

    /// Next free letter in the A, B, C… sequence.
    var nextLetter: String {
        let used = Set(orderedDays.map(\.letter))
        for scalar in UnicodeScalar("A").value...UnicodeScalar("Z").value {
            let candidate = String(UnicodeScalar(scalar)!)
            if !used.contains(candidate) { return candidate }
        }
        return "A"
    }
}

@Model
final class PlanDay {
    var letter: String = "A"
    var title: String = "Day"
    var order: Int = 0
    var plan: Plan?

    @Relationship(deleteRule: .cascade, inverse: \PlanItem.day)
    var items: [PlanItem]? = []

    init(letter: String, title: String, order: Int) {
        self.letter = letter
        self.title = title
        self.order = order
        self.items = []
    }

    var orderedItems: [PlanItem] {
        (items ?? []).sorted { $0.order < $1.order }
    }

    var totalSets: Int {
        orderedItems.reduce(0) { $0 + $1.targetSets.count }
    }

    /// Rough session length: 40 s per working set plus the programmed rest.
    var estimatedMinutes: Int {
        let seconds = orderedItems.reduce(0.0) { partial, item in
            partial + Double(item.targetSets.count) * (40 + Double(item.restSeconds))
        }
        return max(5, Int((seconds / 60).rounded()))
    }

    /// Renumbers `order` to be contiguous and 1-based after a move or delete.
    func renumber() {
        for (index, item) in orderedItems.enumerated() {
            item.order = index + 1
        }
    }
}

/// One numbered line of a day template. Holds the plan, not the history.
@Model
final class PlanItem {
    var order: Int = 1
    var exerciseID: String = ""
    var exerciseName: String = ""
    var targetSets: [SetTarget] = []
    var workingWeightKg: Double = 20
    var stepKg: Double = 2.5
    var restSeconds: Int = 90
    var progressionArmed: Bool = false
    /// How long a timed exercise runs for. Ignored by everything else.
    var durationSeconds: Int = 900
    var suggestedWeightKg: Double?
    var day: PlanDay?

    init(
        order: Int,
        exerciseID: String,
        exerciseName: String,
        targetSets: [SetTarget] = [SetTarget(reps: 10), SetTarget(reps: 10), SetTarget(reps: 10)],
        workingWeightKg: Double = 20,
        stepKg: Double = 2.5,
        restSeconds: Int = 90
    ) {
        self.order = order
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.workingWeightKg = workingWeightKg
        self.stepKg = stepKg
        self.restSeconds = restSeconds
        self.progressionArmed = false
    }

    /// "8/8/6/6" — collapses to "8" when every set shares a rep count.
    var repsSummary: String {
        let reps = targetSets.map(\.reps)
        guard let first = reps.first else { return "—" }
        if reps.allSatisfy({ $0 == first }) { return "\(first)" }
        return reps.map(String.init).joined(separator: "/")
    }

    /// "4 sets · 8/8/6/6 reps", or "20 min" for something timed.
    var schemeSummary: String {
        "\(targetSets.count) set\(targetSets.count == 1 ? "" : "s") · \(repsSummary) reps"
    }

    func schemeSummary(timed: Bool) -> String {
        timed ? UnitFormatter.minutes(durationSeconds) : schemeSummary
    }

    /// The weight the next session should open with.
    var openingWeightKg: Double { suggestedWeightKg ?? workingWeightKg }
}
