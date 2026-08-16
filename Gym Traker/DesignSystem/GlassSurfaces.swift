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

/// Every tappable glass surface scales to 0.98 on press.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.98
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
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
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : Theme.Motion.entryOffset)
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
