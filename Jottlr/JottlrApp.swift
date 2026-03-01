import SwiftUI
import SwiftData
import KeyboardShortcuts

@main
struct JottlrApp: App {
    @State private var editorViewModel = EditorViewModel()

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

        Window("Jottlr Editor", id: "editor") {
            EditorView(viewModel: editorViewModel)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate()
                }
                .onDisappear {
                    editorViewModel.saveCurrentFile()
                    NSApp.setActivationPolicy(.accessory)
                }
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 900, height: 700)
        .defaultPosition(.center)
    }

    init() {
        KeyboardShortcuts.onKeyUp(for: .quickCapture) {
            print("Hotkey pressed!")
        }
    }
}
