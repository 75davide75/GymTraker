//
//  TabSwipe.swift
//  Gym Traker
//
//  Swiping anywhere on a screen moves to the neighbouring tab.
//
//  The system tab bar does not offer this, and replacing it with a paging
//  TabView would cost the Liquid Glass bar. So the gesture lives on the content
//  instead: a horizontal drag that only claims the touch once it is clearly
//  sideways, which keeps vertical scrolling untouched.
//
//  Because each screen owns its own aurora, the gradients travel with the
//  screens as they slide.
//

import SwiftUI

extension View {
    /// Moves between tabs on a horizontal swipe from anywhere on the screen.
    func swipeBetweenTabs<Section: Hashable>(
        selection: Binding<Section>,
        order: [Section]
    ) -> some View {
        modifier(TabSwipe(selection: selection, order: order))
    }
}

private struct TabSwipe<Section: Hashable>: ViewModifier {
    @Binding var selection: Section
    let order: [Section]

    /// Far enough that a scroll never trips it, close enough to feel light.
    private let distance: CGFloat = 60
    /// The drag must be at least this much more horizontal than vertical.
    private let bias: CGFloat = 1.6

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > distance, abs(dx) > abs(dy) * bias else { return }
                        move(by: dx < 0 ? 1 : -1)
                    }
            )
    }

    private func move(by offset: Int) {
        guard let current = order.firstIndex(of: selection) else { return }
        let target = current + offset
        guard order.indices.contains(target) else { return }
        Haptics.light()
        withAnimation(Theme.Motion.spring) {
            selection = order[target]
        }
    }
}
