//
//  HistoryView.swift
//  Gym Traker
//
//  Every session ever logged, with the sets exactly as they were performed.
//
//  The registry answers "when did this change"; this answers "what did I
//  actually do that day". It lives behind the This week card on Home rather
//  than in the tab bar, because it is something you go and look at, not
//  somewhere you work from.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    @State private var expanded: Set<PersistentIdentifier> = []

    private var units: Units { profiles.first?.units ?? .kg }
    private var finished: [WorkoutSession] { sessions.filter(\.isFinished) }

    var body: some View {
        ZStack {
            if finished.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        summary
                        ForEach(grouped, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.title).overlineStyle().padding(.horizontal, 4)
                                ForEach(group.sessions) { session in
                                    sessionCard(session)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.bottom, 30)
                }
            }
        }
        .auroraVariant(.registry)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary

    private var summary: some View {
        GlassCard(radius: Theme.Radius.hero) {
            HStack(spacing: 0) {
                stat("Sessions", "\(finished.count)")
                Divider().frame(height: 38).opacity(0.4)
                stat("Sets", "\(finished.reduce(0) { $0 + $1.setCount })")
                Divider().frame(height: 38).opacity(0.4)
                stat("Volume", UnitFormatter.volume(finished.reduce(0) { $0 + $1.totalVolumeKg }, in: units))
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.numberM).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).overlineStyle()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Session card

    private func sessionCard(_ session: WorkoutSession) -> some View {
        let isOpen = expanded.contains(session.persistentModelID)

        return GlassCard(radius: Theme.Radius.row, padding: 14) {
            VStack(alignment: .leading, spacing: isOpen ? 14 : 0) {
                Button {
                    Haptics.play(.selection)
                    withAnimation(Theme.Motion.spring) {
                        if isOpen { expanded.remove(session.persistentModelID) }
                        else { expanded.insert(session.persistentModelID) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(session.planDayTitle)
                                    .font(.titleS)
                                    .foregroundStyle(.primary)
                                if session.isImported {
                                    Text(session.sourceName ?? "Health")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Theme.Palette.cyan.opacity(0.22)))
                                        .foregroundStyle(Theme.Palette.cyan)
                                }
                            }
                            Text(subtitle(session))
                                .font(.captionM)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 4)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isOpen ? 0 : -90))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressableSilent)

                if isOpen {
                    if session.orderedEntries.isEmpty {
                        Text("Imported from Health, so there are no set details.")
                            .font(.captionM)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(session.orderedEntries) { entry in
                                entryRow(entry)
                            }
                        }
                    }
                }
            }
        }
    }

    private func entryRow(_ entry: SessionEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.exerciseName)
                    .font(.bodyM)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(UnitFormatter.volume(entry.volumeKg, in: units))
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }

            // Every set exactly as performed, not as planned.
            FlowLayout(spacing: 6) {
                ForEach(Array(entry.sets.enumerated()), id: \.element.id) { index, set in
                    Text("\(set.reps) × \(UnitFormatter.number(set.weightKg, in: units))")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(set.isCompleted ? .primary : .tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(set.isCompleted
                                           ? Theme.Palette.violet.opacity(0.18)
                                           : Color.secondary.opacity(0.10))
                        )
                        .accessibilityLabel("Set \(index + 1): \(set.reps) reps at \(UnitFormatter.weight(set.weightKg, in: units))")
                }
            }
        }
    }

    private func subtitle(_ session: WorkoutSession) -> String {
        var parts = [session.startedAt.formatted(date: .abbreviated, time: .shortened)]
        if session.setCount > 0 { parts.append("\(session.setCount) sets") }
        if session.totalVolumeKg > 0 { parts.append(UnitFormatter.volume(session.totalVolumeKg, in: units)) }
        parts.append(UnitFormatter.clock(Int(session.duration)))
        return parts.joined(separator: " · ")
    }

    // MARK: - Grouping

    private struct Group {
        let title: String
        let sessions: [WorkoutSession]
    }

    private var grouped: [Group] {
        var order: [String] = []
        var buckets: [String: [WorkoutSession]] = [:]
        for session in finished {
            let key = session.startedAt.formatted(.dateTime.month(.wide).year())
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(session)
        }
        return order.map { Group(title: $0, sessions: buckets[$0] ?? []) }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No sessions yet").font(.titleL)
            Text("Finish a workout and it lands here with every set you logged.")
                .font(.bodyS)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
