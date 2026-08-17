//
//  CardioGlyph.swift
//  Gym Traker
//
//  A mark for the machines, not a drawing of one.
//
//  The archive's line art is a body performing a movement, and a treadmill has
//  no such drawing — a picture of the machine would be a different kind of
//  image, which is the thing the one-style rule exists to prevent. So cardio
//  gets an abstraction instead: a stride of motion arcs over a pulse line,
//  which says "this one is measured in time" without pretending to be anatomy.
//

import SwiftUI

struct CardioGlyph: View {
    var tint: Color
    var size: CGFloat = 52

    var body: some View {
        Canvas { context, canvas in
            let w = canvas.width, h = canvas.height
            let stroke = max(1.6, w * 0.055)

            // Three motion arcs, opening to the right, fading as they trail.
            for (index, scale) in [0.92, 0.66, 0.40].enumerated() {
                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: w * 0.42, y: h * 0.5),
                    radius: w * 0.5 * scale,
                    startAngle: .degrees(-58),
                    endAngle: .degrees(58),
                    clockwise: false
                )
                context.stroke(
                    arc,
                    with: .color(tint.opacity(1 - Double(index) * 0.28)),
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                )
            }

            // A pulse across the middle: two beats, flat either side.
            var pulse = Path()
            let mid = h * 0.5
            pulse.move(to: CGPoint(x: w * 0.10, y: mid))
            pulse.addLine(to: CGPoint(x: w * 0.26, y: mid))
            pulse.addLine(to: CGPoint(x: w * 0.33, y: mid - h * 0.20))
            pulse.addLine(to: CGPoint(x: w * 0.40, y: mid + h * 0.16))
            pulse.addLine(to: CGPoint(x: w * 0.47, y: mid))
            context.stroke(
                pulse,
                with: .color(tint),
                style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Cardio glyph") {
    ZStack {
        Theme.Palette.backgroundDark
        HStack(spacing: 16) {
            CardioGlyph(tint: Theme.Palette.cyan, size: 52)
            CardioGlyph(tint: Theme.Palette.sportEmber, size: 80)
        }
    }
}
