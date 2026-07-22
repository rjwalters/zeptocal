import SwiftUI

@main
struct ZeptocalApp: App {
    @StateObject private var store = MarkStore()

    var body: some Scene {
        MenuBarExtra {
            CalendarView()
                .environmentObject(store)
        } label: {
            Image(systemName: "calendar")
        }
        .menuBarExtraStyle(.window)
    }
}
