//
//  SettingsView.swift
//  Gym Traker
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query private var profiles: [UserProfile]

    @Environment(HealthStore.self) private var health

    @State private var exportURL: URL?
    @State private var planPDFURL: URL?
    @State private var recalcNotice: String?
    @State private var healthNotice: String?
    @State private var isSyncing = false
    @State private var importing = false
    @State private var pendingBackup: URL?
    @State private var backupNotice: String?
    @State private var backupFailed = false
    @State private var feedbackNotice: String?

    private static let feedbackAddress = "davidesogos@gmail.com"

    private var profile: UserProfile? { profiles.first }
    private var units: Units { profile?.units ?? .kg }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(spacing: 18) {
                    if let profile {
                        unitsSection(profile)
                        languageSection(profile)
                        appearanceSection(profile)
                        profileSection(profile)
                        healthSection(profile)
                        restAlertSection(profile)
                        notificationsSection(profile)
                    }
                    exportSection
                    feedbackSection
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
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                pendingBackup = url
            case .failure(let error):
                showBackupNotice(error.localizedDescription, failed: true)
            }
        }
        // Asked before, not reported after: a restore replaces everything on
        // the phone, and there is no undo for it.
        .alert("Replace everything with this backup?", isPresented: Binding(
            get: { pendingBackup != nil },
            set: { if !$0 { pendingBackup = nil } }
        )) {
            Button("Restore", role: .destructive) { restoreBackup() }
            Button("Cancel", role: .cancel) { pendingBackup = nil }
        } message: {
            Text("Your current profile, plans, sessions and registry are removed and replaced by the ones in the file.")
        }
    }

    // MARK: - Sections

    private func unitsSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "Units") {
            HStack(spacing: 10) {
                ForEach(Units.allCases) { unit in
                    GlassChip(title: unit.rawValue.uppercased(), isSelected: profile.units == unit) {
                        profile.units = unit
                        try? context.save()
                    }
                }
                Spacer()
            }
        }
    }

    private func languageSection(_ profile: UserProfile) -> some View {
        GlassSection(title: "Language") {
            HStack(spacing: 10) {
                ForEach(AppLanguage.allCases) { option in
                    GlassChip(
                        title: option.displayName,
                        isSelected: profile.language == option,
                        tint: Theme.Palette.cyan
                    ) {
                        profile.language = option
                        try? context.save()
                    }
                }
                Spacer()
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
                        rowLabel("square.and.arrow.up", "Share backup")
                    }
                    .buttonStyle(.glassProminent)
                } else {
                    Button {
                        exportURL = try? Backup.writeTemporaryFile(from: context)
                        Haptics.success()
                    } label: {
                        rowLabel("arrow.down.doc", "Create a backup")
                    }
                    .buttonStyle(.glass)
                }

                Button {
                    importing = true
                } label: {
                    rowLabel("arrow.up.doc", "Restore from a backup")
                }
                .buttonStyle(.glass)

                Text("One file with everything: profile, plans, exercises, every session and the whole registry. Restoring replaces what is on this phone.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)

                if let backupNotice {
                    Text(backupNotice)
                        .font(.captionM)
                        .foregroundStyle(backupFailed ? Theme.Palette.sportRed : Theme.Palette.cyan)
                }

                Divider().opacity(0.4).padding(.vertical, 2)

                if let planPDFURL {
                    ShareLink(item: planPDFURL) {
                        rowLabel("square.and.arrow.up", "Share plan PDF")
                    }
                    .buttonStyle(.glassProminent)
                } else {
                    Button {
                        guard let plan = Store.activePlan(in: context) else { return }
                        planPDFURL = try? PlanPDF.write(plan: plan, profile: profile)
                        Haptics.play(.success)
                    } label: {
                        rowLabel("doc.richtext", "Export plan as PDF")
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

    private func rowLabel(_ symbol: String, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text(title)
        }
        .font(.bodyM)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    /// Straight to a mail draft, addressed and with the version already in it.
    ///
    /// No form, no server, no account. A mailto: link costs nothing to run and
    /// nothing to trust, and it puts the reply address in the user's hands
    /// rather than in a database.
    private var feedbackSection: some View {
        GlassSection(title: "Feedback") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Something broken, missing or just wrong? Say so — it goes straight to the person who builds this.")
                    .font(.bodyS)
                    .foregroundStyle(.secondary)

                Button {
                    openFeedbackMail()
                } label: {
                    rowLabel("envelope", "Write feedback")
                }
                .buttonStyle(.glass)

                if let feedbackNotice {
                    Text(feedbackNotice)
                        .font(.captionM)
                        .foregroundStyle(Theme.Palette.decrease)
                }
            }
        }
    }

    private func openFeedbackMail() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        // The device and version go in the body so a report never arrives
        // without the two things that make it reproducible.
        let body = """


        —
        Gym Tracker \(version) (\(build))
        \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.feedbackAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Gym Tracker feedback"),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else { return }
        openURL(url) { accepted in
            guard !accepted else { return }
            withAnimation(Theme.Motion.spring) {
                feedbackNotice = "No mail account is set up on this device. Write to \(Self.feedbackAddress)."
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

    private func restoreBackup() {
        guard let url = pendingBackup else { return }
        pendingBackup = nil
        do {
            let summary = try Backup.restore(contentsOf: url, into: context)
            Haptics.success()
            var parts: [String] = []
            if summary.hasProfile { parts.append("profile") }
            if summary.plans > 0 { parts.append("\(summary.plans) plan\(summary.plans == 1 ? "" : "s")") }
            if summary.sessions > 0 { parts.append("\(summary.sessions) session\(summary.sessions == 1 ? "" : "s")") }
            if summary.records > 0 { parts.append("\(summary.records) registry entr\(summary.records == 1 ? "y" : "ies")") }
            showBackupNotice(parts.isEmpty ? "Restored an empty backup." : "Restored: " + parts.joined(separator: ", ") + ".",
                             failed: false)
        } catch {
            Haptics.play(.failure)
            showBackupNotice(error.localizedDescription, failed: true)
        }
    }

    private func showBackupNotice(_ text: String, failed: Bool) {
        withAnimation(Theme.Motion.spring) {
            backupFailed = failed
            backupNotice = text
        }
    }

    private func noteRecalculation(_ profile: UserProfile) {
        withAnimation(Theme.Motion.spring) {
            recalcNotice = "Tiers recalculated for \(UnitFormatter.weight(profile.bodyweightKg, in: units))"
        }
    }
}
