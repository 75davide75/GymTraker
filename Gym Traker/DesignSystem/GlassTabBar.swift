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

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                button(item)
            }
        }
        .padding(5)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.bar))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.bar, style: .continuous)
                .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
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
                    .font(.system(size: 17, weight: .semibold))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(item.title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Theme.Palette.violet : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                        .fill(Theme.Palette.violet.opacity(0.16))
                }
            }
            .contentShape(.rect(cornerRadius: Theme.Radius.chip))
        }
        .buttonStyle(.pressableSilent)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
