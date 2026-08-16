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

    @Environment(HealthStore.self) private var health

    @State private var exportURL: URL?
    @State private var planPDFURL: URL?
    @State private var recalcNotice: String?
    @State private var healthNotice: String?
    @State private var isSyncing = false

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
                        healthSection(profile)
                        restAlertSection(profile)
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

    private func healthSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "Apple Health") {
            VStack(alignment: .leading, spacing: 12) {
                if !health.isAvailable {
                    Text("Health is not available on this device.")
                        .font(.bodyS)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Pull bodyweight, sex and age from Health, and bring in workouts recorded elsewhere — including sessions from your Apple Watch.")
                        .font(.bodyS)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { await connectHealth(profile) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                            Text(healthButtonTitle)
                            if isSyncing {
                                Spacer()
                                ProgressView().controlSize(.small)
                            }
                        }
                        .font(.bodyM)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(isSyncing)

                    if let healthNotice {
                        Text(healthNotice)
                            .font(.captionM)
                            .foregroundStyle(Theme.Palette.cyan)
                    }

                    // Be honest about the limit rather than let it look broken.
                    Text("A workout started on the Watch appears here once it ends — Health only publishes a workout when it is saved.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var healthButtonTitle: String {
        switch health.availability {
        case .ready: "Sync with Health"
        default: "Connect Health"
        }
    }

    private func connectHealth(_ profile: UserProfile) async {
        isSyncing = true
        defer { isSyncing = false }

        guard await health.requestAuthorization() else {
            healthNotice = health.lastError ?? "Health access was not granted."
            return
        }

        let body = await health.readBodyData()
        var updates: [String] = []

        if let kg = body.bodyweightKg, abs(kg - profile.bodyweightKg) > 0.05 {
            profile.updateBodyweight(kg)
            updates.append("bodyweight \(UnitFormatter.weight(kg, in: units))")
        }
        if let sex = body.sex, sex != profile.sex {
            profile.sex = sex
            updates.append("sex")
        }
        if let year = body.birthYear, year != profile.birthYear {
            profile.birthYear = year
            updates.append("age")
        }

        let imported = await health.importWorkouts(into: context)
        if imported > 0 {
            updates.append("\(imported) workout\(imported == 1 ? "" : "s") imported")
        }

        try? context.save()
        withAnimation(Theme.Motion.spring) {
            healthNotice = updates.isEmpty ? "Health is connected — nothing new to pull." : "Updated: \(updates.joined(separator: ", "))."
        }
        Haptics.success()
    }

    private func restAlertSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "When rest ends") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(RestAlert.allCases) { option in
                    Button {
                        Haptics.play(.selection)
                        profile.restAlert = option
                        try? context.save()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: option.symbolName)
                                .font(.system(size: 15))
                                .frame(width: 24)
                                .foregroundStyle(profile.restAlert == option
                                                 ? Theme.Palette.violet : Color.secondary)
                            Text(option.displayName)
                                .font(.bodyM)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                            if profile.restAlert == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.Palette.violet)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressableSilent)

                    if option != RestAlert.allCases.last {
                        Divider().opacity(0.4)
                    }
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

                Divider().opacity(0.4).padding(.vertical, 2)

                if let planPDFURL {
                    ShareLink(item: planPDFURL) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share plan PDF")
                        }
                        .font(.bodyM)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glassProminent)
                } else {
                    Button {
                        guard let plan = Store.activePlan(in: context) else { return }
                        planPDFURL = try? PlanPDF.write(plan: plan, profile: profile)
                        Haptics.play(.success)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.richtext")
                            Text("Export plan as PDF")
                        }
                        .font(.bodyM)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .disabled(Store.activePlan(in: context) == nil)
                }

                Text("A printable A4 sheet of your plan: the weekly schedule and every exercise with its scheme.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var aboutSection: some View {
        GlassSection(title: "About") {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gym Tracker").font(.bodyM)
                    Text("Tiers come from bodyweight-relative strength standards with an age coefficient. They are guidelines, not measurements.")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }

                Divider().opacity(0.4)

                // CC BY-SA requires the credit to travel with the work, so it
                // lives in the app rather than only in the repository.
                VStack(alignment: .leading, spacing: 4) {
                    Text("Artwork").overlineStyle()
                    Text("Exercise illustrations by Everkinetic, licensed CC BY-SA 4.0.")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                    Text("Reference photographs from free-exercise-db, public domain.")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }
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
