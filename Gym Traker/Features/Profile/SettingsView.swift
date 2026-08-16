//
//  SettingsView.swift
//  Gym Traker
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var exportURL: URL?
    @State private var recalcNotice: String?

    private var profile: UserProfile? { profiles.first }
    private var units: Units { profile?.units ?? .kg }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(spacing: 18) {
                    if let profile {
                        unitsSection(profile)
                        appearanceSection(profile)
                        profileSection(profile)
                        notificationsSection(profile)
                    }
                    exportSection
                    aboutSection
                }
                .padding(Theme.Spacing.screenMargin)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Sections

    private func unitsSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "Units") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ForEach(Units.allCases) { unit in
                        GlassChip(title: unit.rawValue.uppercased(), isSelected: profile.units == unit) {
                            profile.units = unit
                            try? context.save()
                        }
                    }
                    Spacer()
                }
                Text("Display only. Everything is stored in kilograms, so tiers are identical in both units.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func appearanceSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "Appearance") {
            HStack(spacing: 10) {
                ForEach(Appearance.allCases) { option in
                    GlassChip(
                        title: option.displayName,
                        isSelected: profile.appearance == option,
                        tint: Theme.Palette.cyan
                    ) {
                        profile.appearance = option
                        try? context.save()
                    }
                }
                Spacer()
            }
        }
    }

    private func profileSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "Profile") {
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
                }

                Divider().opacity(0.4)

                HStack {
                    Text("Sex").font(.bodyM)
                    Spacer()
                    ForEach(Sex.allCases) { option in
                        GlassChip(title: option.displayName, isSelected: profile.sex == option) {
                            profile.sex = option
                            try? context.save()
                            noteRecalculation(profile)
                        }
                    }
                }

                Divider().opacity(0.4)

                VStack(spacing: 8) {
                    Text("Bodyweight").overlineStyle().frame(maxWidth: .infinity, alignment: .leading)
                    StepperControl(
                        canDecrease: profile.bodyweightKg > 30,
                        canIncrease: profile.bodyweightKg < 250,
                        onDecrease: { changeBodyweight(profile, by: -0.5) },
                        onIncrease: { changeBodyweight(profile, by: 0.5) }
                    ) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text(UnitFormatter.number(profile.bodyweightKg, in: units))
                                .font(.numberM)
                                .contentTransition(.numericText(value: profile.bodyweightKg))
                            Text(units.rawValue).font(.bodyS).foregroundStyle(.secondary)
                        }
                    }
                }

                if let recalcNotice {
                    Text(recalcNotice)
                        .font(.captionM)
                        .foregroundStyle(Theme.Palette.cyan)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func notificationsSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "Notifications") {
            Toggle(isOn: Binding(
                get: { profile.notificationsEnabled },
                set: {
                    profile.notificationsEnabled = $0
                    if $0 { RestTimer.requestAuthorization() }
                    try? context.save()
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest timer alerts").font(.bodyM)
                    Text("Buzz when the rest is over, even with the app in your pocket.")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Theme.Palette.violet)
        }
    }

    private var exportSection: some View {
        GlassSection(title: "Your data") {
            VStack(alignment: .leading, spacing: 10) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share export")
                        }
                        .font(.bodyM)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glassProminent)
                } else {
                    Button {
                        exportURL = try? DataExporter.writeTemporaryFile(from: context)
                        Haptics.success()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc")
                            Text("Export data as JSON")
                        }
                        .font(.bodyM)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                }

                Text("Profile, plan, custom exercises, every session and the whole registry in one file.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var aboutSection: some View {
        GlassSection(title: "About") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Gym Tracker").font(.bodyM)
                Text("Tiers come from bodyweight-relative strength standards with an age coefficient. They are guidelines, not measurements.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    /// A bodyweight change re-ranks every lift, and the user is told rather
    /// than left to notice tiers moving on their own.
    private func changeBodyweight(_ profile: UserProfile, by delta: Double) {
        profile.updateBodyweight(profile.bodyweightKg + delta)
        try? context.save()
        noteRecalculation(profile)
    }

    private func noteRecalculation(_ profile: UserProfile) {
        withAnimation(Theme.Motion.spring) {
            recalcNotice = "Tiers recalculated for \(UnitFormatter.weight(profile.bodyweightKg, in: units))"
        }
    }
}
