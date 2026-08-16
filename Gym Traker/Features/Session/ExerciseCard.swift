//
//  ExerciseCard.swift
//  Gym Traker
//
//  One exercise inside a running session. Expanded it carries every control
//  that can change a tracked parameter; collapsed it is a one-line summary.
//

import SwiftUI

struct ExerciseCard: View {
    @Environment(\.colorScheme) private var scheme

    let entry: SessionEntry
    let item: PlanItem
    let units: Units
    let isExpanded: Bool

    var onTap: () -> Void
    var onWeightChange: (Double) -> Void
    var onRepsChange: (Int, Int) -> Void
    var onToggleSet: (Int) -> Void
    var onAddSet: () -> Void
    var onRestCycle: () -> Void
    var onToggleProgression: () -> Void
    var onAcceptSuggestion: () -> Void
    var onDeclineSuggestion: () -> Void
    var onStats: () -> Void

    private var completed: Int { entry.sets.filter(\.isCompleted).count }
    private var hasSuggestion: Bool { item.suggestedWeightKg != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 16 : 0) {
            header

            if isExpanded {
                if hasSuggestion { suggestionBanner }
                weightControl
                setRows
                addSetButton
                progressionToggle
                footerControls
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            isExpanded ? .regular.tint(Theme.Palette.violet.opacity(0.16)) : .regular,
            in: .rect(cornerRadius: Theme.Radius.card)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(
                    isExpanded ? Theme.Palette.violet.opacity(0.35) : Theme.Palette.stroke(scheme),
                    lineWidth: 1
                )
        }
        .animation(Theme.Motion.spring, value: isExpanded)
    }

    // MARK: - Header

    private var header: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(entry.order)")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Theme.Palette.violet.opacity(isExpanded ? 0.45 : 0.22)))
                    .foregroundStyle(isExpanded ? Color.white : Theme.Palette.violet)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.exerciseName)
                        .font(.titleS)
                        // Collapsed cards dim their title to secondary text.
                        .foregroundStyle(isExpanded ? .primary : .secondary)
                        .lineLimit(1)
                    Text("\(entry.sets.count)×\(item.repsSummary) · \(UnitFormatter.weight(item.workingWeightKg, in: units))")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Text("\(completed)/\(entry.sets.count)")
                    .font(.numberS)
                    .foregroundStyle(completed == entry.sets.count && completed > 0
                                     ? Theme.Palette.increase
                                     : Color.secondary)
            }
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Suggestion

    private var suggestionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundStyle(Theme.Palette.increase)
            VStack(alignment: .leading, spacing: 1) {
                Text("Go up to \(UnitFormatter.weight(item.suggestedWeightKg ?? 0, in: units))")
                    .font(.bodyM)
                Text(item.progressionArmed ? "You armed this last time" : "You cleared every target last time")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button("Keep") { onDeclineSuggestion() }
                .font(.captionM)
                .buttonStyle(.glass)
            Button("Accept") { onAcceptSuggestion() }
                .font(.captionM)
                .buttonStyle(.glassProminent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .fill(Theme.Palette.increase.opacity(0.14))
        )
    }

    // MARK: - Weight

    private var weightControl: some View {
        VStack(spacing: 8) {
            Text("Working weight").overlineStyle()
            WeightStepper(
                weightKg: item.workingWeightKg,
                stepKg: item.stepKg,
                units: units,
                isSuggested: false,
                onChange: onWeightChange
            )
        }
    }

    // MARK: - Sets

    private var setRows: some View {
        VStack(spacing: 0) {
            ForEach(Array(entry.sets.enumerated()), id: \.element.id) { index, set in
                HStack(spacing: 12) {
                    Button {
                        onToggleSet(index)
                    } label: {
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 25))
                            .foregroundStyle(set.isCompleted ? Theme.Palette.increase : Color.secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(set.isCompleted ? "Set \(index + 1) done" : "Complete set \(index + 1)")

                    Text("Set \(index + 1)")
                        .font(.bodyM)
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)

                    Spacer(minLength: 4)

                    RepsStepper(reps: set.reps) { newReps in
                        onRepsChange(index, newReps)
                    }
                }
                .padding(.vertical, 7)

                if index < entry.sets.count - 1 {
                    Divider().opacity(0.35)
                }
            }
        }
    }

    private var addSetButton: some View {
        Button(action: onAddSet) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text("Add set")
            }
            .font(.bodyM)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Progression

    private var progressionToggle: some View {
        Button(action: onToggleProgression) {
            HStack(spacing: 10) {
                Image(systemName: item.progressionArmed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 19))
                    .foregroundStyle(item.progressionArmed ? Theme.Palette.increase : Color.secondary)
                Text(Progression.label(for: item, units: units))
                    .font(.captionM)
                    .foregroundStyle(item.progressionArmed ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footerControls: some View {
        HStack(spacing: 10) {
            Button(action: onRestCycle) {
                HStack(spacing: 6) {
                    Image(systemName: "timer").font(.system(size: 12, weight: .bold))
                    Text(UnitFormatter.rest(item.restSeconds)).font(.captionM)
                }
                .foregroundStyle(Theme.Palette.cyan)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.chip))
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Rest \(UnitFormatter.rest(item.restSeconds)). Tap to change")

            Spacer(minLength: 0)

            Button(action: onStats) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill").font(.system(size: 12, weight: .bold))
                    Text("Stats").font(.captionM)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.chip))
            }
            .buttonStyle(.pressable)
        }
    }
}
