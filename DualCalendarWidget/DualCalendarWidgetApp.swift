import SwiftUI

@main
struct DualCalendarWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 680, height: 520)
    }
}
