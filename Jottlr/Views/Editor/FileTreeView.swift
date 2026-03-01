import SwiftUI

struct FileTreeView: View {
    @Bindable var viewModel: EditorViewModel
    @State private var showNewFolderSheet = false
    @State private var newFolderName = ""
    @State private var newFolderParentURL: URL?
    @State private var renamingURL: URL?
    @State private var renameText = ""
    @State private var itemToDelete: URL?
    @State private var showDeleteConfirmation = false

    /// Whether the tree contains any actual markdown files (not just directories).
    private var hasMarkdownFiles: Bool {
        guard let children = viewModel.rootNode?.children else { return false }
        return children.contains(where: { containsFile($0) })
    }

    private func containsFile(_ node: FileNode) -> Bool {
        if !node.isDirectory { return true }
        return node.children?.contains(where: { containsFile($0) }) ?? false
    }

    /// Flattens the tree into a list of (node, depth) pairs, respecting expansion state.
    private var flattenedNodes: [(node: FileNode, depth: Int)] {
        guard let root = viewModel.rootNode, let children = root.children else { return [] }
        var result: [(FileNode, Int)] = []
        func flatten(_ nodes: [FileNode], depth: Int) {
            for node in nodes {
                result.append((node, depth))
                if node.isDirectory,
                   viewModel.expandedDirectories.contains(node.url),
                   let children = node.children {
                    flatten(children, depth: depth + 1)
                }
            }
        }
        flatten(children, depth: 0)
        return result
    }

    var body: some View {
        List(selection: $viewModel.sidebarSelection) {
            ForEach(flattenedNodes, id: \.node.url) { item in
                FileNodeRow(
                    node: item.node,
                    depth: item.depth,
                    isExpanded: item.node.isDirectory && viewModel.expandedDirectories.contains(item.node.url),
                    renamingURL: $renamingURL,
                    renameText: $renameText,
                    viewModel: viewModel
                )
                .tag(item.node.url)
                .contextMenu {
                    if item.node.isDirectory {
                        folderContextMenu(for: item.node)
                    } else {
                        fileContextMenu(for: item.node)
                    }
                }
            }
        }
        .contextMenu {
            if viewModel.rootNode != nil {
                emptyAreaContextMenu
            }
        }
        .overlay {
            if viewModel.rootNode == nil {
                ContentUnavailableView {
                    Label("No Folder Open", systemImage: "folder")
                } description: {
                    Text("Open a folder to browse your markdown files.")
                }
            } else if !hasMarkdownFiles {
                ContentUnavailableView {
                    Label("No Markdown Files", systemImage: "doc.text")
                } description: {
                    Text("Press ⌘N to create one.")
                }
            }
        }
        .onChange(of: viewModel.sidebarSelection) { _, newURL in
            guard let url = newURL else { return }
            let isDirectory = flattenedNodes.first(where: { $0.node.url == url })?.node.isDirectory ?? false
            if isDirectory {
                viewModel.selectedDirectoryURL = url
            } else {
                viewModel.selectedDirectoryURL = nil
                viewModel.selectFile(at: url)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    viewModel.openDirectory()
                } label: {
                    Label("Open Folder", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("Open Folder")
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationTitle(viewModel.rootNode?.name ?? "Jottlr")
        .sheet(isPresented: $showNewFolderSheet) {
            NewFolderSheet(folderName: $newFolderName) {
                viewModel.createNewFolder(named: newFolderName, in: newFolderParentURL)
                showNewFolderSheet = false
            }
        }
        .alert("Delete Item", isPresented: $showDeleteConfirmation, presenting: itemToDelete) { url in
            Button("Delete", role: .destructive) {
                viewModel.deleteItem(at: url)
                itemToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
        } message: { url in
            Text("Are you sure you want to delete \"\(url.lastPathComponent)\"? This cannot be undone.")
        }
    }

    // MARK: - Context Menus

    @ViewBuilder
    private func folderContextMenu(for node: FileNode) -> some View {
        Button {
            newFolderName = ""
            newFolderParentURL = node.url
            showNewFolderSheet = true
        } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }

        Button {
            viewModel.selectedDirectoryURL = node.url
            NotificationCenter.default.post(name: .showNewFileSheet, object: nil)
        } label: {
            Label("New File", systemImage: "doc.badge.plus")
        }

        Divider()

        Button {
            renamingURL = node.url
            renameText = node.name
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button(role: .destructive) {
            itemToDelete = node.url
            showDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }

        Divider()

        Button {
            NSWorkspace.shared.activateFileViewerSelecting([node.url])
        } label: {
            Label("Reveal in Finder", systemImage: "arrow.right.circle")
        }
    }

    @ViewBuilder
    private func fileContextMenu(for node: FileNode) -> some View {
        Button {
            renamingURL = node.url
            renameText = node.name
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button(role: .destructive) {
            itemToDelete = node.url
            showDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }

        Divider()

        Button {
            NSWorkspace.shared.activateFileViewerSelecting([node.url])
        } label: {
            Label("Reveal in Finder", systemImage: "arrow.right.circle")
        }
    }

    @ViewBuilder
    private var emptyAreaContextMenu: some View {
        Button {
            NotificationCenter.default.post(name: .showNewFileSheet, object: nil)
        } label: {
            Label("New File", systemImage: "doc.badge.plus")
        }

        Button {
            newFolderName = ""
            newFolderParentURL = nil
            showNewFolderSheet = true
        } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }
    }
}

// MARK: - Notification for New File Sheet

extension Notification.Name {
    static let showNewFileSheet = Notification.Name("showNewFileSheet")
}

// MARK: - File Node Row

private struct FileNodeRow: View {
    let node: FileNode
    let depth: Int
    let isExpanded: Bool
    @Binding var renamingURL: URL?
    @Binding var renameText: String
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Indentation
            if depth > 0 {
                Spacer()
                    .frame(width: CGFloat(depth) * 16)
            }

            // Disclosure chevron for directories
            if node.isDirectory {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isExpanded {
                            viewModel.expandedDirectories.remove(node.url)
                        } else {
                            viewModel.expandedDirectories.insert(node.url)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .rotationEffect(isExpanded ? .degrees(90) : .degrees(0))
                        .frame(width: 16)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 16)
            }

            // Icon and name
            Label {
                if renamingURL == node.url {
                    TextField("Name", text: $renameText)
                        .textFieldStyle(.plain)
                        .onSubmit { commitRename() }
                        .onExitCommand { renamingURL = nil }
                } else {
                    Text(node.name)
                }
            } icon: {
                Image(systemName: node.isDirectory ? "folder" : "doc.text")
                    .foregroundStyle(node.isDirectory ? .secondary : .primary)
            }
        }
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != node.name else {
            renamingURL = nil
            return
        }
        viewModel.renameItem(at: node.url, to: trimmed)
        renamingURL = nil
    }
}

// MARK: - New Folder Sheet

private struct NewFolderSheet: View {
    @Binding var folderName: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("New Folder")
                .font(.headline)

            TextField("Folder name", text: $folderName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    guard !folderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onCreate()
                }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    guard !folderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onCreate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
