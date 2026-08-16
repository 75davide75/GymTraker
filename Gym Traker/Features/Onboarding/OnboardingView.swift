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

    @State private var step = 0
    @State private var name = ""
    @State private var units: Units = .kg
    @State private var sex: Sex = .male
    @State private var age = 27
    @State private var bodyweightKg: Double = 75
    @State private var selectedPreset: PlanPreset?
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                progressDots
                    .padding(.top, 20)

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: calibrationStep
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
            ForEach([0, 1, 2], id: \.self) { index in
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
                Text(step == 2 ? "Start training" : "Continue")
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
                Text("Pick a split").font(.system(size: 28, weight: .bold))
                Text("You can rearrange everything later.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 6)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(PlanPreset.all) { preset in
                        presetRow(preset)
                    }
                    presetRow(nil)
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func presetRow(_ preset: PlanPreset?) -> some View {
        let isSelected = preset?.id == selectedPreset?.id

        return Button {
            Haptics.selection()
            withAnimation(Theme.Motion.snappy) { selectedPreset = preset }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21))
                    .foregroundStyle(isSelected ? Theme.Palette.violet : Color.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(preset?.name ?? "Start empty")
                            .font(.titleS)
                        if let days = preset?.dayCount {
                            Text("\(days)×")
                                .font(.system(size: 11, weight: .bold))
                                .monospacedDigit()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Theme.Palette.violet.opacity(0.22)))
                                .foregroundStyle(Theme.Palette.violet)
                        }
                    }
                    Text(preset?.subtitle ?? "Build your own from the library")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                    if let note = preset?.note {
                        Text(note)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                isSelected ? .regular.tint(Theme.Palette.violet.opacity(0.3)) : .regular,
                in: .rect(cornerRadius: Theme.Radius.row)
            )
            .contentShape(.rect(cornerRadius: Theme.Radius.row))
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Completion

    private func advance() {
        guard step == 2 else {
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
        context.insert(profile)
        selectedPreset?.build(in: context)
        try? context.save()

        RestTimer.requestAuthorization()
        Haptics.success()
    }
}
