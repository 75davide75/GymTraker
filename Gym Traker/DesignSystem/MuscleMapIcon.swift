//
//  MuscleMapIcon.swift
//  Gym Traker
//
//  The icon every exercise wears in a list.
//
//  A body silhouette with the worked muscle lit in the accent colour, plus a
//  small badge for the equipment. It answers the two questions you actually ask
//  while scanning a list — what does this train, and what do I need for it —
//  and it is drawn from shapes, so it stays crisp at 44 pt and at 120 pt.
//
//  The silhouette turns around for back and glute work: you cannot show a lat
//  on a chest-on figure.
//

import SwiftUI

struct MuscleMapIcon: View {
    @Environment(\.colorScheme) private var scheme

    let muscle: Muscle
    let equipment: Equipment
    var size: CGFloat = 52
    var showsEquipmentBadge: Bool = true

    private var tint: Color { Theme.Palette.glyph(hue: equipment.glyphHue, scheme: scheme) }
    private var dim: Color { scheme == .dark ? Color.white.opacity(0.24) : Color.black.opacity(0.20) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                .fill(tint.opacity(scheme == .dark ? 0.16 : 0.14))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                        .strokeBorder(tint.opacity(0.32), lineWidth: 1)
                }

            BodyMap(muscle: muscle, highlight: tint, base: dim)
                .frame(width: size * 0.56, height: size * 0.7)
                .frame(width: size, height: size)

            if showsEquipmentBadge {
                EquipmentBadge(equipment: equipment, size: size * 0.36)
                    .offset(x: size * 0.06, y: size * 0.06)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - The figure

private struct BodyMap: View {
    let muscle: Muscle
    let highlight: Color
    let base: Color

    /// Back and glute work is drawn from behind.
    private var isRearView: Bool { muscle == .back || muscle == .glutes }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                // Every part is drawn dim, then the worked ones are painted over.
                parts(w: w, h: h, color: base, only: nil)
                parts(w: w, h: h, color: highlight, only: muscle)
            }
        }
    }

    @ViewBuilder
    private func parts(w: CGFloat, h: CGFloat, color: Color, only: Muscle?) -> some View {
        // Proportions read as a person rather than a stack of blocks: a small
        // head over a neck, shoulders wider than the waist, limbs long enough
        // to be limbs.
        ZStack {
            // Head and neck belong to the outline only.
            Group {
                Circle()
                    .frame(width: w * 0.19, height: w * 0.19)
                    .position(x: w * 0.5, y: h * 0.065)
                Capsule()
                    .frame(width: w * 0.09, height: h * 0.04)
                    .position(x: w * 0.5, y: h * 0.135)
            }
            .foregroundStyle(only == nil ? color : .clear)

            // Shoulder yoke
            Capsule()
                .fill(shouldPaint(.shoulders, only: only) ? color : .clear)
                .frame(width: w * 0.62, height: h * 0.075)
                .position(x: w * 0.5, y: h * 0.19)

            // Upper torso — chest from the front, lats from behind. Tapered
            // towards the waist.
            Trapezoid(topInset: 0, bottomInset: w * 0.07)
                .fill(shouldPaint(isRearView ? .back : .chest, only: only) ? color : .clear)
                .frame(width: w * 0.46, height: h * 0.17)
                .position(x: w * 0.5, y: h * 0.305)

            // Lower torso — abdominals either way.
            RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
                .fill(shouldPaint(.core, only: only) ? color : .clear)
                .frame(width: w * 0.3, height: h * 0.115)
                .position(x: w * 0.5, y: h * 0.45)

            // Arms, angled slightly away from the body.
            Group {
                Capsule()
                    .frame(width: w * 0.1, height: h * 0.3)
                    .rotationEffect(.degrees(-7))
                    .position(x: w * 0.155, y: h * 0.35)
                Capsule()
                    .frame(width: w * 0.1, height: h * 0.3)
                    .rotationEffect(.degrees(7))
                    .position(x: w * 0.845, y: h * 0.35)
            }
            .foregroundStyle(shouldPaint(.arms, only: only) ? color : .clear)

            // Hips and glutes
            RoundedRectangle(cornerRadius: w * 0.09, style: .continuous)
                .fill(shouldPaint(.glutes, only: only) ? color : .clear)
                .frame(width: w * 0.42, height: h * 0.085)
                .position(x: w * 0.5, y: h * 0.555)

            // Legs
            Group {
                Capsule()
                    .frame(width: w * 0.15, height: h * 0.36)
                    .position(x: w * 0.385, y: h * 0.795)
                Capsule()
                    .frame(width: w * 0.15, height: h * 0.36)
                    .position(x: w * 0.615, y: h * 0.795)
            }
            .foregroundStyle(shouldPaint(.legs, only: only) ? color : .clear)
        }
    }

    /// A region is painted in the dim pass always, and in the bright pass only
    /// when it is the one being worked.
    private func shouldPaint(_ region: Muscle, only: Muscle?) -> Bool {
        guard let only else { return true }
        if only == .fullBody || only == .cardio { return true }
        if only == .mobility { return region == .core || region == .legs }
        return only == region
    }
}

/// A rectangle narrowed at the bottom, for the taper from chest to waist.
private struct Trapezoid: Shape {
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - bottomInset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bottomInset, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Equipment badge

private struct EquipmentBadge: View {
    @Environment(\.colorScheme) private var scheme
    let equipment: Equipment
    var size: CGFloat = 19

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                .fill(scheme == .dark ? Color(red: 0.07, green: 0.07, blue: 0.10) : Color.white)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                        .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
                }
            Image(systemName: equipment.symbolName)
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.85))
        }
        .frame(width: size, height: size)
    }
}

extension Equipment {
    /// SF Symbol standing in for the implement.
    var symbolName: String {
        switch self {
        case .barbell: "figure.strengthtraining.traditional"
        case .dumbbell: "dumbbell.fill"
        case .machine: "gearshape.fill"
        case .cable: "cable.connector"
        case .bodyweight: "figure.stand"
        case .kettlebell: "figure.strengthtraining.functional"
        case .cardio: "figure.run"
        case .mobility: "figure.flexibility"
        }
    }
}

extension Exercise {
    var muscleGroup: Muscle {
        Muscle(rawValue: primaryMuscle) ?? .fullBody
    }
}

#Preview("Muscle map icons") {
    let cases: [(Muscle, Equipment)] = [
        (.chest, .barbell), (.chest, .dumbbell), (.back, .cable), (.legs, .barbell),
        (.shoulders, .dumbbell), (.arms, .barbell), (.core, .bodyweight), (.glutes, .machine)
    ]
    return ZStack {
        AuroraBackground()
        VStack(spacing: 20) {
            ForEach(0..<2) { row in
                HStack(spacing: 14) {
                    ForEach(0..<4) { column in
                        let item = cases[row * 4 + column]
                        MuscleMapIcon(muscle: item.0, equipment: item.1, size: 56)
                    }
                }
            }
            MuscleMapIcon(muscle: .chest, equipment: .barbell, size: 120)
        }
    }
}
