# Image brief

Everything the app needs drawn, the style it must be drawn in, and prompts you can paste straight into an image model.

Written so you can hand any single row to a generator and get back a file the app will load without renaming anything.

---

## 1. The style, in one place

Every prompt below inherits this. If you change one thing, change it here and re-run everything, because a set that drifts halfway through looks worse than a set that is uniformly plain.

**Style block — paste into every prompt:**

```
Flat vector illustration. Clean geometric line art, uniform 6px stroke weight,
rounded line caps and joins. No fill except where stated. No gradients, no
shadows, no texture, no outline glow. Single colour: pure white (#FFFFFF) on a
fully transparent background. Centred, with 10% clear margin on all sides.
Front-facing or clean three-quarter view, no perspective distortion. No text,
no numbers, no watermarks, no background objects, no floor line.
```

**Why white on transparent.** The app tints every image at runtime — white in dark mode, near-black in light mode, accent colour where a shape is highlighted. A coloured or baked-in-background image cannot do that and will look pasted on.

**Technical requirements for every file:**

| Property | Value |
|---|---|
| Format | PNG with alpha |
| Canvas | 1024 × 1024, square |
| Content | White strokes only, everything else transparent |
| Margin | ~100px clear on every side |
| Colour profile | sRGB |
| Naming | exactly as given in the tables, all lowercase |

Deliver them in one flat folder. I will downscale and convert; do not pre-shrink them.

---

## 2. Exercise icons — 270 files

One per exercise, shown at 44–52pt in the library list. **This is the set that matters most**: it is what you see while scrolling.

At that size a full figure mid-movement turns to mush. Each icon should be the **equipment plus the working position**, simplified until it still reads at 44pt — a barbell across a bench, not a person on a bench.

**Per-icon prompt template:**

```
[STYLE BLOCK]

Icon for the exercise "{NAME}".
Show: {EQUIPMENT}, positioned as it is during the movement.
Include a minimal human silhouette only if the position is unreadable without
one; if so, reduce the body to a simple stick form with a circular head.
The icon must stay legible at 44 pixels: no more than 8 distinct shapes,
no fine detail, no facial features, no hands or fingers.
```

Replace `{NAME}` with the exercise name and `{EQUIPMENT}` with the equipment column.

### Full list

#### Chest — 39 icons

| File name | Exercise | Equipment |
|---|---|---|
| `barbell-front-raise-pullover.png` | Barbell Front Raise and Pullover | Barbell |
| `barbell-neck-press.png` | Barbell Neck Press | Barbell |
| `bench-press.png` | Bench Press | Barbell |
| `bench-press-dumbbell.png` | Bench Press Dumbbell | Dumbbell |
| `bent-arm-pullover.png` | Bent Arm Pullover | Barbell |
| `body-row.png` | Body Row | Barbell |
| `bosu-ball-push-up.png` | Bosu Ball Push Up | Machine |
| `cable-crossover.png` | Cable Crossover | Cable |
| `chest-dips.png` | Chest Dips | Bodyweight |
| `close-grip-barbell-bench-press.png` | Close Grip Barbell Bench Press | Barbell |
| `crossover-bands.png` | Crossover with Bands | Cable |
| `decline-barbell-bench-press.png` | Decline Barbell Bench Press | Barbell |
| `decline-chest-press.png` | Decline Chest Press | Machine |
| `decline-dumbbell-bench-press.png` | Decline Dumbbell Bench Press | Dumbbell |
| `decline-dumbbell-flys.png` | Decline Dumbbell Fly's | Dumbbell |
| `dumbbell-bent-arm-pullover.png` | Dumbbell Bent Arm Pullover | Dumbbell |
| `dumbbell-flys.png` | Dumbbell Flys | Dumbbell |
| `dumbbell-incline-bench-press.png` | Dumbbell Incline Bench Press | Dumbbell |
| `flat-bench-cable-flys.png` | Flat Bench Cable Flys | Cable |
| `hammer-grip-incline-bench-press.png` | Hammer Grip Incline Bench Press | Dumbbell |
| `incline-bench-press.png` | Incline Bench Press | Barbell |
| `incline-bench-press-with-bands.png` | Incline Bench Press with Bands | Cable |
| `incline-cable-flys.png` | Incline Cable Fly's | Cable |
| `incline-dumbbell-flys.png` | Incline Dumbbell Fly's | Dumbbell |
| `incline-dumbbell-press.png` | Incline Dumbbell Press | Dumbbell |
| `incline-flys-twist.png` | Incline Fly's with a Twist | Dumbbell |
| `machine-bench-press.png` | Machine Bench Press | Machine |
| `one-arm-barbell-floor-press.png` | One Arm Barbell Floor Press | Barbell |
| `one-arm-bench-press.png` | One Arm Bench Press | Dumbbell |
| `one-arm-flat-bench-flys.png` | One Arm Flat Bench Fly’s | Dumbbell |
| `one-armed-biased-push-up.png` | One Armed Biased Push Up | Machine |
| `push-ups.png` | Push Ups | Bodyweight |
| `push-ups-with-feet-on-exercise-ball.png` | Push Ups with feet on exercise ball | Machine |
| `smith-machine-bench-press.png` | Smith Machine Bench Press | Barbell |
| `smith-machine-incline-bench-press.png` | Smith Machine Incline Bench Press | Barbell |
| `straight-arm-dumbbell-pullover.png` | Straight Arm Dumbbell Pullover | Dumbbell |
| `wide-grip-bench-press.png` | Wide Grip Bench Press | Barbell |
| `wide-grip-decline-barbell-pullover.png` | Wide Grip Decline Barbell Pullover | Barbell |
| `wide-grip-decline-bench-press.png` | Wide Grip Decline Bench Press | Barbell |

#### Back — 22 icons

| File name | Exercise | Equipment |
|---|---|---|
| `back-extension-stability-ball.png` | Back Extension on Stability Ball | Machine |
| `barbell-dead-lifts.png` | Barbell Dead Lifts | Barbell |
| `barbell-good-mornings.png` | Barbell Good Mornings | Barbell |
| `barbell-shrugs.png` | Barbell Shrugs | Barbell |
| `cable-shoulder-shrugs.png` | Cable Shoulder Shrugs | Cable |
| `dumbbell-dead-lifts.png` | Dumbbell Dead Lifts | Dumbbell |
| `hyperextensions.png` | Hyperextensions | Machine |
| `narrow-parallel-grip-chin-ups.png` | Narrow Parallel Grip Chin-ups | Barbell |
| `pull-ups.png` | Pull Ups | Barbell |
| `reverse-grips-bent-over-barbell-rows.png` | Reverse Grips Bent Over Barbell Rows | Barbell |
| `seated-cable-rows.png` | Seated Cable Rows | Cable |
| `shoulder-shrugs.png` | Shoulder Shrugs | Dumbbell |
| `smith-machine-dead-lifts.png` | Smith Machine Dead Lifts | Barbell |
| `smith-machine-good-mornings.png` | Smith Machine Good Mornings | Barbell |
| `straight-arm-push-down.png` | Straight Arm Push Down | Cable |
| `supermans.png` | Supermans | Bodyweight |
| `t-bar-rows.png` | T-Bar Rows | Barbell |
| `underhand-pull-down.png` | Underhand Pull down | Cable |
| `underhand-pull-downs.png` | Underhand Pull downs | Cable |
| `upright-band-rows.png` | Upright Band Rows | Cable |
| `v-bar-pull-down.png` | V Bar Pull Down | Cable |
| `wide-grip-chin-up.png` | Wide Grip Chin Up | Bodyweight |

#### Shoulders — 24 icons

| File name | Exercise | Equipment |
|---|---|---|
| `back-flys-exercise-band.png` | Back Fly's with Exercise Band | Cable |
| `ball-wall-circles.png` | Ball Wall Circles | Machine |
| `bent-over-rear-deltoid-raise-with-head-on-bench.png` | Bent Over Rear Deltoid Raise With Head On Bench | Dumbbell |
| `bent-over-lateral-cable-raises.png` | Bent-over Lateral Cable Raises | Cable |
| `dumbbell-upright-rows.png` | Dumbbell Upright Rows | Dumbbell |
| `front-cable-raises.png` | Front Cable Raises | Cable |
| `front-dumbbell-raise.png` | Front Dumbbell Raise | Dumbbell |
| `incline-shoulder-press-dumbbell.png` | Incline Shoulder Press Dumbbell | Dumbbell |
| `internal-cable-rotation.png` | Internal Cable Rotation | Cable |
| `lateral-dumbbell-raises.png` | Lateral Dumbbell Raises | Dumbbell |
| `lying-one-arm-rear-lateral-raise.png` | Lying One Arm Rear Lateral Raise | Dumbbell |
| `lying-rear-lateral-raise.png` | Lying Rear Lateral Raise | Dumbbell |
| `one-arm-dumbbell-shoulder-press.png` | One Arm Dumbbell Shoulder Press | Dumbbell |
| `one-arm-upright-row.png` | One Arm Upright Row | Dumbbell |
| `pullover-stability-ball-weight.png` | Pullover On Stability Ball With Weight | Dumbbell |
| `rear-deltoid-row-barbell.png` | Rear Deltoid Row Barbell | Barbell |
| `rear-deltoid-row-dumbbell.png` | Rear Deltoid Row Dumbbell | Dumbbell |
| `seated-military-press.png` | Seated Military Press | Barbell |
| `seated-rear-lateral-cable-raise.png` | Seated Rear Lateral Cable Raise | Cable |
| `smith-machine-rear-deltoid-row.png` | Smith Machine Rear Deltoid Row | Barbell |
| `smith-machine-shoulder-shrugs.png` | Smith Machine Shoulder Shrugs | Barbell |
| `smith-machine-upright-row.png` | Smith Machine Upright Row | Barbell |
| `upright-barbell-rows.png` | Upright Barbell Rows | Barbell |
| `upright-cable-row.png` | Upright Cable Row | Cable |

#### Arms — 104 icons

| File name | Exercise | Equipment |
|---|---|---|
| `alternating-biceps-curl-with-dumbbell.png` | Alternating Bicep Curl with Dumbbell | Dumbbell |
| `alternating-hammer-curl-with-dumbbell.png` | Alternating Hammer Curl with Dumbbell | Dumbbell |
| `alternating-incline-curl-with-dumbbell.png` | Alternating Incline Curl with Dumbbell | Dumbbell |
| `bench-dips.png` | Bench Dips | Bodyweight |
| `bent-over-one-arm-triceps-extension-with-dumbbell.png` | Bent-Over One Arm Triceps Extension with Dumbbell | Dumbbell |
| `bent-over-two-arm-triceps-extension-with-dumbbell.png` | Bent-Over Two Arm Triceps Extension with Dumbbell | Dumbbell |
| `biceps-curl-lunge-with-bowling-motion.png` | Bicep Curl Lunge with Bowling Motion | Dumbbell |
| `biceps-curl-on-stability-ball-with-leg-raised.png` | Bicep Curl on Stability Ball with Leg Raised | Dumbbell |
| `biceps-curl-with-deadlift-with-barbell.png` | Bicep Curl with Deadlift with Barbell | Barbell |
| `biceps-curl-with-machine.png` | Bicep Curl with Machine | Bodyweight |
| `biceps-curl-reverse-with-dumbbells.png` | Biceps Curl Reverse with Dumbbells | Dumbbell |
| `biceps-curl-seated-on-stability-ball-with-dumbbell.png` | Biceps Curl Seated on Stability Ball with Dumbbell | Dumbbell |
| `biceps-curl-squat-with-dumbbell.png` | Biceps Curl Squat with Dumbbell | Dumbbell |
| `biceps-curl-v-sit-on-dome-with-dumbbells.png` | Biceps Curl V Sit on Dome with Dumbbells | Dumbbell |
| `biceps-curl-with-dumbbell.png` | Biceps Curl with Dumbbell | Dumbbell |
| `biceps-curl-with-overhead-extension-using-dumbbells-on-stability-ball.png` | Biceps Curl with Overhead Extension using Dumbbells on Stability Ball | Dumbbell |
| `biceps-curls-with-barbell.png` | Biceps Curls with Barbell | Barbell |
| `biceps-hammer-curl-with-dumbbell.png` | Biceps Hammer Curl with Dumbbell | Dumbbell |
| `close-grip-ez-bar-curl-with-barbell.png` | Close Grip EZ Bar Curl with Barbell | Barbell |
| `close-grip-standing-biceps-curls-with-barbell.png` | Close Grip Standing Biceps Curls with Barbell | Barbell |
| `close-triceps-pushup.png` | Close Triceps Pushup | Bodyweight |
| `concentration-curls-with-dumbbell.png` | Concentration Curls with Dumbbell | Dumbbell |
| `cross-body-hammer-curl-with-dumbbell.png` | Cross Body Hammer Curl with Dumbbell | Dumbbell |
| `decline-close-grip-bench-to-skull-crusher.png` | Decline Close Grip Bench to Skull Crusher | Barbell |
| `decline-ez-bar-triceps-extension-with-barbell.png` | Decline EZ Bar Triceps Extension with Barbell | Barbell |
| `decline-triceps-extension-with-dumbbell.png` | Decline Triceps Extension with Dumbbell | Dumbbell |
| `drag-curl-with-barbell.png` | Drag Curl with Barbell | Barbell |
| `ez-bar-curl-with-barbell.png` | EZ Bar Curl with Barbell | Barbell |
| `flexor-incline-curls-with-dumbbell.png` | Flexor Incline Curls with Dumbbell | Dumbbell |
| `forward-lunge-with-biceps-curl-using-dumbbell.png` | Forward Lunge with Bicep Curl using Dumbbell | Dumbbell |
| `hammer-curls-with-rope-and-cable.png` | Hammer Curls with Rope and Cable | Cable |
| `high-cable-curls.png` | High Cable Curls | Cable |
| `incline-inner-biceps-curl-with-dumbbell-2.png` | Incline Inner Biceps Curl with Dumbbell | Dumbbell |
| `incline-pushdown-with-cable.png` | Incline Pushdown with Cable | Cable |
| `incline-triceps-extension-with-barbell.png` | Incline Triceps Extension with Barbell | Barbell |
| `incline-triceps-extension-with-cable.png` | Incline Triceps Extension with Cable | Cable |
| `incline-triceps-extensions-with-dumbbell.png` | Incline Triceps Extensions with Dumbbell | Dumbbell |
| `jm-press.png` | JM Press | Barbell |
| `kneeling-triceps-extension-with-cable.png` | Kneeling Triceps Concentration Extension with Cable | Cable |
| `kneeling-triceps-extension-with-cable-2.png` | Kneeling Triceps Extension with Cable | Cable |
| `low-triceps-extension-with-cable.png` | Low Triceps Extension with Cable | Cable |
| `lying-bicep-cable-curl.png` | Lying Bicep Cable Curl | Cable |
| `lying-close-grip-biceps-curls-with-cable.png` | Lying Close Grip Biceps Curls with Cable | Cable |
| `lying-close-grip-triceps-press-to-chin-with-barbell.png` | Lying Close Grip Triceps Press to Chin with Barbell | Barbell |
| `lying-close-grip-triceps-extension-behind-the-head-with-barbell.png` | Lying Close-Grip Triceps Extension Behind the Head with Barbell | Barbell |
| `lying-high-bench-biceps-curl-with-barbell.png` | Lying High Bench Biceps Curl with Barbell | Barbell |
| `lying-incline-curl-with-barbell.png` | Lying Incline Curl with Barbell | Barbell |
| `lying-supine-biceps-curl-with-dumbbell.png` | Lying Supine Biceps Curl with Dumbbell | Dumbbell |
| `lying-triceps-extension-with-cable.png` | Lying Tricep Extension with Cable | Cable |
| `lying-triceps-extension-across-face-with-dumbbell.png` | Lying Triceps Extension Across Face with Dumbbell | Dumbbell |
| `lying-triceps-extension-with-dumbbells.png` | Lying Triceps Extension with Dumbbells | Dumbbell |
| `lying-triceps-press-with-barbell.png` | Lying Triceps Press with Barbell | Barbell |
| `lying-two-arm-triceps-extension-with-dumbbell.png` | Lying Two Arm Triceps Extension with Dumbbell | Dumbbell |
| `medicine-ball-biceps-curl-on-stability-ball.png` | Medicine Ball Biceps Curl on Stability Ball | Dumbbell |
| `old-school-reverse-extensions.png` | Old School Reverse Extensions | Barbell |
| `one-arm-bicep-concentration-on-stability-ball-with-dumbbell.png` | One Arm Bicep Concentration on Stability Ball with Dumbbell | Dumbbell |
| `one-arm-biceps-curl-with-olympic-bar-or-barbell.png` | One Arm Bicep Curl with Olympic Bar or Barbell | Barbell |
| `one-arm-low-pulley-triceps-extension-with-cable.png` | One Arm Low-Pulley Triceps Extension with Cable | Cable |
| `one-arm-preacher-curl-with-dumbbell.png` | One Arm Preacher Curl with Dumbbell | Dumbbell |
| `one-arm-tricep-extension-with-cable.png` | One Arm Tricep Extension with Cable | Cable |
| `one-arm-triceps-extension-with-dumbbell.png` | One Arm Triceps Extension with Dumbbell | Dumbbell |
| `overhead-curl-with-cable.png` | Overhead Curl with Cable | Cable |
| `preacher-curl-with-barbell.png` | Preacher Curl with Barbell | Barbell |
| `preacher-curl-with-cable.png` | Preacher Curl with Cable | Cable |
| `preacher-curl-with-machine.png` | Preacher Curl with Machine | Machine |
| `preacher-hammer-curl-with-dumbbell.png` | Preacher Hammer Curl with Dumbbell | Dumbbell |
| `prone-incline-biceps-curl-with-dumbbell.png` | Prone Incline Biceps Curl with Dumbbell | Dumbbell |
| `quick-alternating-biceps-curls-with-band.png` | Quick Alternating Biceps Curls with Band | Cable |
| `reverse-grip-triceps-pushdown.png` | Reverse Grip Triceps Pushdown | Cable |
| `reverse-plate-curls-with-weight.png` | Reverse Plate Curls with Weight | Barbell |
| `reverse-triceps-bench-press-with-barbell.png` | Reverse Triceps Bench Press with Barbell | Barbell |
| `seated-biceps-curl-with-dumbbell.png` | Seated Bicep Curl with Dumbbell | Dumbbell |
| `seated-close-grip-concentration-curls-with-barbell.png` | Seated Close Grip Concentration Curls with Barbell | Barbell |
| `seated-inner-biceps-curl-with-dumbbell.png` | Seated Inner Biceps Curl with Dumbbell | Dumbbell |
| `seated-one-arm-triceps-extension-with-dumbbell.png` | Seated One Arm Triceps Extension with Dumbbell | Dumbbell |
| `seated-overhead-triceps-extension-with-barbell.png` | Seated Overhead Triceps Extension with Barbell | Barbell |
| `seated-triceps-press-with-dumbbell.png` | Seated Triceps Press with Dumbbell | Dumbbell |
| `seated-two-arm-triceps-extension-with-dumbbell.png` | Seated Two-Arm Triceps Extension with Dumbbell | Dumbbell |
| `single-arm-triceps-extension-with-dumbbell.png` | Single Arm Pronated Triceps Extension with Dumbbell | Dumbbell |
| `single-arm-supinated-triceps-extension-with-dumbbell.png` | Single Arm Supinated Triceps Extension with Dumbbell | Dumbbell |
| `smith-machine-close-grip-bench-press.png` | Smith Machine Close Grip Bench Press | Barbell |
| `spider-curl-with-barbell.png` | Spider Curl with Barbell | Barbell |
| `standing-biceps-curl-with-cable.png` | Standing Biceps Curl with Cable | Cable |
| `standing-inner-biceps-curl-with-dumbbell.png` | Standing Inner Biceps Curl with Dumbbell | Dumbbell |
| `standing-one-arm-biceps-curl-with-cable.png` | Standing One Arm Bicep Curl with Cable | Cable |
| `standing-one-arm-curl-over-incline-bench-with-dumbbell.png` | Standing One Arm Curl Over Incline Bench with Dumbbell | Dumbbell |
| `standing-overhead-triceps-extension-with-barbell.png` | Standing Overhead Triceps Extension with Barbell | Barbell |
| `standing-triceps-extension-2.png` | Standing Triceps Extension | Dumbbell |
| `standing-triceps-extension-with-towel.png` | Standing Triceps Extension with Towel | Bodyweight |
| `step-up-single-leg-balance-with-biceps-curl-using-dumbbells.png` | Step Up Single Leg Balance with Bicep Curl using Dumbbells | Dumbbell |
| `stork-stance-biceps-curl-with-dumbbells.png` | Stork Stance Bicep Curl with Dumbbells | Dumbbell |
| `tate-press.png` | Tate Press | Dumbbell |
| `tate-press-with-dumbbell.png` | Tate Press with Dumbbell | Dumbbell |
| `tricep-dips-using-body-weight.png` | Tricep Dips using Body Weight | Bodyweight |
| `tricep-dips.png` | Tricep Dips using Machine | Machine |
| `triceps-extensions-using-machine.png` | Triceps Extensions using Machine | Machine |
| `triceps-kickback-with-dumbbell.png` | Triceps Kickback with Dumbbell | Dumbbell |
| `triceps-pushdown-with-cable.png` | Triceps Pushdown with Cable | Cable |
| `triceps-pushdown-with-rope-and-cable.png` | Triceps Pushdown with Rope and Cable | Cable |
| `triceps-pushdown-with-v-bar-and-cable.png` | Triceps Pushdown with V Bar and Cable | Barbell |
| `two-arm-preacher-curl-with-dumbbell.png` | Two-Arm Preacher Curl with Dumbbell | Dumbbell |
| `wide-grip-standing-biceps-curl-with-barbell.png` | Wide Grip Standing Biceps Curl with Barbell | Barbell |
| `zottman-curl-with-dumbbells.png` | Zottman Curl with Dumbbells | Dumbbell |
| `zottman-preacher-curl-with-dumbbells.png` | Zottman Preacher Curl with Dumbbells | Dumbbell |

#### Legs — 58 icons

| File name | Exercise | Equipment |
|---|---|---|
| `ankle-circles.png` | Ankle Circles | Bodyweight |
| `barbell-lunges.png` | Barbell Lunges | Barbell |
| `barbell-squat.png` | Barbell Squat | Barbell |
| `calf-raises-with-band.png` | Calf Raises with Band | Cable |
| `calves-press-on-leg-machine.png` | Calves Press on Leg Machine | Machine |
| `donkey-calf-raises.png` | Donkey Calf Raises | Bodyweight |
| `dumbbell-lunges.png` | Dumbbell Lunges | Dumbbell |
| `flutter-kicks.png` | Flutter Kicks | Bodyweight |
| `front-squat-to-bench-with-barbells.png` | Front Squat to Bench with Barbells | Barbell |
| `front-squat-with-barbell.png` | Front Squat with Barbell | Barbell |
| `hack-squat-machine.png` | Hack Squat Machine | Machine |
| `hack-squat-with-barbell.png` | Hack Squat with barbell | Barbell |
| `hip-adduction.png` | Hip Adduction | Cable |
| `iron-cross-with-dumbbells.png` | Iron Cross with Dumbbells | Dumbbell |
| `jefferson-squats-with-barbell.png` | Jefferson Squats with Barbell | Barbell |
| `knee-circles.png` | Knee Circles | Bodyweight |
| `lateral-lunge-with-biceps-curl-with-dumbbell.png` | Lateral Lunge with Bicep Curl with Dumbbell | Dumbbell |
| `leg-extensions.png` | Leg Extensions | Machine |
| `leg-press.png` | Leg Press | Machine |
| `lying-leg-curl-machine.png` | Lying Leg Curl Machine | Machine |
| `lying-squat.png` | Lying Squat | Machine |
| `narrow-stance-hack-squats.png` | Narrow Stance Hack Squats | Machine |
| `narrow-stance-leg-press.png` | Narrow Stance Leg Press | Machine |
| `narrow-stance-squat-with-barbell.png` | Narrow Stance Squat with Barbell | Barbell |
| `one-arm-side-deadlift-with-barbell.png` | One Arm Side Deadlift with Barbell | Barbell |
| `one-arm-snatch-with-barbell.png` | One Arm Snatch with Barbell | Barbell |
| `one-leg-squat-with-barbell.png` | One Leg Squat with Barbell | Barbell |
| `overhead-squat-with-barbell.png` | Overhead Squat with Barbell | Barbell |
| `pile-squat-with-dumbbell.png` | Pile Squat with Dumbbell | Dumbbell |
| `rear-lunges-with-barbell.png` | Rear Lunges with Barbell | Barbell |
| `rear-lunges-with-dumbbell.png` | Rear Lunges with Dumbbell | Dumbbell |
| `rocking-standing-calf-raise-with-barbell.png` | Rocking Standing Calf Raise with Barbell | Barbell |
| `romanian-dead-lift.png` | Romanian Dead Lift | Barbell |
| `seated-calf-raise-using-machine.png` | Seated Calf Raise using Machine | Machine |
| `seated-calf-raise-with-barbell.png` | Seated Calf Raise with Barbell | Barbell |
| `seated-leg-curl.png` | Seated Leg Curl | Machine |
| `seated-one-leg-calf-raise-with-dumbbell.png` | Seated One Leg Calf Raise with Dumbbell | Dumbbell |
| `side-squats-with-barbell.png` | Side Squats with Barbell | Barbell |
| `single-leg-squat-with-barbell.png` | Single Leg Squat with Barbell | Barbell |
| `smith-machine-hack-squat.png` | Smith Machine Hack Squat | Barbell |
| `smith-machine-reverse-calf-raises.png` | Smith Machine Reverse Calf Raises | Barbell |
| `smith-machine-squats.png` | Smith Machine Squats | Barbell |
| `speed-squats-with-barbell.png` | Speed Squats with Barbell | Barbell |
| `squat-to-bench-with-barbell.png` | Squat to Bench with Barbell | Barbell |
| `squat-to-bench-with-dumbbells.png` | Squat to Bench with Dumbbells | Dumbbell |
| `squats-using-dumbbells.png` | Squats using Dumbbells | Dumbbell |
| `squats-with-exercise-bands.png` | Squats with Exercise Bands | Cable |
| `standing-barbell-calf-raise.png` | Standing Barbell Calf Raise | Barbell |
| `standing-calf-raises-using-machine.png` | Standing Calf Raises using Machine | Machine |
| `standing-leg-curls.png` | Standing Leg Curls | Machine |
| `step-ups-with-barbell.png` | Step Ups with Barbell | Barbell |
| `step-ups-with-dumbbells.png` | Step Ups with Dumbbells | Dumbbell |
| `thigh-abductor.png` | Thigh Abductor | Machine |
| `thigh-adductor.png` | Thigh Adductor | Machine |
| `walking-lunges.png` | Walking Lunges | Barbell |
| `weighted-sissy-squat-with-weight-plate.png` | Weighted Sissy Squat with Weight Plate | Barbell |
| `wide-stance-squat-with-barbell.png` | Wide Stance Squat with Barbell | Barbell |
| `zecher-squats.png` | Zecher Squats | Barbell |

#### Glutes — 3 icons

| File name | Exercise | Equipment |
|---|---|---|
| `body-leg-lifts.png` | Body Leg Lifts | Bodyweight |
| `bridging.png` | Bridging | Bodyweight |
| `one-legged-cable-kickback.png` | One Legged Cable Kickback | Cable |

#### Core — 17 icons

| File name | Exercise | Equipment |
|---|---|---|
| `ab-rollout-on-knees-with-barbell.png` | Ab Rollout on Knees with Barbell | Barbell |
| `ab-rollout-with-barbell.png` | Ab Rollout with Barbell | Barbell |
| `air-bike.png` | Air Bike | Bodyweight |
| `bent-knee-hip-raise.png` | Bent Knee Hip Raise | Bodyweight |
| `cross-body-crunch.png` | Cross Body Crunch | Bodyweight |
| `crunches.png` | Crunches | Bodyweight |
| `crunches-with-legs-on-stability-ball.png` | Crunches with Legs on Stability Ball | Machine |
| `decline-crunch.png` | Decline Crunch | Bodyweight |
| `decline-oblique-crunch.png` | Decline Oblique Crunch | Bodyweight |
| `exercise-ball-pull-in.png` | Exercise Ball Pull In | Bodyweight |
| `flat-bench-leg-raises.png` | Flat Bench Leg Raises | Bodyweight |
| `seated-ab-crunch-with-cable.png` | Seated Ab Crunch with Cable | Cable |
| `side-bend-with-dumbbell.png` | Side Bend with Dumbbell | Dumbbell |
| `side-plank.png` | Side Plank | Bodyweight |
| `stability-ball-abdominal-crunch.png` | Stability Ball Abdominal Crunch | Bodyweight |
| `stationary-abdominal-draw-in.png` | Stationary Abdominal Draw In | Bodyweight |
| `weighted-ball-side-bend.png` | Weighted Ball Side Bend | Dumbbell |

#### Full body — 3 icons

| File name | Exercise | Equipment |
|---|---|---|
| `push-up-feet-elevated.png` | Push Up with Feet Elevated | Bodyweight |
| `static-neck-flexion-extension.png` | Static Neck Flexion and Extension | Bodyweight |
| `static-neck-side-flexion.png` | Static Neck Side Flexion | Bodyweight |

---

## 3. Demonstration images — 540 files

Two per exercise, shown large on the exercise detail screen and openable full screen with pinch-zoom. These carry the actual teaching: what the movement looks like at each end of its range.

Same style block, but these can afford detail — they are seen at 300pt and larger.

**Per-image prompt template:**

```
[STYLE BLOCK]

Anatomical demonstration of "{NAME}", {PHASE} position.
A single athletic figure performing the movement with correct form, drawn as
clean outline art with visible muscle contour lines. Include the equipment:
{EQUIPMENT}. Side or three-quarter view, whichever shows the joint angles
most clearly. The working muscles may carry a slightly heavier stroke.
Full body in frame from head to feet. No face detail beyond a simple profile.
```

`{PHASE}` is either **contracted** (the hard end — bar at the chest on a bench press, deep in a squat) or **stretched** (the easy end — arms locked out, standing tall).

Two files per exercise, named:

```
{exercise-id}-tension.png       ← contracted position
{exercise-id}-relaxation.png    ← stretched position
```

The exercise ids are the 270 names in the table above, without the `.png`. So `barbell-squat` needs `barbell-squat-tension.png` and `barbell-squat-relaxation.png`.

**If 540 is too many to start with**, do these 24 first — they are the ones in every starter plan, so they cover a new user's first month:

| Exercise id | Name |
|---|---|
| `bench-press` | Bench Press |
| `barbell-squat` | Barbell Squat |
| `barbell-dead-lifts` | Barbell Dead Lifts |
| `seated-military-press` | Seated Military Press |
| `reverse-grips-bent-over-barbell-rows` | Reverse Grips Bent Over Barbell Rows |
| `pull-ups` | Pull Ups |
| `romanian-dead-lift` | Romanian Dead Lift |
| `leg-press` | Leg Press |
| `biceps-curls-with-barbell` | Biceps Curls with Barbell |
| `triceps-pushdown-with-cable` | Triceps Pushdown with Cable |
| `lateral-dumbbell-raises` | Lateral Dumbbell Raises |
| `dumbbell-incline-bench-press` | Dumbbell Incline Bench Press |
| `chest-dips` | Chest Dips |
| `seated-cable-rows` | Seated Cable Rows |
| `v-bar-pull-down` | V Bar Pull Down |
| `lying-leg-curl-machine` | Lying Leg Curl Machine |
| `leg-extensions` | Leg Extensions |
| `barbell-lunges` | Barbell Lunges |
| `side-plank` | Side Plank |
| `incline-bench-press` | Incline Bench Press |
| `barbell-shrugs` | Barbell Shrugs |
| `front-squat-with-barbell` | Front Squat with Barbell |
| `biceps-hammer-curl-with-dumbbell` | Biceps Hammer Curl with Dumbbell |

---

## 4. Muscle map — 9 files

The body diagram behind the library icons and the per-muscle rank rows. Currently drawn from shapes in code; a proper illustration would be better.

```
[STYLE BLOCK]

Anatomical front-view body map of a human torso and limbs, drawn as clean
outline art with each major muscle group as a separate closed shape. No
internal detail beyond the muscle boundaries. Symmetrical, standing, arms
slightly away from the body. Head reduced to a simple oval.
```

| File name | What it shows |
|---|---|
| `body-front.png` | Front view, all groups as separate shapes |
| `body-back.png` | Back view, same treatment |
| `muscle-chest.png` | Front body, chest filled solid, everything else outline |
| `muscle-back.png` | Back body, lats and traps filled |
| `muscle-shoulders.png` | Front body, both deltoids filled |
| `muscle-arms.png` | Front body, biceps and triceps filled |
| `muscle-legs.png` | Front body, quads and calves filled |
| `muscle-glutes.png` | Back body, glutes filled |
| `muscle-core.png` | Front body, abdominals and obliques filled |

The filled shapes get tinted with the accent colour at runtime, so keep the fill pure white and the outline white too — I separate them by alpha, not by colour.

---

## 5. Rank medals — 15 files

Five tiers, three divisions each. These are the reward art, so they can be the most decorative thing in the app — but they still have to sit on dark glass.

```
[STYLE BLOCK — except: these may use a single flat accent colour, see table]

A circular medal badge for the rank "{TIER} {DIVISION}". Concentric rings with
{DIVISION_COUNT} small notch marks at the top edge. Centre carries the letter
"{INITIAL}". Flat vector, no bevel, no metallic gradient, no ribbon.
Line weight heavier than the rest of the app's icons — this is a reward, it
should feel more solid.
```

| File name | Tier | Division | Accent |
|---|---|---|---|
| `medal-beginner-1.png` | Beginner | I | neutral grey #9FA4B2 |
| `medal-beginner-2.png` | Beginner | II | neutral grey #9FA4B2 |
| `medal-beginner-3.png` | Beginner | III | neutral grey #9FA4B2 |
| `medal-novice-1.png` | Novice | I | cyan #00BFC9 |
| `medal-novice-2.png` | Novice | II | cyan #00BFC9 |
| `medal-novice-3.png` | Novice | III | cyan #00BFC9 |
| `medal-intermediate-1.png` | Intermediate | I | violet #6B90FF |
| `medal-intermediate-2.png` | Intermediate | II | violet #6B90FF |
| `medal-intermediate-3.png` | Intermediate | III | violet #6B90FF |
| `medal-advanced-1.png` | Advanced | I | amber #F2AF48 |
| `medal-advanced-2.png` | Advanced | II | amber #F2AF48 |
| `medal-advanced-3.png` | Advanced | III | amber #F2AF48 |
| `medal-elite-1.png` | Elite | I | magenta #E472DC |
| `medal-elite-2.png` | Elite | II | magenta #E472DC |
| `medal-elite-3.png` | Elite | III | magenta #E472DC |

Higher tiers should look visibly more elaborate than lower ones — more rings, denser notches. A Beginner medal and an Elite medal that differ only in colour will not feel like progress.

---

## 6. Empty states — 6 files

Shown when a screen has nothing in it yet. Keep them light: they are seen when someone has just arrived and should not feel like an error.

| File name | Screen | What to draw |
|---|---|---|
| `empty-plan.png` | Plan, before a plan exists | An empty weekly grid, seven blank cells |
| `empty-history.png` | History, no sessions | A calendar page with nothing marked |
| `empty-registry.png` | Registry, no changes | A clock face with an arrow circling back |
| `empty-search.png` | Library, no search results | A magnifier over an empty list |
| `empty-ranks.png` | Ranks, unranked | A ladder with the lowest rung lit |
| `empty-charts.png` | Detail, fewer than two sessions | A chart axis with a single point on it |

Same style block. These can be 512 × 512.

---

## 7. App icon — 1 file, several sizes

```
App icon for a strength-training tracker called Gym Tracker.
A single bold mark on a deep near-black background (#07070A) with a subtle
violet-to-cyan gradient bloom in one corner. The mark: a minimal barbell
rendered as a horizontal bar with two plates, or an upward-stepping bar chart
that reads as progression — pick whichever is stronger at 60 pixels.
Flat, geometric, no bevel, no gloss, no text. Fills the canvas edge to edge
with no rounded corner drawn in — the system rounds it.
```

Deliver at 1024 × 1024. One file; Xcode generates the rest.

---

## 8. Summary

| Set | Files | Priority |
|---|---|---|
| Exercise icons | 270 | **First** — most visible, currently the weakest |
| Demonstration images | 540 | Second — 48 for the starter list is enough to begin |
| Muscle map | 9 | Third |
| Rank medals | 15 | Fourth |
| Empty states | 6 | Last |
| App icon | 1 | Whenever |
| **Total** | **841** | |

### What to send back

One folder, flat, PNG with alpha, named exactly as the tables specify. I handle downscaling, format conversion and wiring them in. If a name does not match, the app falls back to the generated shape and you will not see an error — so the names matter more than anything else here.

### If you want to test the pipeline first

Generate just these three and send them over:

```
bench-press.png
bench-press-tension.png
bench-press-relaxation.png
```

I will wire them in and screenshot the result, so you can judge the style at real size before committing to 841 images.
