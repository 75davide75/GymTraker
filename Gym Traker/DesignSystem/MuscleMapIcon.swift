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

    let muscle: MuscleGroup
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

            BodyMap(highlighted: muscle, size: size * 0.5)
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
// The figure used to be drawn here, privately, from the seven coarse
// muscles. It lives in BodyMap.swift now and knows all eleven groups —
// one figure, one place, and the per-muscle rank can use it too.

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
    ZStack {
        AuroraBackground()
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(MuscleGroup.ranked) { group in
                    MuscleMapIcon(muscle: group, equipment: .barbell, size: 62)
                }
            }
            .padding()
        }
    }
}
