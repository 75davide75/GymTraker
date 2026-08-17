//
//  Achievements.swift
//  Gym Traker
//
//  Medals for showing up.
//
//  The tier ladder rewards being strong, which is a slow signal and a
//  discouraging one early on: a beginner can train for a month and watch the
//  same word sit on the same card. These reward the things that are actually
//  under your control on any given day — turning up, turning up again
//  tomorrow, staying a bit longer, adding a bit more.
//
//  All of it is computed from the sessions and the registry that already exist.
//  Nothing here is stored, so it cannot drift out of step with the log.
//

import Foundation
import SwiftData
import SwiftUI

struct Achievement: Identifiable, Equatable {
    enum Family: String {
        case streak, endurance, progression, volume
    }

    let id: String
    let family: Family
    let title: String
    /// What it takes, or what it took.
    let detail: String
    let symbolName: String
    let isEarned: Bool
    /// 0–1 towards earning it. 1 when earned.
    let progress: Double

    var tint: Color {
        switch family {
        case .streak: Theme.Palette.sportEmber
        case .endurance: Theme.Palette.cyan
        case .progression: Theme.Palette.increase
        case .volume: Theme.Palette.violet
        }
    }
}

enum Achievements {

    /// Every medal, earned or not, in the order they should be shown: the ones
    /// in reach first.
    static func all(in context: ModelContext) -> [Achievement] {
        let sessions = Store.sessions(in: context).filter(\.isFinished)
        let records = Registry.all(in: context)

        var result = streaks(sessions)
        result.append(contentsOf: endurance(sessions))
        result.append(contentsOf: progression(records))
        result.append(contentsOf: volume(sessions))

        // Earned first, then whatever is closest to being earned.
        return result.sorted { lhs, rhs in
            if lhs.isEarned != rhs.isEarned { return lhs.isEarned }
            return lhs.progress > rhs.progress
        }
    }

    static func earnedCount(in context: ModelContext) -> Int {
        all(in: context).count(where: \.isEarned)
    }

    // MARK: - Consecutive days

    /// The longest run of calendar days with a finished session, and the run
    /// currently going.
    static func streakLengths(_ sessions: [WorkoutSession]) -> (longest: Int, current: Int) {
        let calendar = Calendar.current
        let days = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        guard !days.isEmpty else { return (0, 0) }

        let sorted = days.sorted()
        var longest = 1
        var run = 1
        for index in 1..<sorted.count {
            let gap = calendar.dateComponents([.day], from: sorted[index - 1], to: sorted[index]).day ?? 0
            run = gap == 1 ? run + 1 : 1
            longest = max(longest, run)
        }

        // A streak is still alive if the last session was today or yesterday.
        let today = calendar.startOfDay(for: .now)
        let sinceLast = calendar.dateComponents([.day], from: sorted[sorted.count - 1], to: today).day ?? 0
        let current = sinceLast <= 1 ? run : 0
        return (longest, current)
    }

    private static func streaks(_ sessions: [WorkoutSession]) -> [Achievement] {
        let (longest, _) = streakLengths(sessions)

        return (1...10).map { days in
            Achievement(
                id: "streak-\(days)",
                family: .streak,
                title: days == 1 ? "First day" : "\(days) days in a row",
                detail: days == 1
                    ? "Log your first workout"
                    : "Train \(days) calendar days back to back",
                symbolName: days == 1 ? "flag.fill" : "flame.fill",
                isEarned: longest >= days,
                progress: min(1, Double(longest) / Double(days))
            )
        }
    }

    // MARK: - Longest session

    private static func endurance(_ sessions: [WorkoutSession]) -> [Achievement] {
        let longest = sessions.map(\.duration).max() ?? 0

        return [45, 60, 90, 120].map { minutes in
            let target = TimeInterval(minutes * 60)
            return Achievement(
                id: "long-\(minutes)",
                family: .endurance,
                title: "\(minutes) minutes under the bar",
                detail: "One session lasting \(minutes) minutes",
                symbolName: "hourglass",
                isEarned: longest >= target,
                progress: min(1, longest / target)
            )
        }
    }

    // MARK: - Progressions in a row

    /// Weight increases with no decrease between them, across the whole log.
    static func progressionRun(_ records: [ChangeRecord]) -> Int {
        let weightChanges = records
            .filter { $0.field == .weight }
            .sorted { $0.date < $1.date }

        var longest = 0
        var run = 0
        for record in weightChanges {
            switch record.direction {
            case .up:
                run += 1
                longest = max(longest, run)
            case .down:
                run = 0
            case .neutral:
                break
            }
        }
        return longest
    }

    private static func progression(_ records: [ChangeRecord]) -> [Achievement] {
        let longest = progressionRun(records)

        return [3, 5, 10, 20].map { count in
            Achievement(
                id: "progress-\(count)",
                family: .progression,
                title: "\(count) increases in a row",
                detail: "Put the weight up \(count) times with no step back",
                symbolName: "chart.line.uptrend.xyaxis",
                isEarned: longest >= count,
                progress: min(1, Double(longest) / Double(count))
            )
        }
    }

    // MARK: - Volume

    private static func volume(_ sessions: [WorkoutSession]) -> [Achievement] {
        let best = sessions.map(\.totalVolumeKg).max() ?? 0
        let lifetime = sessions.reduce(0) { $0 + $1.totalVolumeKg }

        var result: [Achievement] = [5_000, 10_000, 20_000].map { target in
            Achievement(
                id: "session-volume-\(target)",
                family: .volume,
                title: "\(target / 1000) tonnes in a session",
                detail: "Move \(target / 1000) tonnes in one workout",
                symbolName: "scalemass.fill",
                isEarned: best >= Double(target),
                progress: min(1, best / Double(target))
            )
        }

        result.append(contentsOf: [100_000, 500_000, 1_000_000].map { target in
            Achievement(
                id: "lifetime-volume-\(target)",
                family: .volume,
                title: "\(target / 1000) tonnes lifted",
                detail: "Move \(target / 1000) tonnes in total",
                symbolName: "mountain.2.fill",
                isEarned: lifetime >= Double(target),
                progress: min(1, lifetime / Double(target))
            )
        })

        return result
    }
}

// MARK: - The medal

struct AchievementMedal: View {
    let achievement: Achievement
    var size: CGFloat = 62

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.isEarned
                          ? achievement.tint.opacity(0.22)
                          : Color.secondary.opacity(0.10))

                if !achievement.isEarned {
                    // The ring is how far along you are, which is more use than
                    // a locked padlock that says only "not yet".
                    Circle()
                        .trim(from: 0, to: achievement.progress)
                        .stroke(achievement.tint.opacity(0.55),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(2)
                }

                Circle()
                    .strokeBorder(achievement.isEarned
                                  ? achievement.tint.opacity(0.6)
                                  : Color.secondary.opacity(0.20), lineWidth: 1)

                Image(systemName: achievement.symbolName)
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(achievement.isEarned ? achievement.tint : Color.secondary.opacity(0.5))
            }
            .frame(width: size, height: size)

            Text(achievement.title)
                .font(.system(size: 10, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(achievement.isEarned ? .primary : .secondary)
                .lineLimit(2)
                .frame(height: 26, alignment: .top)
        }
        .frame(width: size + 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.title). \(achievement.isEarned ? "Earned" : achievement.detail)")
    }
}
