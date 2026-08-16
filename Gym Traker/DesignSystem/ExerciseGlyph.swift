//
//  ExerciseGlyph.swift
//  Gym Traker
//
//  Every exercise diagram in the archive comes out of one generative grammar,
//  so nothing looks hand-drawn or mismatched — and a user-created exercise gets
//  a matching illustration for free.
//
//  A rounded tile tinted by equipment hue holds a composition of primitives
//  keyed to the equipment type. If real illustrations are commissioned later,
//  only this view's body changes.
//

import SwiftUI

struct ExerciseGlyph: View {
    @Environment(\.colorScheme) private var scheme

    let shape: String
    let hue: Int
    var size: CGFloat = 52

    init(shape: String, hue: Int, size: CGFloat = 52) {
        self.shape = shape
        self.hue = hue
        self.size = size
    }

    init(exercise: Exercise, size: CGFloat = 52) {
        self.shape = exercise.glyphShape
        self.hue = exercise.glyphHue
        self.size = size
    }

    private var tint: Color { Theme.Palette.glyph(hue: hue, scheme: scheme) }

    /// Stroke and fill weight scale with the tile so a 40 pt and a 120 pt glyph
    /// read the same.
    private var unit: CGFloat { size / 52 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(scheme == .dark ? 0.32 : 0.26),
                                 tint.opacity(scheme == .dark ? 0.14 : 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                        .strokeBorder(tint.opacity(0.35), lineWidth: 1)
                }

            primitive
                .foregroundStyle(tint)
                .frame(width: size * 0.6, height: size * 0.6)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Primitives

    @ViewBuilder
    private var primitive: some View {
        switch shape {
        case "bar": barbell
        case "dumbbell": dumbbell
        case "frame": frame
        case "cable": cable
        case "ring": ring
        case "bell": kettlebell
        case "wave": wave
        case "arc": arc
        default: barbell
        }
    }

    /// Centre bar with two plates — barbell work.
    private var barbell: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Capsule()
                    .frame(width: w, height: h * 0.11)
                Group {
                    plate(w: w * 0.13, h: h * 0.62)
                        .offset(x: -w * 0.30)
                    plate(w: w * 0.13, h: h * 0.62)
                        .offset(x: w * 0.30)
                    plate(w: w * 0.09, h: h * 0.40)
                        .offset(x: -w * 0.44)
                    plate(w: w * 0.09, h: h * 0.40)
                        .offset(x: w * 0.44)
                }
            }
            .frame(width: w, height: h)
        }
    }

    /// Two spheres and a short bar — dumbbell work.
    private var dumbbell: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Capsule()
                    .frame(width: w * 0.46, height: h * 0.13)
                Circle()
                    .frame(width: w * 0.34, height: w * 0.34)
                    .offset(x: -w * 0.31)
                Circle()
                    .frame(width: w * 0.34, height: w * 0.34)
                    .offset(x: w * 0.31)
            }
            .frame(width: w, height: h)
        }
    }

    /// A rounded rectangle with a bar across it — machine work.
    private var frame: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .strokeBorder(lineWidth: 2 * unit)
                    .frame(width: w * 0.88, height: h * 0.8)
                Capsule()
                    .frame(width: w * 0.62, height: h * 0.11)
                    .offset(y: -h * 0.1)
                Capsule()
                    .frame(width: w * 0.34, height: h * 0.09)
                    .offset(y: h * 0.18)
            }
            .frame(width: w, height: h)
        }
    }

    /// Pulley, line and plate — cable work.
    private var cable: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle()
                    .strokeBorder(lineWidth: 2 * unit)
                    .frame(width: w * 0.24, height: w * 0.24)
                    .offset(y: -h * 0.36)
                Capsule()
                    .frame(width: w * 0.07, height: h * 0.44)
                    .offset(y: h * 0.02)
                plate(w: w * 0.56, h: h * 0.16)
                    .offset(y: h * 0.34)
            }
            .frame(width: w, height: h)
        }
    }

    /// An open ring — bodyweight work.
    private var ring: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle()
                    .strokeBorder(lineWidth: 2.4 * unit)
                    .frame(width: w * 0.82, height: w * 0.82)
                Circle()
                    .frame(width: w * 0.2, height: w * 0.2)
            }
            .frame(width: w, height: h)
        }
    }

    /// A weighted ball with a handle — kettlebell work.
    private var kettlebell: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle()
                    .frame(width: w * 0.68, height: w * 0.68)
                    .offset(y: h * 0.14)
                Arc(start: .degrees(200), end: .degrees(340))
                    .stroke(style: StrokeStyle(lineWidth: 2.6 * unit, lineCap: .round))
                    .frame(width: w * 0.42, height: w * 0.42)
                    .offset(y: -h * 0.22)
            }
            .frame(width: w, height: h)
        }
    }

    /// Stacked bars of varying width — cardio.
    private var wave: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            VStack(spacing: h * 0.12) {
                Capsule().frame(width: w, height: h * 0.14)
                Capsule().frame(width: w * 0.7, height: h * 0.14)
                Capsule().frame(width: w * 0.86, height: h * 0.14)
            }
            .frame(width: w, height: h, alignment: .center)
        }
    }

    /// A half circle over a dot — mobility.
    private var arc: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Arc(start: .degrees(180), end: .degrees(360))
                    .stroke(style: StrokeStyle(lineWidth: 2.6 * unit, lineCap: .round))
                    .frame(width: w * 0.88, height: w * 0.88)
                    .offset(y: h * 0.12)
                Circle()
                    .frame(width: w * 0.16, height: w * 0.16)
                    .offset(y: h * 0.26)
            }
            .frame(width: w, height: h)
        }
    }

    private func plate(w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: w * 0.35, style: .continuous)
            .frame(width: w, height: h)
    }
}

/// A stroked arc between two angles, measured clockwise from three o'clock.
private struct Arc: Shape {
    let start: Angle
    let end: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: start,
            endAngle: end,
            clockwise: false
        )
        return path
    }
}

#Preview("Every glyph shape") {
    let shapes = ["bar", "dumbbell", "frame", "cable", "ring", "bell", "wave", "arc"]
    let hues = [268, 200, 260, 150, 40, 20, 330, 100]

    return ZStack {
        AuroraBackground()
        VStack(spacing: 24) {
            ForEach(0..<2) { row in
                HStack(spacing: 18) {
                    ForEach(0..<4) { column in
                        let index = row * 4 + column
                        VStack(spacing: 8) {
                            ExerciseGlyph(shape: shapes[index], hue: hues[index], size: 64)
                            Text(shapes[index]).font(.captionM).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
