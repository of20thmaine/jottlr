import SwiftUI

struct EditorView: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        NavigationSplitView {
            FileTreeView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 350)
        } detail: {
            if viewModel.selectedFileURL != nil {
                TextEditor(text: $viewModel.documentText)
                    .font(.system(.body, design: .monospaced))
                    .navigationTitle(viewModel.selectedFileURL?.lastPathComponent ?? "")
            } else {
                ContentUnavailableView {
                    Label("No File Selected", systemImage: "doc.text")
                } description: {
                    Text("Select a markdown file from the sidebar to start editing.")
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            viewModel.restoreDirectory()
        }
    }
}

#Preview {
    EditorView(viewModel: EditorViewModel())
}
