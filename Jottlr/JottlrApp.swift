import SwiftUI
import SwiftData
import KeyboardShortcuts

@main
struct JottlrApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Jotting.self,
            JottingCopy.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("Jottlr", systemImage: "pencil.and.scribble") {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        KeyboardShortcuts.onKeyUp(for: .quickCapture) {
            print("Hotkey pressed!")
        }
    }
}
