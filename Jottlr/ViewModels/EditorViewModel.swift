import Foundation
import SwiftUI

enum SaveStatus: Equatable {
    case idle
    case saved
}

@Observable
final class EditorViewModel {
    var rootNode: FileNode?
    var selectedFileURL: URL?
    var selectedDirectoryURL: URL?
    /// The URL currently highlighted in the sidebar. Bind the List directly to this.
    var sidebarSelection: URL?
    var documentText: String = ""
    var saveStatus: SaveStatus = .idle
    var expandedDirectories: Set<URL> = []

    /// The security-scoped directory URL currently being accessed.
    private var accessedDirectoryURL: URL?
    private let fileService = FileSystemService()

    private static let bookmarkKey = "directoryBookmark"

    /// Task handle for the debounced auto-save.
    private var autoSaveTask: Task<Void, Never>?

    /// The root directory URL currently loaded.
    var rootDirectoryURL: URL? {
        rootNode?.url
    }

    /// Opens a directory picker and scans the chosen folder.
    func openDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder containing your markdown files"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadDirectory(at: url, saveBookmark: true)
    }

    /// Loads a directory tree from a URL.
    func loadDirectory(at url: URL, saveBookmark: Bool) {
        // Release any previously accessed directory
        accessedDirectoryURL?.stopAccessingSecurityScopedResource()

        // Start accessing the new directory's security scope
        if url.startAccessingSecurityScopedResource() {
            accessedDirectoryURL = url
        }

        if saveBookmark {
            Self.saveBookmark(for: url)
        }

        rootNode = fileService.scanDirectory(at: url)
    }

    /// Restores the last opened directory from a persisted security-scoped bookmark.
    func restoreDirectory() {
        guard let url = Self.resolveBookmark() else { return }
        loadDirectory(at: url, saveBookmark: false)
    }

    /// Selects a file and loads its content. Ignores directories.
    func selectFile(at url: URL) {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return
        }
        guard url != selectedFileURL else { return }

        // Save the previous file before switching
        saveCurrentFile()

        selectedFileURL = url
        sidebarSelection = url
        saveStatus = .idle
        autoSaveTask?.cancel()
        do {
            documentText = try fileService.readFile(at: url)
        } catch {
            documentText = ""
        }
    }

    /// Saves the current document text to disk.
    func saveCurrentFile() {
        guard let url = selectedFileURL else { return }
        try? fileService.writeFile(documentText, to: url)
    }

    /// Triggers a debounced auto-save. Call this when document text changes.
    func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return // Cancelled
            }
            guard let self, let url = self.selectedFileURL else { return }
            try? self.fileService.writeFile(self.documentText, to: url)
            self.saveStatus = .saved
        }
    }

    /// Creates a new .md file in the selected directory, or the root directory if none is selected.
    func createNewFile(named filename: String) {
        guard let rootURL = rootDirectoryURL else { return }
        let parentURL = selectedDirectoryURL
            ?? selectedFileURL?.deletingLastPathComponent()
            ?? rootURL
        let name = filename.hasSuffix(".md") ? filename : "\(filename).md"
        let fileURL = parentURL.appendingPathComponent(name)

        guard !FileManager.default.fileExists(atPath: fileURL.path) else { return }

        try? fileService.writeFile("", to: fileURL)

        // Expand parent so the new file is visible, then refresh and select
        expandedDirectories.insert(parentURL)
        refreshTree()
        selectFile(at: fileURL)
    }

    /// Creates a new folder in the contextual parent directory.
    func createNewFolder(named name: String, in parentURL: URL? = nil) {
        guard let rootURL = rootDirectoryURL else { return }
        let parent = parentURL ?? selectedDirectoryURL ?? rootURL
        let folderURL = parent.appendingPathComponent(name)

        guard !FileManager.default.fileExists(atPath: folderURL.path) else { return }
        try? fileService.createDirectory(at: folderURL)

        // Expand parent so the new folder is visible
        expandedDirectories.insert(parent)
        refreshTree()
        selectedDirectoryURL = folderURL
        sidebarSelection = folderURL
    }

    /// Renames a file or directory.
    func renameItem(at url: URL, to newName: String) {
        guard let newURL = try? fileService.renameItem(at: url, to: newName) else { return }

        // If the renamed item was the selected file, update selection
        if url == selectedFileURL {
            selectedFileURL = newURL
        }
        // If it was the selected directory, update that too
        if url == selectedDirectoryURL {
            selectedDirectoryURL = newURL
        }
        if url == sidebarSelection {
            sidebarSelection = newURL
        }

        refreshTree()
    }

    /// Deletes a file or directory.
    func deleteItem(at url: URL) {
        guard (try? fileService.deleteItem(at: url)) != nil else { return }

        // Clear selection if the deleted item was selected
        if url == selectedFileURL {
            selectedFileURL = nil
            documentText = ""
            saveStatus = .idle
            autoSaveTask?.cancel()
        }
        if url == selectedDirectoryURL {
            selectedDirectoryURL = nil
        }
        if url == sidebarSelection {
            sidebarSelection = nil
        }

        refreshTree()
    }

    /// Rescans the root directory to pick up file system changes.
    func refreshTree() {
        guard let rootURL = rootDirectoryURL else { return }
        rootNode = fileService.scanDirectory(at: rootURL)
    }

    deinit {
        autoSaveTask?.cancel()
        accessedDirectoryURL?.stopAccessingSecurityScopedResource()
    }

    // MARK: - Bookmark Persistence

    private static func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        } catch {
            // Bookmark creation failed — directory won't restore on next launch
        }
    }

    private static func resolveBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                saveBookmark(for: url)
            }
            return url
        } catch {
            return nil
        }
    }
}
