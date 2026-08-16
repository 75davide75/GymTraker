//
//  ExerciseImageViewer.swift
//  Gym Traker
//
//  Full-screen viewer for an exercise's artwork. Pinch or double-tap to zoom,
//  drag to pan, swipe between the illustrations and the reference photos.
//
//  The complaint that started this: the pictures were too small to read and
//  there was no way to make them bigger.
//

import SwiftUI

struct ExerciseImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let exercise: Exercise
    /// Which page to open on.
    var startIndex: Int = 0

    @State private var page: Int = 0

    private struct Page: Identifiable {
        let id: Int
        let image: UIImage
        let caption: String
        /// Line art is tinted; photographs are shown as they are.
        let isLineArt: Bool
    }

    private var pages: [Page] {
        var result: [Page] = []
        for (index, name) in exercise.illustrationNames.enumerated() {
            guard let image = ExerciseArtwork.illustration(name) else { continue }
            result.append(Page(
                id: result.count,
                image: image,
                caption: index == 0 ? "Contracted position" : "Stretched position",
                isLineArt: true
            ))
        }
        for (index, name) in exercise.photoNames.enumerated() {
            guard let image = ExerciseArtwork.photo(name) else { continue }
            result.append(Page(
                id: result.count,
                image: image,
                caption: index == 0 ? "Reference photo · start" : "Reference photo · end",
                isLineArt: false
            ))
        }
        return result
    }

    var body: some View {
        ZStack {
            AuroraBackground(variant: .library)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages) { item in
                        ZoomableImage(image: item.image, isLineArt: item.isLineArt)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: pages.count > 1 ? .automatic : .never))

                if let caption = pages.first(where: { $0.id == page })?.caption {
                    Text(caption)
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 26)
                        .transition(.opacity)
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { page = min(startIndex, max(0, pages.count - 1)) }
    }
}

/// Pinch, double-tap and drag. Resets when it is let go under 1×.
private struct ZoomableImage: View {
    @Environment(\.colorScheme) private var scheme

    let image: UIImage
    var isLineArt: Bool

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maxScale: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            artwork
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(
                    SimultaneousGesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = min(maxScale, max(1, lastScale * value.magnification))
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale <= 1 { resetPan() }
                            },
                        DragGesture()
                            .onChanged { value in
                                guard scale > 1 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in lastOffset = offset }
                    )
                )
                .onTapGesture(count: 2) {
                    Haptics.light()
                    withAnimation(Theme.Motion.spring) {
                        if scale > 1 {
                            scale = 1
                            resetPan()
                        } else {
                            scale = 2.5
                        }
                        lastScale = scale
                    }
                }
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if isLineArt {
            Image(uiImage: image)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(20)
                .foregroundStyle(scheme == .dark ? Color.white.opacity(0.95) : Color.black.opacity(0.85))
        } else {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(12)
        }
    }

    private func resetPan() {
        offset = .zero
        lastOffset = .zero
    }
}
