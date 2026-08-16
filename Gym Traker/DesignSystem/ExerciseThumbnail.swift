//
//  ExerciseThumbnail.swift
//  Gym Traker
//
//  Archive exercises ship two demonstration photographs — start position and
//  end position — from the public-domain free-exercise-db set, so every one of
//  them is shot the same way. User-created exercises have no photo, and fall
//  back to the generated glyph so the list still reads as one system.
//

import SwiftUI

/// Loads a bundled exercise photo. HEIC files sit flat in the bundle, so a
/// plain name lookup finds them.
enum ExercisePhoto {
    private static var cache = NSCache<NSString, UIImage>()

    static func load(_ name: String) -> UIImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        guard let url = Bundle.main.url(forResource: name, withExtension: "heic"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)
        else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}

/// Square thumbnail for rows and pickers.
struct ExerciseThumbnail: View {
    @Environment(\.colorScheme) private var scheme

    let exercise: Exercise
    var size: CGFloat = 52

    private var photo: UIImage? {
        exercise.imageNames.first.flatMap(ExercisePhoto.load)
    }

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                            .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
                    }
            } else {
                ExerciseGlyph(exercise: exercise, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The two-frame demonstration shown on the exercise detail screen. Tapping
/// swaps between start and end so the movement reads as a movement.
struct ExerciseDemo: View {
    @Environment(\.colorScheme) private var scheme

    let exercise: Exercise
    @State private var showingEnd = false

    private var names: [String] { exercise.imageNames }

    var body: some View {
        if names.isEmpty {
            ExerciseGlyph(exercise: exercise, size: 120)
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 10) {
                ZStack {
                    ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                        if let image = ExercisePhoto.load(name) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(shouldShow(index) ? 1 : 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
                }
                .contentShape(.rect(cornerRadius: Theme.Radius.card))
                .onTapGesture {
                    guard names.count > 1 else { return }
                    Haptics.light()
                    withAnimation(Theme.Motion.spring) { showingEnd.toggle() }
                }

                if names.count > 1 {
                    HStack(spacing: 8) {
                        phaseChip("Start", active: !showingEnd) { showingEnd = false }
                        phaseChip("End", active: showingEnd) { showingEnd = true }
                    }
                }
            }
        }
    }

    private func shouldShow(_ index: Int) -> Bool {
        names.count > 1 ? (showingEnd ? index == 1 : index == 0) : index == 0
    }

    private func phaseChip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        GlassChip(title: title, isSelected: active, tint: Theme.Palette.cyan) {
            withAnimation(Theme.Motion.spring) { action() }
        }
    }
}
