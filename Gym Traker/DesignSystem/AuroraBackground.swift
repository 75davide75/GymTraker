//
//  AuroraBackground.swift
//  Gym Traker
//
//  Two radial gradient blooms drifting behind everything, so the glass has
//  something worth refracting.
//
//  There is one aurora for the whole app, living behind the tab bar. Each
//  screen declares a variant with `.auroraVariant(_:)`; the root reads it
//  through a preference and eases between variants, so moving between screens
//  shifts the colour and the position of the blooms rather than cutting to a
//  new background.
//

import SwiftUI

/// Where the blooms sit and how they are tinted on a given screen.
struct AuroraVariant: Equatable {
    /// Degrees added to both bloom hues.
    var hueShift: Double
    /// Bloom centres in unit coordinates, before the drift is applied.
    var primary: UnitPoint
    var secondary: UnitPoint
    var intensity: Double

    static let home = AuroraVariant(hueShift: 0, primary: UnitPoint(x: 0.78, y: 0.08),
                                    secondary: UnitPoint(x: 0.18, y: 0.86), intensity: 1)
    static let plan = AuroraVariant(hueShift: -18, primary: UnitPoint(x: 0.18, y: 0.14),
                                    secondary: UnitPoint(x: 0.86, y: 0.72), intensity: 0.94)
    static let library = AuroraVariant(hueShift: 22, primary: UnitPoint(x: 0.88, y: 0.32),
                                       secondary: UnitPoint(x: 0.10, y: 0.94), intensity: 0.9)
    static let registry = AuroraVariant(hueShift: -34, primary: UnitPoint(x: 0.30, y: 0.06),
                                        secondary: UnitPoint(x: 0.92, y: 0.58), intensity: 0.88)
    static let profile = AuroraVariant(hueShift: 42, primary: UnitPoint(x: 0.62, y: 0.10),
                                       secondary: UnitPoint(x: 0.14, y: 0.78), intensity: 1.05)
    static let session = AuroraVariant(hueShift: 8, primary: UnitPoint(x: 0.50, y: -0.04),
                                       secondary: UnitPoint(x: 0.50, y: 1.02), intensity: 1.15)
}

// MARK: - Shared state

/// The variant currently in force, shared by every screen.
///
/// A single aurora behind the tab bar would be tidier, but the tab container
/// paints an opaque background over anything behind it. So each screen draws
/// its own aurora and they all read this one value: arriving on a screen eases
/// the blooms from wherever they were to where that screen wants them.
@Observable
final class AuroraState {
    var variant: AuroraVariant = .home

    func move(to variant: AuroraVariant) {
        guard self.variant != variant else { return }
        withAnimation(.smooth(duration: 0.85)) { self.variant = variant }
    }
}

private struct AuroraStateKey: EnvironmentKey {
    static let defaultValue = AuroraState()
}

extension EnvironmentValues {
    var auroraState: AuroraState {
        get { self[AuroraStateKey.self] }
        set { self[AuroraStateKey.self] = newValue }
    }
}

extension View {
    /// Declares which aurora this screen wants, and eases into it on arrival.
    func auroraVariant(_ variant: AuroraVariant) -> some View {
        modifier(AuroraVariantModifier(variant: variant))
    }
}

private struct AuroraVariantModifier: ViewModifier {
    @Environment(\.auroraState) private var state
    let variant: AuroraVariant

    func body(content: Content) -> some View {
        content
            .background(AuroraBackground(variant: state.variant).ignoresSafeArea())
            .onAppear { state.move(to: variant) }
    }
}

// MARK: - The background

struct AuroraBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var variant: AuroraVariant = .home

    var body: some View {
        ZStack {
            Theme.Palette.background(scheme)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let size = geometry.size
                let bloom = max(size.width, size.height) * 0.95
                let sway = size.width * 0.09

                ZStack {
                    bloomCircle(Theme.Palette.violetDeep)
                        .frame(width: bloom, height: bloom)
                        .position(
                            x: variant.primary.x * size.width + (drift ? sway : -sway),
                            y: variant.primary.y * size.height + (drift ? -sway * 0.7 : sway * 0.7)
                        )

                    bloomCircle(Theme.Palette.cyan)
                        .frame(width: bloom * 0.85, height: bloom * 0.85)
                        .position(
                            x: variant.secondary.x * size.width + (drift ? -sway : sway),
                            y: variant.secondary.y * size.height + (drift ? sway * 0.7 : -sway * 0.7)
                        )
                }
                .blur(radius: 34)
                .opacity((scheme == .dark ? 0.85 : 0.5) * variant.intensity)
                .hueRotation(.degrees(variant.hueShift))
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        // Moving between screens eases the blooms across rather than cutting.
        .animation(.smooth(duration: 0.85), value: variant)
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
