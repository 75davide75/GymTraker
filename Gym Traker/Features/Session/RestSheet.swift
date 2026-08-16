//
//  RestSheet.swift
//  Gym Traker
//
//  Adjusting rest mid-set should take one gesture, not six taps. A short sheet
//  with the wheel plus the handful of values people actually use.
//

import SwiftUI

struct RestSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: PlanItem
    let onChange: (Int) -> Void

    /// The values worth one tap: short accessory rest through heavy-single rest.
    private let presets = [45, 60, 90, 120, 180]

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 20) {
                VStack(spacing: 3) {
                    Text(item.exerciseName)
                        .font(.titleL)
                        .lineLimit(1)
                    Text("Rest between sets").overlineStyle()
                }
                .padding(.top, 24)

                GlassCard(radius: Theme.Radius.hero) {
                    RestPicker(seconds: item.restSeconds) { onChange($0) }
                }

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { value in
                        GlassChip(
                            title: UnitFormatter.rest(value),
                            isSelected: item.restSeconds == value,
                            tint: Theme.Palette.cyan
                        ) {
                            onChange(value)
                        }
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.bodyM)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }
}
