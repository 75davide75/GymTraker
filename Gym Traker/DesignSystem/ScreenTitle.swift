//
//  ScreenTitle.swift
//  Gym Traker
//
//  The large title at the top of a section.
//
//  The system title sits on its own inset, which did not line up with the
//  screen's content margin — the heading read as pushed out to the edge while
//  everything under it started further in. Inside a paging scroll it could also
//  be clipped. Drawing it here keeps one margin for the whole screen.
//

import SwiftUI

struct ScreenTitle<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

extension ScreenTitle where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
    }
}
