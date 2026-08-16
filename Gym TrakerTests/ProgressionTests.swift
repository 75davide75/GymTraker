//
//  ProgressionTests.swift
//  Gym TrakerTests
//
//  Acceptance check from design/SPEC.md §7: arming progression pre-fills the
//  higher weight next session and can be overridden without losing the flag's
//  history.
//

import Testing
import Foundation
@testable import Gym_Traker

struct ProgressionTests {

    private func makeItem(armed: Bool = false) -> PlanItem {
        let item = PlanItem(
            order: 1,
            exerciseID: "bench-press",
            exerciseName: "Bench Press",
            targetSets: [SetTarget(reps: 8), SetTarget(reps: 8), SetTarget(reps: 6)],
            workingWeightKg: 70,
            stepKg: 2.5,
            restSeconds: 90
        )
        item.progressionArmed = armed
        return item
    }

    private func makeEntry(reps: [Int], targets: [Int], weightKg: Double = 70) -> SessionEntry {
        let sets = zip(reps, targets).map {
            PerformedSet(reps: $0.0, weightKg: weightKg, targetReps: $0.1, completedAt: .now)
        }
        return SessionEntry(order: 1, exerciseID: "bench-press", exerciseName: "Bench Press",
                            restSeconds: 90, sets: sets)
    }

    @Test func meetingEverySetTargetSuggestsTheNextStep() {
        let item = makeItem()
        let entry = makeEntry(reps: [8, 8, 6], targets: [8, 8, 6])
        #expect(Progression.suggestion(for: entry, item: item) == 72.5)
    }

    @Test func exceedingTargetsAlsoSuggests() {
        let item = makeItem()
        let entry = makeEntry(reps: [10, 9, 8], targets: [8, 8, 6])
        #expect(Progression.suggestion(for: entry, item: item) == 72.5)
    }

    @Test func missingASingleTargetSuggestsNothing() {
        let item = makeItem()
        let entry = makeEntry(reps: [8, 8, 5], targets: [8, 8, 6])
        #expect(Progression.suggestion(for: entry, item: item) == nil)
    }

    @Test func anArmedFlagSuggestsEvenAfterAMissedTarget() {
        let item = makeItem(armed: true)
        let entry = makeEntry(reps: [8, 6, 4], targets: [8, 8, 6])
        #expect(Progression.suggestion(for: entry, item: item) == 72.5)
    }

    @Test func incompleteSetsDoNotCountAsMetTargets() {
        let item = makeItem()
        let sets = [
            PerformedSet(reps: 8, weightKg: 70, targetReps: 8, completedAt: .now),
            PerformedSet(reps: 0, weightKg: 70, targetReps: 8, completedAt: nil)
        ]
        let entry = SessionEntry(order: 1, exerciseID: "bench-press", exerciseName: "Bench Press",
                                 restSeconds: 90, sets: sets)
        // Only the completed set is judged, and it met its target.
        #expect(Progression.suggestion(for: entry, item: item) == 72.5)
    }

    @Test func acceptingASuggestionMovesTheWeightAndClearsTheFlag() throws {
        let item = makeItem(armed: true)
        item.suggestedWeightKg = 72.5

        let change = try #require(Progression.accept(item))
        #expect(change.from == 70)
        #expect(change.to == 72.5)
        #expect(item.workingWeightKg == 72.5)
        #expect(item.suggestedWeightKg == nil)
        #expect(item.progressionArmed == false)
    }

    @Test func decliningClearsTheSuggestionButKeepsTheFlag() {
        let item = makeItem(armed: true)
        item.suggestedWeightKg = 72.5

        Progression.decline(item)

        #expect(item.suggestedWeightKg == nil)
        #expect(item.workingWeightKg == 70)
        // The intent survives a session where the numbers did not.
        #expect(item.progressionArmed)
    }

    @Test func openingWeightPrefersTheSuggestion() {
        let item = makeItem()
        #expect(item.openingWeightKg == 70)
        item.suggestedWeightKg = 72.5
        #expect(item.openingWeightKg == 72.5)
    }

    @Test func checkboxCopyReflectsTheArmedState() {
        let item = makeItem()
        #expect(Progression.label(for: item, units: .kg) == "Remind me to add 2.5 kg")
        item.progressionArmed = true
        #expect(Progression.label(for: item, units: .kg) == "Progression armed · 72.5 kg next")
    }

    @Test func applyWritesSuggestionsAcrossTheWholeSession() {
        let bench = makeItem()
        let squat = PlanItem(order: 2, exerciseID: "back-squat", exerciseName: "Back Squat",
                             targetSets: [SetTarget(reps: 5)], workingWeightKg: 100, stepKg: 5)

        let session = WorkoutSession(planDayLetter: "A", planDayTitle: "Push")
        let benchEntry = makeEntry(reps: [8, 8, 6], targets: [8, 8, 6])
        benchEntry.session = session
        let squatEntry = SessionEntry(
            order: 2, exerciseID: "back-squat", exerciseName: "Back Squat", restSeconds: 120,
            sets: [PerformedSet(reps: 3, weightKg: 100, targetReps: 5, completedAt: .now)]
        )
        squatEntry.session = session
        session.entries = [benchEntry, squatEntry]

        Progression.apply(session: session, items: [bench, squat])

        #expect(bench.suggestedWeightKg == 72.5)
        #expect(squat.suggestedWeightKg == nil)
    }
}
