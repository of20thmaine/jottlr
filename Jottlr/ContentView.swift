import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        QuickCaptureView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Jotting.self, inMemory: true)
}
