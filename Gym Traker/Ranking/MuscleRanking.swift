//
//  MuscleRanking.swift
//  Gym Traker
//
//  A rank per muscle group, and a medal to go with every tier.
//
//  One global number says how strong you are; it says nothing about what you
//  have neglected. Averaging each muscle's exercises exposes the shape of a
//  physique — the chest three tiers above the legs is the thing worth knowing.
//

import Foundation
import SwiftData
import SwiftUI

/// Where one muscle group stands.
struct MuscleRank: Identifiable, Equatable {
    let muscle: MuscleGroup
    let result: RankResult
    /// How many exercises fed the average.
    let exerciseCount: Int
    /// The exercise carrying the group.
    let bestExerciseName: String?

    var id: MuscleGroup { muscle }
}

extension RankingSnapshot {
    /// Eleven groups rather than seven coarse ones.
    ///
    /// "Arms" covered a hundred exercises and could not tell you that your
    /// triceps were behind your biceps, which is exactly the kind of thing a
    /// per-muscle rank exists to say. Cardio and mobility are tracked and not
    /// ranked: there is no bodyweight-relative standard for a treadmill.
    static let rankedMuscles: [MuscleGroup] = MuscleGroup.ranked
}

extension Store {

    /// Averages each muscle group's scored exercises.
    static func muscleRanks(in context: ModelContext, snapshot: RankingSnapshot) -> [MuscleRank] {
        guard !snapshot.perExercise.isEmpty else { return [] }

        var byMuscle: [MuscleGroup: [(score: Double, name: String)]] = [:]
        for exercise in allExercises(in: context) {
            guard let result = snapshot.perExercise[exercise.id] else { continue }
            byMuscle[exercise.group, default: []].append((result.score, exercise.name))
        }

        return RankingSnapshot.rankedMuscles.compactMap { muscle in
            guard let entries = byMuscle[muscle], !entries.isEmpty else { return nil }
            let mean = entries.map(\.score).reduce(0, +) / Double(entries.count)
            guard let result = RankingEngine.result(forScore: mean) else { return nil }
            return MuscleRank(
                muscle: muscle,
                result: result,
                exerciseCount: entries.count,
                bestExerciseName: entries.max { $0.score < $1.score }?.name
            )
        }
    }
}

// MARK: - Medals

/// The badge for a tier and division. Fifteen of them, so there is always a
/// next one close enough to want.
struct TierMedal: View {
    let tier: Tier
    let division: Int
    var size: CGFloat = 56
    var isLocked: Bool = false

    private var metal: [Color] {
        guard !isLocked else {
            return [Color.gray.opacity(0.5), Color.gray.opacity(0.25)]
        }
        return [tier.tint, tier.tint.opacity(0.55)]
    }

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .fill(
                    AngularGradient(
                        colors: metal + [metal[0]],
                        center: .center
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .fill(Theme.Palette.backgroundDark.opacity(0.82))
                .frame(width: size * 0.78, height: size * 0.78)

            // Division marks: one, two or three notches around the top.
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index < division ? (isLocked ? Color.gray.opacity(0.6) : tier.tint) : Color.white.opacity(0.14))
                    .frame(width: size * 0.045, height: size * 0.1)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(index - 1) * 18))
            }

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.26, weight: .bold))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    Text(tier.displayName.prefix(1))
                        .font(.system(size: size * 0.3, weight: .black))
                        .foregroundStyle(tier.tint)
                    Text(numeral)
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(tier.displayName) \(numeral)\(isLocked ? ", locked" : "")")
    }

    private var numeral: String {
        switch division {
        case 1: "I"
        case 2: "II"
        default: "III"
        }
    }
}

// MARK: - Muscle row

struct MuscleRankRow: View {
    let rank: MuscleRank

    var body: some View {
        HStack(spacing: 14) {
            BodyMap(highlighted: rank.muscle, size: 30)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(rank.muscle.displayName)
                        .font(.bodyM)
                    Spacer()
                    Text(rank.result.label)
                        .font(.captionM)
                        .foregroundStyle(rank.result.tier.tint)
                }

                GlassProgressBar(value: rank.result.progressInTier, tint: rank.result.tier.tint, height: 6)

                Text("\(rank.exerciseCount) exercise\(rank.exerciseCount == 1 ? "" : "s") · best on \(rank.bestExerciseName ?? "—")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
}
