import SwiftUI

struct EditorPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Editor", systemImage: "doc.text")
        } description: {
            Text("Coming soon")
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    EditorPlaceholderView()
}
