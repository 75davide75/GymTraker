//
//  SessionDashboard.swift
//  Gym Traker
//
//  The readout at the top of a running session.
//
//  A single elapsed clock and a plain progress bar did not say much. A session
//  is two things interleaved — time under the bar and time waiting — and the
//  split is what tells you whether you are training or loitering. So the clock
//  is broken into work and rest, the bar is segmented by set, and the whole
//  thing runs hot: red while you are working, cool while you are resting, like
//  a dashboard in its aggressive setting.
//

import SwiftUI

struct SessionDashboard: View {
    @Environment(\.colorScheme) private var scheme

    let startedAt: Date
    /// Seconds spent resting so far, including the rest running right now.
    let restSeconds: Int
    let completedSets: Int
    let totalSets: Int
    /// Per-exercise set counts, so the bar reads as the session's shape.
    let segments: [SessionSegment]
    let isResting: Bool

    struct SessionSegment: Identifiable, Equatable {
        let id: Int
        let name: String
        let total: Int
        let completed: Int
    }

    private var accent: Color {
        isResting ? Theme.Palette.sportCool : Theme.Palette.sportRed
    }

    var body: some View {
        GlassCard(radius: Theme.Radius.hero, tint: accent.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 16) {
                clocks
                segmentedBar
                footer
            }
        }
        .animation(Theme.Motion.spring, value: isResting)
    }

    // MARK: - Clocks

    private var clocks: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = Int(context.date.timeIntervalSince(startedAt))
            let working = max(0, elapsed - restSeconds)

            HStack(alignment: .firstTextBaseline, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isResting ? "Resting" : "Working").overlineStyle()
                    Text(UnitFormatter.clock(elapsed))
                        .font(.system(size: 40, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accent, accent.opacity(0.72)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    readout("WORK", UnitFormatter.clock(working), Theme.Palette.sportRed)
                    readout("REST", UnitFormatter.clock(restSeconds), Theme.Palette.sportCool)
                }
            }
        }
    }

    private func readout(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }

    // MARK: - Segmented bar

    /// One block per set, grouped by exercise. Reads like a rev counter: you
    /// can see how much of the session is left without counting rows.
    private var segmentedBar: some View {
        HStack(spacing: 5) {
            ForEach(segments) { segment in
                HStack(spacing: 2) {
                    ForEach(0..<max(segment.total, 1), id: \.self) { index in
                        Capsule()
                            .fill(index < segment.completed
                                  ? AnyShapeStyle(LinearGradient(
                                        colors: [Theme.Palette.sportRed, Theme.Palette.sportEmber],
                                        startPoint: .leading, endPoint: .trailing))
                                  : AnyShapeStyle(Theme.Palette.track(scheme)))
                            .frame(height: 7)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(Theme.Motion.spring, value: completedSets)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("\(completedSets) of \(totalSets) sets")
                .font(.numberS)
                .foregroundStyle(.secondary)

            Spacer()

            if totalSets > 0 {
                Text("\(Int((Double(completedSets) / Double(totalSets) * 100).rounded()))%")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accent)
            }
        }
    }
}
