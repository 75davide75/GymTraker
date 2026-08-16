//
//  RegistryView.swift
//  Gym Traker
//
//  The read side of requirement 1. Nothing else writes here, and nothing is
//  ever silently overwritten — so this screen answers "when did that change,
//  and from what".
//

import SwiftUI
import SwiftData

struct RegistryView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \ChangeRecord.date, order: .reverse) private var allRecords: [ChangeRecord]

    @State private var fieldFilter: ChangeField?
    @State private var exerciseFilter: String?
    @State private var visibleCount = 50

    private var filtered: [ChangeRecord] {
        allRecords.filter { record in
            (fieldFilter == nil || record.field == fieldFilter)
                && (exerciseFilter == nil || record.exerciseID == exerciseFilter)
        }
    }

    private var page: [ChangeRecord] { Array(filtered.prefix(visibleCount)) }

    /// Exercises that actually appear in the log, for the filter menu.
    private var loggedExercises: [(id: String, name: String)] {
        var seen = Set<String>()
        var result: [(id: String, name: String)] = []
        for record in allRecords where !seen.contains(record.exerciseID) {
            seen.insert(record.exerciseID)
            result.append((record.exerciseID, record.exerciseName))
        }
        return result.sorted { $0.name < $1.name }
    }

    var body: some View {
        ZStack {
            AuroraBackground()

            if allRecords.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        filterBar

                        ForEach(RegistryGroup.group(page), id: \.title) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.title).overlineStyle().padding(.horizontal, 4)

                                GlassCard(padding: 4) {
                                    VStack(spacing: 0) {
                                        ForEach(Array(group.records.enumerated()), id: \.element.persistentModelID) { index, record in
                                            RegistryRow(record: record)
                                                .padding(.horizontal, 12)
                                            if index < group.records.count - 1 {
                                                Divider().opacity(0.4).padding(.leading, 46)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if filtered.count > visibleCount {
                            Button("Show 50 more") {
                                withAnimation(Theme.Motion.spring) { visibleCount += 50 }
                            }
                            .buttonStyle(.glass)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Registry")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Filters

    private var filterBar: some View {
        HStack(spacing: 8) {
            Menu {
                Button("All fields") { fieldFilter = nil }
                Divider()
                ForEach(ChangeField.allCases) { field in
                    Button(field.displayName) { fieldFilter = field }
                }
            } label: {
                filterLabel(
                    icon: "line.3.horizontal.decrease",
                    text: fieldFilter?.displayName ?? "All fields",
                    active: fieldFilter != nil
                )
            }

            Menu {
                Button("All exercises") { exerciseFilter = nil }
                Divider()
                ForEach(loggedExercises, id: \.id) { entry in
                    Button(entry.name) { exerciseFilter = entry.id }
                }
            } label: {
                filterLabel(
                    icon: "dumbbell",
                    text: loggedExercises.first { $0.id == exerciseFilter }?.name ?? "All exercises",
                    active: exerciseFilter != nil
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private func filterLabel(icon: String, text: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text).font(.captionM).lineLimit(1)
        }
        .foregroundStyle(active ? Theme.Palette.violet : Color.secondary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .glassEffect(
            active ? .regular.tint(Theme.Palette.violet.opacity(0.3)) : .regular,
            in: .rect(cornerRadius: Theme.Radius.chip)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Nothing logged yet").font(.titleL)
            Text("Change a weight, a rep count, a set count or a rest time and it lands here with the date.")
                .font(.bodyS)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Grouping

/// Reverse-chronological sections: Recent, Earlier, then by month.
struct RegistryGroup {
    let title: String
    let records: [ChangeRecord]

    static func group(_ records: [ChangeRecord]) -> [RegistryGroup] {
        let calendar = Calendar.current
        let now = Date.now
        let recentCutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let earlierCutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        var recent: [ChangeRecord] = []
        var earlier: [ChangeRecord] = []
        var byMonth: [String: [ChangeRecord]] = [:]
        var monthOrder: [String] = []

        for record in records {
            if record.date >= recentCutoff {
                recent.append(record)
            } else if record.date >= earlierCutoff {
                earlier.append(record)
            } else {
                let key = record.date.formatted(.dateTime.month(.wide).year())
                if byMonth[key] == nil { monthOrder.append(key) }
                byMonth[key, default: []].append(record)
            }
        }

        var groups: [RegistryGroup] = []
        if !recent.isEmpty { groups.append(RegistryGroup(title: "Recent", records: recent)) }
        if !earlier.isEmpty { groups.append(RegistryGroup(title: "Earlier", records: earlier)) }
        for key in monthOrder {
            groups.append(RegistryGroup(title: key, records: byMonth[key] ?? []))
        }
        return groups
    }
}

// MARK: - Row

struct RegistryRow: View {
    let record: ChangeRecord
    var showExerciseName: Bool = true

    private var tint: Color { Theme.Palette.direction(record.direction) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: record.direction.glyph)
                    .font(.system(size: record.direction == .neutral ? 6 : 12, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                if showExerciseName {
                    Text(record.exerciseName)
                        .font(.bodyM)
                        .lineLimit(1)
                }
                Text(record.summary)
                    .font(showExerciseName ? .captionM : .bodyM)
                    .foregroundStyle(showExerciseName ? .secondary : .primary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Text(record.date.formatted(.relative(presentation: .numeric)))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .layoutPriority(-1)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack { RegistryView() }
}
