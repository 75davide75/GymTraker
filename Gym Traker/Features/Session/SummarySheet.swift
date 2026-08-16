//
//  SummarySheet.swift
//  Gym Traker
//
//  What the session produced: volume, sets, tier moves, registry entries.
//

import SwiftUI

struct SummarySheet: View {
    @Environment(\.dismiss) private var dismiss

    let summary: SessionSummary
    let units: Units
    let onDone: () -> Void

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Session complete")
                        .font(.displayL)
                        .padding(.top, 20)
                        .entryTransition(0)

                    stats.entryTransition(1)

                    if !summary.tierChanges.isEmpty {
                        tierCard.entryTransition(2)
                    }

                    registryCard.entryTransition(3)

                    Button {
                        dismiss()
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.bodyM)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.glassProminent)
                    .padding(.top, 6)
                    .entryTransition(4)
                }
                .padding(Theme.Spacing.screenMargin)
            }
        }
        .interactiveDismissDisabled()
    }

    private var stats: some View {
        GlassCard(radius: Theme.Radius.hero) {
            HStack(spacing: 0) {
                statColumn("Volume", UnitFormatter.volume(summary.volumeKg, in: units))
                Divider().frame(height: 40).opacity(0.4)
                statColumn("Sets", "\(summary.setCount)")
                Divider().frame(height: 40).opacity(0.4)
                statColumn("Time", UnitFormatter.clock(Int(summary.duration)))
            }
        }
    }

    private func statColumn(_ title: String, _ value: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.numberM)
            Text(title).overlineStyle()
        }
        .frame(maxWidth: .infinity)
    }

    private var tierCard: some View {
        GlassSection(title: "Tier changes") {
            VStack(spacing: 0) {
                ForEach(Array(summary.tierChanges.enumerated()), id: \.element.id) { index, change in
                    HStack(spacing: 10) {
                        Image(systemName: change.promoted ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(change.promoted ? Theme.Palette.increase : Theme.Palette.decrease)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(change.exerciseName).font(.bodyM)
                            Text("\(change.from) → \(change.to)")
                                .font(.captionM)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 9)

                    if index < summary.tierChanges.count - 1 {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private var registryCard: some View {
        GlassSection(title: "Registry") {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Theme.Palette.violet)
                Text(summary.registryCount == 0
                     ? "No parameters changed this session."
                     : "\(summary.registryCount) new \(summary.registryCount == 1 ? "entry" : "entries") logged.")
                    .font(.bodyS)
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Promotion

/// The one celebratory moment in the app. No confetti — just the numbers that
/// earned it.
struct PromotionView: View {
    @Environment(\.dismiss) private var dismiss
    let promotion: Promotion

    @State private var appeared = false

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 22) {
                Spacer()

                Text("New tier").overlineStyle()

                Text(promotion.tierLabel)
                    .font(.system(size: 42, weight: .bold))
                    .multilineTextAlignment(.center)

                GlassCard(radius: Theme.Radius.hero) {
                    VStack(spacing: 8) {
                        Text(promotion.exerciseName)
                            .font(.titleL)
                        Text(promotion.detail)
                            .font(.numberS)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Text("Standards are guidelines, not measurements.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.bodyM)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(Theme.Spacing.screenMargin)
            .scaleEffect(appeared ? 1 : 0.94)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            Haptics.success()
            withAnimation(Theme.Motion.spring) { appeared = true }
        }
    }
}
