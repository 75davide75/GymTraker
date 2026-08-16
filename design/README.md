# Gym Progress Tracker

Design + implementation package for an iOS strength-tracking app. UI language: English. Visual direction: Apple Liquid Glass — translucent cards, animated gradient blooms, spring motion, dark and light.

## What's here

| File | What it is |
|---|---|
| `Gym Tracker.dc.html` | **The prototype.** Nine screens, live state — set logging, weight steppers, per-set reps, rest timer, plan editor, library search, custom exercise creation, change registry, ranking. Chips above the phone jump between screens; the last chip flips dark/light. |
| `SPEC.md` | Product spec: every screen, interaction, motion and visual rule, plus build order and acceptance checks. |
| `DATA-MODEL.md` | SwiftData models, seeding, registry rules, progression rule, queries the UI needs. |
| `RANKING.md` | The tier system: threshold tables, age factors, formulas, worked examples for unit tests, sources. |
| `data/exercises.json` | 125-exercise seed archive (name, muscle, equipment, rank anchor, tracking type, diagram descriptor). |
| `Session A - Swipe Cards.dc.html`, `Session C - Focus Mode.dc.html` | The two workout-screen alternatives that weren't picked, kept for reference. |

## Handing this to Claude Code

Start with `SPEC.md` §6 (build order). It references the other three documents where detail lives. The prototype is the visual source of truth — colours, radii, spacing and copy in the spec match it.

## Nota

Le immagini degli esercizi sono diagrammi geometrici generati da una singola grammatica (una `ExerciseGlyph` view in SwiftUI, descritta in `SPEC.md` §2.5), così ogni esercizio — anche quelli creati dall'utente — ha un'illustrazione coerente. Se più avanti vuoi illustrazioni reali, si sostituisce solo il corpo di quella view.
