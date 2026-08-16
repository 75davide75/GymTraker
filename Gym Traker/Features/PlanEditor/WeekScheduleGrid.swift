//
//  WeekScheduleGrid.swift
//  Gym Traker
//
//  Seven tappable day cells. Each tap cycles Rest → A → B → C → … → Rest, and
//  a letter is free to appear on several days — repeating a template within the
//  week is the normal case, not an edge case.
//
//  Styling follows the prototype: today carries the violet gradient, days with
//  a template sit on plain glass, rest days are just an outline.
//

import SwiftUI

struct WeekScheduleGrid: View {
    @Environment(\.colorScheme) private var scheme

    let letters: [String]                 // available day-template letters
    let assignments: [String]             // 7 entries, "" means rest
    var highlightToday: Bool = true
    var isInteractive: Bool = true
    let onCycle: (Int) -> Void

    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let dayIndices = [0, 1, 2, 3, 4, 5, 6]
    private var todayIndex: Int { Plan.mondayBasedIndex(for: .now) }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(dayIndices, id: \.self) { index in
                cell(index)
            }
        }
        // On Home the strip is a read-only summary, so it reads as one thing
        // rather than seven buttons — which also stops it answering to the
        // same queries as the real editor on the Plan screen.
        .accessibilityElement(children: isInteractive ? .contain : .ignore)
        .accessibilityLabel(isInteractive ? "" : summaryLabel)
    }

    private var summaryLabel: String {
        let assigned = dayIndices.compactMap { index -> String? in
            let letter = assignments.indices.contains(index) ? assignments[index] : ""
            return letter.isEmpty ? nil : "\(dayNames[index]) \(letter)"
        }
        return assigned.isEmpty ? "No sessions scheduled this week" : "This week: " + assigned.joined(separator: ", ")
    }

    private func cell(_ index: Int) -> some View {
        let letter = assignments.indices.contains(index) ? assignments[index] : ""
        let hasTemplate = !letter.isEmpty
        let isToday = highlightToday && index == todayIndex

        return Button {
            guard isInteractive else { return }
            Haptics.selection()
            withAnimation(Theme.Motion.spring) { onCycle(index) }
        } label: {
            VStack(spacing: 5) {
                Text(dayNames[index])
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(isToday ? Color.white.opacity(0.8) : Color.secondary)

                Text(hasTemplate ? letter : "—")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tagColor(isToday: isToday, hasTemplate: hasTemplate))
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 9)
            .padding(.bottom, 10)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background(isToday: isToday, hasTemplate: hasTemplate))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(border(isToday: isToday, hasTemplate: hasTemplate), lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.pressable)
        .disabled(!isInteractive)
        // The read-only copy on Home is decoration: the container already
        // carries a summary label, so the cells stay out of the tree entirely.
        .accessibilityHidden(!isInteractive)
        .accessibilityLabel("\(dayNames[index]): \(hasTemplate ? "template \(letter)" : "rest")")
        .accessibilityHint(isInteractive ? "Tap to change" : "")
    }

    // MARK: - Styling

    private func background(isToday: Bool, hasTemplate: Bool) -> AnyShapeStyle {
        if isToday {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Theme.Palette.violet.opacity(0.85), Theme.Palette.violetDeep.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        if hasTemplate {
            return AnyShapeStyle(scheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
        }
        return AnyShapeStyle(Color.clear)
    }

    private func border(isToday: Bool, hasTemplate: Bool) -> Color {
        if isToday { return .clear }
        return hasTemplate ? Theme.Palette.stroke(scheme) : Theme.Palette.separator(scheme)
    }

    private func tagColor(isToday: Bool, hasTemplate: Bool) -> Color {
        if isToday { return .white }
        return hasTemplate ? .primary : .secondary
    }
}

extension Array where Element == String {
    /// Rest → A → B → … → last letter → Rest.
    func cycled(at index: Int, letters: [String]) -> [String] {
        guard indices.contains(index) else { return self }
        var copy = self
        let current = copy[index]

        if current.isEmpty {
            copy[index] = letters.first ?? ""
        } else if let position = letters.firstIndex(of: current) {
            copy[index] = position + 1 < letters.count ? letters[position + 1] : ""
        } else {
            copy[index] = ""
        }
        return copy
    }
}
