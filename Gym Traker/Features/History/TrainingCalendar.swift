//
//  TrainingCalendar.swift
//  Gym Traker
//
//  Every month you have trained, scrolling back through the years.
//
//  A list of sessions answers "what did I do that day". It answers "how often
//  am I actually going" badly, because a gap in a list looks like the end of
//  the list. A month grid makes the gaps the same size as the sessions, which
//  is the only honest way to show consistency.
//

import SwiftUI

struct TrainingCalendar: View {
    /// The days that have a finished session, and how many sets were logged.
    let days: [Date: Int]
    /// Total volume per day, for the tooltip line under the grid.
    let volume: [Date: Double]
    /// Opening the workout that day is what a day cell is for.
    var onSelectDay: (Date) -> Void = { _ in }

    private var calendar: Calendar { Calendar.current }

    /// Every month back to 1999, newest first.
    ///
    /// It used to start at the first logged session, which meant a new install
    /// showed exactly one month and there was nowhere to scroll to. The point
    /// of a calendar is that the empty years are visible too — and a workout
    /// imported from Health can be older than anything logged here.
    private var months: [Date] {
        let today = calendar.startOfDay(for: .now)
        let thisMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today

        var floor = calendar.date(from: DateComponents(year: 1999, month: 1, day: 1)) ?? thisMonth
        if let earliest = days.keys.min(),
           let earliestMonth = calendar.dateInterval(of: .month, for: earliest)?.start,
           earliestMonth < floor {
            floor = earliestMonth
        }

        var result: [Date] = []
        var cursor = thisMonth
        while cursor >= floor {
            result.append(cursor)
            guard let previous = calendar.date(byAdding: .month, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return result
    }

    /// A card per month rather than one card holding three hundred of them.
    ///
    /// Every month back to 1999 is a lot of grids, and a single self-sizing
    /// card would have to build all of them to know how tall it is. One card
    /// each, in the caller's lazy stack, builds only what is on screen.
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("\(days.count) day\(days.count == 1 ? "" : "s") trained in total.")
                .font(.captionM)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ForEach(months, id: \.self) { month in
                GlassCard(radius: Theme.Radius.row, padding: 14) {
                    monthGrid(month)
                }
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Monday first, whatever the locale's own first weekday is, because the
    /// plan's week is Monday-based everywhere else in the app.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return ["M", "T", "W", "T", "F", "S", "S"] }
        return Array(symbols[1...6]) + [symbols[0]]
    }

    private func monthGrid(_ month: Date) -> some View {
        let cells = self.cells(for: month)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                let trained = cells.compactMap { $0 }.count { days[$0] != nil }
                Text("\(trained) session\(trained == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            // Repeated per month, directly over the columns it names. One row
            // at the top of the card labelled the first month and then floated
            // above nothing.
            weekdayHeader

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 30)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let sets = days[day]
        let isToday = calendar.isDateInToday(day)

        return Button {
            guard sets != nil else { return }
            Haptics.play(.selection)
            onSelectDay(day)
        } label: {
            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 11, weight: sets != nil ? .bold : .medium))
                .monospacedDigit()
                .foregroundStyle(foreground(trained: sets != nil, isToday: isToday))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(sets != nil
                              ? Theme.Palette.violet.opacity(0.55)
                              : Color.secondary.opacity(0.08))
                }
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Theme.Palette.cyan, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.pressableSilent)
        .disabled(sets == nil)
        .accessibilityLabel(accessibilityLabel(day, sets: sets))
    }

    private func foreground(trained: Bool, isToday: Bool) -> Color {
        if trained { return .white }
        return isToday ? Theme.Palette.cyan : .secondary
    }

    private func accessibilityLabel(_ day: Date, sets: Int?) -> String {
        let date = day.formatted(date: .abbreviated, time: .omitted)
        guard let sets else { return "\(date), no session" }
        return "\(date), \(sets) sets logged"
    }

    /// A month's days, padded with nils so the first lands on its weekday.
    private func cells(for month: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }

        // Monday is column 0; `weekday` is 1 for Sunday.
        let firstWeekday = calendar.component(.weekday, from: month)
        let leading = (firstWeekday + 5) % 7

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in range {
            let day = calendar.date(byAdding: .day, value: offset - 1, to: month)
            cells.append(day.map { calendar.startOfDay(for: $0) })
        }
        return cells
    }
}
