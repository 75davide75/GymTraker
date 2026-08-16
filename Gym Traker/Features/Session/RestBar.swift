//
//  RestBar.swift
//  Gym Traker
//
//  The floating rest bar. Sits above the tab bar, shows a circular countdown
//  and what is coming next.
//

import SwiftUI

struct RestBar: View {
    @Environment(\.colorScheme) private var scheme
    let timer: RestTimer
    let onSkip: () -> Void

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            countdownRing

            VStack(alignment: .leading, spacing: 2) {
                Text("Resting")
                    .font(.overline)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Palette.cyan)
                Text("Next · \(timer.exerciseName) set \(timer.nextSetNumber)")
                    .font(.bodyM)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button("Skip") {
                Haptics.light()
                onSkip()
            }
            .font(.bodyM)
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.bar))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.bar, style: .continuous)
                .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(Theme.Palette.track(scheme), lineWidth: 4)

            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    timer.isFinishing ? Theme.Palette.decrease : Theme.Palette.cyan,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                // The ring drains linearly; anything springy reads as wrong here.
                .animation(.linear(duration: 0.25), value: timer.progress)

            Text("\(timer.remainingSeconds)")
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
        }
        .frame(width: 46, height: 46)
        .scaleEffect(pulse ? 1.07 : 1)
        .onChange(of: timer.isFinishing) { _, finishing in
            guard finishing else { pulse = false; return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
