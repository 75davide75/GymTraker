//
//  SessionView.swift
//  Gym Traker
//
//  A running workout. Vertical list of exercise cards, current one expanded.
//  Every parameter change here writes to the registry in the same transaction,
//  and the actual per-set values are kept independent of the plan's scheme.
//

import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(HealthStore.self) private var health

    let day: PlanDay

    @State private var session: WorkoutSession?
    @State private var expandedIndex: Int = 0
    @State private var timer = RestTimer()
    @State private var showingSummary = false
    @State private var summary: SessionSummary?
    @State private var promotion: Promotion?
    @State private var statsExercise: Exercise?
    @State private var restEditingItem: PlanItem?
    /// Rest already served this session, in seconds.
    @State private var restAccumulated: Int = 0
    @State private var confirmingFinish = false

    private var units: Units { Store.units(in: context) }
    private var items: [PlanItem] { day.orderedItems }

    private var entries: [SessionEntry] { session?.orderedEntries ?? [] }
    private var totalSets: Int { entries.reduce(0) { $0 + $1.sets.count } }
    private var completedSets: Int { entries.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count } }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 12) {
                    header
                    cards
                    finishButton
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, timer.isResting ? 120 : 44)
            }

            if timer.isResting {
                RestBar(timer: timer) {
                    restAccumulated += timer.elapsedInCurrentRest
                    timer.skip()
                }
                .padding(.bottom, 12)
            }
        }
        .auroraVariant(.session)
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Finish") { confirmingFinish = true }
                    .font(.bodyM)
                    .tint(Theme.Palette.sportRed)
            }
        }
        .confirmationDialog(
            "Finish this workout?",
            isPresented: $confirmingFinish,
            titleVisibility: .visible
        ) {
            Button("End session") { finish() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("\(completedSets) of \(totalSets) sets logged.")
        }
        .task {
            timer.alert = Store.profile(in: context)?.restAlert ?? .soundAndHaptics
            startIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { timer.refresh() }
        }
        .onChange(of: timer.isResting) { wasResting, isResting in
            // A rest that ran to the end still counts towards the split.
            if wasResting, !isResting { restAccumulated += timer.lastRestDuration }
        }
        .sheet(isPresented: $showingSummary) {
            if let summary {
                SummarySheet(summary: summary, units: units) { dismiss() }
            }
        }
        .fullScreenCover(item: $promotion) { promotion in
            PromotionView(promotion: promotion)
        }
        .navigationDestination(item: $statsExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .sheet(item: $restEditingItem) { item in
            RestSheet(item: item) { seconds in
                item.restSeconds = seconds
                try? context.save()
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if let session {
            SessionDashboard(
                startedAt: session.startedAt,
                restSeconds: restAccumulated + timer.elapsedInCurrentRest,
                completedSets: completedSets,
                totalSets: totalSets,
                segments: segments,
                isResting: timer.isResting
            )
            .entryTransition(0)
        }
    }

    private var segments: [SessionDashboard.SessionSegment] {
        entries.enumerated().map { index, entry in
            SessionDashboard.SessionSegment(
                id: index,
                name: entry.exerciseName,
                total: entry.sets.count,
                completed: entry.sets.filter(\.isCompleted).count
            )
        }
    }

    // MARK: - Cards

    private var cards: some View {
        ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
            if let item = items.first(where: { $0.exerciseID == entry.exerciseID }) {
                ExerciseCard(
                    entry: entry,
                    item: item,
                    units: units,
                    isExpanded: index == expandedIndex,
                    onTap: {
                        withAnimation(Theme.Motion.spring) {
                            expandedIndex = index == expandedIndex ? -1 : index
                        }
                    },
                    onWeightChange: { changeWeight(item: item, entry: entry, to: $0) },
                    onRepsChange: { changeReps(item: item, entry: entry, setIndex: $0, to: $1) },
                    onToggleSet: { toggleSet(entry: entry, item: item, index: $0, cardIndex: index) },
                    onAddSet: { addSet(entry: entry, item: item) },
                    onRestTap: { restEditingItem = item },
                    onToggleProgression: { toggleProgression(item: item) },
                    onAcceptSuggestion: { acceptSuggestion(item: item, entry: entry) },
                    onDeclineSuggestion: { Progression.decline(item); try? context.save() },
                    onStats: { statsExercise = Store.exercise(id: entry.exerciseID, in: context) }
                )
                .entryTransition(index + 1)
            }
        }
    }

    /// Sits after the last exercise, where you actually are when you finish.
    private var finishButton: some View {
        VStack(spacing: 10) {
            Button {
                confirmingFinish = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flag.checkered")
                    Text("Finish workout")
                }
                .font(.bodyM)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.pressableSilent)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Palette.sportRed, Theme.Palette.sportEmber],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
            }
            .foregroundStyle(.white)

            Text("\(completedSets) of \(totalSets) sets logged")
                .font(.captionM)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 6)
    }

    // MARK: - Session lifecycle

    /// Builds the session from the plan, opening each exercise at its suggested
    /// weight when one is waiting.
    private func startIfNeeded() {
        guard session == nil else { return }
        RestTimer.requestAuthorization()

        let workout = WorkoutSession(planDayLetter: day.letter, planDayTitle: day.title)
        context.insert(workout)

        for item in items {
            let opening = item.openingWeightKg
            let sets = item.targetSets.map {
                PerformedSet(reps: $0.reps, weightKg: opening, targetReps: $0.reps)
            }
            let entry = SessionEntry(
                order: item.order,
                exerciseID: item.exerciseID,
                exerciseName: item.exerciseName,
                restSeconds: item.restSeconds,
                sets: sets
            )
            entry.session = workout
            context.insert(entry)
        }

        try? context.save()
        session = workout
    }

    private func finish() {
        guard let session else { dismiss(); return }
        timer.stop()
        session.endedAt = .now

        // The plan learns from what actually happened.
        Progression.apply(session: session, items: items)
        let tierChanges = recomputeRanks(for: session)

        try? context.save()
        Haptics.success()

        let finished = session
        Task { await health.save(session: finished) }

        summary = SessionSummary(
            volumeKg: session.totalVolumeKg,
            setCount: session.setCount,
            duration: session.duration,
            tierChanges: tierChanges,
            registryCount: newRegistryCount(since: session.startedAt)
        )
        if let first = tierChanges.first(where: \.promoted) {
            promotion = Promotion(
                exerciseName: first.exerciseName,
                tierLabel: first.to,
                detail: first.detail
            )
        }
        showingSummary = true
    }

    private func newRegistryCount(since date: Date) -> Int {
        Registry.all(in: context).filter { $0.date >= date }.count
    }

    // MARK: - Mutations

    private func changeWeight(item: PlanItem, entry: SessionEntry, to newValue: Double) {
        let old = item.workingWeightKg
        guard abs(old - newValue) > 0.001 else { return }
        item.workingWeightKg = newValue
        // Sets already logged keep the load they were performed at.
        for index in entry.sets.indices where !entry.sets[index].isCompleted {
            entry.sets[index].weightKg = newValue
        }
        Registry.weightChanged(
            item: item, from: old, to: newValue, units: units,
            sessionUUID: session?.uuid, in: context
        )
        try? context.save()
    }

    private func changeReps(item: PlanItem, entry: SessionEntry, setIndex: Int, to newReps: Int) {
        guard entry.sets.indices.contains(setIndex) else { return }
        let old = entry.sets[setIndex].reps
        guard old != newReps else { return }

        entry.sets[setIndex].reps = newReps
        // The plan's target follows, so the next session opens at the new scheme.
        if item.targetSets.indices.contains(setIndex) {
            item.targetSets[setIndex].reps = newReps
            entry.sets[setIndex].targetReps = newReps
        }
        Registry.repsChanged(
            item: item, setIndex: setIndex, from: old, to: newReps,
            sessionUUID: session?.uuid, in: context
        )
        try? context.save()
    }

    private func toggleSet(entry: SessionEntry, item: PlanItem, index: Int, cardIndex: Int) {
        guard entry.sets.indices.contains(index) else { return }

        if entry.sets[index].isCompleted {
            entry.sets[index].completedAt = nil
        } else {
            entry.sets[index].completedAt = .now
            entry.sets[index].weightKg = item.workingWeightKg
            Haptics.light()

            // Completing a set starts this exercise's rest automatically.
            let nextSet = index + 2
            if index < entry.sets.count - 1 {
                timer.start(
                    seconds: item.restSeconds,
                    exerciseName: entry.exerciseName,
                    nextSetNumber: nextSet,
                    notify: Store.profile(in: context)?.notificationsEnabled ?? true
                )
            } else {
                timer.stop()
                // Last set done — move on to the next exercise.
                withAnimation(Theme.Motion.spring) {
                    if cardIndex + 1 < entries.count { expandedIndex = cardIndex + 1 }
                }
            }
        }
        try? context.save()
    }

    private func addSet(entry: SessionEntry, item: PlanItem) {
        let reps = entry.sets.last?.reps ?? 10
        let oldCount = item.targetSets.count
        withAnimation(Theme.Motion.spring) {
            entry.sets.append(
                PerformedSet(reps: reps, weightKg: item.workingWeightKg, targetReps: reps)
            )
            item.targetSets.append(SetTarget(reps: reps))
        }
        Registry.setsChanged(
            item: item, from: oldCount, to: item.targetSets.count,
            sessionUUID: session?.uuid, in: context
        )
        try? context.save()
        Haptics.medium()
    }

    private func toggleProgression(item: PlanItem) {
        let armed = !item.progressionArmed
        item.progressionArmed = armed
        Registry.progressionToggled(
            item: item, armed: armed,
            targetKg: item.workingWeightKg + item.stepKg,
            units: units, in: context
        )
        try? context.save()
        Haptics.medium()
    }

    private func acceptSuggestion(item: PlanItem, entry: SessionEntry) {
        guard let change = Progression.accept(item) else { return }
        for index in entry.sets.indices where !entry.sets[index].isCompleted {
            entry.sets[index].weightKg = change.to
        }
        Registry.weightChanged(
            item: item, from: change.from, to: change.to, units: units,
            sessionUUID: session?.uuid, in: context
        )
        try? context.save()
        Haptics.success()
    }

    // MARK: - Ranking

    /// Rescores every exercise touched by this session and records the moves.
    private func recomputeRanks(for session: WorkoutSession) -> [TierChange] {
        guard let profile = Store.profile(in: context) else { return [] }
        var changes: [TierChange] = []

        for entry in session.orderedEntries {
            guard let exercise = Store.exercise(id: entry.exerciseID, in: context),
                  let anchor = exercise.rankAnchor,
                  let best = entry.bestSet,
                  let result = RankingEngine.rank(
                      anchor: anchor,
                      weightKg: best.weightKg,
                      reps: best.reps,
                      lifter: profile.lifter,
                      exerciseID: exercise.id
                  )
            else { continue }

            let previousTier = exercise.cachedTierIndex
            exercise.cachedScore = result.score
            exercise.cachedTierIndex = result.tier.rawValue
            exercise.cachedScoredAt = .now

            guard let previousTier, previousTier != result.tier.rawValue else { continue }

            let from = Tier(rawValue: previousTier)?.displayName ?? "Unranked"
            let promoted = result.tier.rawValue > previousTier
            Registry.tierChanged(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                from: from,
                to: result.label,
                promoted: promoted,
                sessionUUID: session.uuid,
                in: context
            )

            let key = "\(exercise.id)#\(result.tier.rawValue)"
            let alreadyCelebrated = profile.celebratedPromotions.contains(key)
            if promoted && !alreadyCelebrated {
                profile.celebratedPromotions.append(key)
            }

            changes.append(
                TierChange(
                    exerciseName: exercise.name,
                    from: from,
                    to: result.label,
                    promoted: promoted && !alreadyCelebrated,
                    detail: "\(UnitFormatter.weight(best.weightKg, in: units)) × \(best.reps) · \(UnitFormatter.weight(result.value, in: units)) e1RM"
                )
            )
        }
        return changes
    }
}

// MARK: - Value types

struct TierChange: Identifiable, Hashable {
    let id = UUID()
    let exerciseName: String
    let from: String
    let to: String
    let promoted: Bool
    let detail: String
}

struct SessionSummary {
    let volumeKg: Double
    let setCount: Int
    let duration: TimeInterval
    let tierChanges: [TierChange]
    let registryCount: Int
}

struct Promotion: Identifiable {
    let id = UUID()
    let exerciseName: String
    let tierLabel: String
    let detail: String
}
