//
//  PlanPresets.swift
//  Gym Traker
//
//  The three starting plans offered during onboarding. Every id here exists in
//  the bundled archive; anything missing is skipped rather than faked.
//

import Foundation
import SwiftData

struct PlanPreset: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let days: [Day]
    /// index 0 = Monday … 6 = Sunday. "" means rest.
    let weekAssignments: [String]

    struct Day {
        let letter: String
        let title: String
        let exerciseIDs: [String]
    }

    static let all: [PlanPreset] = [pushPullLegs, upperLower, fullBody]

    static let pushPullLegs = PlanPreset(
        id: "ppl",
        name: "Push / Pull / Legs",
        subtitle: "3 days · classic split",
        days: [
            Day(letter: "A", title: "Push", exerciseIDs: [
                "bench-press", "overhead-press", "incline-dumbbell-press",
                "lateral-raise", "cable-triceps-pushdown"
            ]),
            Day(letter: "B", title: "Pull", exerciseIDs: [
                "pull-up", "barbell-row", "lat-pulldown", "face-pull", "barbell-curl"
            ]),
            Day(letter: "C", title: "Legs", exerciseIDs: [
                "back-squat", "romanian-deadlift", "leg-press",
                "lying-leg-curl", "standing-calf-raise"
            ])
        ],
        weekAssignments: ["A", "", "B", "", "C", "", ""]
    )

    static let upperLower = PlanPreset(
        id: "upper-lower",
        name: "Upper / Lower",
        subtitle: "4 days · each template twice a week",
        days: [
            Day(letter: "A", title: "Upper", exerciseIDs: [
                "bench-press", "barbell-row", "overhead-press",
                "lat-pulldown", "barbell-curl", "cable-triceps-pushdown"
            ]),
            Day(letter: "B", title: "Lower", exerciseIDs: [
                "back-squat", "romanian-deadlift", "leg-press",
                "leg-extension", "standing-calf-raise"
            ])
        ],
        // A and B each repeat within the week — the case the brief calls out.
        weekAssignments: ["A", "B", "", "A", "B", "", ""]
    )

    static let fullBody = PlanPreset(
        id: "full-body",
        name: "Full body",
        subtitle: "3 days · one template, three times",
        days: [
            Day(letter: "A", title: "Full body", exerciseIDs: [
                "back-squat", "bench-press", "barbell-row",
                "overhead-press", "romanian-deadlift", "plank"
            ])
        ],
        weekAssignments: ["A", "", "A", "", "A", "", ""]
    )

    // MARK: - Building

    /// Materialises the preset into SwiftData, resolving names from the archive.
    @discardableResult
    func build(in context: ModelContext) -> Plan {
        let plan = Plan(name: name)
        context.insert(plan)
        plan.weekAssignmentsRaw = weekAssignments

        for (dayIndex, template) in days.enumerated() {
            let day = PlanDay(letter: template.letter, title: template.title, order: dayIndex)
            day.plan = plan
            context.insert(day)

            var order = 1
            for exerciseID in template.exerciseIDs {
                guard let exercise = Store.exercise(id: exerciseID, in: context) else { continue }
                let item = PlanItem(
                    order: order,
                    exerciseID: exercise.id,
                    exerciseName: exercise.name,
                    targetSets: [SetTarget(reps: 8), SetTarget(reps: 8), SetTarget(reps: 8)],
                    workingWeightKg: exercise.equipment == .bodyweight ? 0 : 20,
                    stepKg: exercise.defaultStepKg,
                    restSeconds: 90
                )
                item.day = day
                context.insert(item)
                Registry.exerciseAdded(
                    exerciseID: exercise.id,
                    exerciseName: exercise.name,
                    dayTitle: template.title,
                    in: context
                )
                order += 1
            }
        }

        try? context.save()
        return plan
    }
}
