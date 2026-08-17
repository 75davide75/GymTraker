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

    /// The same drawing with the empty margin cut away.
    ///
    /// The set is drawn on a fixed 512 canvas, and the figure occupies anywhere
    /// from a quarter of it to four fifths depending on whether the exercise is
    /// standing, lying down or holding a long barbell. Shown as-is at row size
    /// that reads as a set of drawings at random scales, most of them too small
    /// to make out. Cropped to the ink, every one of them fills its tile.
    static func trimmedIllustration(_ name: String) -> UIImage? {
        let key = "trimmed:\(name)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let image = illustration(name), let cgImage = image.cgImage else { return nil }
        guard let box = inkBounds(cgImage), let cropped = cgImage.cropping(to: box) else { return image }

        let trimmed = UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
            .withRenderingMode(.alwaysTemplate)
        cache.setObject(trimmed, forKey: key)
        return trimmed
    }

    /// The smallest rectangle containing any non-transparent pixel.
    private static func inkBounds(_ image: CGImage) -> CGRect? {
        let width = image.width, height = image.height
        var alpha = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &alpha, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            let row = y * width
            for x in 0..<width where alpha[row + x] > 8 {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
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

    /// The muscle worked, not the equipment used.
    ///
    /// Tinting by equipment put a gold tile between two violet ones and made a
    /// list of the same kind of thing look like a list of different kinds. The
    /// muscle is the thing you scan a library for, so it is the thing the
    /// colour answers — and the equipment gets a badge, which is exact rather
    /// than a colour you have to learn.
    private var tint: Color { exercise.group.tint }

    /// The contracted phase — the position that identifies the movement.
    private var artwork: UIImage? {
        guard let name = exercise.illustrationNames.first else { return nil }
        return ExerciseArtwork.trimmedIllustration(name)
    }

    var body: some View {
        // The list used to wear a generated muscle map, on the grounds that a
        // drawing of the movement was too fine to read this small. It was too
        // fine because it was shown inside its whole 512 canvas, most of which
        // is empty. Cropped to the ink it reads perfectly, and one drawn set
        // across the whole archive beats a diagram that means the same thing
        // for every press.
        ZStack {
            Circle().fill(tint.opacity(scheme == .dark ? 0.18 : 0.13))
            Circle().strokeBorder(tint.opacity(0.32), lineWidth: 1)

            if let artwork {
                Image(uiImage: artwork)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.17)
                    .foregroundStyle(tint)
            } else {
                // Only a user-created exercise gets here.
                MuscleMapIcon(
                    muscle: exercise.group,
                    equipment: exercise.equipment,
                    size: size
                )
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) { equipmentBadge }
        .accessibilityHidden(true)
    }

    /// On the lower corner rather than the lower edge: centred, it landed on
    /// the figure's legs, and a badge over the drawing is two pictures fighting
    /// for the same forty points.
    private var equipmentBadge: some View {
        Image(systemName: exercise.equipment.symbolName)
            .font(.system(size: size * 0.22, weight: .semibold))
            .foregroundStyle(scheme == .dark ? Color.white : Color.black.opacity(0.78))
            .frame(width: size * 0.38, height: size * 0.38)
            .background {
                Circle()
                    .fill(.regularMaterial)
                    .overlay(Circle().strokeBorder(tint.opacity(0.5), lineWidth: 1))
            }
            .offset(x: size * 0.06, y: size * 0.06)
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
    /// The same tint the thumbnail uses. These disagreed: an amber icon next
    /// to a violet panel, for one exercise, on one screen.
    private var tint: Color { exercise.group.tint }

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
