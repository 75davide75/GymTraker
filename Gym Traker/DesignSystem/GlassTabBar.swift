//
//  GlassTabBar.swift
//  Gym Traker
//
//  The bar that goes with the paging content.
//
//  The system tab bar cannot page, and bolting a drag gesture onto it went
//  wrong twice: as a simultaneous gesture it stole horizontal scrolls, and as a
//  plain one it delayed every tap in the app. A paging scroll view has neither
//  problem — UIKit already knows how to arbitrate between nested scrolls — so
//  the bar is drawn here instead, on the same glass as everything else.
//

import SwiftUI

struct GlassTabBar<Section: Hashable & Identifiable>: View {
    @Environment(\.colorScheme) private var scheme

    struct Item: Identifiable {
        let section: Section
        let title: String
        let symbol: String
        var id: Section.ID { section.id }
    }

    @Binding var selection: Section
    let items: [Item]
    /// Collapses to icons alone while the screen is being scrolled down, the
    /// way the system bar does, so the list gets the room.
    var isCompact: Bool = false

    var body: some View {
        // One GlassEffectContainer so the pills and the bar merge into a
        // single piece of glass rather than stacking two sheets of it.
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(items) { item in
                    button(item)
                }
            }
            .padding(isCompact ? 4 : 6)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .overlay {
            Capsule().strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
        }
        .shadow(color: .black.opacity(scheme == .dark ? 0.5 : 0.16), radius: 18, y: 8)
        .padding(.horizontal, isCompact ? 78 : 16)
        .padding(.bottom, 6)
        .animation(.snappy(duration: 0.32, extraBounce: 0.04), value: isCompact)
    }

    private func button(_ item: Item) -> some View {
        let isSelected = item.section == selection

        return Button {
            guard !isSelected else { return }
            Haptics.play(.selection)
            withAnimation(.snappy(duration: 0.35, extraBounce: 0.05)) {
                selection = item.section
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: isCompact ? 18 : 17, weight: .semibold))
                    .symbolVariant(isSelected ? .fill : .none)
                if !isCompact {
                    Text(item.title)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .foregroundStyle(isSelected ? Theme.Palette.violet : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompact ? 9 : 7)
            .background {
                if isSelected {
                    Capsule().fill(Theme.Palette.violet.opacity(0.18))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.pressableSilent)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
