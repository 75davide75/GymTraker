//
//  YouView.swift
//  Gym Traker
//
//  Where the lifter sits: one global score, four anchor lifts, and the ladder
//  they climb. Every number here is a guideline, and the screen says so.
//

import SwiftUI
import SwiftData

struct YouView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]

    @State private var showingSettings = false
    @State private var ranking = RankingSnapshot.empty
    @State private var muscleRanks: [MuscleRank] = []
    @State private var achievements: [Achievement] = []
    @State private var editingProfile = false

    private var profile: UserProfile? { profiles.first }
    private var units: Units { profile?.units ?? .kg }

    private var globalLevel: RankResult? { ranking.global }
    private var anchorScores: [RankAnchor: RankResult] { ranking.perAnchor }
    private var sessionsLast4Weeks: Int { ranking.sessionsLast4Weeks }

    private let bigFour: [RankAnchor] = [.squat, .bench, .deadlift, .ohp]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 18) {
                    identity.entryTransition(0)
                    globalCard.entryTransition(1)
                    medalCard.entryTransition(2)
                    muscleCard.entryTransition(3)
                    perLift.entryTransition(4)
                    ladder.entryTransition(5)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, 24)
            }
        }
        .auroraVariant(.profile)
        .task {
            ranking = Store.rankingSnapshot(in: context)
            muscleRanks = Store.muscleRanks(in: context, snapshot: ranking)
            achievements = Achievements.all(in: context)
        }
        .navigationTitle("You")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
                .appAppearance()
        }
        .sheet(isPresented: $editingProfile) {
            if let profile {
                NavigationStack { ProfileEditor(profile: profile) }
                    .appAppearance()
            }
        }
    }

    // MARK: - Identity

    private var identity: some View {
        Button {
            editingProfile = true
        } label: {
            GlassCard(radius: Theme.Radius.hero) {
                HStack(spacing: 16) {
                    ProfileAvatar(profile: profile, size: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile?.name.isEmpty == false ? profile!.name : "Lifter")
                            .font(.titleL)
                            .foregroundStyle(.primary)
                        if let profile {
                            Text(detailLine(profile))
                                .font(.captionM)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.pressable)
    }

    private func detailLine(_ profile: UserProfile) -> String {
        var parts = [
            profile.sex.displayName,
            "\(profile.age)",
            UnitFormatter.weight(profile.bodyweightKg, in: units)
        ]
        if let height = profile.heightCm {
            parts.append("\(Int(height.rounded())) cm")
        }
        return parts.joined(separator: " · ")
    }

    private var initials: String {
        let name = profile?.name.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else { return "GT" }
        return name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    // MARK: - Global rank

    /// The rank, read as one thing.
    ///
    /// This used to be a ring, a medal, a tier name, a note, a consistency line
    /// and a disclaimer, all competing inside one card — six pieces of type at
    /// five sizes, and the number you actually came for was the smallest of
    /// them. The tier is the headline; the ring became a bar under it, because
    /// what it shows is progress along a scale and a bar is how a scale reads.
    private var globalCard: some View {
        GlassSection(title: "Global rank") {
            if let global = globalLevel {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 14) {
                        TierMedal(tier: global.tier, division: global.division, size: 52)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(global.label)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(global.tier.tint)
                            Text(global.tier.note)
                                .font(.captionM)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)

                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(Int(global.score.rounded()))")
                                .font(.system(size: 30, weight: .bold))
                                .monospacedDigit()
                                .contentTransition(.numericText(value: global.score))
                            Text("of 100")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    GlassProgressBar(value: global.score / 100, tint: global.tier.tint, height: 8)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .bold))
                        Text(consistencyLine)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.tertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Unranked").font(.titleL).foregroundStyle(.secondary)
                    Text("Log at least two of squat, bench, deadlift and overhead press to get a global level.")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Medals, earned ones first.
    private var medalCard: some View {
        GlassSection(title: "Medals") {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(achievements.count(where: \.isEarned)) of \(achievements.count) earned")
                    .font(.captionM)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(achievements) { achievement in
                            AchievementMedal(achievement: achievement)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollClipDisabled()

                if let next = achievements.first(where: { !$0.isEarned }) {
                    Text("Next: \(next.detail.lowercased()).")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func scoreRing(_ result: RankResult) -> some View {
        ZStack {
            Circle()
                .stroke(Theme.Palette.track(.dark), lineWidth: 8)
            Circle()
                .trim(from: 0, to: result.score / 100)
                .stroke(
                    AngularGradient(
                        colors: [result.tier.tint.opacity(0.7), result.tier.tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Motion.spring, value: result.score)

            VStack(spacing: 0) {
                Text("\(Int(result.score.rounded()))")
                    .font(.system(size: 26, weight: .bold))
                    .monospacedDigit()
                Text("/ 100")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 96, height: 96)
    }

    private var consistencyLine: String {
        let count = sessionsLast4Weeks
        let missing = RankingEngine.sessionsToFullConsistency(count)
        if missing == 0 {
            return "\(count) sessions in 4 weeks · full consistency bonus"
        }
        return "\(count) sessions in 4 weeks · \(missing) more for the full bonus"
    }

    // MARK: - Per muscle

    @ViewBuilder
    private var muscleCard: some View {
        if muscleRanks.isEmpty {
            GlassSection(title: "By muscle") {
                Text("Log a few exercises and each muscle group gets its own standing.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            }
        } else {
            GlassSection(title: "By muscle") {
                VStack(spacing: 0) {
                    ForEach(Array(muscleRanks.enumerated()), id: \.element.id) { index, rank in
                        MuscleRankRow(rank: rank)
                        if index < muscleRanks.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Per lift

    private var perLift: some View {
        GlassSection(title: "Tier per lift") {
            VStack(spacing: 0) {
                ForEach(Array(bigFour.enumerated()), id: \.element) { index, anchor in
                    liftRow(anchor)
                    if index < bigFour.count - 1 {
                        Divider().opacity(0.4).padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func liftRow(_ anchor: RankAnchor) -> some View {
        let result = anchorScores[anchor]
        let best = ranking.anchorExerciseIDs[anchor].flatMap { ranking.bestSet(for: $0) }

        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(anchor.displayName)
                    .font(.bodyM)
                Spacer()
                Text(result?.label ?? "Unranked")
                    .font(.captionM)
                    .foregroundStyle(result?.tier.tint ?? Color.secondary)
            }

            GlassProgressBar(
                value: result?.progressInTier ?? 0,
                tint: result?.tier.tint ?? Color.secondary,
                height: 6
            )

            HStack {
                if let best {
                    Text("\(UnitFormatter.weight(best.weightKg, in: units)) × \(best.reps)")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    Text("No sets logged")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if let result, !result.isRepBased {
                    Text("\(UnitFormatter.weight(result.value, in: units)) e1RM")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Ladder

    private var ladder: some View {
        GlassSection(title: "The ladder") {
            VStack(spacing: 0) {
                ForEach(Tier.allCases) { tier in
                    let isCurrent = globalLevel?.tier == tier

                    HStack(spacing: 12) {
                        Circle()
                            .fill(tier.tint)
                            .frame(width: 9, height: 9)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tier.displayName)
                                .font(.bodyM)
                                .foregroundStyle(isCurrent ? .primary : .secondary)
                            Text(tier.note)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }

                        Spacer(minLength: 0)

                        Text(tier.scoreRangeLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, isCurrent ? 10 : 0)
                    .background {
                        if isCurrent {
                            RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                                .fill(tier.tint.opacity(0.14))
                        }
                    }
                }
            }
        }
    }
}
