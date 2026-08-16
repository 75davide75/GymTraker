# Gym Progress Tracker — Product & Implementation Spec

Target: native iOS app (SwiftUI, iOS 18+), Xcode project, SwiftData persistence, offline-first, no backend.
App UI language: **English only**. Design language: Apple Liquid Glass — translucent materials, soft gradient blooms, spring animations.

Reference prototype: `Gym Tracker.dc.html` (interactive, all nine screens, live state).
Companion docs: `DATA-MODEL.md` (SwiftData), `RANKING.md` (tier math), `data/exercises.json` (125-exercise seed archive).

---

## 1. Scope

Three pillars, from the brief:

1. **Exercise tracking** — weight, rest time, set count, per-set reps. Every change to any of these parameters is written to a **change registry** readable elsewhere in the app, with the date of the change. A per-exercise flag arms a "go up next time" reminder.
2. **Plan builder** — a plan is a set of numbered day-templates (A, B, C, …). Each weekday maps to zero or one day-template, and a template may repeat within the week. Exercises come from a bundled archive; users can add their own, which persist in their archive with the same diagram style.
3. **Ranking** — per-exercise strength tiers from real strength standards plus a global profile level. Full math in `RANKING.md`.

Out of scope for v1: social features, cloud sync, Watch app, HealthKit, media attachments.

---

## 2. Screens

Nine screens, all present in the prototype. Tab bar: **Home · Plan · Library · Registry · You**.

### 2.1 Onboarding (3 steps)
1. Welcome + units (kg/lb).
2. **Calibration** — sex, age, bodyweight. These set the thresholds every tier is measured against (`RANKING.md` §2). Steppers, not keyboards, for age and bodyweight.
3. Plan start — pick a preset (Push/Pull/Legs 3×, Upper/Lower 4×, Full body 3×) or start empty.

Onboarding writes a `UserProfile`. Values remain editable in **You › Settings**.

### 2.2 Home
- Greeting + week strip (Mon–Sun) showing each day's assigned template letter; today is highlighted. Tapping the strip opens Plan.
- **Up next** card: day title, exercise count, estimated duration, first three exercises with their scheme (`4×8 · 72.5 kg`), primary button `Start workout`.
- Two glass tiles: current **Rank** (tier + progress to next tier) and **Last change** (most recent registry entry).
- **This week** volume bars (per weekday) + consistency line ("11 sessions in the last 4 weeks").

### 2.3 Workout session — the chosen structure (option B)
Vertical scrollable list of exercise cards; the current exercise is expanded, the rest collapsed. Header: elapsed time + progress bar over total sets.

Expanded card contains:
- **Working weight** with −/+ steppers using the exercise's `step` (2.5 kg barbell, 2 kg dumbbell/cable, 5 kg leg press — configurable per exercise). A change here writes a registry entry immediately.
- **One row per set**: a completion circle, `Set n`, and a −/+ reps stepper. **Each set carries its own rep count** — sets are not forced to be uniform. `+ Add set` appends a set copying the previous set's reps.
- **Progression checkbox**: "Remind me to add 2.5 kg" / when armed: "Progression armed · 75 kg next". Persisted on the exercise; the next session pre-fills the higher weight and shows a "suggested" badge that the user can accept or override (both automatic suggestion and manual arming, per the brief).
- **Rest** pill: tap cycles 45 s → 60 → 75 … → 180 → 45. Changing it writes a registry entry.
- **Stats** opens the exercise detail screen.

Floating glass rest bar (above the tab bar): circular countdown, "Resting / Next · <exercise> set n", `Skip`. Completing a set starts the exercise's rest timer automatically. Timer must keep running in background: schedule a local notification on completion and restore remaining time from a stored fire date.

Session end: `Close` → summary sheet (total volume, sets logged, tier changes triggered, new registry entries) → writes a `WorkoutSession`.

### 2.4 Plan editor
- Plan title.
- **Weekly schedule**: seven tappable day cells; each tap cycles `Rest → A → B → C → Rest`. A letter may appear on several days (repetition within the week is expected).
- **Day tabs** `A Push`, `B Pull`, `C Legs`, plus `+` to add a day-template (letters continue D, E, …).
- **Numbered exercise list** for the selected day: index badge, name, scheme summary (`4 sets · 8/8/6/6 reps · 72.5 kg`), rest, remove button. Drag to reorder (renumbers).
- `+ Add exercise from library` opens the Library in picker mode; picking returns to the Plan with the exercise appended and default sets (3 × 10) that the user then edits.

### 2.5 Library (archive)
- Count line + `+ New`.
- Search field (matches name and muscle).
- Equipment filter chips: All · Barbell · Dumbbell · Machine · Cable · Bodyweight · Kettlebell · Cardio · Mobility.
- Rows: 52 pt diagram tile, name, `muscle · equipment` (custom items badged `Custom`), chevron. Tap → exercise detail, or select when in picker mode.

**Diagrams.** All archive images share one generative grammar so nothing looks hand-drawn or mismatched: a rounded tile tinted by equipment hue, containing a composition of primitives keyed to the equipment type — `bar` (centre bar + two plates), `dumbbell` (two spheres + short bar), `frame` (rounded rectangle), `cable` (vertical line + plate), `ring` (outlined circle), `bell` (filled circle + handle), `wave` (horizontal bars), `arc` (half circle). Implement as a single `ExerciseGlyph` SwiftUI view driven by `glyph.shape` + `glyph.hue` from the archive JSON, so custom exercises get a matching diagram for free. If real illustrations are commissioned later, swap the view's body only.

### 2.6 New exercise
Live diagram preview (updates as equipment changes), name field, primary-muscle chips, equipment chips, `Save to my library`. Saved items get `isCustom = true`, appear in search and filters, and are pickable in the plan. Rank anchor for custom exercises defaults to `nil` (no tier) with an optional "treat as" picker (bench / squat / deadlift / press / row).

### 2.7 Registry (change log)
Reverse-chronological list, grouped (`Recent`, `Earlier`, then by month). Each entry: direction glyph (↑ green / ↓ orange / · neutral), exercise name, `field · from → to`, relative date. Filterable by exercise and by field. This is the read side of requirement 1 — nothing else writes here, and nothing is ever silently overwritten.

Fields that generate entries: `weight`, `reps` (per set index), `sets`, `rest`, `progressionArmed`, `exerciseAdded`, `exerciseRemoved`.

### 2.8 Exercise detail
- Name + current scheme.
- **Tier card**: tier name + division (e.g. `Advanced I`), estimated 1RM, progress bar to the next tier, "Next tier at 105 kg estimated 1RM".
- **Working weight, last 8 sessions** — bar chart, latest bar accented.
- **Set scheme** list (per-set reps and load).
- **Registry for this exercise** — filtered entries.

### 2.9 You (profile & ranking)
- Avatar, name, `sex · age · bodyweight`.
- **Global rank** card: 0–100 score ring, tier + division, one-line explanation, consistency line.
- **Tier per lift**: squat, bench, deadlift, overhead press — tier, progress bar, `load × reps`, `e1RM`.
- **The ladder**: five tiers with score ranges and a plain-language note; current tier highlighted.
- **Settings**: units (kg/lb), appearance (Dark/Light), profile edit, notification preferences, export data (JSON).

---

## 3. Interaction & motion

- Spring animations only: `.spring(response: 0.42, dampingFraction: 0.86)` for card expand/collapse and screen transitions; `.snappy` for steppers.
- Every tappable glass surface scales to 0.98 on press.
- Card expansion animates height and background tint together; collapsed cards dim their title to secondary text.
- Screen entry: 14 pt upward offset + opacity, 0.4 s, staggered by 30 ms for list children (cap the stagger at 8 items).
- Rest timer ring animates linearly; the last 5 seconds pulse the ring.
- Haptics: `.light` on set completion, `.medium` on weight change, `.success` on session complete and on tier promotion.
- Tier promotion is the one celebratory moment: full-screen glass card with the new tier name, the lift that earned it, and the numbers behind it. No confetti.

## 4. Visual system

- Materials: `.ultraThinMaterial` for cards, `.regularMaterial` for the floating bars, plus a 1 pt hairline stroke at 12 % white (dark) / 9 % black (light) and an inset top highlight.
- Background: two animated radial gradient blooms (violet `oklch(0.62 0.19 268)`, cyan `oklch(0.64 0.17 200)`) behind a near-black `#07070A` (dark) or `#EFF0F5` (light), 34 pt blur, 17 s drift loop.
- Accents: violet primary, cyan secondary. Semantic: green `oklch(0.8 0.14 145)` for increases, orange `oklch(0.78 0.15 30)` for decreases.
- Tier colours: Beginner neutral, Novice cyan, Intermediate violet, Advanced amber, Elite magenta.
- Type: SF Pro. Display 30/700/-0.9, title 22/700, body 15/600, caption 12/600, overline 11/600 with 1.2 pt tracking uppercase. Tabular numerals for every weight, rep and timer.
- Corner radii: 30 (hero cards), 26 (cards), 22 (rows), 18–16 (controls), 14 (chips). Tab bar and floating bars 26.
- Minimum hit target 44 pt; steppers are 46–52 pt.
- Both appearances are first-class; test the glass stack on light backgrounds (raise stroke opacity, lower blur).

## 5. Data & persistence

`DATA-MODEL.md` holds the SwiftData models. Rules:
- Seed the archive from `data/exercises.json` on first launch; user exercises are separate rows with `isCustom = true` so archive updates never clobber them.
- All weights stored in **kilograms**; unit choice is display-only (`lb = kg × 2.20462`, rounded to 0.5).
- The registry is append-only and never edited on plan changes.
- Session logs keep the actual per-set values performed, independent of the plan's current scheme.
- Export: single JSON file containing profile, plan, exercises, sessions and registry.

## 6. Build order

1. Models + archive seeding + units.
2. Plan editor (day templates, weekly schedule, exercise picker).
3. Session screen with set logging, per-set reps, rest timer, registry writes.
4. Registry screen + exercise detail (chart from session history).
5. Ranking engine + You screen + promotion moment.
6. Onboarding, settings, export.
7. Motion, haptics, light mode pass, notification handling.

## 7. Acceptance checks

- Changing a weight, a rep count, a set count or a rest time each produce exactly one registry entry with the correct old and new value and a date.
- Arming progression on an exercise pre-fills the higher weight in the next session and can be overridden without losing the flag's history.
- Sets within one exercise can hold different rep counts and survive relaunch.
- Assigning template A to two weekdays works and both days start the same exercise list.
- A custom exercise appears in search, filters, plan picker and gets a diagram matching the archive style.
- Switching kg/lb never changes stored values; tiers are identical in both units.
- Tier for a lift matches the worked example in `RANKING.md` §5.
