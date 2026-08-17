# Exercise imagery: what is actually available

Written after checking each option rather than collecting links. Prices and
licences are as found in August 2026; anything paid should be re-checked before
money changes hands.

The brief was: one clean style, the same for every exercise, close to what Apple
would ship. That rules out mixing sources, and it rules out photography — a
photograph next to a drawing reads as two different apps.

---

## What is in the app today

**Everkinetic, CC BY-SA 4.0.** 539 drawings covering all 270 archive exercises,
two phases each (contracted and stretched). Flat line art, one figure, one line
weight, transparent background, so they tint like a symbol and sit on glass.

Attribution is shown in-app under You › Settings › About, which CC BY-SA
requires. Share-alike applies to the images and to modifications of them, not to
the app's own code.

They were already bundled and shown on the exercise detail screen. As of this
round they are also the list thumbnails, cropped to the ink — see below.

### The change that mattered most

The list used to show a generated muscle map, on the stated grounds that the
drawings were "too fine to read at row size". Measuring the set says otherwise:
each drawing sits on a fixed 512×512 canvas and the figure fills a **median 57%**
of it, ranging from **25% to 83%** depending on whether the exercise is standing,
lying down, or holding a long barbell.

So the drawings were not too fine. They were being shown inside a large and
inconsistent empty margin. Cropping each one to its own alpha bounding box makes
every thumbnail fill its tile at the same visual weight. `ExerciseArtwork
.trimmedIllustration(_:)` does this once per image and caches the result.

That is the single biggest improvement available, it cost nothing, and it needed
no new licence.

---

## Option 1 — Keep Everkinetic (current, recommended)

| | |
|---|---|
| Coverage | 270 / 270 exercises, two phases each |
| Style | Flat line art, one consistent figure |
| Licence | CC BY-SA 4.0 — free, attribution required, share-alike on the art |
| Cost | Nothing |
| Risk | None outstanding |

**Why it stays the recommendation:** it is the only option that is already
complete, already consistent, and already legally settled. The complaint about
the icons was about the muscle map, not about these.

**Its real limit:** the drawings are anatomical line art, not the polished
circular renders in the reference image. They read as a technical manual rather
than as Apple Fitness.

---

## Option 2 — SF Symbols `figure.*` (Apple's own)

Worth stating clearly because a web search will tell you otherwise: the claim
that "SF Symbols contains no workout icons" is out of date. Checking the symbol
catalogue on this machine directly:

- **8,302** symbols total
- **371** in the `figure.*` family
- Including `figure.strengthtraining.traditional`, `figure.strengthtraining
  .functional`, `figure.core.training`, `figure.flexibility`, `figure.cooldown`,
  `figure.mixed.cardio`, `figure.highintensity.intervaltraining`, plus
  `figure.rower`, `figure.indoor.cycle`, `figure.elliptical`, `figure.climbing`,
  `figure.jumprope`, `figure.stair.stepper`, `figure.pilates`, `figure.yoga`,
  and `dumbbell` / `dumbbell.fill`

These are precisely the icons Apple Fitness uses for workout types, and they are
free to use in any app.

| | |
|---|---|
| Coverage | ~15 usable for gym work — **per category, not per exercise** |
| Style | Apple's own. Uniform by construction, scales and tints natively |
| Licence | Free within an Apple platform app |
| Cost | Nothing |

**The catch, and it is decisive:** Apple ships one icon per *workout type*, not
per exercise. Bench press, incline press and dumbbell fly would all be
`figure.strengthtraining.traditional`. That is fine for Fitness, which lists
workouts; it is useless for a library of 270 movements you have to tell apart at
a glance.

**Where it does belong:** category headers, muscle-group filters, empty states,
the Live Activity, and the app icon. Used there, alongside the drawings in the
rows, the app looks more Apple-native without losing per-exercise identity.

---

## Option 3 — WorkoutLabs (licensed)

The closest commercially available thing to the reference image.

| | |
|---|---|
| Coverage | 679 strength and mobility exercises, 146 yoga |
| Style | Warm illustrated characters, anatomically accurate, male/female variants |
| Formats | PNG with alpha, SVG, and animated MP4 / GIF / SVG |
| Extras | Structured metadata: muscle groups, equipment, instructions |
| Licence | Commercial, per-illustration or full library |
| Cost | **$15/year or $25 perpetual per illustration**; **$1,200/year or $3,500+ perpetual** for the full library. API access $195 setup + $50/month during development |
| Free tier | None |

**Verdict:** the honest paid answer. Covers the archive with room to spare, has
animation, and the style is friendlier and more finished than Everkinetic. If
this app is going to the App Store and the look matters, $3,500 perpetual is the
price of not thinking about it again.

**Do not** take a subset: 40 licensed illustrations mixed with 230 Everkinetic
ones is worse than either set alone.

---

## Option 4 — Gym Visual (the reference image)

The circular 3D anatomical renders with the worked muscle highlighted in orange,
from the screenshot. This is **Gym Visual** (also resold through ExerciseDB).

**Copyrighted, paid licence required, and not included.** This was checked
before and the answer has not changed. It is the best-looking option and the one
that cannot be had for free.

---

## Option 5 — Generate the set

`docs/IMAGE-BRIEF.md` already specifies 841 images across six sets: the exact
filenames the app looks for, a shared style block so every prompt lands in the
same style, and a three-file pipeline test to run before committing to the
other 838.

| | |
|---|---|
| Coverage | Whatever is generated |
| Style | Whatever the style block says — including the reference style |
| Licence | Owned outright |
| Cost | Generation time, plus the work of rejecting the ones that come out wrong |

**Honest risk:** consistency across 841 generated images is hard. Hands, barbell
plate counts and joint angles drift. Budget for reviewing every one and
regenerating perhaps a fifth of them. This is the only route to the reference
style without paying for it.

---

## Ruled out

- **free-exercise-db** (public domain) — photographs. Already bundled as an
  optional reference gallery on the detail screen, never in lists.
- **wger** (GPL) — community-contributed images, inconsistent between exercises.
  Fails the "same for every exercise" requirement outright.
- **MuscleWiki** — copyrighted, no public licence.
- **Noun Project / Flaticon / Freepik** — per-icon attribution or subscription,
  drawn by many different hands. Assembling 270 exercises from them guarantees
  the inconsistency the brief was written to avoid.

---

## Recommendation

1. **Now, free:** Everkinetic everywhere, cropped to the ink, one tint across the
   archive. Done — this is what the app does today.
2. **Now, free:** SF Symbols `figure.*` for categories, filters and empty states,
   so the app's furniture is Apple's own.
3. **If the look is worth money:** WorkoutLabs full library, $3,500 perpetual.
   Replaces set 1 wholesale, keeps set 2.
4. **If it is worth time instead:** run `IMAGE-BRIEF.md`, starting with its
   three-file pipeline test.

## Sources

- [WorkoutLabs licensing](https://workoutlabs.com/exercise-illustrations-licensing/)
- [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
- SF Symbols catalogue read directly from
  `/System/Library/CoreServices/CoreGlyphs.bundle`
