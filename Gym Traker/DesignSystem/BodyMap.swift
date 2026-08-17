//
//  BodyMap.swift
//  Gym Traker
//
//  A figure with one muscle group lit up.
//
//  The per-muscle rank used to sit next to a generic tile that said "Legs" in
//  a coloured circle, which is a label with extra steps. A rank per muscle is
//  worth reading precisely because it is spatial — the chest three tiers above
//  the legs is a shape, not a list — so it gets a body.
//
//  Drawn rather than drawn from an archive. The anatomical renders that would
//  do this better are licensed, and eleven consistent shapes are exactly the
//  thing a few paths do well.
//

import SwiftUI

struct BodyMap: View {
    let highlighted: MuscleGroup
    var size: CGFloat = 46
    /// Muscles you only see from behind turn the figure round.
    private var showsBack: Bool {
        switch highlighted {
        case .back, .glutes, .hamstrings, .traps, .triceps: true
        default: false
        }
    }

    private var tint: Color { highlighted.tint }

    var body: some View {
        Canvas { context, canvas in
            // One coordinate space, 100 × 210, scaled to whatever it is given.
            let scale = min(canvas.width / 100, canvas.height / 210)
            let dx = (canvas.width - 100 * scale) / 2
            let dy = (canvas.height - 210 * scale) / 2
            context.translateBy(x: dx, y: dy)
            context.scaleBy(x: scale, y: scale)

            for region in Region.all(back: showsBack) {
                let isLit = region.group == highlighted
                context.fill(
                    region.path,
                    with: .color(isLit ? tint : Color.secondary.opacity(0.22))
                )
            }
        }
        .frame(width: size, height: size * 210 / 100)
        .accessibilityLabel("\(highlighted.displayName) highlighted on a \(showsBack ? "back" : "front") view")
    }

    /// One shape per body part, in a 100 × 210 space with the head at the top.
    private struct Region {
        let group: MuscleGroup?
        let path: Path

        static func all(back: Bool) -> [Region] {
            var regions: [Region] = []

            func add(_ group: MuscleGroup?, _ rect: CGRect, corner: CGFloat = 6) {
                regions.append(Region(
                    group: group,
                    path: Path(roundedRect: rect, cornerRadius: corner, style: .continuous)
                ))
            }

            // Head and neck are never a muscle group here — they are what makes
            // the rest read as a body.
            regions.append(Region(group: nil, path: Path(ellipseIn: CGRect(x: 40, y: 2, width: 20, height: 24))))
            add(nil, CGRect(x: 45, y: 24, width: 10, height: 8), corner: 3)

            // Traps sit on top of the shoulders, and read from behind.
            add(.traps, CGRect(x: 31, y: 30, width: 38, height: 12), corner: 6)

            // Delts, one each side.
            add(.delts, CGRect(x: 18, y: 34, width: 16, height: 20), corner: 8)
            add(.delts, CGRect(x: 66, y: 34, width: 16, height: 20), corner: 8)

            // The torso: chest and abs from the front, one back from behind.
            if back {
                add(.back, CGRect(x: 33, y: 42, width: 34, height: 46), corner: 10)
            } else {
                add(.chest, CGRect(x: 33, y: 42, width: 34, height: 24), corner: 8)
                add(.abs, CGRect(x: 38, y: 68, width: 24, height: 30), corner: 7)
            }

            // Upper arm: biceps in front, triceps behind. Same place, and that
            // is the point of turning the figure round.
            let upperArm = back ? MuscleGroup.triceps : .biceps
            add(upperArm, CGRect(x: 15, y: 56, width: 14, height: 26), corner: 7)
            add(upperArm, CGRect(x: 71, y: 56, width: 14, height: 26), corner: 7)

            // Forearms belong to no ranked group, so they are just anatomy.
            add(nil, CGRect(x: 14, y: 84, width: 12, height: 26), corner: 6)
            add(nil, CGRect(x: 74, y: 84, width: 12, height: 26), corner: 6)

            // Hips: glutes only exist on the back view.
            if back {
                add(.glutes, CGRect(x: 34, y: 92, width: 32, height: 22), corner: 10)
            } else {
                add(nil, CGRect(x: 36, y: 96, width: 28, height: 16), corner: 8)
            }

            // Thigh: quads in front, hamstrings behind.
            let thigh = back ? MuscleGroup.hamstrings : .quads
            add(thigh, CGRect(x: 34, y: back ? 114 : 110, width: 14, height: 42), corner: 7)
            add(thigh, CGRect(x: 52, y: back ? 114 : 110, width: 14, height: 42), corner: 7)

            // Knees, then calves.
            add(nil, CGRect(x: 35, y: 156, width: 12, height: 8), corner: 4)
            add(nil, CGRect(x: 53, y: 156, width: 12, height: 8), corner: 4)
            add(.calves, CGRect(x: 35, y: 164, width: 12, height: 34), corner: 6)
            add(.calves, CGRect(x: 53, y: 164, width: 12, height: 34), corner: 6)

            // Feet.
            add(nil, CGRect(x: 33, y: 198, width: 15, height: 8), corner: 3)
            add(nil, CGRect(x: 52, y: 198, width: 15, height: 8), corner: 3)

            return regions
        }
    }
}

#Preview("Body map") {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            ForEach(MuscleGroup.ranked) { group in
                VStack(spacing: 6) {
                    BodyMap(highlighted: group, size: 54)
                    Text(group.displayName).font(.system(size: 10, weight: .semibold))
                }
            }
        }
        .padding()
    }
    .background(Theme.Palette.backgroundDark)
}
