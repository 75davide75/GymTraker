//
//  SessionDetailView.swift
//  Gym Traker
//
//  One workout, with everything known about it.
//
//  Two kinds of session end up here and they know different things. One logged
//  in the app knows every set as performed; one imported from Health knows how
//  long it ran, what it burned and what the heart did, and nothing at all about
//  sets. The screen shows what exists and does not leave placeholders where the
//  other kind's data would have been.
//

import SwiftUI
import SwiftData
import Charts

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthStore.self) private var health

    let session: WorkoutSession

    @State private var heartRateSeries: [HeartRatePoint] = []
    @State private var loadingSeries = false

    struct HeartRatePoint: Identifiable {
        let id = UUID()
        let date: Date
        let bpm: Double
    }

    private var units: Units { Store.units(in: context) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headline.entryTransition(0)
                statGrid.entryTransition(1)
                if session.isImported { heartRateCard.entryTransition(2) }
                if !session.orderedEntries.isEmpty { exerciseCard.entryTransition(3) }
                sourceCard.entryTransition(4)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
        .auroraVariant(.registry)
        .navigationTitle(session.planDayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadHeartRate() }
    }

    // MARK: - Headline

    private var headline: some View {
        GlassCard(radius: Theme.Radius.hero) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.startedAt.formatted(date: .complete, time: .omitted))
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                Text(session.planDayTitle)
                    .font(.titleL)
                Text(timeRange)
                    .font(.bodyS)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var timeRange: String {
        let start = session.startedAt.formatted(date: .omitted, time: .shortened)
        guard let end = session.endedAt else { return start }
        return "\(start) – \(end.formatted(date: .omitted, time: .shortened))"
    }

    // MARK: - Numbers

    /// Only the tiles that have something in them. A workout imported from a
    /// watch has no set count, and a zero there is a lie.
    private var stats: [(label: String, value: String, symbol: String)] {
        var result: [(String, String, String)] = [
            ("Duration", UnitFormatter.clock(Int(session.duration)), "clock")
        ]
        if session.setCount > 0 {
            result.append(("Sets", "\(session.setCount)", "checklist"))
        }
        if session.totalVolumeKg > 0 {
            result.append(("Volume", UnitFormatter.volume(session.totalVolumeKg, in: units), "scalemass"))
        }
        if let energy = session.energyKcal, energy > 0 {
            result.append(("Energy", "\(Int(energy.rounded())) kcal", "flame"))
        }
        if let average = session.averageHeartRate, average > 0 {
            result.append(("Avg HR", "\(Int(average.rounded())) bpm", "heart"))
        }
        if let peak = session.maxHeartRate, peak > 0 {
            result.append(("Peak HR", "\(Int(peak.rounded())) bpm", "waveform.path.ecg"))
        }
        if let distance = session.distanceMeters, distance > 0 {
            result.append(("Distance", distanceText(distance), "figure.walk"))
        }
        if session.orderedEntries.count > 0 {
            result.append(("Exercises", "\(session.orderedEntries.count)", "dumbbell"))
        }
        return result
    }

    private func distanceText(_ meters: Double) -> String {
        meters >= 1000
            ? String(format: "%.2f km", meters / 1000)
            : "\(Int(meters.rounded())) m"
    }

    private var statGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            ForEach(stats, id: \.label) { stat in
                GlassCard(radius: Theme.Radius.row, padding: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: stat.symbol)
                                .font(.system(size: 11, weight: .bold))
                            Text(stat.label).overlineStyle()
                        }
                        .foregroundStyle(.secondary)
                        Text(stat.value)
                            .font(.numberM)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Heart rate

    @ViewBuilder
    private var heartRateCard: some View {
        GlassSection(title: "Heart rate") {
            if loadingSeries {
                HStack { ProgressView().controlSize(.small); Text("Reading from Health…").font(.captionM) }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if heartRateSeries.isEmpty {
                Text("Health has no heart-rate samples for this workout.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(heartRateSeries) { point in
                    AreaMark(x: .value("Time", point.date), y: .value("BPM", point.bpm))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Palette.sportRed.opacity(0.35), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    LineMark(x: .value("Time", point.date), y: .value("BPM", point.bpm))
                        .foregroundStyle(Theme.Palette.sportRed)
                        .interpolationMethod(.monotone)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { AxisGridLine(); AxisValueLabel() }
                }
                .frame(height: 160)
            }
        }
    }

    private func loadHeartRate() async {
        guard session.isImported, let end = session.endedAt, heartRateSeries.isEmpty else { return }
        loadingSeries = true
        defer { loadingSeries = false }
        let samples = await health.heartRateSeries(from: session.startedAt, to: end)
        heartRateSeries = samples.map { HeartRatePoint(date: $0.date, bpm: $0.bpm) }
    }

    // MARK: - What was performed

    private var exerciseCard: some View {
        GlassSection(title: "Exercises") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(session.orderedEntries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.exerciseName).font(.bodyM).lineLimit(1)
                            Spacer(minLength: 6)
                            Text(UnitFormatter.volume(entry.volumeKg, in: units))
                                .font(.system(size: 11, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        }

                        FlowLayout(spacing: 6) {
                            ForEach(Array(entry.sets.enumerated()), id: \.element.id) { _, set in
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
                            }
                        }
                    }
                }
            }
        }
    }

    private var sourceCard: some View {
        GlassSection(title: "Source") {
            HStack(spacing: 10) {
                Image(systemName: session.isImported ? "heart.fill" : "iphone")
                    .foregroundStyle(session.isImported ? Theme.Palette.sportRed : Theme.Palette.violet)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.isImported ? (session.sourceName ?? "Health") : "Logged in Gym Tracker")
                        .font(.bodyM)
                    Text(session.isImported
                         ? "Imported, so there are no set details."
                         : "Every set on this screen is as you performed it.")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
