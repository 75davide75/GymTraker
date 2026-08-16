# Ranking system

Hybrid, as chosen: **real strength standards per exercise** + **one global profile level**. Tier names use strength terminology: Beginner · Novice · Intermediate · Advanced · Elite.

## 1. Where the numbers come from

Bodyweight-relative strength standards are the accepted way to classify a lift. <cite index="3-11,3-12">Standards categorise performance relative to body weight across five levels — Beginner, Novice, Intermediate, Advanced and Elite — and let a lifter benchmark against others of the same body weight and gender.</cite> <cite index="1-15">As a rough guide for men, an intermediate lifter benches about 1× bodyweight, squats about 1.5× and deadlifts about 2×; for women those marks are roughly 0.75×, 1.25× and 1.5×.</cite> <cite index="8-17">"Elite" here means roughly the top 5 % of consistent barbell-training gym-goers, not a competitive standard.</cite>

Age is handled with a coefficient curve of the kind masters powerlifting uses. <cite index="12-1">Federations apply the McCulloch age coefficient so masters lifters (40+) can be compared fairly with 25-year-olds.</cite> <cite index="15-6">A common simplification is a factor per age band — 1.00 (18–29), 0.98 (30–39), 0.92 (40–49), 0.83 (50–59), 0.72 (60+) — derived from those curves and rounded conservatively.</cite> We use exactly that band table; it is honest, cheap to compute and easy to explain in the UI.

Treat all of this as **guidelines, not measurements** — say so in the app (one line under the global rank card).

## 2. Threshold table

Thresholds are `ratio × bodyweight × ageFactor`, expressed as estimated 1RM in kg.

**Male** (1RM ÷ bodyweight)

| Lift | Beginner | Novice | Intermediate | Advanced | Elite |
|---|---|---|---|---|---|
| Bench press | 0.50 | 0.75 | 1.15 | 1.45 | 1.75 |
| Back squat | 0.75 | 1.15 | 1.55 | 2.05 | 2.55 |
| Deadlift | 1.00 | 1.40 | 1.90 | 2.45 | 3.00 |
| Overhead press | 0.35 | 0.55 | 0.80 | 1.05 | 1.30 |
| Barbell row | 0.50 | 0.75 | 1.05 | 1.30 | 1.60 |

**Female**

| Lift | Beginner | Novice | Intermediate | Advanced | Elite |
|---|---|---|---|---|---|
| Bench press | 0.30 | 0.45 | 0.70 | 0.95 | 1.20 |
| Back squat | 0.50 | 0.80 | 1.20 | 1.60 | 2.00 |
| Deadlift | 0.60 | 1.00 | 1.40 | 1.85 | 2.30 |
| Overhead press | 0.20 | 0.35 | 0.50 | 0.70 | 0.90 |
| Barbell row | 0.30 | 0.50 | 0.70 | 0.90 | 1.15 |

**Age factor:** 18–29 → 1.00 · 30–39 → 0.98 · 40–49 → 0.92 · 50–59 → 0.83 · 60+ → 0.72. Under 18: use 1.00 and hide tier promotion notifications.

**Anchors.** Every archive exercise carries `rankAnchor ∈ {bench, squat, deadlift, ohp, row, bw, null}` (see `data/exercises.json`). Variants map to the closest anchor (incline bench → `bench`, leg press → `squat`, RDL → `deadlift`). Accessory and isolation work is `null`: it gets progression tracking and charts but no tier — this keeps the ladder meaningful.

**Bodyweight exercises** (`bw`) are ranked on reps, not load, using a separate table (male / female):

| Exercise | Beginner | Novice | Intermediate | Advanced | Elite |
|---|---|---|---|---|---|
| Pull-up | 1 / 0 | 5 / 2 | 10 / 5 | 16 / 10 | 22 / 15 |
| Push-up | 8 / 4 | 20 / 12 | 35 / 22 | 50 / 34 | 70 / 48 |
| Dip | 2 / 0 | 8 / 4 | 16 / 9 | 24 / 15 | 34 / 22 |
| Plank (seconds) | 20 | 45 | 90 | 150 | 240 |

Added load on a `bw` exercise converts to reps with `effectiveReps = reps × (bodyweight + load) / bodyweight`.

## 3. Per-exercise score

```
e1RM   = weight × (1 + reps / 30)            // Epley, valid to ~12 reps; cap reps at 10 for scoring
th[i]  = ratio[i] × bodyweight × ageFactor   // i = 0…4
score  = 0…100, piecewise-linear:
         v ≤ th[0]           → v / th[0] × 20                                  // has not met Beginner yet
         th[i] ≤ v < th[i+1] → i × 20 + (v − th[i]) / (th[i+1] − th[i]) × 20   // met standard i, sits in tier i
         v ≥ th[4]           → min(100, 80 + (v − th[4]) / th[4] × 80)         // Elite band, 100 at +25 %
tier   = floor(score / 20)                   // 0 Beginner … 4 Elite
division = I / II / III over the tier's inner thirds
```

Score the **best set of the most recent session** for that exercise (highest e1RM). Recompute on every logged set; a tier increase fires the promotion moment once per tier per exercise.

## 4. Global level

```
base       = mean(score of squat, bench, deadlift, overhead press)   // lifts never trained are excluded
consistency = min(5, sessionsCompletedLast4Weeks / 16 × 5)
global      = min(100, base + consistency)
```

The global tier and division use the same 0–100 → tier mapping, so the profile ring, the ladder and the per-lift bars all read on one scale. If fewer than two of the four big lifts have data, show `Unranked` and prompt the user to log them.

Ladder copy for the You screen:

| Tier | Score | Note |
|---|---|---|
| Beginner | 0–20 | First weeks under the bar |
| Novice | 20–40 | 3–6 months of steady work |
| Intermediate | 40–60 | 1–2 years · bodyweight bench |
| Advanced | 60–80 | Several years of focus |
| Elite | 80–100 | Top 5 % of natural lifters |

<cite index="1-19,1-20,1-21">These bands track training experience as much as raw numbers: Novice is about 3 to 6 months of consistent work, Intermediate roughly 1 to 2 years when the classic bodyweight milestones land, Advanced several years of focused training, and Elite the top tier of dedicated drug-free recreational lifters, reached only after many years.</cite>

## 5. Worked example (use as a unit test)

Male, 27 y, 78 kg. Bench press 72.5 kg × 8.

```
ageFactor = 1.00
e1RM      = 72.5 × (1 + 8/30) = 91.83 kg          // 1.18 × bodyweight
thresholds= [39.0, 58.5, 89.7, 113.1, 136.5]
91.83 sits in [th[2], th[3]) → tier index 2
score     = 2×20 + (91.83 − 89.7) / (113.1 − 89.7) × 20 = 41.8
tier      = Intermediate, division I
```

Second case — same lifter, back squat 115 kg × 6:

```
e1RM      = 115 × 1.2 = 138 kg                   // 1.77 × bodyweight
thresholds= [58.5, 89.7, 120.9, 159.9, 198.9]
score     = 2×20 + (138 − 120.9)/(159.9 − 120.9) × 20 = 48.8  → Intermediate II
```

A lifter meeting a standard exactly lands at the **bottom** of that tier: e1RM = 1.15 × bodyweight on bench is Intermediate I with 0 % progress, not Advanced.

## 6. Implementation notes

- Keep the tables in a bundled `ranking.json` so they can be tuned without a code change; version them.
- Never round a score before display; round only the integer shown in the ring.
- Recompute lazily (on session save and on profile edit), cache the result on the exercise row.
- Bodyweight changes re-rank every lift — that is correct and expected; surface it as "tiers recalculated for 79 kg" rather than as silent movement.
- Store the source of every tier change in the registry, so the user can see why a tier moved.
