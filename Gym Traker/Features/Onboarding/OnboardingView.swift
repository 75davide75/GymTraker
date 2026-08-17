//
//  OnboardingView.swift
//  Gym Traker
//
//  Three steps. Step two matters most: sex, age and bodyweight set the
//  thresholds every tier is measured against, so they use steppers rather than
//  a keyboard — nobody wants a numeric pad on their first screen.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthStore.self) private var health

    @State private var step = 0
    @State private var name = ""
    @State private var units: Units = .kg
    @State private var sex: Sex = .male
    @State private var age = 27
    @State private var bodyweightKg: Double = 75
    @State private var heightCm: Double?
    @State private var selectedPreset: PlanPreset?
    @State private var experience: ExperienceLevel = .beginner
    @State private var variant: PlanPreset.Variant = .balanced
    @State private var wantsPlan: Bool?
    @FocusState private var nameFocused: Bool

    private let lastStep = 4

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                progressDots
                    .padding(.top, 20)

                Group {
                    switch step {
                    case 0: introStep
                    case 1: welcomeStep
                    case 2: calibrationStep
                    case 3: experienceStep
                    default: planStep
                    }
                }
                .frame(maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                footer
            }
            .padding(Theme.Spacing.screenMargin)
        }
    }

    // MARK: - Chrome

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(0...lastStep), id: \.self) { index in
                Capsule()
                    .fill(index == step ? Theme.Palette.violet : Theme.Palette.violet.opacity(0.22))
                    .frame(width: index == step ? 22 : 7, height: 7)
            }
        }
        .animation(Theme.Motion.spring, value: step)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                advance()
            } label: {
                Text(continueTitle)
                    .font(.bodyM)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.glassProminent)

            if step > 0 {
                Button("Back") {
                    withAnimation(Theme.Motion.spring) { step -= 1 }
                }
                .font(.captionM)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 8)
    }

    private var continueTitle: String {
        if step == lastStep { return wantsPlan == false ? "Start empty" : "Start training" }
        if step == 3 { return "Continue" }
        return "Continue"
    }

    // MARK: - Step 0 — what the app is

    private var introStep: some View {
        VStack(spacing: 26) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Theme.Palette.violet)

            VStack(spacing: 8) {
                Text("Gym Tracker")
                    .font(.system(size: 34, weight: .bold))
                Text("Three things, done properly.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                pitch("list.bullet.rectangle", "Every set on record",
                      "Weight, reps and rest per set — and a log of every time one of them moved.")
                pitch("calendar", "A plan you can shape",
                      "Lettered day templates, repeated across the week however you train.")
                pitch("chart.line.uptrend.xyaxis", "Where you stand",
                      "Strength tiers from real standards, for every exercise and every muscle.")
                pitch("heart.text.square", "Health, if you let it",
                      "Bodyweight and height fill themselves in, and finished workouts go back.")
            }

            Spacer()
        }
        // Asked here, on the first screen, rather than the first time something
        // needs it. The next step is the one Health can fill in, so permission
        // has to have been settled before it is shown — and being asked while
        // reading what the app does is clearer than being asked mid-task.
        .task {
            guard health.availability == .notRequested else { return }
            await health.requestAuthorization()
            await prefillFromHealth()
        }
    }

    /// Health seeds the fields; it never overrules them. Anything typed later
    /// wins, and anything Health will not give simply stays as it was.
    private func prefillFromHealth() async {
        guard health.availability == .ready else { return }
        let data = await health.readBodyData()
        if let weight = data.bodyweightKg, weight > 20 { bodyweightKg = weight }
        if let sex = data.sex { self.sex = sex }
        if let year = data.birthYear {
            let computed = Calendar.current.component(.year, from: .now) - year
            if (13...100).contains(computed) { age = computed }
        }
        if let height = data.heightCm, height > 80 { heightCm = height }
    }

    private func pitch(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Palette.violet)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.bodyM)
                Text(body)
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.row))
    }

    // MARK: - Step 3 — experience

    private var experienceStep: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 8) {
                Text("How long have you trained?")
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("It sets the sets and reps a plan opens with. You can change everything after.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                ForEach(ExperienceLevel.allCases) { level in
                    Button {
                        Haptics.play(.selection)
                        withAnimation(Theme.Motion.snappy) {
                            experience = level
                            variant = PlanPreset.Variant.suggested(for: level)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: level.symbolName)
                                .font(.system(size: 18))
                                .frame(width: 28)
                                .foregroundStyle(experience == level ? Theme.Palette.violet : Color.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.displayName).font(.titleS).foregroundStyle(.primary)
                                Text(level.blurb).font(.captionM).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            if experience == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Palette.violet)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(
                            experience == level ? .regular.tint(Theme.Palette.violet.opacity(0.3)) : .regular,
                            in: .rect(cornerRadius: Theme.Radius.row)
                        )
                        .contentShape(.rect(cornerRadius: Theme.Radius.row))
                    }
                    .buttonStyle(.pressableSilent)
                }
            }

            Spacer()
        }
    }

    // MARK: - Step 1

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 30)

                VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Theme.Palette.violet)
                Text("Gym Tracker")
                    .font(.system(size: 34, weight: .bold))
                Text("Track every set, watch the numbers move, and see where you sit against real strength standards.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

                GlassSection(title: "Your name") {
                    TextField("Optional", text: $name)
                        .font(.bodyM)
                        .textInputAutocapitalization(.words)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit { advance() }
                }

                GlassSection(title: "Units") {
                    HStack(spacing: 10) {
                        ForEach(Units.allCases) { unit in
                            GlassChip(title: unit.rawValue.uppercased(), isSelected: units == unit) {
                                units = unit
                            }
                        }
                        Spacer()
                        Text("Weights are always stored in kg.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Step 2

    private var calibrationStep: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 8) {
                Text("Calibration").font(.system(size: 30, weight: .bold))
                Text("These set the thresholds every tier is measured against.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            GlassSection(title: "Sex") {
                HStack(spacing: 10) {
                    ForEach(Sex.allCases) { option in
                        GlassChip(title: option.displayName, isSelected: sex == option) {
                            sex = option
                        }
                    }
                    Spacer()
                }
            }

            GlassSection(title: "Age") {
                StepperControl(
                    canDecrease: age > 14,
                    canIncrease: age < 90,
                    onDecrease: { age -= 1 },
                    onIncrease: { age += 1 }
                ) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(age)").font(.numberL).contentTransition(.numericText(value: Double(age)))
                        Text("years").font(.bodyS).foregroundStyle(.secondary)
                    }
                }
            }

            GlassSection(title: "Bodyweight") {
                StepperControl(
                    canDecrease: bodyweightKg > 30,
                    canIncrease: bodyweightKg < 250,
                    onDecrease: { bodyweightKg -= 0.5 },
                    onIncrease: { bodyweightKg += 0.5 }
                ) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(UnitFormatter.number(bodyweightKg, in: units))
                            .font(.numberL)
                            .contentTransition(.numericText(value: bodyweightKg))
                        Text(units.rawValue).font(.bodyS).foregroundStyle(.secondary)
                    }
                }
            }

            Text("Standards are guidelines, not measurements.")
                .font(.captionM)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    // MARK: - Step 3

    private var planStep: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(wantsPlan == nil ? "Where do you start?" : "Pick a split")
                    .font(.system(size: 28, weight: .bold))
                Text(wantsPlan == nil
                     ? "Either way you can change everything afterwards."
                     : "Suggested for a \(experience.displayName.lowercased()) lifter first.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 6)

            if wantsPlan == nil {
                startChoice
            } else {
                ScrollView {
                    PlanPresetList(
                        experience: experience,
                        selection: $selectedPreset,
                        variant: $variant
                    )
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }

            Spacer(minLength: 0)
        }
    }

    /// Splits that suit the stated level come first.
    private var sortedPresets: [PlanPreset] {
        PlanPreset.all.sorted { lhs, rhs in
            let l = lhs.suits.contains(experience) ? 0 : 1
            let r = rhs.suits.contains(experience) ? 0 : 1
            return l == r ? lhs.dayCount < rhs.dayCount : l < r
        }
    }

    private var startChoice: some View {
        VStack(spacing: 12) {
            choiceCard(
                title: "Give me a plan",
                blurb: "Pick a split and the exercises are filled in, ready to train today.",
                symbol: "square.grid.2x2.fill",
                isSelected: false
            ) {
                withAnimation(Theme.Motion.spring) {
                    wantsPlan = true
                    selectedPreset = sortedPresets.first
                }
            }

            choiceCard(
                title: "Start empty",
                blurb: "An empty plan you build yourself from the library.",
                symbol: "square.dashed",
                isSelected: false
            ) {
                withAnimation(Theme.Motion.spring) {
                    wantsPlan = false
                    selectedPreset = nil
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func choiceCard(title: String, blurb: String, symbol: String,
                            isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.play(.selection)
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .frame(width: 32)
                    .foregroundStyle(Theme.Palette.violet)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.titleS).foregroundStyle(.primary)
                    Text(blurb)
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.row))
            .contentShape(.rect(cornerRadius: Theme.Radius.row))
        }
        .buttonStyle(.pressableSilent)
    }

    // MARK: - Completion

    private func advance() {
        guard step == lastStep else {
            // Resign focus inside the same animation, so the keyboard slides
            // away with the step transition instead of snapping first.
            withAnimation(Theme.Motion.spring) {
                nameFocused = false
                step += 1
            }
            Haptics.light()
            return
        }

        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sex: sex,
            birthYear: Calendar.current.component(.year, from: .now) - age,
            bodyweightKg: bodyweightKg,
            units: units
        )
        profile.experience = experience
        profile.heightCm = heightCm
        context.insert(profile)
        if wantsPlan == true { selectedPreset?.build(in: context, variant: variant) }
        try? context.save()

        RestTimer.requestAuthorization()
        Haptics.success()
    }
}
