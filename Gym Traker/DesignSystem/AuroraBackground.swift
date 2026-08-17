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

    // Every screen names its two colours.
    //
    // They used to be one pair rotated by a per-screen number of degrees, which
    // is not a way to choose a colour: rotating violet and cyan by the same
    // amount sends them to two unrelated places, and the registry came out
    // green while sport mode came out yellow. Naming them keeps the whole app
    // inside one blue-to-magenta arc, and lets the workout step outside it on
    // purpose.

    static let home = AuroraVariant(
        primaryColor: Theme.Palette.violetDeep, secondaryColor: Theme.Palette.cyan,
        primary: UnitPoint(x: 0.78, y: 0.08), secondary: UnitPoint(x: 0.18, y: 0.86),
        intensity: 1
    )
    static let plan = AuroraVariant(
        primaryColor: Theme.Palette.violet, secondaryColor: Theme.Palette.violetDeep,
        primary: UnitPoint(x: 0.18, y: 0.14), secondary: UnitPoint(x: 0.86, y: 0.72),
        intensity: 0.94
    )
    static let library = AuroraVariant(
        primaryColor: Theme.Palette.cyan, secondaryColor: Theme.Palette.violetDeep,
        primary: UnitPoint(x: 0.88, y: 0.32), secondary: UnitPoint(x: 0.10, y: 0.94),
        intensity: 0.9
    )
    static let registry = AuroraVariant(
        primaryColor: Theme.Palette.sportCool, secondaryColor: Theme.Palette.violetDeep,
        primary: UnitPoint(x: 0.30, y: 0.06), secondary: UnitPoint(x: 0.92, y: 0.58),
        intensity: 0.88
    )
    static let profile = AuroraVariant(
        primaryColor: Theme.Palette.violet, secondaryColor: Theme.Palette.sportEmber,
        primary: UnitPoint(x: 0.62, y: 0.10), secondary: UnitPoint(x: 0.14, y: 0.78),
        intensity: 1.02
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
                withAnimation(.smooth(duration: 0.7)) { shown = chrome.variant }
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
