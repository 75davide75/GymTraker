//
//  ProgressCharts.swift
//  Gym Traker
//
//  How an exercise has moved: load, reps, sets and rest across sessions.
//
//  A single bar chart of the working weight hid most of what changes. Weight
//  going up while reps quietly fall is not progress, and rest creeping longer
//  is worth seeing. Each parameter gets its own trace, on one axis of time.
//

import SwiftUI
import Charts

struct ProgressCharts: View {
    @Environment(\.colorScheme) private var scheme

    let history: [SessionEntry]
    let units: Units

    @State private var metric: Metric = .weight

    enum Metric: String, CaseIterable, Identifiable {
        case weight, reps, sets, rest
        var id: String { rawValue }

        var title: String {
            switch self {
            case .weight: "Weight"
            case .reps: "Reps"
            case .sets: "Sets"
            case .rest: "Rest"
            }
        }

        var symbolName: String {
            switch self {
            case .weight: "scalemass"
            case .reps: "repeat"
            case .sets: "square.stack"
            case .rest: "timer"
            }
        }

        var tint: Color {
            switch self {
            case .weight: Theme.Palette.violet
            case .reps: Theme.Palette.cyan
            case .sets: Theme.Palette.increase
            case .rest: Theme.Palette.sportEmber
            }
        }
    }

    private struct Point: Identifiable {
        let id: Int
        let date: Date
        let value: Double
        let label: String
    }

    // MARK: - Data

    private var points: [Point] {
        history.enumerated().compactMap { index, entry in
            let date = entry.session?.startedAt ?? .now
            let value: Double
            let label: String

            switch metric {
            case .weight:
                value = UnitFormatter.display(entry.topWeightKg, in: units)
                label = UnitFormatter.weight(entry.topWeightKg, in: units)
            case .reps:
                // Total reps performed, which is what actually moved.
                let total = entry.completedSets.reduce(0) { $0 + $1.reps }
                value = Double(total)
                label = "\(total) reps"
            case .sets:
                value = Double(entry.completedSets.count)
                label = "\(entry.completedSets.count) sets"
            case .rest:
                value = Double(entry.restSeconds)
                label = UnitFormatter.rest(entry.restSeconds)
            }

            guard value.isFinite else { return nil }
            return Point(id: index, date: date, value: value, label: label)
        }
    }

    /// First-to-last movement, which is the only number most people want.
    private var change: (delta: Double, direction: ChangeDirection)? {
        guard let first = points.first?.value, let last = points.last?.value, points.count > 1 else { return nil }
        let delta = last - first
        if abs(delta) < 0.001 { return (0, .neutral) }
        return (delta, delta > 0 ? .up : .down)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            picker

            if points.count < 2 {
                Text("Log this exercise twice and the trend appears here.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                summary
                chart
            }
        }
    }

    // MARK: - Pieces

    private var picker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Metric.allCases) { option in
                    GlassChip(title: option.title, isSelected: metric == option, tint: option.tint) {
                        withAnimation(Theme.Motion.spring) { metric = option }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private var summary: some View {
        if let change, let last = points.last {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(last.label)
                    .font(.numberM)
                    .foregroundStyle(metric.tint)

                if change.direction != .neutral {
                    HStack(spacing: 3) {
                        Image(systemName: change.direction.glyph)
                            .font(.system(size: 10, weight: .bold))
                        Text(deltaText(change.delta))
                            .font(.system(size: 12, weight: .bold))
                            .monospacedDigit()
                    }
                    // Rest getting longer is not an improvement, so it is
                    // never painted green.
                    .foregroundStyle(tintForChange(change.direction))
                } else {
                    Text("unchanged")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("over \(points.count) sessions")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func deltaText(_ delta: Double) -> String {
        let magnitude = abs(delta)
        let formatted = magnitude == magnitude.rounded()
            ? String(Int(magnitude.rounded()))
            : String(format: "%.1f", magnitude)
        return metric == .rest ? "\(formatted)s" : formatted
    }

    private func tintForChange(_ direction: ChangeDirection) -> Color {
        if metric == .rest {
            return direction == .up ? Theme.Palette.decrease : Theme.Palette.increase
        }
        return direction == .up ? Theme.Palette.increase : Theme.Palette.decrease
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Session", point.date),
                y: .value(metric.title, point.value)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(
                LinearGradient(
                    colors: [metric.tint.opacity(0.32), metric.tint.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Session", point.date),
                y: .value(metric.title, point.value)
            )
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .foregroundStyle(metric.tint)

            PointMark(
                x: .value("Session", point.date),
                y: .value(metric.title, point.value)
            )
            .symbolSize(point.id == points.last?.id ? 70 : 26)
            .foregroundStyle(metric.tint)
        }
        .chartYScale(domain: .automatic(includesZero: metric != .weight))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Theme.Palette.separator(scheme))
                AxisValueLabel()
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 170)
        .animation(Theme.Motion.spring, value: metric)
    }
}
