//
//  RestPicker.swift
//  Gym Traker
//
//  Rest used to cycle one tap at a time through a ladder, which meant six taps
//  to get from 45 s to 180 s. This is a horizontal wheel: flick to the value,
//  or nudge it with the arrows. It snaps to 15-second steps, which is as fine
//  as anyone actually rests.
//

import SwiftUI

struct RestPicker: View {
    @Environment(\.colorScheme) private var scheme

    let seconds: Int
    var range: ClosedRange<Int> = 15...300
    var step: Int = 15
    let onChange: (Int) -> Void

    private var values: [Int] {
        Array(stride(from: range.lowerBound, through: range.upperBound, by: step))
    }

    var body: some View {
        VStack(spacing: 12) {
            readout

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(values, id: \.self) { value in
                            tick(value)
                                .id(value)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 6)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
                .frame(height: 46)
                .onAppear {
                    proxy.scrollTo(nearest(seconds), anchor: .center)
                }
                .onChange(of: seconds) { _, value in
                    withAnimation(Theme.Motion.spring) {
                        proxy.scrollTo(nearest(value), anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Pieces

    private var readout: some View {
        HStack(spacing: 14) {
            nudge("minus", enabled: seconds > range.lowerBound) {
                onChange(max(range.lowerBound, seconds - step))
            }

            VStack(spacing: 1) {
                Text(UnitFormatter.clock(seconds))
                    .font(.numberM)
                    .contentTransition(.numericText(value: Double(seconds)))
                Text("rest").overlineStyle()
            }
            .frame(maxWidth: .infinity)

            nudge("plus", enabled: seconds < range.upperBound) {
                onChange(min(range.upperBound, seconds + step))
            }
        }
    }

    private func nudge(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            Haptics.light()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                .contentShape(.rect(cornerRadius: 14))
                .opacity(enabled ? 1 : 0.3)
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
        .accessibilityLabel(systemName == "minus" ? "Less rest" : "More rest")
    }

    private func tick(_ value: Int) -> some View {
        let isSelected = nearest(seconds) == value
        // Minutes get a full label; the 15-second marks in between stay small
        // so the strip reads as a ruler rather than a wall of numbers.
        let isMinute = value % 60 == 0

        return Button {
            Haptics.selection()
            onChange(value)
        } label: {
            Text(isMinute ? "\(value / 60)m" : "\(value % 60)")
                .font(.system(size: isMinute ? 13 : 11, weight: isSelected ? .bold : .semibold))
                .monospacedDigit()
                .foregroundStyle(isSelected ? Color.white : (isMinute ? Color.primary : Color.secondary))
                .frame(width: isMinute ? 46 : 38, height: 38)
                .glassEffect(
                    isSelected ? .regular.tint(Theme.Palette.cyan.opacity(0.75)) : .regular,
                    in: .rect(cornerRadius: 13)
                )
                .contentShape(.rect(cornerRadius: 13))
        }
        .buttonStyle(.pressable)
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
