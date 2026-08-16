//
//  ExerciseThumbnail.swift
//  Gym Traker
//
//  Archive exercises ship line-art illustrations in two phases — the
//  contracted position and the stretched one — from the Everkinetic set
//  (CC BY-SA 4.0). They are rasterised with a transparent background, so the
//  app tints them like a symbol and they sit on glass instead of fighting it.
//
//  Photographs are a separate, optional reference gallery on the detail
//  screen. They never appear in lists: a photo next to a drawing reads as two
//  different apps.
//
//  User-created exercises have neither and fall back to the generated glyph.
//

import SwiftUI

/// Loads a bundled asset. Files sit flat in the bundle, so a plain name lookup
/// finds them.
enum ExerciseArtwork {
    private static let cache = NSCache<NSString, UIImage>()

    static func illustration(_ name: String) -> UIImage? {
        load(name, extension: "png")
    }

    static func photo(_ name: String) -> UIImage? {
        load(name, extension: "heic")
    }

    private static func load(_ name: String, extension ext: String) -> UIImage? {
        let key = "\(name).\(ext)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)
        else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}

// MARK: - Row thumbnail

struct ExerciseThumbnail: View {
    @Environment(\.colorScheme) private var scheme

    let exercise: Exercise
    var size: CGFloat = 52

    private var tint: Color { Theme.Palette.glyph(hue: exercise.glyphHue, scheme: scheme) }

    private var artwork: UIImage? {
        exercise.illustrationNames.first.flatMap(ExerciseArtwork.illustration)
    }

    var body: some View {
        Group {
            if let artwork {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(scheme == .dark ? 0.26 : 0.20),
                                         tint.opacity(scheme == .dark ? 0.11 : 0.09)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                                .strokeBorder(tint.opacity(0.32), lineWidth: 1)
                        }

                    Image(uiImage: artwork)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(size * 0.08)
                        .foregroundStyle(scheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.78))
                }
                .frame(width: size, height: size)
            } else {
                ExerciseGlyph(exercise: exercise, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Detail demonstration

/// The two-phase demonstration on the exercise detail screen. Tapping swaps
/// between the phases so the movement reads as a movement.
struct ExerciseDemo: View {
    @Environment(\.colorScheme) private var scheme

    let exercise: Exercise
    @State private var showingSecond = false

    private var names: [String] { exercise.illustrationNames }
    private var tint: Color { Theme.Palette.glyph(hue: exercise.glyphHue, scheme: scheme) }

    var body: some View {
        if names.isEmpty {
            ExerciseGlyph(exercise: exercise, size: 120)
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(scheme == .dark ? 0.20 : 0.16),
                                         tint.opacity(scheme == .dark ? 0.07 : 0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                        if let image = ExerciseArtwork.illustration(name) {
                            Image(uiImage: image)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(14)
                                .foregroundStyle(scheme == .dark ? Color.white.opacity(0.94) : Color.black.opacity(0.8))
                                .opacity(shouldShow(index) ? 1 : 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                }
                .contentShape(.rect(cornerRadius: Theme.Radius.card))
                .onTapGesture {
                    guard names.count > 1 else { return }
                    Haptics.light()
                    withAnimation(Theme.Motion.spring) { showingSecond.toggle() }
                }

                if names.count > 1 {
                    HStack(spacing: 8) {
                        phaseChip("Contracted", active: !showingSecond) { showingSecond = false }
                        phaseChip("Stretched", active: showingSecond) { showingSecond = true }
                    }
                }
            }
        }
    }

    private func shouldShow(_ index: Int) -> Bool {
        names.count > 1 ? (showingSecond ? index == 1 : index == 0) : index == 0
    }

    private func phaseChip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        GlassChip(title: title, isSelected: active, tint: Theme.Palette.cyan) {
            withAnimation(Theme.Motion.spring) { action() }
        }
    }
}

// MARK: - Photo gallery

/// Reference photographs, kept behind a tap so they never clash with the
/// drawn style of the rest of the app.
struct ExercisePhotoGallery: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(exercise.photoNames.enumerated()), id: \.offset) { index, name in
                        if let photo = ExerciseArtwork.photo(name) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(index == 0 ? "Start position" : "End position")
                                    .overlineStyle()
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                                            .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
                                    }
                            }
                        }
                    }

                    Text("Reference photographs from free-exercise-db, public domain.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding(Theme.Spacing.screenMargin)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
