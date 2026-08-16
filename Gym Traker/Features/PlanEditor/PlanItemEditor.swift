//
//  PlanItemEditor.swift
//  Gym Traker
//
//  One line of the plan. Every control here writes a registry entry, because
//  these are exactly the parameters requirement 1 asks the app to remember.
//

import SwiftUI
import SwiftData

struct PlanItemEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let item: PlanItem
    let units: Units
    /// Called when the user removes the exercise from the plan.
    var onDelete: (() -> Void)?

    @State private var confirmingDelete = false

    /// Rest values the pill cycles through, per design/SPEC.md §2.3.
    static let restLadder = [45, 60, 75, 90, 105, 120, 150, 180]

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(spacing: 18) {
                    weightCard
                    setsCard
                    restCard
                }
                .padding(Theme.Spacing.screenMargin)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(item.exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .tint(Theme.Palette.decrease)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    try? context.save()
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            "Remove \(item.exerciseName)?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Remove from plan", role: .destructive) {
                Haptics.play(.remove)
                onDelete?()
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("The history stays in the registry.")
        }
    }

    // MARK: - Weight

    private var weightCard: some View {
        GlassSection(title: "Working weight") {
            VStack(spacing: 12) {
                WeightStepper(
                    weightKg: item.workingWeightKg,
                    stepKg: item.stepKg,
                    units: units
                ) { newValue in
                    changeWeight(to: newValue)
                }

                HStack(spacing: 8) {
                    Text("Step").font(.captionM).foregroundStyle(.secondary)
                    Spacer()
                    ForEach([0.5, 1.0, 2.0, 2.5, 5.0], id: \.self) { step in
                        GlassChip(
                            title: UnitFormatter.number(step, in: units),
                            isSelected: abs(item.stepKg - step) < 0.001
                        ) {
                            item.stepKg = step
                            try? context.save()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sets

    private var setsCard: some View {
        GlassSection(title: "Sets · each set keeps its own reps") {
            VStack(spacing: 0) {
                ForEach(Array(item.targetSets.enumerated()), id: \.element.id) { index, target in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.bodyM)
                            .frame(width: 60, alignment: .leading)

                        Spacer()

                        RepsStepper(reps: target.reps) { newReps in
                            changeReps(at: index, to: newReps)
                        }

                        Button {
                            removeSet(at: index)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(item.targetSets.count > 1 ? Theme.Palette.decrease : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(item.targetSets.count <= 1)
                        .padding(.leading, 6)
                        .accessibilityLabel("Remove set \(index + 1)")
                    }
                    .padding(.vertical, 8)

                    if index < item.targetSets.count - 1 {
                        Divider().opacity(0.4)
                    }
                }

                Button {
                    addSet()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add set")
                    }
                    .font(.bodyM)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.glass)
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Rest

    private var restCard: some View {
        GlassSection(title: "Rest between sets") {
            RestPicker(seconds: item.restSeconds) { changeRest(to: $0) }
        }
    }

    // MARK: - Mutations — each one writes to the registry

    private func changeWeight(to newValue: Double) {
        let old = item.workingWeightKg
        guard abs(old - newValue) > 0.001 else { return }
        item.workingWeightKg = newValue
        Registry.weightChanged(item: item, from: old, to: newValue, units: units, in: context)
        try? context.save()
    }

    private func changeReps(at index: Int, to newReps: Int) {
        guard item.targetSets.indices.contains(index) else { return }
        let old = item.targetSets[index].reps
        guard old != newReps else { return }
        item.targetSets[index].reps = newReps
        Registry.repsChanged(item: item, setIndex: index, from: old, to: newReps, in: context)
        try? context.save()
    }

    private func addSet() {
        let old = item.targetSets.count
        // A new set copies the previous set's reps.
        let reps = item.targetSets.last?.reps ?? 10
        withAnimation(Theme.Motion.spring) {
            item.targetSets.append(SetTarget(reps: reps))
        }
        Registry.setsChanged(item: item, from: old, to: item.targetSets.count, in: context)
        try? context.save()
        Haptics.medium()
    }

    private func removeSet(at index: Int) {
        guard item.targetSets.count > 1, item.targetSets.indices.contains(index) else { return }
        let old = item.targetSets.count
        withAnimation(Theme.Motion.spring) {
            _ = item.targetSets.remove(at: index)
        }
        Registry.setsChanged(item: item, from: old, to: item.targetSets.count, in: context)
        try? context.save()
        Haptics.light()
    }

    private func changeRest(to seconds: Int) {
        let old = item.restSeconds
        guard old != seconds else { return }
        item.restSeconds = seconds
        try? context.save()
        Haptics.selection()
    }

}
