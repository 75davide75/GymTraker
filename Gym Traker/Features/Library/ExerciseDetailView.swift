//
//  ExerciseDetailView.swift
//  Gym Traker
//
//  One exercise, everything known about it: where it sits on the ladder, how
//  the working weight has moved, and every logged change.
//

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var context
    let exercise: Exercise
    @State private var showingPhotos = false

    private var units: Units { Store.units(in: context) }
    private var rank: RankResult? { Store.rank(for: exercise, in: context) }
    private var history: [SessionEntry] { Store.history(for: exercise.id, in: context, limit: 8) }
    private var records: [ChangeRecord] { Registry.forExercise(exercise.id, in: context, limit: 20) }
    private var planItem: PlanItem? {
        Store.activePlan(in: context)?.orderedDays
            .flatMap(\.orderedItems)
            .first { $0.exerciseID == exercise.id }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 18) {
                    heading.entryTransition(0)
                    demoCard.entryTransition(1)
                    instructionsCard.entryTransition(2)
                    tipsCard.entryTransition(3)
                    tierCard.entryTransition(4)
                    chartCard.entryTransition(5)
                    schemeCard.entryTransition(6)
                    registryCard.entryTransition(7)
                }
                .padding(Theme.Spacing.screenMargin)
                .padding(.bottom, 30)
            }
        }
        .auroraVariant(.library)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPhotos) {
            NavigationStack { ExercisePhotoGallery(exercise: exercise) }
        }
    }

    // MARK: - Heading

    private var heading: some View {
        GlassCard(radius: Theme.Radius.hero) {
            HStack(spacing: 16) {
                ExerciseThumbnail(exercise: exercise, size: 76)
                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.name).font(.titleL).lineLimit(2)
                    Text(exercise.subtitle).font(.captionM).foregroundStyle(.secondary)
                    if let item = planItem {
                        Text("\(item.schemeSummary) · \(UnitFormatter.weight(item.workingWeightKg, in: units))")
                            .font(.captionM)
                            .foregroundStyle(Theme.Palette.violet)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Demonstration

    @ViewBuilder
    private var demoCard: some View {
        if exercise.hasIllustrations {
            GlassSection(title: "How it looks") {
                VStack(spacing: 12) {
                    ExerciseDemo(exercise: exercise)

                    if exercise.hasPhotos {
                        Button {
                            showingPhotos = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle")
                                Text("Reference photos")
                            }
                            .font(.captionM)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tipsCard: some View {
        if !exercise.tips.isEmpty {
            GlassSection(title: "Watch out for") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(exercise.tips.enumerated()), id: \.offset) { _, tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Palette.decrease)
                                .padding(.top, 2)
                            Text(tip)
                                .font(.bodyS)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var instructionsCard: some View {
        if !exercise.instructions.isEmpty {
            GlassSection(title: "How to do it") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .monospacedDigit()
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Theme.Palette.violet.opacity(0.22)))
                                .foregroundStyle(Theme.Palette.violet)
                            Text(step)
                                .font(.bodyS)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tier

    @ViewBuilder
    private var tierCard: some View {
        if let rank {
            GlassSection(title: "Strength tier") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(rank.label)
                            .font(.titleL)
                            .foregroundStyle(rank.tier.tint)
                        Spacer()
                        Text(rank.isRepBased
                             ? "\(Int(rank.value.rounded())) effective reps"
                             : "\(UnitFormatter.weight(rank.value, in: units)) e1RM")
                            .font(.numberS)
                            .foregroundStyle(.secondary)
                    }

                    GlassProgressBar(value: rank.progressInTier, tint: rank.tier.tint)

                    if let next = rank.nextThreshold, let nextTier = Tier(rawValue: rank.tier.rawValue + 1) {
                        Text(rank.isRepBased
                             ? "\(nextTier.displayName) at \(Int(next.rounded())) reps"
                             : "\(nextTier.displayName) at \(UnitFormatter.weight(next, in: units)) estimated 1RM")
                            .font(.captionM)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Top of the ladder — nothing above Elite.")
                            .font(.captionM)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else if exercise.rankAnchor == nil {
            GlassSection(title: "Strength tier") {
                Text("Accessory work is tracked and charted but never tiered, which keeps the ladder meaningful.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            }
        } else {
            GlassSection(title: "Strength tier") {
                Text("Log a set to see where this lift sits.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Chart

    private var chartCard: some View {
        GlassSection(title: "Working weight · last \(max(history.count, 1)) sessions") {
            if history.isEmpty {
                Text("No sessions logged yet.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            } else {
                WeightBarChart(
                    values: history.map(\.topWeightKg),
                    labels: history.map { shortDate($0.session?.startedAt) },
                    units: units
                )
            }
        }
    }

    // MARK: - Scheme

    @ViewBuilder
    private var schemeCard: some View {
        if let item = planItem, !item.targetSets.isEmpty {
            GlassSection(title: "Set scheme") {
                VStack(spacing: 0) {
                    ForEach(Array(item.targetSets.enumerated()), id: \.element.id) { index, target in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.bodyM)
                            Spacer()
                            Text("\(target.reps) reps")
                                .font(.numberS)
                                .foregroundStyle(.secondary)
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(UnitFormatter.weight(item.workingWeightKg, in: units))
                                .font(.numberS)
                        }
                        .padding(.vertical, 10)

                        if index < item.targetSets.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Registry

    private var registryCard: some View {
        GlassSection(title: "Registry for this exercise") {
            if records.isEmpty {
                Text("No changes recorded yet.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.persistentModelID) { index, record in
                        RegistryRow(record: record, showExerciseName: false)
                        if index < records.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func shortDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

// MARK: - Bar chart

/// Hand-rolled so the bars carry the same glass and accent language as the
/// rest of the app. Latest bar is accented.
struct WeightBarChart: View {
    @Environment(\.colorScheme) private var scheme
    let values: [Double]
    let labels: [String]
    let units: Units

    private var maxValue: Double { max(values.max() ?? 1, 0.001) }
    private var minValue: Double { values.min() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    let isLatest = index == values.count - 1
                    // Scale from just below the lightest session so small
                    // increments stay visible.
                    let floorValue = max(0, minValue * 0.82)
                    let fraction = maxValue > floorValue
                        ? (value - floorValue) / (maxValue - floorValue)
                        : 1

                    VStack(spacing: 6) {
                        Text(UnitFormatter.number(value, in: units))
                            .font(.system(size: 10, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(isLatest ? Theme.Palette.violet : Color.secondary)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                isLatest
                                ? LinearGradient(colors: [Theme.Palette.violet, Theme.Palette.violet.opacity(0.6)],
                                                 startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Theme.Palette.fill(scheme), Theme.Palette.fill(scheme)],
                                                 startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: 20 + 76 * max(0.05, min(1, fraction)))

                        Text(labels.indices.contains(index) ? labels[index] : "")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
