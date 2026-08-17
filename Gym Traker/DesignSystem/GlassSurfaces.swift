//
//  GlassSurfaces.swift
//  Gym Traker
//
//  Wrappers around the system Liquid Glass so every surface in the app picks up
//  the same hairline stroke and top highlight. If Apple changes the material,
//  this is the only file that needs to notice.
//

import SwiftUI

// MARK: - Card

/// The standard glass card. Radius defaults to 26 pt per design/SPEC.md §4.
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme

    var radius: CGFloat = Theme.Radius.card
    var padding: CGFloat = Theme.Spacing.cardPadding
    var tint: Color?
    /// Fills the available height, so cards sitting side by side in an HStack
    /// match instead of each shrinking to its own content.
    var stretchVertically: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: stretchVertically ? .infinity : nil, alignment: .top)
            .glassEffect(
                tint.map { .regular.tint($0.opacity(0.28)) } ?? .regular,
                in: .rect(cornerRadius: radius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                // Inset highlight: a thin bright line just below the top edge.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .trim(from: 0.06, to: 0.44)
                    .stroke(
                        LinearGradient(
                            colors: [.clear, Theme.Palette.topHighlight(scheme).opacity(0.55), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(scheme == .dark ? .plusLighter : .normal)
                    .allowsHitTesting(false)
            }
    }
}

// MARK: - Section

/// A titled block: uppercase overline plus a card.
struct GlassSection<Content: View>: View {
    let title: String
    var trailing: AnyView?
    var radius: CGFloat = Theme.Radius.card
    var padding: CGFloat = Theme.Spacing.cardPadding
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).overlineStyle()
                Spacer()
                trailing
            }
            .padding(.horizontal, 4)

            GlassCard(radius: radius, padding: padding) { content }
        }
    }
}

// MARK: - Press feedback

/// Press feedback for any tappable surface.
///
/// The spec asked for a 0.98 scale, which is right for a big card and
/// invisible on a 46 pt stepper — under a point of movement. Scale is now
/// chosen for the control's size, a dip in opacity backs it up, and the haptic
/// fires on the way *down* rather than when the action runs, which is what
/// makes a button feel like a button.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var haptic: Haptics.Style? = .press

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.62), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                guard isPressed, let haptic else { return }
                haptic.fire()
            }
    }
}

extension ButtonStyle where Self == PressableStyle {
    /// Cards, rows and chips.
    static var pressable: PressableStyle { PressableStyle() }

    /// Small controls, where a 3 % scale would not register.
    static var pressableControl: PressableStyle {
        PressableStyle(scale: 0.88, haptic: .step)
    }

    /// Surfaces that already fire their own haptic when the action lands.
    static var pressableSilent: PressableStyle {
        PressableStyle(haptic: nil)
    }
}

// MARK: - Chips

/// Filter and selection chip. Selected chips take a tinted glass.
struct GlassChip: View {
    let title: String
    var isSelected: Bool
    var tint: Color = Theme.Palette.violet
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.captionM)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .glassEffect(
                    isSelected ? .regular.tint(tint.opacity(0.45)) : .regular,
                    in: .rect(cornerRadius: Theme.Radius.chip)
                )
        }
        .buttonStyle(.pressable)
        .animation(Theme.Motion.snappy, value: isSelected)
    }
}

// MARK: - Progress

/// The thin progress bar used by tier cards, session headers and volume rows.
struct GlassProgressBar: View {
    @Environment(\.colorScheme) private var scheme
    var value: Double            // 0…1
    var tint: Color = Theme.Palette.violet
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.track(scheme))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(1, value)) * geometry.size.width)
            }
        }
        .frame(height: height)
        .animation(Theme.Motion.spring, value: value)
    }
}

// MARK: - Entry motion

/// Screen entry: 14 pt upward offset plus opacity, staggered for list children.
///
/// Only for the fixed set of cards that make up a screen. Rows in a lazy list
/// must never use it: they appear as you scroll, and a 0.4 s fade on each one
/// cannot keep up with a flick.
struct EntryTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            // Opacity only. This used to lift each card fourteen points as it
            // faded in, so arriving anywhere was a small stampede of things
            // sliding into place — and with five sections that is five
            // stampedes. Fading in is a change of state; sliding in is an
            // event, and arriving on a screen is not an event.
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard !reduceMotion else { shown = true; return }
                withAnimation(
                    .easeOut(duration: Theme.Motion.entryDuration)
                    .delay(Theme.Motion.stagger(index))
                ) { shown = true }
            }
    }
}

extension View {
    /// Applies the staggered entry animation. Pass the child's index in a list.
    func entryTransition(_ index: Int = 0) -> some View {
        modifier(EntryTransition(index: index))
    }

    /// Screen scaffold: aurora behind, standard margins, large title.
    func auroraScreen() -> some View {
        self.background(AuroraBackground())
            .scrollContentBackground(.hidden)
    }
}
