//
//  PlanPresetList.swift
//  Gym Traker
//
//  The split catalogue, in one place.
//
//  It is offered twice: during onboarding, to whoever wants a plan handed to
//  them, and from the Plan screen afterwards. Choosing "start empty" on day one
//  is not meant to be a decision you are stuck with, so the same list has to be
//  reachable later — and it is the same list, not a second copy of it.
//

import SwiftUI
import SwiftData

struct PlanPresetList: View {
    /// Splits suiting this level are shown first. The rest are still offered:
    /// nobody should be told which programmes they are allowed to run.
    let experience: ExperienceLevel
    @Binding var selection: PlanPreset?
    @Binding var variant: PlanPreset.Variant

    private var sorted: [PlanPreset] {
        PlanPreset.all.sorted { lhs, rhs in
            let l = lhs.suits.contains(experience) ? 0 : 1
            let r = rhs.suits.contains(experience) ? 0 : 1
            return l == r ? lhs.dayCount < rhs.dayCount : l < r
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            variantPicker
            ForEach(sorted) { preset in
                row(preset)
            }
        }
    }

    /// The same split, loaded three ways.
    private var variantPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How it loads").overlineStyle().padding(.horizontal, 4)
            HStack(spacing: 8) {
                ForEach(PlanPreset.Variant.allCases) { option in
                    GlassChip(title: option.displayName, isSelected: variant == option) {
                        withAnimation(Theme.Motion.snappy) { variant = option }
                    }
                }
                Spacer(minLength: 0)
            }
            Text(variant.blurb)
                .font(.captionM)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.bottom, 4)
    }

    private func row(_ preset: PlanPreset) -> some View {
        let isSelected = preset.id == selection?.id

        return Button {
            Haptics.selection()
            withAnimation(Theme.Motion.snappy) { selection = preset }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21))
                    .foregroundStyle(isSelected ? Theme.Palette.violet : Color.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(preset.name).font(.titleS)
                        Text("\(preset.dayCount)×")
                            .font(.system(size: 11, weight: .bold))
                            .monospacedDigit()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.Palette.violet.opacity(0.22)))
                            .foregroundStyle(Theme.Palette.violet)
                    }
                    Text(preset.subtitle)
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                    Text(preset.note)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                isSelected ? .regular.tint(Theme.Palette.violet.opacity(0.3)) : .regular,
                in: .rect(cornerRadius: Theme.Radius.row)
            )
            .contentShape(.rect(cornerRadius: Theme.Radius.row))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - As a sheet

/// Picking a ready-made plan from the Plan screen.
struct PlanPresetSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    /// Called with the plan that was built, so the caller can select it.
    var onBuilt: (Plan) -> Void = { _ in }

    @State private var selection: PlanPreset?
    @State private var variant: PlanPreset.Variant = .balanced

    private var experience: ExperienceLevel { profiles.first?.experience ?? .beginner }

    var body: some View {
        ScrollView {
            PlanPresetList(experience: experience, selection: $selection, variant: $variant)
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            Button("Use this plan") { build() }
                .buttonStyle(.glassProminent)
                .disabled(selection == nil)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, 10)
        }
        .navigationTitle("Ready-made plans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .task {
            guard selection == nil else { return }
            selection = PlanPreset.all.first { $0.suits.contains(experience) } ?? PlanPreset.all.first
            variant = PlanPreset.Variant.suggested(for: experience)
        }
    }

    private func build() {
        guard let selection else { return }
        let plan = selection.build(in: context, variant: variant)
        try? context.save()
        Haptics.play(.success)
        onBuilt(plan)
        dismiss()
    }
}
