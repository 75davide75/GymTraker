//
//  AuroraBackground.swift
//  Gym Traker
//
//  Two radial gradient blooms drifting behind everything, so the glass has
//  something worth refracting. Driven by one repeating animation rather than a
//  per-frame timeline — a 34 pt blur redrawn every frame is not free.
//

import SwiftUI

struct AuroraBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        ZStack {
            Theme.Palette.background(scheme)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let size = geometry.size
                let bloom = max(size.width, size.height) * 0.95

                ZStack {
                    bloomCircle(Theme.Palette.violetDeep)
                        .frame(width: bloom, height: bloom)
                        .offset(
                            x: drift ? -size.width * 0.28 : size.width * 0.22,
                            y: drift ? -size.height * 0.22 : -size.height * 0.05
                        )

                    bloomCircle(Theme.Palette.cyan)
                        .frame(width: bloom * 0.85, height: bloom * 0.85)
                        .offset(
                            x: drift ? size.width * 0.30 : -size.width * 0.18,
                            y: drift ? size.height * 0.28 : size.height * 0.42
                        )
                }
                .blur(radius: 34)
                .opacity(scheme == .dark ? 0.85 : 0.5)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 17).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func bloomCircle(_ color: Color) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(scheme == .dark ? 0.55 : 0.42), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 260
                )
            )
    }
}

#Preview("Aurora") {
    AuroraBackground()
}
