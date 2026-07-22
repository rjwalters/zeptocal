import SwiftUI

struct CalendarView: View {
    @State private var visibleMonth = Date()       // any date within the shown month
    @State private var selected: Date? = nil        // day the user clicked
    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 10) {
            header
            selectionLine
            weekdayHeader
            grid
            footer
        }
        .padding(12)
        .frame(width: 260)
    }

    // MARK: Header (month/year + navigation)

    private var header: some View {
        HStack {
            navButton("chevron.left.2") { shiftYear(-1) }
            navButton("chevron.left") { shiftMonth(-1) }
            Spacer()
            Text(monthTitle(visibleMonth))
                .font(.headline)
                .monospacedDigit()
            Spacer()
            navButton("chevron.right") { shiftMonth(1) }
            navButton("chevron.right.2") { shiftYear(1) }
        }
    }

    private func navButton(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
        }
        .buttonStyle(.borderless)
    }

    // MARK: Selected-day readout — "what day of the week was it"

    private var selectionLine: some View {
        Group {
            if let selected {
                Text(fullWeekday(selected))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(fullWeekday(Date()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Weekday column headers (with a spacer over the week-number column)

    private var weekdayHeader: some View {
        HStack(spacing: 2) {
            Text("wk")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 22)
            ForEach(orderedWeekdaySymbols, id: \.self) { s in
                Text(s)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Month grid

    private var grid: some View {
        VStack(spacing: 2) {
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 2) {
                    Text("\(weekNumber(for: week[0]))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 22)
                    ForEach(week, id: \.self) { day in
                        dayCell(day)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = cal.isDate(day, equalTo: visibleMonth, toGranularity: .month)
        let isToday = cal.isDateInToday(day)
        let isSelected = selected.map { cal.isDate($0, inSameDayAs: day) } ?? false
        let fg: AnyShapeStyle = isToday ? AnyShapeStyle(.white)
            : inMonth ? AnyShapeStyle(.primary)
            : AnyShapeStyle(.tertiary)
        return Button {
            selected = day
        } label: {
            Text("\(cal.component(.day, from: day))")
                .font(.callout)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 24)
                .background {
                    if isToday {
                        Circle().fill(Color.accentColor)
                    } else if isSelected {
                        Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
                    }
                }
                .foregroundStyle(fg)
        }
        .buttonStyle(.plain)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Button("Today") {
                visibleMonth = Date()
                selected = nil
            }
            .font(.caption)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Date math

    /// 6 weeks × 7 days covering the visible month, padded with adjacent-month days.
    private var weeks: [[Date]] {
        guard let monthInterval = cal.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstOfMonth = monthInterval.start
        let weekday = cal.component(.weekday, from: firstOfMonth)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        guard let gridStart = cal.date(byAdding: .day, value: -offset, to: firstOfMonth) else { return [] }

        return (0..<6).map { row in
            (0..<7).compactMap { col in
                cal.date(byAdding: .day, value: row * 7 + col, to: gridStart)
            }
        }
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols  // ["S","M","T",...] Sunday-first
        let start = cal.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private func weekNumber(for day: Date) -> Int {
        cal.component(.weekOfYear, from: day)
    }

    private func shiftMonth(_ n: Int) {
        if let d = cal.date(byAdding: .month, value: n, to: visibleMonth) { visibleMonth = d }
    }

    private func shiftYear(_ n: Int) {
        if let d = cal.date(byAdding: .year, value: n, to: visibleMonth) { visibleMonth = d }
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: date)
    }

    private func fullWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, yyyy")
        return f.string(from: date)
    }
}
