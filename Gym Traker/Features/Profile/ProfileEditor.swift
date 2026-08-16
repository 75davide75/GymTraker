//
//  ProfileEditor.swift
//  Gym Traker
//
//  Tap your own name to change who the app thinks you are: photo, name, sex,
//  age, bodyweight and height.
//
//  Health can fill any of these in, but what you type always wins. A value you
//  entered is a decision; a value from Health is a reading, and the app should
//  not quietly overwrite the first with the second.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthStore.self) private var health

    let profile: UserProfile

    @State private var photoItem: PhotosPickerItem?
    @State private var healthNotice: String?
    @State private var isImporting = false

    private var units: Units { profile.units }

    var body: some View {
        ZStack {
            AuroraBackground(variant: .profile)

            ScrollView {
                VStack(spacing: 18) {
                    avatarSection
                    identitySection
                    bodySection
                    healthSection
                }
                .padding(Theme.Spacing.screenMargin)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Your details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    try? context.save()
                    Haptics.play(.commit)
                    dismiss()
                }
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatar(profile: profile, size: 108)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.Palette.violet))
                        .overlay(Circle().strokeBorder(Theme.Palette.backgroundDark, lineWidth: 2))
                }
            }
            .buttonStyle(.pressableSilent)

            if profile.avatarData != nil {
                Button("Remove photo") {
                    Haptics.play(.remove)
                    profile.avatarData = nil
                    try? context.save()
                }
                .font(.captionM)
                .buttonStyle(.plain)
                .foregroundStyle(Theme.Palette.decrease)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let shrunk = image.squareThumbnail(side: 512)
        else { return }
        profile.avatarData = shrunk
        try? context.save()
        Haptics.play(.success)
    }

    // MARK: - Identity

    private var identitySection: some View {
        GlassSection(title: "Identity") {
            VStack(spacing: 14) {
                HStack {
                    Text("Name").font(.bodyM)
                    Spacer()
                    TextField("Lifter", text: Binding(
                        get: { profile.name },
                        set: { profile.name = $0 }
                    ))
                    .multilineTextAlignment(.trailing)
                    .font(.bodyM)
                    .textInputAutocapitalization(.words)
                }

                Divider().opacity(0.4)

                HStack {
                    Text("Sex").font(.bodyM)
                    Spacer()
                    ForEach(Sex.allCases) { option in
                        GlassChip(title: option.displayName, isSelected: profile.sex == option) {
                            profile.sex = option
                            try? context.save()
                        }
                    }
                }

                Divider().opacity(0.4)

                stepperRow(
                    title: "Age",
                    value: "\(profile.age)",
                    unit: "years",
                    canDecrease: profile.age > 14,
                    canIncrease: profile.age < 90,
                    onDecrease: { profile.birthYear += 1 },
                    onIncrease: { profile.birthYear -= 1 }
                )
            }
        }
    }

    // MARK: - Body

    private var bodySection: some View {
        GlassSection(title: "Body") {
            VStack(spacing: 16) {
                stepperRow(
                    title: "Bodyweight",
                    value: UnitFormatter.number(profile.bodyweightKg, in: units),
                    unit: units.rawValue,
                    canDecrease: profile.bodyweightKg > 30,
                    canIncrease: profile.bodyweightKg < 250,
                    onDecrease: { profile.updateBodyweight(profile.bodyweightKg - 0.5) },
                    onIncrease: { profile.updateBodyweight(profile.bodyweightKg + 0.5) }
                )

                Divider().opacity(0.4)

                stepperRow(
                    title: "Height",
                    value: profile.heightCm.map { String(Int($0.rounded())) } ?? "—",
                    unit: "cm",
                    canDecrease: (profile.heightCm ?? 170) > 120,
                    canIncrease: (profile.heightCm ?? 170) < 230,
                    onDecrease: { profile.heightCm = (profile.heightCm ?? 170) - 1 },
                    onIncrease: { profile.heightCm = (profile.heightCm ?? 170) + 1 }
                )

                Text("Bodyweight drives every strength tier, so keeping it current keeps the ladder honest.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func stepperRow(
        title: String, value: String, unit: String,
        canDecrease: Bool, canIncrease: Bool,
        onDecrease: @escaping () -> Void, onIncrease: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Text(title).overlineStyle().frame(maxWidth: .infinity, alignment: .leading)
            StepperControl(
                canDecrease: canDecrease,
                canIncrease: canIncrease,
                onDecrease: { onDecrease(); try? context.save() },
                onIncrease: { onIncrease(); try? context.save() }
            ) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(value).font(.numberM).contentTransition(.numericText())
                    Text(unit).font(.bodyS).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Health

    private var healthSection: some View {
        GlassSection(title: "Fill in from Health") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Only fills what you have left blank. Anything you typed here stays as you set it.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await importFromHealth() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                        Text("Fill in the gaps")
                        if isImporting {
                            Spacer()
                            ProgressView().controlSize(.small)
                        }
                    }
                    .font(.bodyM)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.glass)
                .disabled(isImporting || !health.isAvailable)

                if let healthNotice {
                    Text(healthNotice)
                        .font(.captionM)
                        .foregroundStyle(Theme.Palette.cyan)
                }
            }
        }
    }

    private func importFromHealth() async {
        isImporting = true
        defer { isImporting = false }

        guard await health.requestAuthorization() else {
            healthNotice = "Health access was not granted."
            return
        }

        let data = await health.readBodyData()
        var filled: [String] = []

        // Height is the one the app cannot guess, so it is worth pulling even
        // when the rest is already set.
        if profile.heightCm == nil, let cm = data.heightCm {
            profile.heightCm = cm
            filled.append("height")
        }
        if profile.name.isEmpty, let name = data.name, !name.isEmpty {
            profile.name = name
            filled.append("name")
        }

        try? context.save()
        withAnimation(Theme.Motion.spring) {
            healthNotice = filled.isEmpty
                ? "Nothing left to fill — everything here is yours."
                : "Filled in \(filled.joined(separator: " and ")) from Health."
        }
        Haptics.play(.success)
    }
}

// MARK: - Avatar

/// The photo if there is one, otherwise initials on the app's gradient.
struct ProfileAvatar: View {
    let profile: UserProfile?
    var size: CGFloat = 64

    private var initials: String {
        let name = profile?.name.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else { return "GT" }
        return name.split(separator: " ").prefix(2)
            .compactMap(\.first).map(String.init).joined().uppercased()
    }

    var body: some View {
        ZStack {
            if let data = profile?.avatarData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Theme.Palette.violet, Theme.Palette.cyan],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

extension UIImage {
    /// Crops to a square and scales down, so an avatar never carries a full
    /// camera frame into the store.
    func squareThumbnail(side: CGFloat) -> Data? {
        let shortest = min(size.width, size.height)
        let crop = CGRect(
            x: (size.width - shortest) / 2,
            y: (size.height - shortest) / 2,
            width: shortest, height: shortest
        )
        guard let cropped = cgImage?.cropping(to: crop) else { return nil }

        let target = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: target)
        let scaled = renderer.image { _ in
            UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
                .draw(in: CGRect(origin: .zero, size: target))
        }
        return scaled.jpegData(compressionQuality: 0.85)
    }
}
