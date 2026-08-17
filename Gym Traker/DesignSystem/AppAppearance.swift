//
//  AppAppearance.swift
//  Gym Traker
//
//  Light or dark, everywhere, including the screens that are presented rather
//  than pushed.
//
//  `preferredColorScheme` set at the root reaches everything inside that root's
//  hierarchy, and a sheet is not inside it — it is presented in its own. So
//  switching to light left Settings dark until it was closed and reopened,
//  which is where the setting lives, so it was the one screen guaranteed to be
//  wrong at the moment the choice was made.
//

import SwiftUI
import SwiftData

extension View {
    /// Applies the profile's chosen appearance. Needed on the root of anything
    /// presented — sheets, covers — not on pushed screens.
    func appAppearance() -> some View {
        modifier(AppAppearanceModifier())
    }
}

private struct AppAppearanceModifier: ViewModifier {
    @Query private var profiles: [UserProfile]

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(profiles.first?.appearance.colorScheme ?? .dark)
            .tint(Theme.Palette.violet)
    }
}
