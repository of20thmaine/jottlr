import SwiftUI

struct FileTreeView: View {
    @Bindable var viewModel: EditorViewModel
    @State private var listSelection: URL?

    var body: some View {
        Group {
            if let root = viewModel.rootNode, let children = root.children, !children.isEmpty {
                List(selection: $listSelection) {
                    OutlineGroup(children, children: \.children) { node in
                        FileNodeRow(node: node)
                            .tag(node.url)
                    }
                }
                .onChange(of: listSelection) { _, newURL in
                    guard let url = newURL, !url.hasDirectoryPath else { return }
                    viewModel.selectFile(at: url)
                }
            } else {
                ContentUnavailableView {
                    Label("No Folder Open", systemImage: "folder")
                } description: {
                    Text("Open a folder to browse your markdown files.")
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.openDirectory()
                } label: {
                    Label("Open Folder", systemImage: "folder.badge.plus")
                }
                .help("Open Folder")
            }
        }
    }
}

private struct FileNodeRow: View {
    let node: FileNode

    var body: some View {
        Label {
            Text(node.name)
        } icon: {
            Image(systemName: node.isDirectory ? "folder" : "doc.text")
                .foregroundStyle(node.isDirectory ? .secondary : .primary)
        }
    }
}
