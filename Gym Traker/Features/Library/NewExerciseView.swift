//
//  NewExerciseView.swift
//  Gym Traker
//
//  Adds an exercise to the user's own archive. The diagram preview updates as
//  the equipment changes, so what you pick is what you get in the list.
//

import SwiftUI
import SwiftData

struct NewExerciseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var onSave: ((Exercise) -> Void)?

    @State private var name = ""
    @State private var muscle: Muscle = .chest
    @State private var equipment: Equipment = .barbell
    @State private var anchor: RankAnchor?
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(spacing: 20) {
                    preview
                    nameField
                    muscleChips
                    equipmentChips
                    anchorPicker
                    saveButton
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("New exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Pieces

    private var preview: some View {
        GlassCard(radius: Theme.Radius.hero) {
            VStack(spacing: 14) {
                ExerciseGlyph(shape: equipment.glyphShape, hue: equipment.glyphHue, size: 104)
                    .animation(Theme.Motion.spring, value: equipment)

                VStack(spacing: 4) {
                    Text(name.isEmpty ? "Your exercise" : name)
                        .font(.titleL)
                        .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                    Text("\(muscle.rawValue) · \(equipment.rawValue)")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private var nameField: some View {
        GlassSection(title: "Name") {
            TextField("Cable crossover", text: $name)
                .font(.bodyM)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
        }
    }

    private var muscleChips: some View {
        GlassSection(title: "Primary muscle") {
            FlowChips(items: Muscle.allCases.map(\.rawValue), selected: muscle.rawValue) { value in
                if let picked = Muscle(rawValue: value) { muscle = picked }
            }
        }
    }

    private var equipmentChips: some View {
        GlassSection(title: "Equipment") {
            FlowChips(items: Equipment.allCases.map(\.rawValue), selected: equipment.rawValue) { value in
                if let picked = Equipment(rawValue: value) { equipment = picked }
            }
        }
    }

    private var anchorPicker: some View {
        GlassSection(title: "Rank as") {
            VStack(alignment: .leading, spacing: 10) {
                FlowChips(
                    items: ["No tier"] + RankAnchor.allCases.filter { $0 != .bw }.map(\.displayName),
                    selected: anchor?.displayName ?? "No tier"
                ) { value in
                    anchor = RankAnchor.allCases.first { $0.displayName == value }
                }
                Text("Accessory work is best left untiered — it keeps the ladder meaningful.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Save to my library")
                .font(.bodyM)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
    }

    // MARK: - Saving

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let exercise = Exercise(
            id: uniqueID(for: trimmed),
            name: trimmed,
            primaryMuscle: muscle.rawValue,
            equipment: equipment,
            rankAnchor: anchor,
            tracking: equipment == .bodyweight ? .repsOptionalLoad : .weightReps,
            isCustom: true,
            notes: notes.isEmpty ? nil : notes
        )
        context.insert(exercise)
        try? context.save()
        Haptics.success()
        onSave?(exercise)
        dismiss()
    }

    /// Keeps the slug unique against everything already in the archive.
    private func uniqueID(for name: String) -> String {
        let base = Exercise.slug(from: name)
        let taken = Set(Store.allExercises(in: context).map(\.id))
        guard taken.contains(base) else { return base }
        var suffix = 2
        while taken.contains("\(base)-\(suffix)") { suffix += 1 }
        return "\(base)-\(suffix)"
    }
}

// MARK: - Wrapping chip row

/// A wrapping row of single-select chips.
struct FlowChips: View {
    let items: [String]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                GlassChip(title: item, isSelected: item == selected) {
                    Haptics.selection()
                    onSelect(item)
                }
            }
        }
    }
}

/// Minimal wrapping layout — chips flow onto the next line when they run out
/// of width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = layout(subviews: subviews, width: width)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in layout(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func layout(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = current.width == 0 ? size.width : current.width + spacing + size.width
            if projected > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = projected
                current.height = max(current.height, size.height)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    NavigationStack {
        NewExerciseView()
    }
}
