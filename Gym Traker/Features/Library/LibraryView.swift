//
//  LibraryView.swift
//  Gym Traker
//
//  The archive. Doubles as the exercise picker for the plan editor — same list,
//  different tap target.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    enum Mode: Equatable {
        case browse
        case picker
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    var mode: Mode = .browse
    var onSelect: ((Exercise) -> Void)?

    @State private var search = ""
    @State private var equipmentFilter: Equipment?
    @State private var showingNewExercise = false
    @State private var detailExercise: Exercise?
    @FocusState private var searchFocused: Bool

    /// Only equipment the archive actually has exercises for. A chip that
    /// filters to nothing is a dead end.
    private var availableEquipment: [Equipment] {
        let present = Set(exercises.map(\.equipment))
        return Equipment.allCases.filter(present.contains)
    }

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            exercise.matches(search)
                && (equipmentFilter == nil || exercise.equipment == equipmentFilter)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                rows
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        // A safe-area inset is what "pinned" should have been all along: the
        // header stays put, the list scrolls under it, and the scroll view
        // works out its own top inset instead of being handed a measured one.
        .safeAreaInset(edge: .top, spacing: 0) { pinnedHeader }
        .auroraVariant(.library)
        .navigationTitle(mode == .picker ? "Add exercise" : "Library")
        .navigationBarTitleDisplayMode(mode == .picker ? .inline : .large)
        .toolbar {
            if mode == .picker {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewExercise = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewExercise) {
            NavigationStack {
                NewExerciseView { created in
                    if mode == .picker {
                        onSelect?(created)
                        dismiss()
                    }
                }
            }
        }
        .navigationDestination(item: $detailExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    // MARK: - Pinned header

    /// Search and filters stay put; the list passes behind them and fades out
    /// under a soft edge rather than being clipped by a hard line.
    private var pinnedHeader: some View {
        VStack(spacing: 10) {
            searchField
            filterChips
            countLine
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.72),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField("Search name or muscle", text: $search)
                .font(.bodyM)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)
            if !search.isEmpty {
                Button {
                    Haptics.play(.selection)
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.pressableSilent)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.control))
        .animation(Theme.Motion.snappy, value: search.isEmpty)
    }

    private var countLine: some View {
        HStack {
            Text("\(filtered.count) of \(exercises.count) exercises")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                GlassChip(title: "All", isSelected: equipmentFilter == nil) {
                    equipmentFilter = nil
                }
                ForEach(availableEquipment) { equipment in
                    GlassChip(
                        title: equipment.rawValue,
                        isSelected: equipmentFilter == equipment,
                        tint: Theme.Palette.glyph(hue: equipment.glyphHue)
                    ) {
                        equipmentFilter = equipmentFilter == equipment ? nil : equipment
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private var rows: some View {
        if filtered.isEmpty {
            emptyState
        } else {
            ForEach(filtered, id: \.id) { exercise in
                Button {
                    if mode == .picker {
                        onSelect?(exercise)
                        dismiss()
                    } else {
                        detailExercise = exercise
                    }
                } label: {
                    ExerciseRow(exercise: exercise)
                }
                .buttonStyle(.pressable)
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Nothing matches “\(search)”")
                    .font(.bodyM)
                Text("Add it to your own archive instead.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
                Button("Create exercise") { showingNewExercise = true }
                    .buttonStyle(.glassProminent)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding(.top, 20)
    }
}

// MARK: - Row

struct ExerciseRow: View {
    @Environment(\.colorScheme) private var scheme
    let exercise: Exercise
    var trailingText: String?

    var body: some View {
        HStack(spacing: 14) {
            ExerciseThumbnail(exercise: exercise, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.titleS)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if exercise.isCustom {
                        Text("Custom")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Theme.Palette.cyan.opacity(0.25))
                            )
                            .foregroundStyle(Theme.Palette.cyan)
                    }
                }
                Text(trailingText ?? exercise.subtitle)
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.row))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
