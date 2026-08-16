# Gym Tracker iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the nine-screen Gym Progress Tracker iPhone app described in `design/SPEC.md` as a working SwiftUI + SwiftData application, and publish it to https://github.com/75davide75/GymTraker.

**Architecture:** One SwiftUI app target, offline-first, no backend. SwiftData owns every persisted entity. Three pure-Swift service layers sit between models and views — `RankingEngine` (tier math), `Registry` (append-only change log writes), `Progression` (suggested-weight rule) — so the numbers are unit-testable without a view. Views are organised per feature folder and all share one `DesignSystem` layer that wraps iOS 26's native Liquid Glass APIs.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing, Xcode 26.6, iOS 26.0 deployment target, native `.glassEffect` / `GlassEffectContainer`.

## Global Constraints

- App UI language is **English only**. Source comments may be English; no Italian strings in the UI.
- Deployment target **iOS 26.0** (project currently 26.5 — lower it to 26.0 to widen device support). Use native Liquid Glass APIs, no hand-rolled material imitation.
- All weights stored in **kilograms**. Unit preference is display-only: `lb = kg × 2.20462`, displayed rounded to 0.5.
- The change registry is **append-only**. Nothing edits or deletes a `ChangeRecord`; removals write a `removed` record.
- Sets within one exercise carry **independent rep counts**. Never force uniform reps.
- Animations: `.spring(response: 0.42, dampingFraction: 0.86)` for expand/collapse and transitions, `.snappy` for steppers. Every tappable glass surface scales to 0.98 on press.
- Palette: violet primary `oklch(0.62 0.19 268)`, cyan secondary `oklch(0.64 0.17 200)`, green `oklch(0.8 0.14 145)` increases, orange `oklch(0.78 0.15 30)` decreases. Backgrounds `#07070A` dark / `#EFF0F5` light.
- Corner radii: 30 hero, 26 cards and bars, 22 rows, 18–16 controls, 14 chips. Minimum hit target 44 pt.
- Tabular numerals on every weight, rep count and timer.
- Both light and dark appearance are first-class.
- The Xcode project uses `PBXFileSystemSynchronizedRootGroup`: any `.swift` file placed under `Gym Traker/Gym Traker/` joins the target automatically. Never hand-edit `project.pbxproj` to add sources.

---

## File Structure

Repository root is the existing git repo at `Gym Traker/`. The design package is copied in as `design/`.

```
Gym Traker/                              # git root → github.com/75davide75/GymTraker
├── Gym Traker.xcodeproj
├── Gym Traker/                          # app target (synchronized group)
│   ├── Gym_TrakerApp.swift              # @main, ModelContainer, seeding, appearance
│   ├── ContentView.swift                # RootView: onboarding gate + tab bar
│   ├── Resources/
│   │   ├── exercises.json               # 125-exercise archive, copied from design
│   │   └── ranking.json                 # threshold tables extracted from RANKING.md
│   ├── Models/
│   │   ├── Enums.swift                  # Sex, Units, ChangeField, Direction, Tracking, Equipment
│   │   ├── UserProfile.swift            # + BodyweightEntry
│   │   ├── Exercise.swift               # archive row + Glyph descriptor
│   │   ├── TrainingPlan.swift           # Plan, PlanDay, PlanItem, SetTarget
│   │   ├── WorkoutSession.swift         # WorkoutSession, SessionEntry, PerformedSet
│   │   └── ChangeRecord.swift
│   ├── Services/
│   │   ├── ArchiveSeeder.swift          # first-launch + version-bump upsert
│   │   ├── Registry.swift               # the only writer of ChangeRecord
│   │   ├── Progression.swift            # suggested-weight rule
│   │   ├── UnitFormatter.swift          # kg↔lb display, tabular strings
│   │   ├── RestTimer.swift              # @Observable countdown + notification
│   │   └── DataExporter.swift           # JSON export
│   ├── Ranking/
│   │   ├── Tier.swift                   # tier enum, divisions, colours, ladder copy
│   │   ├── RankingTables.swift          # decodes ranking.json
│   │   └── RankingEngine.swift          # e1RM, score, tier, global level
│   ├── DesignSystem/
│   │   ├── Theme.swift                  # colours, radii, typography tokens
│   │   ├── AuroraBackground.swift       # two drifting radial blooms
│   │   ├── GlassSurfaces.swift          # GlassCard, GlassTile, PressableStyle
│   │   ├── StepperControl.swift         # −/+ control, .snappy, haptics
│   │   ├── ExerciseGlyph.swift          # generative diagram, 8 shapes × hue
│   │   └── Haptics.swift
│   └── Features/
│       ├── Onboarding/OnboardingView.swift
│       ├── Home/HomeView.swift
│       ├── Session/SessionView.swift, ExerciseCard.swift, RestBar.swift, SummarySheet.swift
│       ├── PlanEditor/PlanEditorView.swift, WeekScheduleGrid.swift
│       ├── Library/LibraryView.swift, NewExerciseView.swift, ExerciseDetailView.swift
│       ├── Registry/RegistryView.swift
│       └── Profile/YouView.swift, SettingsView.swift, PromotionView.swift
├── Gym TrakerTests/                      # Swift Testing
│   ├── RankingEngineTests.swift
│   ├── RegistryTests.swift
│   ├── ProgressionTests.swift
│   └── UnitFormatterTests.swift
├── design/                               # copied design package
├── docs/superpowers/plans/
├── .gitignore
└── README.md
```

---

### Task 1: Models, enums and the ModelContainer

**Files:**
- Create: `Gym Traker/Models/Enums.swift`, `UserProfile.swift`, `Exercise.swift`, `TrainingPlan.swift`, `WorkoutSession.swift`, `ChangeRecord.swift`
- Modify: `Gym Traker/Gym_TrakerApp.swift`
- Modify: `Gym Traker.xcodeproj/project.pbxproj` (deployment target 26.5 → 26.0 only)

**Interfaces:**
- Produces: the `@Model` types exactly as written in `design/DATA-MODEL.md`, plus `enum Sex: String`, `enum Units: String`, `enum ChangeField: String { weight, reps, sets, rest, progression, tier, added, removed }`, `enum ChangeDirection: String { up, down, neutral }`, `enum Tracking: String { weightReps, repsOptionalLoad, time, timeDistance }`.
- Produces: `ModelContainer` shared through `.modelContainer(for:)` in the App scene.

- [ ] **Step 1:** Write `Enums.swift` with the five enums above, each `Codable` and `CaseIterable` where the UI needs iteration.
- [ ] **Step 2:** Transcribe every `@Model` class from `design/DATA-MODEL.md` verbatim into the Models files, splitting by the file map above. `SetTarget`, `PerformedSet`, `BodyweightEntry` stay `Codable` structs.
- [ ] **Step 3:** In `Gym_TrakerApp.swift`, attach `.modelContainer(for: [UserProfile.self, Exercise.self, Plan.self, PlanDay.self, PlanItem.self, WorkoutSession.self, SessionEntry.self, ChangeRecord.self])`.
- [ ] **Step 4:** Lower `IPHONEOS_DEPLOYMENT_TARGET` to `26.0` in both build configurations.
- [ ] **Step 5:** Build for the iPhone 17 simulator. Expected: `BUILD SUCCEEDED`.
- [ ] **Step 6:** Commit `feat: SwiftData models and container`.

**Done when:** the app builds and launches with an empty store and no runtime SwiftData schema error.

---

### Task 2: Archive seeding and unit formatting

**Files:**
- Create: `Gym Traker/Resources/exercises.json` (copy of `design/data/exercises.json`)
- Create: `Gym Traker/Services/ArchiveSeeder.swift`, `UnitFormatter.swift`
- Test: `Gym TrakerTests/UnitFormatterTests.swift`

**Interfaces:**
- Produces: `enum ArchiveSeeder { static func seedIfNeeded(_ context: ModelContext) throws }` — decodes the bundled JSON, inserts one `Exercise` per entry with `isCustom = false`, stores `archiveVersion` in `UserDefaults`, and on a version bump upserts by `id` while never touching rows where `isCustom == true`.
- Produces: `enum UnitFormatter { static func weight(_ kg: Double, in units: Units) -> String; static func short(_ kg: Double, in units: Units) -> String; static func kg(fromDisplay value: Double, in units: Units) -> Double }`.

- [ ] **Step 1:** Write the failing test for unit conversion:

```swift
@Test func poundsRoundToHalf() {
    #expect(UnitFormatter.weight(72.5, in: .kg) == "72.5 kg")
    #expect(UnitFormatter.weight(72.5, in: .lb) == "160 lb")   // 159.83 → 160.0
    #expect(UnitFormatter.kg(fromDisplay: 160, in: .lb) == 72.5)
}
```

- [ ] **Step 2:** Run it. Expected: fails, `UnitFormatter` not found.
- [ ] **Step 3:** Implement `UnitFormatter`. Conversion `kg × 2.20462`, rounded to the nearest 0.5, trailing `.0` trimmed.
- [ ] **Step 4:** Implement `ArchiveSeeder`. Decode into a private `ArchiveFile: Decodable { let version: Int; let exercises: [ArchiveEntry] }`.
- [ ] **Step 5:** Call `ArchiveSeeder.seedIfNeeded` from the App's container setup.
- [ ] **Step 6:** Run tests, then run the app and confirm 125 archive rows exist (temporary count label or a `#expect` in a seeding test).
- [ ] **Step 7:** Commit `feat: archive seeding and unit formatting`.

**Done when:** first launch inserts exactly 125 exercises; a second launch inserts none.

---

### Task 3: Ranking engine

**Files:**
- Create: `Gym Traker/Resources/ranking.json`, `Gym Traker/Ranking/Tier.swift`, `RankingTables.swift`, `RankingEngine.swift`
- Test: `Gym TrakerTests/RankingEngineTests.swift`

**Interfaces:**
- Produces: `enum Tier: Int, CaseIterable { beginner, novice, intermediate, advanced, elite }` with `displayName`, `scoreRange`, `note`, `tint`.
- Produces: `struct RankResult { let score: Double; let tier: Tier; let division: Int; let e1RM: Double; let nextThresholdKg: Double? }` with `label` → `"Intermediate I"`.
- Produces: `enum RankingEngine { static func e1RM(weightKg: Double, reps: Int) -> Double; static func rank(anchor: String, weightKg: Double, reps: Int, profile: UserProfile) -> RankResult?; static func globalLevel(lifts: [RankResult], sessionsLast4Weeks: Int) -> RankResult? }`.

- [ ] **Step 1:** Extract the two threshold tables, the bodyweight rep table and the age-factor bands from `design/RANKING.md` §2 into `ranking.json`, versioned.
- [ ] **Step 2:** Write the failing tests straight from `RANKING.md` §5:

```swift
@Test func benchWorkedExample() {
    let p = UserProfile.test(sex: .male, age: 27, bodyweightKg: 78)
    let r = RankingEngine.rank(anchor: "bench", weightKg: 72.5, reps: 8, profile: p)!
    #expect(abs(r.e1RM - 91.83) < 0.01)
    #expect(r.tier == .intermediate)
    #expect(r.division == 1)
    #expect(abs(r.score - 41.8) < 0.1)
}

@Test func squatWorkedExample() {
    let p = UserProfile.test(sex: .male, age: 27, bodyweightKg: 78)
    let r = RankingEngine.rank(anchor: "squat", weightKg: 115, reps: 6, profile: p)!
    #expect(abs(r.score - 48.8) < 0.1)
    #expect(r.division == 2)
}

@Test func meetingStandardExactlyLandsAtTierBottom() {
    let p = UserProfile.test(sex: .male, age: 27, bodyweightKg: 78)
    // 1.15 × 78 = 89.7 e1RM exactly → Intermediate I, 0 % progress
    let r = RankingEngine.rank(anchor: "bench", weightKg: 89.7, reps: 0, profile: p)!
    #expect(r.tier == .intermediate)
    #expect(abs(r.score - 40.0) < 0.001)
}
```

- [ ] **Step 3:** Run. Expected: fails to compile, `RankingEngine` missing.
- [ ] **Step 4:** Implement the piecewise-linear score from `RANKING.md` §3, reps capped at 10 for scoring, division = thirds of the tier band, plus the `bw` reps table with `effectiveReps = reps × (bodyweight + load) / bodyweight`.
- [ ] **Step 5:** Implement `globalLevel`: mean of the four anchor scores present, `consistency = min(5, sessions / 16 × 5)`, capped at 100; returns `nil` when fewer than two anchors have data.
- [ ] **Step 6:** Run tests. Expected: all pass.
- [ ] **Step 7:** Commit `feat: ranking engine with strength standards`.

**Done when:** both worked examples from the spec pass to within 0.1 score points.

---

### Task 4: Registry and progression services

**Files:**
- Create: `Gym Traker/Services/Registry.swift`, `Progression.swift`
- Test: `Gym TrakerTests/RegistryTests.swift`, `ProgressionTests.swift`

**Interfaces:**
- Produces: `enum Registry { static func record(_ field: ChangeField, exercise: Exercise, from: String, to: String, direction: ChangeDirection, in context: ModelContext) }` plus typed helpers `weightChanged`, `repsChanged(setIndex:)`, `setsChanged`, `restChanged`, `progressionToggled`, `tierChanged`, `exerciseAdded`, `exerciseRemoved`.
- Produces: `enum Progression { static func suggestion(for entry: SessionEntry, item: PlanItem) -> Double? }` implementing the rule in `DATA-MODEL.md`.

- [ ] **Step 1:** Write failing tests: one weight change writes exactly one record with correct from/to/direction; a reps change records the set index as `"Set 3 · 6 reps"` → `"Set 3 · 8 reps"`; removing a plan item writes a `removed` record and deletes nothing.
- [ ] **Step 2:** Run. Expected: fail.
- [ ] **Step 3:** Implement `Registry`. Values are pre-formatted display strings in the user's current units at write time.
- [ ] **Step 4:** Write the failing progression test: all sets meeting target reps → suggestion is `workingWeight + step`; `progressionArmed` → suggestion at least `workingWeight + step`; a missed target with the flag off → `nil`.
- [ ] **Step 5:** Implement `Progression`.
- [ ] **Step 6:** Run all tests. Expected: pass.
- [ ] **Step 7:** Commit `feat: append-only change registry and progression rule`.

**Done when:** each parameter change produces exactly one record, and no code path outside `Registry` constructs a `ChangeRecord`.

---

### Task 5: Design system — glass, aurora, glyphs

**Files:**
- Create: `Gym Traker/DesignSystem/Theme.swift`, `AuroraBackground.swift`, `GlassSurfaces.swift`, `StepperControl.swift`, `ExerciseGlyph.swift`, `Haptics.swift`

**Interfaces:**
- Produces: `enum Theme` with `Color.violet/.cyan/.increase/.decrease`, `Radius` constants, `Font` helpers (`.display`, `.titleL`, `.bodyM`, `.caption`, `.overline`) all with `.monospacedDigit()` where numeric.
- Produces: `struct GlassCard<Content: View>: View` (`init(radius:padding:@ViewBuilder content:)`) applying `.glassEffect(.regular, in: .rect(cornerRadius:))`, and `struct PressableStyle: ButtonStyle` scaling to 0.98.
- Produces: `struct AuroraBackground: View` — two radial gradient blooms drifting on a 17 s loop over the base colour, adapting to colour scheme.
- Produces: `struct ExerciseGlyph: View` (`init(shape: String, hue: Int, size: CGFloat)`) rendering the eight primitives `bar · dumbbell · frame · cable · ring · bell · wave · arc` on a hue-tinted rounded tile.
- Produces: `enum Haptics { static func light(); static func medium(); static func success() }`.

- [ ] **Step 1:** Write `Theme.swift` converting the spec's oklch values to `Color(red:green:blue:)` sRGB equivalents, with light/dark variants.
- [ ] **Step 2:** Write `AuroraBackground` using two `RadialGradient` ellipses inside a `TimelineView(.animation)` drift, blurred 34 pt.
- [ ] **Step 3:** Write `GlassSurfaces.swift` wrapping the native `.glassEffect` and `GlassEffectContainer`, with the hairline stroke and inset top highlight.
- [ ] **Step 4:** Write `ExerciseGlyph` — one `switch` over the shape string composing `Capsule`, `Circle`, `RoundedRectangle` primitives. Verify all eight shapes in an Xcode preview grid.
- [ ] **Step 5:** Write `StepperControl` (46–52 pt targets, `.snappy`, medium haptic) and `Haptics`.
- [ ] **Step 6:** Build and check the preview grid renders all eight glyphs in both appearances.
- [ ] **Step 7:** Commit `feat: liquid glass design system`.

**Done when:** every archive glyph shape renders distinctly and the aurora animates without dropping frames.

---

### Task 6: Plan editor

**Files:**
- Create: `Gym Traker/Features/PlanEditor/PlanEditorView.swift`, `WeekScheduleGrid.swift`

- [ ] **Step 1:** Build `WeekScheduleGrid`: seven day cells, tapping cycles `Rest → A → B → C → … → Rest`, writing `plan.weekAssignments`. The same letter is allowed on several days.
- [ ] **Step 2:** Build the day-template tab row (`A Push`, `B Pull`, `C Legs`, `+` appends D, E, …) with editable titles.
- [ ] **Step 3:** Build the numbered exercise list: index badge, name, scheme summary `4 sets · 8/8/6/6 reps · 72.5 kg`, rest, remove. `.onMove` reorders and renumbers `PlanItem.order`.
- [ ] **Step 4:** Per-item editor sheet: working weight stepper (`stepKg`), per-set reps steppers, `+ Add set` copying the previous set's reps, delete set, rest picker. Every change calls the matching `Registry` helper.
- [ ] **Step 5:** `+ Add exercise from library` presents `LibraryView` in picker mode (Task 7 provides it; until then wire the presentation and a stub list) and appends the picked exercise with 3 × 10 defaults.
- [ ] **Step 6:** Removing an item calls `Registry.exerciseRemoved`.
- [ ] **Step 7:** Manual check on the simulator: assign template A to Monday and Thursday, confirm both show A. Commit `feat: plan editor`.

**Done when:** a three-day plan can be built end to end and survives relaunch, and repeated letters within a week work.

---

### Task 7: Library, new exercise, exercise detail

**Files:**
- Create: `Gym Traker/Features/Library/LibraryView.swift`, `NewExerciseView.swift`, `ExerciseDetailView.swift`

- [ ] **Step 1:** `LibraryView(mode: .browse | .picker(onSelect:))` — count line, `+ New`, search matching name and muscle, equipment filter chips (All · Barbell · Dumbbell · Machine · Cable · Bodyweight · Kettlebell · Cardio · Mobility).
- [ ] **Step 2:** Rows: 52 pt `ExerciseGlyph`, name, `muscle · equipment`, `Custom` badge when `isCustom`, chevron.
- [ ] **Step 3:** `NewExerciseView` — live glyph preview that updates as equipment changes, name field, primary-muscle chips, equipment chips, optional "treat as" rank anchor picker, `Save to my library` setting `isCustom = true` and a slugified unique `id`.
- [ ] **Step 4:** `ExerciseDetailView` — tier card (tier + division, e1RM, progress bar, "Next tier at N kg estimated 1RM"), working-weight bar chart over the last 8 sessions with the latest bar accented, set scheme list, and the registry filtered to this exercise.
- [ ] **Step 5:** Manual check: create a custom exercise, confirm it appears in search, in a filter chip and in the plan picker with a matching diagram. Commit `feat: exercise library, custom exercises and detail`.

**Done when:** the acceptance check "a custom exercise appears in search, filters, plan picker and gets a matching diagram" passes.

---

### Task 8: Workout session, rest timer, registry writes

**Files:**
- Create: `Gym Traker/Features/Session/SessionView.swift`, `ExerciseCard.swift`, `RestBar.swift`, `SummarySheet.swift`, `Gym Traker/Services/RestTimer.swift`

- [ ] **Step 1:** `SessionView` — header with elapsed time and a progress bar over total sets; a vertical scroll of exercise cards where the current one is expanded and the rest are collapsed, animated with the spec's spring.
- [ ] **Step 2:** Expanded card: working-weight stepper using `item.stepKg`, writing a registry entry on change; one row per set with a completion circle, `Set n` and an independent reps stepper; `+ Add set` copying the previous reps.
- [ ] **Step 3:** Progression checkbox — "Remind me to add 2.5 kg" / "Progression armed · 75 kg next", persisted on `PlanItem.progressionArmed`, writing a registry entry. A pending `suggestedWeightKg` shows a "suggested" badge that can be accepted or overridden.
- [ ] **Step 4:** Rest pill cycling 45 → 60 → 75 → … → 180 → 45, writing a registry entry.
- [ ] **Step 5:** `RestTimer` as an `@Observable` — completing a set starts the exercise's rest countdown, stores a fire date so the remaining time is restored after backgrounding, and schedules a local notification. `RestBar` floats above the tab bar with a circular countdown, "Resting / Next · <exercise> set n" and `Skip`; the last five seconds pulse.
- [ ] **Step 6:** `Close` → `SummarySheet` (total volume, sets logged, tier changes, new registry entries) → persists a `WorkoutSession` with the real per-set values, then runs `Progression.suggestion` for each entry and recomputes ranks.
- [ ] **Step 7:** Haptics: light on set completion, medium on weight change, success on session complete.
- [ ] **Step 8:** Manual check: log a session with sets of 8/8/6/6, relaunch, confirm the differing rep counts persisted. Commit `feat: workout session with per-set logging and rest timer`.

**Done when:** the acceptance checks on registry entries, armed progression pre-fill and non-uniform sets all pass.

---

### Task 9: Registry screen and Home

**Files:**
- Create: `Gym Traker/Features/Registry/RegistryView.swift`, `Gym Traker/Features/Home/HomeView.swift`

- [ ] **Step 1:** `RegistryView` — reverse-chronological, grouped `Recent` / `Earlier` / by month; each entry shows the direction glyph (↑ green, ↓ orange, · neutral), exercise name, `field · from → to` and a relative date. Filter by exercise and by field. Paged 50 at a time.
- [ ] **Step 2:** `HomeView` — greeting and a Mon–Sun week strip showing each day's template letter with today highlighted; tapping opens Plan.
- [ ] **Step 3:** "Up next" card — day title, exercise count, estimated duration, first three exercises with their scheme, `Start workout` primary button.
- [ ] **Step 4:** Two glass tiles — current rank with progress to the next tier, and the most recent registry entry.
- [ ] **Step 5:** "This week" volume bars per weekday plus the consistency line ("11 sessions in the last 4 weeks").
- [ ] **Step 6:** Commit `feat: home dashboard and change registry screen`.

**Done when:** a weight change made in a session appears at the top of the registry and in the Home tile.

---

### Task 10: You, promotion moment, onboarding, settings, export

**Files:**
- Create: `Gym Traker/Features/Profile/YouView.swift`, `SettingsView.swift`, `PromotionView.swift`, `Gym Traker/Features/Onboarding/OnboardingView.swift`, `Gym Traker/Services/DataExporter.swift`
- Modify: `Gym Traker/ContentView.swift` (onboarding gate + `Home · Plan · Library · Registry · You` tab bar)

- [ ] **Step 1:** `OnboardingView` — three steps: welcome + units; calibration (sex, age, bodyweight via steppers, no keyboard); plan start with the presets Push/Pull/Legs 3×, Upper/Lower 4×, Full body 3×, or empty. Writes a `UserProfile` and, for a preset, a `Plan` with `weekAssignments = ["A", nil, "B", nil, "C", nil, nil]`.
- [ ] **Step 2:** `ContentView` shows onboarding when no profile exists, otherwise the five-tab bar.
- [ ] **Step 3:** `YouView` — avatar, `sex · age · bodyweight`; global rank card with a 0–100 score ring, tier and division, the guidelines disclaimer line, consistency; tier per lift for squat, bench, deadlift and overhead press; the five-tier ladder with the spec's copy, current tier highlighted.
- [ ] **Step 4:** `PromotionView` — full-screen glass card naming the new tier, the lift that earned it and the numbers behind it, success haptic, fires once per tier per exercise. No confetti.
- [ ] **Step 5:** `SettingsView` — units, appearance (Dark/Light/System), profile edit (a bodyweight edit re-ranks every lift and surfaces "tiers recalculated for 79 kg"), notification preferences, export.
- [ ] **Step 6:** `DataExporter` writes one JSON file containing profile, plan, exercises, sessions and registry, shared via `ShareLink`.
- [ ] **Step 7:** Commit `feat: profile, ranking screen, onboarding and export`.

**Done when:** a fresh install can be onboarded, reach a plan, log a session and see a rank without touching Xcode.

---

### Task 11: Motion, light mode, verification pass

**Files:** touches views across `Features/`

- [ ] **Step 1:** Apply the entry transition everywhere — 14 pt upward offset plus opacity over 0.4 s, staggered 30 ms per list child, capped at 8 items.
- [ ] **Step 2:** Confirm every tappable glass surface uses `PressableStyle`, and card expansion animates height and tint together with collapsed titles dimmed to secondary.
- [ ] **Step 3:** Light-mode pass — raise stroke opacity, lower blur, screenshot every screen in both appearances on the simulator.
- [ ] **Step 4:** Walk the seven acceptance checks in `design/SPEC.md` §7 on the simulator and record the result of each.
- [ ] **Step 5:** Run the full test suite. Expected: all pass.
- [ ] **Step 6:** Commit `feat: motion, haptics and light mode pass`.

**Done when:** all seven acceptance checks pass and both appearances are screenshotted.

---

### Task 12: Repository publication

**Files:**
- Create: `.gitignore`, `README.md`
- Copy: `design/` from `../Gym Progress Tracker App`

- [ ] **Step 1:** Write `.gitignore` for Xcode (`xcuserdata/`, `DerivedData/`, `.DS_Store`, `*.xcuserstate`).
- [ ] **Step 2:** `git rm -r --cached` anything already tracked that the ignore file now covers.
- [ ] **Step 3:** Copy the design package to `design/`.
- [ ] **Step 4:** Write `README.md` — what the app is, the three pillars, screenshots, build instructions (Xcode 26.6, iOS 26 simulator), the ranking system summary and a pointer to `design/SPEC.md`.
- [ ] **Step 5:** `git remote add origin https://github.com/75davide75/GymTraker.git`, reconcile with the existing remote README, push `main`.
- [ ] **Step 6:** Verify with `gh repo view` that the tree is on GitHub.

**Done when:** https://github.com/75davide75/GymTraker holds the Xcode project, the design folder and a README, and the project clones and builds from a fresh checkout.
