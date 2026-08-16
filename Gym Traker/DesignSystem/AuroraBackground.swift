//
//  AuroraBackground.swift
//  Gym Traker
//
//  Two radial gradient blooms behind everything, so the glass has something
//  worth refracting.
//
//  Each screen declares its own variant with `.auroraVariant(_:)` and owns the
//  background outright. Screens differ in bloom position, hue and intensity,
//  so moving between them carries the gradients along with the transition.
//

import SwiftUI

/// Where the blooms sit and how they are tinted on a given screen.
struct AuroraVariant: Equatable {
    /// Degrees added to both bloom hues. Fine for nudging the house palette
    /// along; useless for landing on a specific colour, since rotating two
    /// different hues by the same amount sends them to two different places.
    /// When a screen needs particular colours, name them instead.
    var hueShift: Double
    /// Overrides the bloom colours outright.
    var primaryColor: Color?
    var secondaryColor: Color?
    /// Bloom centres in unit coordinates, before the drift is applied.
    var primary: UnitPoint
    var secondary: UnitPoint
    var intensity: Double

    static let home = AuroraVariant(hueShift: 0, primaryColor: nil, secondaryColor: nil, primary: UnitPoint(x: 0.78, y: 0.08),
                                    secondary: UnitPoint(x: 0.18, y: 0.86), intensity: 1)
    static let plan = AuroraVariant(hueShift: -18, primaryColor: nil, secondaryColor: nil, primary: UnitPoint(x: 0.18, y: 0.14),
                                    secondary: UnitPoint(x: 0.86, y: 0.72), intensity: 0.94)
    static let library = AuroraVariant(hueShift: 22, primaryColor: nil, secondaryColor: nil, primary: UnitPoint(x: 0.88, y: 0.32),
                                       secondary: UnitPoint(x: 0.10, y: 0.94), intensity: 0.9)
    static let registry = AuroraVariant(hueShift: -34, primaryColor: nil, secondaryColor: nil, primary: UnitPoint(x: 0.30, y: 0.06),
                                        secondary: UnitPoint(x: 0.92, y: 0.58), intensity: 0.88)
    static let profile = AuroraVariant(hueShift: 42, primaryColor: nil, secondaryColor: nil, primary: UnitPoint(x: 0.62, y: 0.10),
                                       secondary: UnitPoint(x: 0.14, y: 0.78), intensity: 1.05)
    /// Sport mode. Rotating the house hues landed on green and yellow, so the
    /// session names its colours: red overhead, ember below.
    static let session = AuroraVariant(
        hueShift: 0,
        primaryColor: Theme.Palette.sportRed,
        secondaryColor: Theme.Palette.sportEmber,
        primary: UnitPoint(x: 0.16, y: 0.02),
        secondary: UnitPoint(x: 0.86, y: 0.96),
        intensity: 1.15
    )
}

// MARK: - Attaching a variant

extension View {
    /// Puts this screen's aurora behind it.
    ///
    /// This used to route every screen's variant through one shared
    /// `@Observable` object so the blooms could morph between screens. That
    /// object was observed by every screen at once: arriving somewhere new
    /// invalidated all of them, each re-rendering a full-screen blurred
    /// background mid-transition, and a pushed screen would present its title
    /// and never its content — the app looked frozen.
    ///
    /// Each screen now owns a plain value. Nothing is shared, nothing else
    /// redraws, and the gradients still travel between screens because the
    /// screens themselves slide.
    func auroraVariant(_ variant: AuroraVariant) -> some View {
        background(AuroraBackground(variant: variant).ignoresSafeArea())
    }
}

// MARK: - The background

struct AuroraBackground: View {
    @Environment(\.colorScheme) private var scheme

    var variant: AuroraVariant = .home

    var body: some View {
        ZStack {
            Theme.Palette.background(scheme)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let size = geometry.size
                let bloom = max(size.width, size.height) * 0.95

                ZStack {
                    bloomCircle(variant.primaryColor ?? Theme.Palette.violetDeep)
                        .frame(width: bloom, height: bloom)
                        .position(
                            x: variant.primary.x * size.width,
                            y: variant.primary.y * size.height
                        )

                    bloomCircle(variant.secondaryColor ?? Theme.Palette.cyan)
                        .frame(width: bloom * 0.85, height: bloom * 0.85)
                        .position(
                            x: variant.secondary.x * size.width,
                            y: variant.secondary.y * size.height
                        )
                }
                .blur(radius: 34)
                .opacity((scheme == .dark ? 0.85 : 0.5) * variant.intensity)
                .hueRotation(.degrees(variant.hueShift))
                // Rasterise the blurred blooms once instead of re-blurring
                // them on every frame the glass above asks for a redraw.
                .drawingGroup()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        // The blooms move only when the screen changes.
        //
        // They used to drift on a permanent `repeatForever` loop. With one
        // aurora per screen, pushing a screen left two of them animating at
        // once, and the display link never stopped re-rendering the glass on
        // top — the app never went idle and felt frozen. Motion now happens
        // when it means something: arriving somewhere new.
        .animation(.smooth(duration: 0.85), value: variant)
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
