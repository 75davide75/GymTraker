//
//  Progression.swift
//  Gym Traker
//
//  Decides what weight the next session should open with. Two routes reach the
//  same place: the automatic rule (every set met its target) and the user
//  arming the flag by hand.
//

import Foundation

enum Progression {

    /// Run on session save. Returns the weight to pre-fill next time, or nil
    /// when nothing earned an increase.
    static func suggestion(for entry: SessionEntry, item: PlanItem) -> Double? {
        var suggested: Double?

        if entry.allSetsMetTarget {
            suggested = item.workingWeightKg + item.stepKg
        }
        if item.progressionArmed {
            suggested = max(suggested ?? 0, item.workingWeightKg + item.stepKg)
        }
        return suggested
    }

    /// Applies the rule to a whole session. Kept separate from the view so the
    /// session screen has one line to call.
    static func apply(session: WorkoutSession, items: [PlanItem]) {
        let itemsByExercise = Dictionary(items.map { ($0.exerciseID, $0) }, uniquingKeysWith: { first, _ in first })
        for entry in session.orderedEntries {
            guard let item = itemsByExercise[entry.exerciseID] else { continue }
            item.suggestedWeightKg = suggestion(for: entry, item: item)
        }
    }

    /// The user accepted the suggested weight. Moves the working weight, clears
    /// the flag — it has done its job — and reports the old value so the caller
    /// can write the registry entry.
    @discardableResult
    static func accept(_ item: PlanItem) -> (from: Double, to: Double)? {
        guard let suggested = item.suggestedWeightKg, abs(suggested - item.workingWeightKg) > 0.001 else {
            item.suggestedWeightKg = nil
            return nil
        }
        let previous = item.workingWeightKg
        item.workingWeightKg = suggested
        item.suggestedWeightKg = nil
        item.progressionArmed = false
        return (previous, suggested)
    }

    /// The user declined. The suggestion goes away; the armed flag stays, so
    /// the intent survives a session where the numbers did not.
    static func decline(_ item: PlanItem) {
        item.suggestedWeightKg = nil
    }

    /// Copy for the progression checkbox. Deliberately without a figure: the
    /// reminder is an intention to go up, and what that means in kilograms is
    /// decided when you are standing at the bar.
    static func label(for item: PlanItem, units: Units) -> String {
        item.progressionArmed
            ? "Reminder set · go heavier next time"
            : "Remind me to go up next time"
    }
}
