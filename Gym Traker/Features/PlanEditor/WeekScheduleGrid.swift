//
//  WeekScheduleGrid.swift
//  Gym Traker
//
//  Seven tappable day cells. Each tap cycles Rest → A → B → C → … → Rest, and
//  a letter is free to appear on several days — repeating a template within the
//  week is the normal case, not an edge case.
//

import SwiftUI

struct WeekScheduleGrid: View {
    @Environment(\.colorScheme) private var scheme

    let letters: [String]                 // available day-template letters
    let assignments: [String]             // 7 entries, "" means rest
    var highlightToday: Bool = true
    let onCycle: (Int) -> Void

    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let dayIndices = [0, 1, 2, 3, 4, 5, 6]
    private var todayIndex: Int { Plan.mondayBasedIndex(for: .now) }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(dayIndices, id: \.self) { index in
                let letter = assignments.indices.contains(index) ? assignments[index] : ""
                let isToday = highlightToday && index == todayIndex

                Button {
                    Haptics.selection()
                    withAnimation(Theme.Motion.spring) { onCycle(index) }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayNames[index])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isToday ? Theme.Palette.violet : Color.secondary)

                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(letter.isEmpty
                                      ? Theme.Palette.track(scheme)
                                      : Theme.Palette.violet.opacity(0.85))
                            Text(letter.isEmpty ? "—" : letter)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(letter.isEmpty ? Color.secondary : Color.white)
                                .contentTransition(.opacity)
                        }
                        .frame(height: 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .overlay {
                        if isToday {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Theme.Palette.violet.opacity(0.6), lineWidth: 1.5)
                        }
                    }
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("\(dayNames[index]): \(letter.isEmpty ? "rest" : "template \(letter)")")
                .accessibilityHint("Tap to change")
            }
        }
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
