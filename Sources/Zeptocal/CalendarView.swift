import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: MarkStore
    @State private var visibleMonth = Date()       // any date within the shown month
    @State private var editingDay: Date? = nil      // day whose mark is being edited
    @State private var editingYear = false          // year field is open for typing
    @State private var yearText = ""
    @FocusState private var yearFieldFocused: Bool
    private let cal = Calendar.current
    private let weekColor = Color.orange            // week-number accent

    var body: some View {
        Group {
            if let editingDay {
                MarkEditor(day: editingDay) { self.editingDay = nil }
            } else {
                calendar
            }
        }
    }

    private var calendar: some View {
        VStack(spacing: 10) {
            header
            weekdayHeader
            grid
            if let countdownText {
                Divider()
                Text(countdownText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            footer
        }
        .padding(12)
        .frame(width: 260)
    }

    // MARK: Header (month + typable year + navigation)

    private var header: some View {
        HStack {
            navButton("chevron.left.2") { shiftYear(-1) }
            navButton("chevron.left") { shiftMonth(-1) }
            Spacer()
            HStack(spacing: 5) {
                Text(monthName(visibleMonth))
                    .font(.headline)
                yearControl
            }
            Spacer()
            navButton("chevron.right") { shiftMonth(1) }
            navButton("chevron.right.2") { shiftYear(1) }
        }
    }

    /// Click the year to type a new one; Return commits, Esc cancels.
    private var yearControl: some View {
        Group {
            if editingYear {
                TextField("", text: $yearText)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .frame(width: 52)
                    .focused($yearFieldFocused)
                    .onAppear { yearFieldFocused = true }
                    .onSubmit(commitYear)
                    .onExitCommand { editingYear = false }
            } else {
                Button(yearString(visibleMonth)) {
                    yearText = yearString(visibleMonth)
                    editingYear = true
                }
                .buttonStyle(.plain)
            }
        }
        .font(.headline.monospacedDigit())
    }

    private func commitYear() {
        var comps = cal.dateComponents([.year, .month, .day], from: visibleMonth)
        if let y = Int(yearText.trimmingCharacters(in: .whitespaces)) {
            comps.year = y
            if let d = cal.date(from: comps) { visibleMonth = d }
        }
        editingYear = false
    }

    private func navButton(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
        }
        .buttonStyle(.borderless)
    }

    // MARK: Weekday column headers (with the week-number column label)

    private var weekdayHeader: some View {
        HStack(spacing: 2) {
            Text("wk")
                .font(.caption2)
                .foregroundStyle(weekColor.opacity(0.75))
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
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(weekColor)
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
        let mark = store.mark(on: day, cal: cal)
        let fg: AnyShapeStyle = {
            if let mark, mark.filled { return AnyShapeStyle(.white) }
            if isToday, mark == nil { return AnyShapeStyle(.white) }
            return inMonth ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary)
        }()
        return Button {
            editingDay = day
        } label: {
            Text("\(cal.component(.day, from: day))")
                .font(.callout)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 24)
                .background { markBackground(mark: mark, isToday: isToday).padding(1.5) }
                .foregroundStyle(fg)
        }
        .buttonStyle(.plain)
    }

    /// Draws the day's mark (shape + fill/outline + color), plus a today ring on top.
    @ViewBuilder
    private func markBackground(mark: DateMark?, isToday: Bool) -> some View {
        ZStack {
            if let mark {
                shapeView(mark.shape, filled: mark.filled, color: Color(hex: mark.colorHex))
            } else if isToday {
                Circle().fill(Color.accentColor)
            }
            if isToday, let mark {
                shapeView(mark.shape, filled: false, color: .accentColor)
            }
        }
    }

    @ViewBuilder
    private func shapeView(_ shape: MarkShape, filled: Bool, color: Color) -> some View {
        switch shape {
        case .circle:
            if filled { Circle().fill(color) }
            else { Circle().strokeBorder(color, lineWidth: 1.5) }
        case .roundedRect:
            if filled { RoundedRectangle(cornerRadius: 5).fill(color) }
            else { RoundedRectangle(cornerRadius: 5).strokeBorder(color, lineWidth: 1.5) }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Button("Today") {
                visibleMonth = Date()
            }
            .font(.caption)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// "34 days until Mom's Birthday" for the soonest upcoming mark, if any.
    private var countdownText: String? {
        guard let (mark, date) = store.nextCountdown(cal: cal) else { return nil }
        let today = cal.startOfDay(for: Date())
        let days = cal.dateComponents([.day], from: today, to: date).day ?? 0
        let name = mark.label.isEmpty ? "marked date" : mark.label
        switch days {
        case 0:  return "\(name) is today"
        case 1:  return "1 day until \(name)"
        default: return "\(days) days until \(name)"
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

    private func monthName(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMM")
        return f.string(from: date)
    }

    private func yearString(_ date: Date) -> String {
        "\(cal.component(.year, from: date))"
    }
}
