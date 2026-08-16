//
//  PlanEditorView.swift
//  Gym Traker
//
//  Build a plan: name it, decide which weekday runs which template, then fill
//  each template with a numbered exercise list.
//

import SwiftUI
import SwiftData

struct PlanEditorView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [Plan]

    @State private var selectedLetter: String?
    @State private var showingPicker = false
    @State private var editingItem: PlanItem?
    @State private var renamingDay: PlanDay?
    /// Cleared whenever the plan changes, so a shared PDF is never stale.
    @State private var pdfURL: URL?

    private var plan: Plan? { plans.first(where: \.isActive) ?? plans.first }
    private var units: Units { Store.units(in: context) }

    private var selectedDay: PlanDay? {
        guard let plan else { return nil }
        if let letter = selectedLetter, let day = plan.day(withLetter: letter) { return day }
        return plan.orderedDays.first
    }

    var body: some View {
        ZStack {
            if let plan {
                content(plan)
            } else {
                emptyState
            }
        }
        .auroraVariant(.plan)
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let plan {
                ToolbarItem(placement: .primaryAction) {
                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            pdfURL = try? PlanPDF.write(plan: plan, profile: Store.profile(in: context))
                            Haptics.success()
                        } label: {
                            Label("Export PDF", systemImage: "doc.richtext")
                        }
                    }
                }
            }
        }
        .onChange(of: selectedLetter) { _, _ in pdfURL = nil }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                LibraryView(mode: .picker) { exercise in
                    append(exercise)
                }
            }
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                PlanItemEditor(item: item, units: units) {
                    if let day = item.day { remove(item, from: day) }
                }
            }
            .presentationDetents([.large])
        }
        .alert("Rename day", isPresented: Binding(
            get: { renamingDay != nil },
            set: { if !$0 { renamingDay = nil } }
        )) {
            RenameDayFields(day: renamingDay) { renamingDay = nil }
        }
    }

    // MARK: - Content

    private func content(_ plan: Plan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                planName(plan).entryTransition(0)
                schedule(plan).entryTransition(1)
                dayTabs(plan).entryTransition(2)
                exerciseList.entryTransition(3)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 40)
        }
    }

    private func planName(_ plan: Plan) -> some View {
        GlassSection(title: "Plan name") {
            TextField("My plan", text: Binding(
                get: { plan.name },
                set: { plan.name = $0 }
            ))
            .font(.titleL)
            .textInputAutocapitalization(.words)
        }
    }

    private func schedule(_ plan: Plan) -> some View {
        GlassSection(title: "Weekly schedule") {
            VStack(alignment: .leading, spacing: 10) {
                WeekScheduleGrid(
                    letters: plan.orderedDays.map(\.letter),
                    assignments: plan.weekAssignmentsRaw
                ) { index in
                    plan.weekAssignmentsRaw = plan.weekAssignmentsRaw.cycled(
                        at: index,
                        letters: plan.orderedDays.map(\.letter)
                    )
                    try? context.save()
                }
                Text("Tap a day to cycle through your templates. The same letter can sit on several days.")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dayTabs(_ plan: Plan) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(plan.orderedDays) { day in
                    Button {
                        Haptics.selection()
                        withAnimation(Theme.Motion.spring) { selectedLetter = day.letter }
                    } label: {
                        HStack(spacing: 6) {
                            Text(day.letter)
                                .font(.system(size: 13, weight: .bold))
                            Text(day.title)
                                .font(.captionM)
                        }
                        .foregroundStyle(day.letter == selectedDay?.letter ? Color.white : Color.secondary)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .glassEffect(
                            day.letter == selectedDay?.letter
                                ? .regular.tint(Theme.Palette.violet.opacity(0.75))
                                : .regular,
                            in: .rect(cornerRadius: Theme.Radius.chip)
                        )
                    }
                    .buttonStyle(.pressable)
                    .contextMenu {
                        Button("Rename") { renamingDay = day }
                        Button("Delete day", role: .destructive) { deleteDay(day, from: plan) }
                    }
                }

                Button {
                    addDay(to: plan)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 38)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Theme.Radius.chip))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Add day template")
            }
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private var exerciseList: some View {
        if let day = selectedDay {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(day.letter) · \(day.title)").overlineStyle()
                    Spacer()
                    Text("\(day.orderedItems.count) exercises · \(day.estimatedMinutes) min")
                        .font(.captionM)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                if day.orderedItems.isEmpty {
                    GlassCard {
                        Text("No exercises yet. Add the first one from your library.")
                            .font(.bodyS)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(day.orderedItems) { item in
                        // The context menu sits on the row, not on the button.
                        // Attached to the button it competed with the tap and
                        // the long press only registered some of the time.
                        PlanItemRow(item: item, units: units)
                            .contentShape(.rect(cornerRadius: Theme.Radius.row))
                            .onTapGesture { editingItem = item }
                            .contextMenu {
                                Button {
                                    move(item, in: day, by: -1)
                                } label: { Label("Move up", systemImage: "arrow.up") }
                                Button {
                                    move(item, in: day, by: 1)
                                } label: { Label("Move down", systemImage: "arrow.down") }
                                Divider()
                                Button(role: .destructive) {
                                    remove(item, from: day)
                                } label: { Label("Remove", systemImage: "trash") }
                            }
                    }
                }

                Button {
                    showingPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add exercise from library")
                    }
                    .font(.bodyM)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .padding(.top, 4)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No plan yet").font(.titleL)
            Button("Create a plan") { createPlan() }
                .buttonStyle(.glassProminent)
        }
    }

    // MARK: - Mutations

    private func createPlan() {
        let plan = Plan(name: "My plan")
        context.insert(plan)
        let day = PlanDay(letter: "A", title: "Day A", order: 0)
        day.plan = plan
        context.insert(day)
        plan.weekAssignmentsRaw = ["A", "", "", "", "", "", ""]
        try? context.save()
        selectedLetter = "A"
    }

    private func addDay(to plan: Plan) {
        let letter = plan.nextLetter
        let day = PlanDay(letter: letter, title: "Day \(letter)", order: plan.orderedDays.count)
        day.plan = plan
        context.insert(day)
        try? context.save()
        Haptics.medium()
        withAnimation(Theme.Motion.spring) { selectedLetter = letter }
    }

    private func deleteDay(_ day: PlanDay, from plan: Plan) {
        // The registry keeps its own copy of every change, so removing the
        // template does not erase the history.
        for item in day.orderedItems {
            Registry.exerciseRemoved(
                exerciseID: item.exerciseID,
                exerciseName: item.exerciseName,
                dayTitle: day.title,
                in: context
            )
        }
        let letter = day.letter
        plan.weekAssignmentsRaw = plan.weekAssignmentsRaw.map { $0 == letter ? "" : $0 }
        context.delete(day)
        try? context.save()
        selectedLetter = plan.orderedDays.first?.letter
    }

    private func append(_ exercise: Exercise) {
        guard let day = selectedDay else { return }
        let item = PlanItem(
            order: day.orderedItems.count + 1,
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            targetSets: [SetTarget(reps: 10), SetTarget(reps: 10), SetTarget(reps: 10)],
            workingWeightKg: exercise.equipment == .bodyweight ? 0 : 20,
            stepKg: exercise.defaultStepKg,
            restSeconds: 90
        )
        item.day = day
        context.insert(item)
        Registry.exerciseAdded(
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            dayTitle: day.title,
            in: context
        )
        try? context.save()
        Haptics.success()
    }

    private func remove(_ item: PlanItem, from day: PlanDay) {
        Registry.exerciseRemoved(
            exerciseID: item.exerciseID,
            exerciseName: item.exerciseName,
            dayTitle: day.title,
            in: context
        )
        context.delete(item)
        try? context.save()
        withAnimation(Theme.Motion.spring) { day.renumber() }
        try? context.save()
    }

    private func move(_ item: PlanItem, in day: PlanDay, by offset: Int) {
        var items = day.orderedItems
        guard let index = items.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) else { return }
        let target = index + offset
        guard items.indices.contains(target) else { return }
        items.swapAt(index, target)
        withAnimation(Theme.Motion.spring) {
            for (position, entry) in items.enumerated() { entry.order = position + 1 }
        }
        try? context.save()
        Haptics.light()
    }
}

// MARK: - Row

struct PlanItemRow: View {
    @Environment(\.colorScheme) private var scheme
    let item: PlanItem
    let units: Units

    var body: some View {
        HStack(spacing: 12) {
            Text("\(item.order)")
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.Palette.violet.opacity(0.25)))
                .foregroundStyle(Theme.Palette.violet)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.exerciseName)
                    .font(.titleS)
                    .lineLimit(1)
                Text("\(item.schemeSummary) · \(UnitFormatter.weight(item.workingWeightKg, in: units))")
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Text(UnitFormatter.rest(item.restSeconds))
                    .font(.captionM)
                    .foregroundStyle(.secondary)
                if item.progressionArmed {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Palette.increase)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.row))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                .strokeBorder(Theme.Palette.stroke(scheme), lineWidth: 1)
        }
    }
}

// MARK: - Rename fields

private struct RenameDayFields: View {
    let day: PlanDay?
    let onDone: () -> Void
    @State private var title = ""

    var body: some View {
        TextField("Push", text: $title)
            .onAppear { title = day?.title ?? "" }
        Button("Save") {
            day?.title = title
            onDone()
        }
        Button("Cancel", role: .cancel) { onDone() }
    }
}

#Preview {
    NavigationStack { PlanEditorView() }
}
