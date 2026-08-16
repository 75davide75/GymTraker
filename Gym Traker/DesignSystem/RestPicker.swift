//
//  RestPicker.swift
//  Gym Traker
//
//  Rest has now been through three shapes. It started as a pill that cycled one
//  value per tap — six taps to get from 45 s to 180 s. Then a horizontal ruler,
//  which was fiddly to land on a value. This is the third: the system wheel
//  everyone already knows from the Clock app, with one-tap shortcuts above it
//  for the values people actually use.
//

import SwiftUI

struct RestPicker: View {
    let seconds: Int
    var range: ClosedRange<Int> = 15...300
    var step: Int = 15
    /// The values worth a single tap.
    var presets: [Int] = [45, 60, 90, 120, 180]
    let onChange: (Int) -> Void

    private var values: [Int] {
        Array(stride(from: range.lowerBound, through: range.upperBound, by: step))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                // Zero means no timer at all, for anyone who rests by feel.
                GlassChip(title: "Off", isSelected: seconds <= 0, tint: Theme.Palette.decrease) {
                    onChange(0)
                }
                ForEach(presets, id: \.self) { value in
                    GlassChip(
                        title: UnitFormatter.rest(value),
                        isSelected: seconds == value,
                        tint: Theme.Palette.cyan
                    ) {
                        onChange(value)
                    }
                }
                Spacer(minLength: 0)
            }

            if seconds <= 0 {
                Text("No rest timer on this exercise — start the next set when you are ready.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 110)
            } else {
            Picker("Rest between sets", selection: Binding(
                get: { nearest(seconds) },
                set: { newValue in
                    guard newValue != seconds else { return }
                    Haptics.selection()
                    onChange(newValue)
                }
            )) {
                ForEach(values, id: \.self) { value in
                    Text(UnitFormatter.clock(value))
                        .font(.numberM)
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 110)
            .clipped()
            }
        }
    }

    private func nearest(_ value: Int) -> Int {
        values.min { abs($0 - value) < abs($1 - value) } ?? range.lowerBound
    }
}

#Preview("Rest picker") {
    struct Harness: View {
        @State private var seconds = 90
        var body: some View {
            ZStack {
                AuroraBackground()
                GlassSection(title: "Rest between sets") {
                    RestPicker(seconds: seconds) { seconds = $0 }
                }
                .padding()
            }
        }
    }
    return Harness()
}
