# Data model — SwiftData

Swift 6, SwiftData, iOS 18+. All weights in **kilograms**; unit preference affects display only.

```swift
import SwiftData
import Foundation

// MARK: - Profile

@Model final class UserProfile {
    var name: String
    var sexRaw: String          // "male" | "female"
    var birthYear: Int
    var bodyweightKg: Double
    var unitsRaw: String        // "kg" | "lb"
    var appearanceRaw: String   // "dark" | "light" | "system"
    var createdAt: Date
    var bodyweightHistory: [BodyweightEntry]

    var sex: Sex { Sex(rawValue: sexRaw) ?? .male }
    var age: Int { Calendar.current.component(.year, from: .now) - birthYear }
}

struct BodyweightEntry: Codable, Hashable { var date: Date; var kg: Double }
enum Sex: String, Codable { case male, female }
enum Units: String, Codable { case kg, lb }

// MARK: - Archive

@Model final class Exercise {
    @Attribute(.unique) var id: String      // slug, e.g. "bench-press"
    var name: String
    var primaryMuscle: String               // Chest, Back, Shoulders, Arms, Legs, Glutes, Core, Full body, Cardio, Mobility
    var equipment: String                   // Barbell, Dumbbell, Machine, Cable, Bodyweight, Kettlebell, Cardio, Mobility
    var rankAnchorRaw: String?              // bench | squat | deadlift | ohp | row | bw | nil
    var trackingRaw: String                 // weightReps | repsOptionalLoad | time | timeDistance
    var glyphShape: String                  // bar | dumbbell | frame | cable | ring | bell | wave | arc
    var glyphHue: Int
    var isCustom: Bool
    var notes: String?

    // cached ranking output
    var cachedScore: Double?
    var cachedTierIndex: Int?
    var cachedScoredAt: Date?
}

// MARK: - Plan

@Model final class Plan {
    var name: String
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var days: [PlanDay]
    /// index 0 = Monday … 6 = Sunday; value = PlanDay.letter or nil for rest
    var weekAssignments: [String?]
}

@Model final class PlanDay {
    var letter: String                      // "A", "B", "C", …
    var title: String                       // "Push"
    var order: Int
    @Relationship(deleteRule: .cascade) var items: [PlanItem]
    var plan: Plan?
}

/// One numbered line of a day template. Holds the *plan*, not the history.
@Model final class PlanItem {
    var order: Int                          // 1-based, renumbered on reorder
    var exerciseID: String
    var targetSets: [SetTarget]             // per-set reps — sets may differ
    var workingWeightKg: Double
    var stepKg: Double                      // increment used by the steppers (2.5 barbell, 2 dumbbell, 5 leg press)
    var restSeconds: Int
    var progressionArmed: Bool              // user asked to go up next session
    var suggestedWeightKg: Double?          // written by the auto-progression rule
    var day: PlanDay?
}

struct SetTarget: Codable, Hashable { var reps: Int }

// MARK: - Sessions (what actually happened)

@Model final class WorkoutSession {
    var startedAt: Date
    var endedAt: Date?
    var planDayLetter: String
    var planDayTitle: String
    @Relationship(deleteRule: .cascade) var entries: [SessionEntry]

    var totalVolumeKg: Double { entries.flatMap(\.sets).reduce(0) { $0 + $1.weightKg * Double($1.reps) } }
}

@Model final class SessionEntry {
    var order: Int
    var exerciseID: String
    var exerciseName: String                // denormalised so history survives archive edits
    var restSeconds: Int
    var sets: [PerformedSet]
    var session: WorkoutSession?

    var bestE1RM: Double { sets.map { $0.weightKg * (1 + Double(min($0.reps, 10)) / 30) }.max() ?? 0 }
}

struct PerformedSet: Codable, Hashable {
    var reps: Int
    var weightKg: Double
    var completedAt: Date?
    var isWarmup: Bool = false
}

// MARK: - Change registry (append-only)

@Model final class ChangeRecord {
    var date: Date
    var exerciseID: String
    var exerciseName: String
    var fieldRaw: String                    // weight | reps | sets | rest | progression | tier | added | removed
    var fromValue: String                   // display strings, already formatted ("70 kg")
    var toValue: String
    var directionRaw: String                // up | down | neutral
    var sessionID: PersistentIdentifier?
}
```

## Seeding

1. On first launch decode `exercises.json` from the bundle and insert one `Exercise` per entry with `isCustom = false`.
2. Store the archive `version` in `UserDefaults`. On a bundle version bump, upsert by `id` and never touch rows where `isCustom == true`.
3. Presets create a `Plan` with three `PlanDay`s and `weekAssignments = ["A", nil, "B", nil, "C", nil, nil]`.

## Registry rules

- One `ChangeRecord` per user-visible parameter change, written in the same transaction as the change.
- `fromValue` / `toValue` are formatted in the user's current unit at write time; also keep the raw kg in the string only if needed for debugging — the registry is a human log, not a source of truth for numbers.
- Reps changes record the set index: `field = "reps"`, `from = "Set 3 · 6 reps"`, `to = "Set 3 · 8 reps"`.
- Tier changes are recorded too (`field = "tier"`, `from = "Intermediate III"`, `to = "Advanced I"`), which is what powers the "why did my rank move" answer.
- Never delete records when a plan item is removed; write a `removed` record instead.

## Progression rule (both automatic and manual)

On session save, for each `SessionEntry`:

```
if every set met or exceeded its target reps:
    suggestedWeightKg = workingWeightKg + stepKg
if progressionArmed:
    suggestedWeightKg = max(suggested ?? 0, workingWeightKg + stepKg)
```

The next session pre-fills `suggestedWeightKg` with a "suggested" badge. Accepting it sets `workingWeightKg` and writes a `weight` record; rejecting clears the suggestion and writes nothing. `progressionArmed` resets after the weight actually moves.

## Queries the UI needs

- `Home` — active plan, today's `PlanDay`, last 4 weeks of `WorkoutSession` (count + per-weekday volume), newest `ChangeRecord`.
- `Session` — today's `PlanDay` with items, plus each item's last `SessionEntry` for the "vs last time" delta.
- `Detail` — last 8 `SessionEntry` for one exercise (chart), `ChangeRecord` filtered by exercise.
- `Registry` — all records, sorted descending, paged 50 at a time, filter by exercise / field.
- `You` — cached scores of the four anchor lifts + session count for the consistency bonus.
