//
//  StepperControl.swift
//  Gym Traker
//
//  The −/+ pair used for weights, reps and set counts. Targets are 46–52 pt
//  because these get tapped mid-set with chalk on your hands.
//

import SwiftUI

/// A −/+ stepper with a large tabular readout between the buttons.
struct StepperControl<Label: View>: View {
    @Environment(\.colorScheme) private var scheme

    var canDecrease: Bool = true
    var canIncrease: Bool = true
    var buttonSize: CGFloat = 46
    var haptic: () -> Void = Haptics.medium
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    @ViewBuilder var label: Label

    var body: some View {
        HStack(spacing: 12) {
            button(systemName: "minus", enabled: canDecrease, action: onDecrease)

            label
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())

            button(systemName: "plus", enabled: canIncrease, action: onIncrease)
        }
    }

    private func button(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            haptic()
            withAnimation(Theme.Motion.snappy) { action() }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .frame(width: buttonSize, height: buttonSize)
                .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.smallControl))
                // Without this the tappable area follows the glyph's own
                // shape, and a minus sign is a thin bar — far harder to hit
                // than a plus. The whole tile is the button.
                .contentShape(.rect(cornerRadius: Theme.Radius.smallControl))
                .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
        .accessibilityLabel(systemName == "minus" ? "Decrease" : "Increase")
    }
}

/// The compact reps stepper used on each set row.
struct RepsStepper: View {
    let reps: Int
    var range: ClosedRange<Int> = 1...50
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            smallButton("minus", enabled: reps > range.lowerBound) { onChange(reps - 1) }

            Text("\(reps)")
                .font(.numberS)
                .frame(minWidth: 28)
                .contentTransition(.numericText(value: Double(reps)))

            smallButton("plus", enabled: reps < range.upperBound) { onChange(reps + 1) }
        }
    }

    private func smallButton(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            Haptics.light()
            withAnimation(Theme.Motion.snappy) { action() }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 34, height: 34)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                // The tile reads as 34 pt but takes a 44 pt touch, the
                // documented minimum, without pushing the row taller.
                .contentShape(.rect(cornerRadius: 12))
                .padding(5)
                .contentShape(Rectangle())
                .opacity(enabled ? 1 : 0.3)
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
        .accessibilityLabel(systemName == "minus" ? "One rep fewer" : "One rep more")
    }
}

/// The hero weight control on an expanded exercise card.
struct WeightStepper: View {
    let weightKg: Double
    let stepKg: Double
    let units: Units
    var isSuggested: Bool = false
    let onChange: (Double) -> Void

    var body: some View {
        StepperControl(
            canDecrease: weightKg - stepKg >= 0,
            buttonSize: 52,
            onDecrease: { onChange(max(0, weightKg - stepKg)) },
            onIncrease: { onChange(weightKg + stepKg) }
        ) {
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(UnitFormatter.number(weightKg, in: units))
                        .font(.numberL)
                        .contentTransition(.numericText(value: weightKg))
                    Text(units.rawValue)
                        .font(.bodyS)
                        .foregroundStyle(.secondary)
                }
                if isSuggested {
                    Text("Suggested")
                        .font(.overline)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.increase)
                }
            }
        }
    }
}

#Preview("Steppers") {
    ZStack {
        AuroraBackground()
        VStack(spacing: 28) {
            GlassCard {
                WeightStepper(weightKg: 72.5, stepKg: 2.5, units: .kg, isSuggested: true) { _ in }
            }
            GlassCard {
                HStack {
                    Text("Set 3").font(.bodyM)
                    Spacer()
                    RepsStepper(reps: 8) { _ in }
                }
            }
        }
        .padding()
    }
}
