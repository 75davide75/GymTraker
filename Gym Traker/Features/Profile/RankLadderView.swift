//
//  RankLadderView.swift
//  Gym Traker
//
//  The whole ladder in one place: which tiers are unlocked, which are not, and
//  the actual numbers each one asks for at this lifter's bodyweight and age.
//

import SwiftUI
import SwiftData

struct RankLadderView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    @State private var selectedLift: RankAnchor = .bench
    @State private var ranking = RankingSnapshot.empty

    private var profile: UserProfile? { profiles.first }
    private var units: Units { profile?.units ?? .kg }
    private var globalLevel: RankResult? { ranking.global }
    private var anchorScores: [RankAnchor: RankResult] { ranking.perAnchor }

    private let lifts: [RankAnchor] = [.bench, .squat, .deadlift, .ohp, .row]

    /// Highest tier reached on any lift — what "unlocked" means here.
    private var highestReached: Tier? {
        anchorScores.values.map(\.tier).max { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                standing.entryTransition(0)
                liftPicker.entryTransition(1)
                ladder.entryTransition(2)
                footnote.entryTransition(3)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 30)
        }
        .auroraVariant(.profile)
        .task { ranking = Store.rankingSnapshot(in: context) }
        .navigationTitle("Ranks")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Standing

    private var standing: some View {
        GlassCard(radius: Theme.Radius.hero) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Where you stand").overlineStyle()
                if let global = globalLevel {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(global.label)
                            .font(.displayL)
                            .foregroundStyle(global.tier.tint)
                        Text("\(Int(global.score.rounded())) / 100")
                            .font(.numberS)
                            .foregroundStyle(.secondary)
                    }
                    GlassProgressBar(value: global.score / 100, tint: global.tier.tint)
                    if let next = Tier(rawValue: global.tier.rawValue + 1) {
                        Text("\(next.displayName) opens at score \(next.rawValue * 20).")
                            .font(.captionM)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Top of the ladder.")
                            .font(.captionM)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Unranked").font(.titleL).foregroundStyle(.secondary)
                    Text("Log at least two of squat, bench, deadlift and overhead press to open the ladder.")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Lift picker

    private var liftPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requirements for").overlineStyle().padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lifts) { lift in
                        GlassChip(title: lift.displayName, isSelected: selectedLift == lift) {
                            withAnimation(Theme.Motion.spring) { selectedLift = lift }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: - Ladder

    private var ladder: some View {
        VStack(spacing: 10) {
            ForEach(Tier.allCases) { tier in
                tierRow(tier)
            }
        }
    }

    private func tierRow(_ tier: Tier) -> some View {
        let current = anchorScores[selectedLift]
        let isReached = (current?.tier.rawValue ?? -1) >= tier.rawValue
        let isCurrent = current?.tier == tier
        let requirement = requirementText(for: tier)

        return GlassCard(radius: Theme.Radius.row, padding: 14, tint: isCurrent ? tier.tint : nil) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tier.tint.opacity(isReached ? 0.9 : 0.16))
                        .frame(width: 38, height: 38)
                    Image(systemName: isReached ? "checkmark" : "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isReached ? Color.white : tier.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tier.displayName)
                            .font(.titleS)
                            .foregroundStyle(isReached ? .primary : .secondary)
                        if isCurrent {
                            Text("You are here")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(tier.tint.opacity(0.3)))
                                .foregroundStyle(tier.tint)
                        }
                    }

                    Text(tier.note)
                        .font(.captionM)
                        .foregroundStyle(.secondary)

                    Text(requirement)
                        .font(.numberS)
                        .foregroundStyle(isReached ? tier.tint : Color.secondary)

                    Text("Score \(tier.scoreRangeLabel)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 0)
            }
        }
        .opacity(isReached ? 1 : 0.78)
    }

    /// The load — or rep count — this tier asks for, at this lifter's numbers.
    private func requirementText(for tier: Tier) -> String {
        guard let profile else { return "Set your profile to see the numbers" }
        let lifter = profile.lifter

        guard let thresholds = RankingTables.shared.thresholds(anchor: selectedLift, lifter: lifter),
              thresholds.indices.contains(tier.rawValue)
        else { return "—" }

        let target = thresholds[tier.rawValue]
        let ratio = target / max(profile.bodyweightKg, 1)
        return "\(UnitFormatter.weight(target, in: units)) e1RM · \(String(format: "%.2f", ratio))× bodyweight"
    }

    // MARK: - Footnote

    private var footnote: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("How this is worked out").overlineStyle()
                Text("Every tier is a multiple of your bodyweight, adjusted by an age coefficient — 1.00 under 30, then 0.98, 0.92, 0.83 and 0.72 past 60. A set is scored by its estimated 1RM, capped at ten reps.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
                Text("Standards are guidelines, not measurements. Elite here means roughly the top 5 % of consistent drug-free lifters, not a competitive standard.")
                    .font(.captionM)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
