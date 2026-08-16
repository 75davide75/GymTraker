//
//  PlanPresets.swift
//  Gym Traker
//
//  The training splits offered during onboarding, from the ones people
//  actually run: full body, upper/lower, push/pull/legs at three and six days,
//  PPLUL, the Arnold split, a body-part split and a 5×5 strength template.
//
//  Every id here exists in the bundled archive; anything missing is skipped
//  rather than faked.
//

import Foundation
import SwiftData

struct PlanPreset: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    /// One line on what the split is for, shown under the name.
    let note: String
    let days: [Day]
    /// index 0 = Monday … 6 = Sunday. "" means rest.
    let weekAssignments: [String]

    struct Day {
        let letter: String
        let title: String
        let exerciseIDs: [String]
    }

    var dayCount: Int { weekAssignments.filter { !$0.isEmpty }.count }

    static let all: [PlanPreset] = [
        fullBody, upperLower, pushPullLegs, pushPullLegsSix, pplul, arnold, bodyPart, strength5x5
    ]

    // MARK: - Common building blocks

    private static let bench = "barbell-bench-press-medium-grip"
    private static let inclineBarbell = "barbell-incline-bench-press-medium-grip"
    private static let inclineDumbbell = "incline-dumbbell-press"
    private static let ohp = "barbell-shoulder-press"
    private static let lateralRaise = "seated-side-lateral-raise"
    private static let pushdown = "triceps-pushdown"
    private static let skullcrusher = "cable-lying-triceps-extension"
    private static let dips = "dips-chest-version"
    private static let row = "bent-over-barbell-row"
    private static let pulldown = "wide-grip-lat-pulldown"
    private static let seatedRow = "seated-cable-rows"
    private static let pullups = "pullups"
    private static let facePull = "face-pull"
    private static let curl = "barbell-curl"
    private static let hammerCurl = "alternate-hammer-curl"
    private static let shrug = "barbell-shrug"
    private static let squat = "barbell-squat"
    private static let frontSquat = "front-barbell-squat"
    private static let deadlift = "barbell-deadlift"
    private static let rdl = "romanian-deadlift"
    private static let legPress = "leg-press"
    private static let legCurl = "lying-leg-curls"
    private static let legExtension = "leg-extensions"
    private static let calfRaise = "standing-calf-raises"
    private static let lunge = "barbell-lunge"
    private static let hipThrust = "barbell-hip-thrust"
    private static let plank = "plank"
    private static let hangingLegRaise = "hanging-leg-raise"

    // MARK: - The splits

    static let fullBody = PlanPreset(
        id: "full-body",
        name: "Full body",
        subtitle: "3 days · one template, three times",
        note: "The most time-efficient way to start. Every muscle gets three shots a week.",
        days: [
            Day(letter: "A", title: "Full body", exerciseIDs: [
                squat, bench, row, ohp, rdl, plank
            ])
        ],
        weekAssignments: ["A", "", "A", "", "A", "", ""]
    )

    static let upperLower = PlanPreset(
        id: "upper-lower",
        name: "Upper / Lower",
        subtitle: "4 days · each template twice a week",
        note: "The usual step up from full body. Splits the week in half, top and bottom.",
        days: [
            Day(letter: "A", title: "Upper", exerciseIDs: [
                bench, row, ohp, pulldown, curl, pushdown
            ]),
            Day(letter: "B", title: "Lower", exerciseIDs: [
                squat, rdl, legPress, legCurl, calfRaise
            ])
        ],
        weekAssignments: ["A", "B", "", "A", "B", "", ""]
    )

    static let pushPullLegs = PlanPreset(
        id: "ppl-3",
        name: "Push / Pull / Legs",
        subtitle: "3 days · the classic split",
        note: "Pressing, pulling and legs each get their own day. Easy to follow, easy to rotate.",
        days: [
            Day(letter: "A", title: "Push", exerciseIDs: [
                bench, ohp, inclineDumbbell, lateralRaise, pushdown
            ]),
            Day(letter: "B", title: "Pull", exerciseIDs: [
                pullups, row, pulldown, facePull, curl
            ]),
            Day(letter: "C", title: "Legs", exerciseIDs: [
                squat, rdl, legPress, legCurl, calfRaise
            ])
        ],
        weekAssignments: ["A", "", "B", "", "C", "", ""]
    )

    static let pushPullLegsSix = PlanPreset(
        id: "ppl-6",
        name: "Push / Pull / Legs ×2",
        subtitle: "6 days · every muscle twice a week",
        note: "The same three templates run twice. High volume, and it needs six days you will actually show up for.",
        days: [
            Day(letter: "A", title: "Push", exerciseIDs: [
                bench, ohp, inclineDumbbell, lateralRaise, pushdown, skullcrusher
            ]),
            Day(letter: "B", title: "Pull", exerciseIDs: [
                pullups, row, seatedRow, facePull, curl, hammerCurl
            ]),
            Day(letter: "C", title: "Legs", exerciseIDs: [
                squat, rdl, legPress, legCurl, legExtension, calfRaise
            ])
        ],
        weekAssignments: ["A", "B", "C", "A", "B", "C", ""]
    )

    static let pplul = PlanPreset(
        id: "pplul",
        name: "PPL + Upper / Lower",
        subtitle: "5 days · Monday to Friday",
        note: "Push, pull and legs early in the week, then an upper and a lower day. Weekends free.",
        days: [
            Day(letter: "A", title: "Push", exerciseIDs: [
                bench, ohp, inclineDumbbell, lateralRaise, pushdown
            ]),
            Day(letter: "B", title: "Pull", exerciseIDs: [
                pullups, row, pulldown, facePull, curl
            ]),
            Day(letter: "C", title: "Legs", exerciseIDs: [
                squat, rdl, legPress, legCurl, calfRaise
            ]),
            Day(letter: "D", title: "Upper", exerciseIDs: [
                inclineBarbell, seatedRow, ohp, pulldown, hammerCurl, skullcrusher
            ]),
            Day(letter: "E", title: "Lower", exerciseIDs: [
                frontSquat, deadlift, lunge, legExtension, calfRaise
            ])
        ],
        weekAssignments: ["A", "B", "C", "D", "E", "", ""]
    )

    static let arnold = PlanPreset(
        id: "arnold",
        name: "Arnold split",
        subtitle: "6 days · antagonists paired",
        note: "Chest with back, shoulders with arms, then legs — each run twice a week. High volume, old-school.",
        days: [
            Day(letter: "A", title: "Chest & Back", exerciseIDs: [
                bench, row, inclineBarbell, pullups, dips, pulldown
            ]),
            Day(letter: "B", title: "Shoulders & Arms", exerciseIDs: [
                ohp, lateralRaise, facePull, curl, skullcrusher, hammerCurl
            ]),
            Day(letter: "C", title: "Legs", exerciseIDs: [
                squat, rdl, legPress, legCurl, calfRaise, hangingLegRaise
            ])
        ],
        weekAssignments: ["A", "B", "C", "A", "B", "C", ""]
    )

    static let bodyPart = PlanPreset(
        id: "body-part",
        name: "Body-part split",
        subtitle: "5 days · one muscle group per session",
        note: "A dedicated day per muscle. Plenty of volume each session, but each group waits a full week.",
        days: [
            Day(letter: "A", title: "Chest", exerciseIDs: [
                bench, inclineBarbell, inclineDumbbell, dips
            ]),
            Day(letter: "B", title: "Back", exerciseIDs: [
                deadlift, row, pulldown, seatedRow, shrug
            ]),
            Day(letter: "C", title: "Shoulders", exerciseIDs: [
                ohp, lateralRaise, facePull, shrug
            ]),
            Day(letter: "D", title: "Arms", exerciseIDs: [
                curl, hammerCurl, pushdown, skullcrusher
            ]),
            Day(letter: "E", title: "Legs", exerciseIDs: [
                squat, legPress, legCurl, legExtension, calfRaise
            ])
        ],
        weekAssignments: ["A", "B", "C", "D", "E", "", ""]
    )

    static let strength5x5 = PlanPreset(
        id: "strength-5x5",
        name: "5×5 strength",
        subtitle: "3 days · two alternating templates",
        note: "Heavy compounds, five sets of five. Built for adding weight every session rather than chasing a pump.",
        days: [
            Day(letter: "A", title: "Workout A", exerciseIDs: [squat, bench, row]),
            Day(letter: "B", title: "Workout B", exerciseIDs: [squat, ohp, deadlift])
        ],
        weekAssignments: ["A", "", "B", "", "A", "", ""]
    )

    // MARK: - Building

    /// Materialises the preset into SwiftData, resolving names from the archive.
    @discardableResult
    func build(in context: ModelContext) -> Plan {
        let plan = Plan(name: name)
        context.insert(plan)
        plan.weekAssignmentsRaw = weekAssignments

        // 5×5 means five sets of five; everything else opens at 3×8.
        let isStrength = id == "strength-5x5"
        let targets = isStrength
            ? Array(repeating: SetTarget(reps: 5), count: 5)
            : Array(repeating: SetTarget(reps: 8), count: 3)

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
                    targetSets: targets.map { SetTarget(reps: $0.reps) },
                    workingWeightKg: exercise.equipment == .bodyweight ? 0 : 20,
                    stepKg: exercise.defaultStepKg,
                    restSeconds: isStrength ? 180 : 90
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
