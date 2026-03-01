import Foundation
import SwiftUI

@Observable
final class EditorViewModel {
    var rootNode: FileNode?
    var selectedFileURL: URL?
    var documentText: String = ""

    /// The security-scoped directory URL currently being accessed.
    private var accessedDirectoryURL: URL?
    private let fileService = FileSystemService()

    private static let bookmarkKey = "directoryBookmark"

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

    /// Selects a file and loads its content.
    func selectFile(at url: URL) {
        guard url != selectedFileURL else { return }

        // Save the previous file before switching
        saveCurrentFile()

        selectedFileURL = url
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

    deinit {
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
                // Re-save a fresh bookmark
                saveBookmark(for: url)
            }
            return url
        } catch {
            return nil
        }
    }
}
