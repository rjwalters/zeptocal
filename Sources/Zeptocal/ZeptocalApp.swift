import SwiftUI

@main
struct ZeptocalApp: App {
    @StateObject private var clock = Clock()
    @StateObject private var store = MarkStore()

    var body: some Scene {
        MenuBarExtra {
            CalendarView()
                .environmentObject(store)
        } label: {
            Text(clock.barTitle)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Drives the menu bar title and rolls it over at midnight.
final class Clock: ObservableObject, @unchecked Sendable {
    @Published var today = Date()
    private var timer: Timer?

    init() {
        scheduleMidnightTick()
    }

    var barTitle: String {
        // Four-digit year, to sit next to the system clock (e.g. "2026").
        "\(Calendar.current.component(.year, from: today))"
    }

    private func scheduleMidnightTick() {
        let cal = Calendar.current
        let nextMidnight = cal.nextDate(after: Date(),
                                        matching: DateComponents(hour: 0, minute: 0, second: 1),
                                        matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
        timer = Timer(fire: nextMidnight, interval: 86_400, repeats: true) { [weak self] _ in
            self?.today = Date()
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }
}
