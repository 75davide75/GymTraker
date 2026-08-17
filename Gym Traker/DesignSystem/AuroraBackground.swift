//
//  AuroraBackground.swift
//  Gym Traker
//
//  Two radial gradient blooms behind everything, so the glass has something
//  worth refracting.
//
//  Screens name the one they want with `.auroraVariant(_:)`. Arriving somewhere
//  new does not cut to a new background: the blooms travel there from wherever
//  the last screen left them, which is the whole point of `ChromeState` below.
//

import SwiftUI

/// Where the blooms sit and how they are tinted on a given screen.
struct AuroraVariant: Equatable {
    /// The two bloom colours.
    var primaryColor: Color
    var secondaryColor: Color
    /// Bloom centres, in unit coordinates.
    var primary: UnitPoint
    var secondary: UnitPoint
    var intensity: Double

    // Five screens, five shades of one light.
    //
    // Two things were wrong before. The colours came from rotating one pair of
    // hues by a per-screen number of degrees, which is not a way to choose a
    // colour — rotating violet and cyan by the same amount sends them to two
    // unrelated places, and the registry came out green while sport mode came
    // out yellow. And the blooms were parked in a different corner on every
    // screen, so moving between two of them swept a bright patch right across
    // the display: a movement, not a change.
    //
    // The blooms sit in nearly the same place everywhere and differ in colour,
    // walking one arc across the five sections: blue-violet at Home, through
    // indigo and teal, to green and amber by the last screen. Going next door
    // is a shift in the light rather than a patch of it sweeping past. Sport
    // mode is the deliberate exception, and it announces itself.

    private static let indigo = Color(red: 0.36, green: 0.44, blue: 0.92)
    private static let teal = Color(red: 0.24, green: 0.62, blue: 0.86)
    private static let seagreen = Color(red: 0.18, green: 0.71, blue: 0.59)
    private static let amber = Color(red: 0.94, green: 0.63, blue: 0.24)

    static let home = AuroraVariant(
        primaryColor: Theme.Palette.violetDeep, secondaryColor: Theme.Palette.cyan,
        primary: UnitPoint(x: 0.76, y: 0.06), secondary: UnitPoint(x: 0.18, y: 0.86),
        intensity: 1
    )
    static let plan = AuroraVariant(
        primaryColor: indigo, secondaryColor: Theme.Palette.violetDeep,
        primary: UnitPoint(x: 0.72, y: 0.10), secondary: UnitPoint(x: 0.22, y: 0.84),
        intensity: 0.97
    )
    static let library = AuroraVariant(
        primaryColor: teal, secondaryColor: indigo,
        primary: UnitPoint(x: 0.80, y: 0.09), secondary: UnitPoint(x: 0.16, y: 0.88),
        intensity: 0.95
    )
    static let registry = AuroraVariant(
        primaryColor: seagreen, secondaryColor: teal,
        primary: UnitPoint(x: 0.70, y: 0.07), secondary: UnitPoint(x: 0.24, y: 0.82),
        intensity: 0.93
    )
    static let profile = AuroraVariant(
        primaryColor: amber, secondaryColor: seagreen,
        primary: UnitPoint(x: 0.78, y: 0.11), secondary: UnitPoint(x: 0.20, y: 0.87),
        intensity: 0.98
    )

    /// Sport mode: red overhead, ember below.
    static let session = AuroraVariant(
        primaryColor: Theme.Palette.sportRed, secondaryColor: Theme.Palette.sportEmber,
        primary: UnitPoint(x: 0.16, y: 0.02), secondary: UnitPoint(x: 0.86, y: 0.96),
        intensity: 1.15
    )
}

// MARK: - Naming a variant

/// Where the light is, and where it was a moment ago.
///
/// The second half is the point. Three arrangements of a genuinely single
/// aurora were built and measured, and none of them can work under a system
/// tab view: one layer per screen changes colour instantly, because a screen
/// arriving for the first time renders its background from scratch and a view
/// with no previous value has nothing to animate from; and one layer beneath
/// the tab view is simply never visible, because the tab view paints its own
/// container over anything behind it.
///
/// So each screen does own its layer — but the layer is told where the light
/// was, and moves it from there. What the eye gets is the same thing a single
/// travelling layer would have given it.
///
/// Only `AuroraLayer` reads this. Screens write to it and observe nothing, so
/// writing costs the writer no redraw: the mistake that once made every screen
/// re-render a full-screen blur mid-transition, and looked like a freeze.
@Observable
final class ChromeState {
    private(set) var variant: AuroraVariant = .home
    private(set) var previous: AuroraVariant = .home

    func move(to next: AuroraVariant) {
        guard next != variant else { return }
        previous = variant
        variant = next
    }
}

extension View {
    /// Asks the aurora to move here.
    ///
    /// Handed to the navigation container rather than to `.background`, which
    /// takes the size of the view it is attached to: on a centred empty state
    /// that drew a hard-edged rectangle of colour floating in black, and on a
    /// long list it stopped partway down. A container background is the whole
    /// container by definition, title bar included.
    func auroraVariant(_ variant: AuroraVariant) -> some View {
        modifier(AuroraVariantSetter(variant: variant))
    }
}

private struct AuroraVariantSetter: ViewModifier {
    // Optional so a screen still renders on its own in a preview, where nothing
    // has put a ChromeState in the environment.
    @Environment(ChromeState.self) private var chrome: ChromeState?
    let variant: AuroraVariant

    func body(content: Content) -> some View {
        content
            // On appear rather than in the body: popping back to a screen
            // re-runs onAppear, which is exactly when the aurora should travel
            // back with it.
            .onAppear { chrome?.move(to: variant) }
            .containerBackground(for: .navigation) {
                // Handed the environment explicitly: a container background is
                // hosted outside the normal view hierarchy, so what is injected
                // at the root is not guaranteed to reach it.
                AuroraLayer(fallback: variant)
                    .environment(chrome)
            }
    }
}

/// The aurora, isolated in its own view so that moving the light redraws this
/// and nothing else.
struct AuroraLayer: View {
    @Environment(ChromeState.self) private var chrome: ChromeState?
    /// Used when there is no ChromeState, i.e. in a preview.
    var fallback: AuroraVariant = .home

    @State private var shown: AuroraVariant?

    var body: some View {
        AuroraBackground(variant: shown ?? chrome?.previous ?? fallback)
            .ignoresSafeArea()
            .task(id: chrome?.variant) {
                guard let chrome else {
                    shown = fallback
                    return
                }
                // Put the light back where the last screen left it, without
                // animating — this is the starting point, not a change.
                var immediate = Transaction()
                immediate.disablesAnimations = true
                withTransaction(immediate) { shown = chrome.previous }

                // Then move it, one frame later. Setting both values in the
                // same turn of the run loop collapses them into one state and
                // there is nothing left to interpolate.
                try? await Task.sleep(for: .milliseconds(16))
                // Slow enough to read as the light changing rather than as
                // something being swapped.
                withAnimation(.smooth(duration: 1.1)) { shown = chrome.variant }
            }
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
                    bloomCircle(variant.primaryColor)
                        .frame(width: bloom, height: bloom)
                        .position(
                            x: variant.primary.x * size.width,
                            y: variant.primary.y * size.height
                        )

                    bloomCircle(variant.secondaryColor)
                        .frame(width: bloom * 0.85, height: bloom * 0.85)
                        .position(
                            x: variant.secondary.x * size.width,
                            y: variant.secondary.y * size.height
                        )
                }
                .blur(radius: 34)
                .opacity((scheme == .dark ? 0.85 : 0.5) * variant.intensity)
                // Rasterise the blurred blooms once instead of re-blurring
                // them on every frame the glass above asks for a redraw.
                .drawingGroup()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        // No animation of its own. AuroraLayer drives the move, because only
        // it knows where the light was before this screen asked for it.
        //
        // The blooms also used to drift on a permanent `repeatForever` loop.
        // The display link then never stopped re-rendering the glass above,
        // the app never went idle, and it felt frozen. Motion happens when it
        // means something: arriving somewhere new.
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
