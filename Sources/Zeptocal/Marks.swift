import SwiftUI
import AppKit

// MARK: - Model

enum MarkRepeat: String, Codable, CaseIterable, Identifiable {
    case none, weekly, monthly, yearly
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "Once"
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .yearly: return "Year"
        }
    }
}

enum MarkShape: String, Codable, CaseIterable, Identifiable {
    case circle, roundedRect
    var id: String { rawValue }
}

/// A user-defined mark anchored to a calendar day (y/m/d, timezone-safe).
struct DateMark: Codable, Identifiable, Equatable {
    var id = UUID()
    var year: Int
    var month: Int
    var day: Int
    var label: String
    var repeatRule: MarkRepeat
    var shape: MarkShape
    var filled: Bool
    var colorHex: String

    /// Weekday (1–7) of the anchor date, for weekly repeats.
    func weekday(cal: Calendar) -> Int {
        let d = cal.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
        return cal.component(.weekday, from: d)
    }
}

// MARK: - Store (persisted to UserDefaults)

final class MarkStore: ObservableObject {
    @Published var marks: [DateMark] = [] { didSet { save() } }
    private let key = "zeptocal.marks.v1"

    init() { load() }

    /// The mark that should render on `date`, honoring repeat rules.
    func mark(on date: Date, cal: Calendar) -> DateMark? {
        let c = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let y = c.year, let m = c.month, let d = c.day, let wd = c.weekday else { return nil }
        return marks.first { mk in
            switch mk.repeatRule {
            case .none:    return mk.year == y && mk.month == m && mk.day == d
            case .weekly:  return mk.weekday(cal: cal) == wd
            case .monthly: return mk.day == d
            case .yearly:  return mk.month == m && mk.day == d
            }
        }
    }

    func upsert(_ mark: DateMark) {
        if let i = marks.firstIndex(where: { $0.id == mark.id }) { marks[i] = mark }
        else { marks.append(mark) }
    }

    func remove(id: UUID) { marks.removeAll { $0.id == id } }
    func clearAll() { marks.removeAll() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DateMark].self, from: data) else { return }
        marks = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(marks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Color <-> hex

extension Color {
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self = Color(red: Double((v >> 16) & 0xFF) / 255,
                     green: Double((v >> 8) & 0xFF) / 255,
                     blue: Double(v & 0xFF) / 255)
    }

    var hexString: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return String(format: "#%02X%02X%02X",
                      Int(round(ns.redComponent * 255)),
                      Int(round(ns.greenComponent * 255)),
                      Int(round(ns.blueComponent * 255)))
    }
}
