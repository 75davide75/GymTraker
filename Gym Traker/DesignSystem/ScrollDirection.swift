//
//  ScrollDirection.swift
//  Gym Traker
//
//  Reports whether a screen is being scrolled down, so the tab bar can shrink
//  out of the way and come back when you scroll up — the behaviour the system
//  bar had before it was replaced.
//

import SwiftUI

struct ScrollDirectionKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Publishes "the user is scrolling down" up the view tree.
    func reportsScrollDirection() -> some View {
        modifier(ScrollDirectionReporter())
    }
}

private struct ScrollDirectionReporter: ViewModifier {
    @State private var lastOffset: CGFloat = 0
    @State private var isScrollingDown = false

    /// Ignores tiny movements so the bar does not flicker while a finger rests
    /// on the screen.
    private let threshold: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, offset in
                let delta = offset - lastOffset
                guard abs(delta) > threshold else { return }
                lastOffset = offset

                // Near the top the bar is always full: there is nothing to
                // make room for yet.
                let shouldCompact = offset > 40 && delta > 0
                guard shouldCompact != isScrollingDown else { return }
                isScrollingDown = shouldCompact
            }
            .preference(key: ScrollDirectionKey.self, value: isScrollingDown)
    }
}
