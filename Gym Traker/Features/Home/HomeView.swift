//
//  HomeView.swift
//  Gym Traker
//
//  The landing screen: what is on today, where the rank sits, what changed
//  last, and how the week has actually gone.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context

    @Query private var plans: [Plan]
    @Query private var profiles: [UserProfile]
    @Query(sort: \ChangeRecord.date, order: .reverse) private var records: [ChangeRecord]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    var onOpenPlan: () -> Void = {}

    /// One destination type for the whole screen.
    ///
    /// Home previously carried two `navigationDestination` modifiers — one
    /// `item:` for the session and one `isPresented:` for the ladder. SwiftUI
    /// pushed a screen it could not resolve: the Ranks title appeared with no
    /// content and no back button, and the app was stuck there. A single
    /// destination keyed off one enum leaves nothing to disambiguate.
    private enum Route: Hashable, Identifiable {
        case session(PlanDay)
        case ranks
        case registry
        case history

        var id: Self { self }
    }

    @State private var route: Route?
    @State private var ranking = RankingSnapshot.empty

    private var plan: Plan? { plans.first(where: \.isActive) ?? plans.first }
    private var profile: UserProfile? { profiles.first }
    private var units: Units { profile?.units ?? .kg }
    /// Today's template, or the next one scheduled. On a rest day the card
    /// still offers a session — the alternative is a dead screen four days a
    /// week.
    private var upNextDay: PlanDay? { plan?.nextScheduled()?.day }
    private var daysAhead: Int { plan?.nextScheduled()?.daysAhead ?? 0 }
    private var isToday: Bool { daysAhead == 0 }

    private var recentSessions: [WorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now
        return sessions.filter { $0.isFinished && $0.startedAt >= cutoff }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    greeting.entryTransition(0)
                    weekStrip.entryTransition(1)
                    upNext.entryTransition(2)
                    tiles.entryTransition(3)
                    weekVolume.entryTransition(4)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, 30)
            }
        }
        .auroraVariant(.home)
        .task { ranking = Store.rankingSnapshot(in: context) }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $route) { destination in
            switch destination {
            case .session(let day): SessionView(day: day)
            case .ranks: RankLadderView()
            case .registry: RegistryView()
            case .history: HistoryView()
            }
        }
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(greetingText)
                .font(.titleL)
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.captionM)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
    }

    private var greetingText: String {
        let name = profile?.name ?? ""
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.isEmpty ? part : "\(part), \(name)"
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        // The prototype puts the strip straight on the background, not inside
        // a card — the day cells are the only surfaces here.
        WeekScheduleGrid(
            letters: plan?.orderedDays.map(\.letter) ?? [],
            assignments: plan?.weekAssignmentsRaw ?? Array(repeating: "", count: 7),
            isInteractive: false
        ) { _ in }
        .contentShape(Rectangle())
        .onTapGesture { onOpenPlan() }
    }

    // MARK: - Up next

    @ViewBuilder
    private var upNext: some View {
        if let day = upNextDay, !day.orderedItems.isEmpty {
            GlassCard(radius: Theme.Radius.hero) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(isToday ? "Up next" : "Rest day · next session").overlineStyle()
                        Spacer()
                        Text("\(day.letter) · \(day.estimatedMinutes) min")
                            .font(.captionM)
                            .foregroundStyle(Theme.Palette.violet)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.title).font(.titleL)
                        Text("\(day.orderedItems.count) exercises · \(day.totalSets) sets")
                            .font(.captionM)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 8) {
                        ForEach(day.orderedItems.prefix(3)) { item in
                            HStack {
                                Text(item.exerciseName)
                                    .font(.bodyS)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                Text("\(item.targetSets.count)×\(item.repsSummary) · \(UnitFormatter.weight(item.workingWeightKg, in: units))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        if day.orderedItems.count > 3 {
                            HStack {
                                Text("+ \(day.orderedItems.count - 3) more")
                                    .font(.captionM)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                            }
                        }
                    }

                    Button {
                        route = .session(day)
                    } label: {
                        Text("Start workout")
                            .font(.bodyM)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        } else {
            GlassCard(radius: Theme.Radius.hero) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(plan == nil ? "No plan yet" : "Nothing scheduled").font(.titleL)
                    Text(plan == nil
                         ? "Build a plan and your next session will show up here."
                         : "Add exercises to a day template and it will appear here.")
                        .font(.bodyS)
                        .foregroundStyle(.secondary)
                    Button(plan == nil ? "Build a plan" : "Open plan") { onOpenPlan() }
                        .buttonStyle(.glassProminent)
                        .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Tiles

    private var tiles: some View {
        HStack(spacing: 12) {
            rankTile
            lastChangeTile
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var rankTile: some View {
        Button {
            route = .ranks
        } label: {
            rankTileBody
        }
        .buttonStyle(.pressable)
    }

    private var rankTileBody: some View {
        GlassCard(padding: 14, stretchVertically: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rank").overlineStyle()
                if let global = ranking.global {
                    Text(global.label)
                        .font(.titleS)
                        .foregroundStyle(global.tier.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    GlassProgressBar(value: global.progressInTier, tint: global.tier.tint, height: 6)
                    Text("\(Int(global.score.rounded())) / 100")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    Text("Unranked").font(.titleS).foregroundStyle(.secondary)
                    Text("Log two of the big four lifts.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var lastChangeTile: some View {
        Button {
            route = .registry
        } label: {
            lastChangeTileBody
        }
        .buttonStyle(.pressable)
    }

    private var lastChangeTileBody: some View {
        GlassCard(padding: 14, stretchVertically: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Last change").overlineStyle()
                if let record = records.first {
                    HStack(spacing: 6) {
                        Image(systemName: record.direction.glyph)
                            .font(.system(size: record.direction == .neutral ? 5 : 10, weight: .bold))
                            .foregroundStyle(Theme.Palette.direction(record.direction))
                        Text(record.exerciseName)
                            .font(.titleS)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Text(record.summary)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(record.date.compactRelative)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Nothing yet").font(.titleS).foregroundStyle(.secondary)
                    Text("Changes land here with their date.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Week volume

    private var weekVolume: some View {
        Button {
            route = .history
        } label: {
            weekVolumeBody
        }
        .buttonStyle(.pressable)
    }

    private var weekVolumeBody: some View {
        GlassSection(title: "This week") {
            VStack(alignment: .leading, spacing: 12) {
                let volumes = weekdayVolumes()
                let peak = max(volumes.max() ?? 1, 1)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(volumes.enumerated()), id: \.offset) { index, volume in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(volume > 0
                                      ? AnyShapeStyle(LinearGradient(
                                            colors: [Theme.Palette.violet, Theme.Palette.violet.opacity(0.55)],
                                            startPoint: .top, endPoint: .bottom))
                                      : AnyShapeStyle(Color.secondary.opacity(0.18)))
                                .frame(height: 8 + 56 * (volume / peak))
                            Text(["M", "T", "W", "T", "F", "S", "S"][index])
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(index == Plan.mondayBasedIndex(for: .now) ? Theme.Palette.violet : Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                HStack(spacing: 6) {
                    Text(consistencyLine)
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text("All sessions")
                        .font(.captionM)
                        .foregroundStyle(Theme.Palette.violet)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.Palette.violet)
                }
            }
        }
    }

    /// Volume per weekday for the current Monday-based week.
    private func weekdayVolumes() -> [Double] {
        var volumes = Array(repeating: 0.0, count: 7)
        let calendar = Calendar.current
        let todayIndex = Plan.mondayBasedIndex(for: .now)
        guard let weekStart = calendar.date(byAdding: .day, value: -todayIndex, to: calendar.startOfDay(for: .now)) else {
            return volumes
        }

        for session in sessions where session.isFinished && session.startedAt >= weekStart {
            let index = Plan.mondayBasedIndex(for: session.startedAt)
            guard volumes.indices.contains(index) else { continue }
            volumes[index] += session.totalVolumeKg
        }
        return volumes
    }

    private var consistencyLine: String {
        let count = recentSessions.count
        guard count > 0 else { return "No sessions logged in the last 4 weeks." }
        return "\(count) session\(count == 1 ? "" : "s") in the last 4 weeks"
    }
}
