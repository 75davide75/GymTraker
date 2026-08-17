//
//  ExerciseImageViewer.swift
//  Gym Traker
//
//  Full-screen viewer for an exercise's artwork. Pinch or double-tap to zoom,
//  drag to pan, swipe between the pages.
//
//  It shows one kind of picture at a time. It used to put the drawings and the
//  photographs in one run of pages and open at whichever index the caller
//  wanted, so opening the reference photos and swiping back landed on the
//  drawing that is already on the screen behind — and already the exercise's
//  icon. Two collections of two, not one of four.
//
//  The complaint that started this: the pictures were too small to read and
//  there was no way to make them bigger.
//

import SwiftUI

struct ExerciseImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    enum Kind {
        case illustrations
        case photos
    }

    let exercise: Exercise
    var kind: Kind = .illustrations
    /// Which page within that kind to open on.
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
        switch kind {
        case .illustrations:
            for (index, name) in exercise.illustrationNames.enumerated() {
                guard let image = ExerciseArtwork.illustration(name) else { continue }
                result.append(Page(
                    id: result.count,
                    image: image,
                    caption: index == 0 ? "Contracted position" : "Stretched position",
                    isLineArt: true
                ))
            }
        case .photos:
            for (index, name) in exercise.photoNames.enumerated() {
                guard let image = ExerciseArtwork.photo(name) else { continue }
                result.append(Page(
                    id: result.count,
                    image: image,
                    caption: index == 0 ? "Start position" : "End position",
                    isLineArt: false
                ))
            }
        }
        return result
    }

    private var title: String {
        switch kind {
        case .illustrations: exercise.name
        case .photos: "Reference photos"
        }
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
        .navigationTitle(title)
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
