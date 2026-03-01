import SwiftUI
import KeyboardShortcuts

@main
struct JottlrApp: App {
    var body: some Scene {
        MenuBarExtra("Jottlr", systemImage: "pencil.and.scribble") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        KeyboardShortcuts.onKeyUp(for: .quickCapture) {
            print("Hotkey pressed!")
        }
    }
}
