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

    var body: some View {
        // A drawing of the movement is too fine to read at row size, so the
        // list wears a muscle map instead and the drawings live on the detail
        // screen at a size where they mean something.
        MuscleMapIcon(
            muscle: exercise.muscleGroup,
            equipment: exercise.equipment,
            size: size
        )
    }
}

// MARK: - Detail demonstration

/// The two-phase demonstration on the exercise detail screen. Tapping swaps
/// between the phases so the movement reads as a movement.
struct ExerciseDemo: View {
    @Environment(\.colorScheme) private var scheme

    let exercise: Exercise
    var onOpenViewer: ((Int) -> Void)?
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
                .frame(height: 300)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                }
                .contentShape(.rect(cornerRadius: Theme.Radius.card))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Circle().fill(.ultraThinMaterial))
                        .padding(10)
                }
                .onTapGesture {
                    Haptics.light()
                    onOpenViewer?(showingSecond ? 1 : 0)
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
