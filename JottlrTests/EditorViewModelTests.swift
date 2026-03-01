import Foundation
import Testing
import SwiftData
@testable import Jottlr

@Suite("EditorViewModel Tests", .serialized)
@MainActor
struct EditorViewModelTests {
    private let fileManager = FileManager.default

    private func makeTempDir() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("JottlrEditorTests-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func cleanUp(_ url: URL) {
        try? fileManager.removeItem(at: url)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Jotting.self, JottingCopy.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Auto-save Debounce

    @Test func debounceCoalescesRapidEdits() async throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let fileURL = tempDir.appendingPathComponent("debounce.md")
        try "initial".write(to: fileURL, atomically: true, encoding: .utf8)

        let vm = EditorViewModel()
        vm.loadDirectory(at: tempDir, saveBookmark: false)
        vm.selectFile(at: fileURL)

        // Simulate rapid edits — each one resets the debounce timer
        vm.documentText = "edit 1"
        vm.scheduleAutoSave()
        try await Task.sleep(for: .milliseconds(500))

        vm.documentText = "edit 2"
        vm.scheduleAutoSave()
        try await Task.sleep(for: .milliseconds(500))

        vm.documentText = "edit 3"
        vm.scheduleAutoSave()

        // At this point, no save should have happened yet (each edit was < 2s apart)
        let contentBeforeDebounce = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(contentBeforeDebounce == "initial")

        // Wait for the debounce to fire (2s + buffer)
        try await Task.sleep(for: .seconds(2.5))

        // Only the final text should be on disk
        let contentAfterDebounce = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(contentAfterDebounce == "edit 3")
    }

    @Test func manualSaveWritesImmediately() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let fileURL = tempDir.appendingPathComponent("manual.md")
        try "original".write(to: fileURL, atomically: true, encoding: .utf8)

        let vm = EditorViewModel()
        vm.loadDirectory(at: tempDir, saveBookmark: false)
        vm.selectFile(at: fileURL)
        vm.documentText = "manually saved"
        vm.saveCurrentFile()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content == "manually saved")
    }

    // MARK: - JottingCopy Creation

    @Test func copyJottingCreatesRecord() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let jotting = Jotting(content: "Idea to copy")
        context.insert(jotting)
        try context.save()

        let filePath = "/Users/test/notes/ideas.md"
        let copy = JottingCopy(destinationFilePath: filePath, originalJotting: jotting)
        context.insert(copy)
        try context.save()

        let descriptor = FetchDescriptor<JottingCopy>()
        let copies = try context.fetch(descriptor)

        #expect(copies.count == 1)
        let fetched = try #require(copies.first)
        #expect(fetched.destinationFilePath == filePath)
        #expect(fetched.originalJotting?.content == "Idea to copy")
    }

    @Test func copyJottingRecordsCorrectFilePath() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let jotting1 = Jotting(content: "First idea")
        let jotting2 = Jotting(content: "Second idea")
        context.insert(jotting1)
        context.insert(jotting2)
        try context.save()

        let path1 = "/notes/project-a.md"
        let path2 = "/notes/project-b.md"

        context.insert(JottingCopy(destinationFilePath: path1, originalJotting: jotting1))
        context.insert(JottingCopy(destinationFilePath: path2, originalJotting: jotting2))
        try context.save()

        let descriptor = FetchDescriptor<JottingCopy>(
            sortBy: [SortDescriptor(\.destinationFilePath)]
        )
        let copies = try context.fetch(descriptor)

        #expect(copies.count == 2)
        #expect(copies[0].destinationFilePath == path1)
        #expect(copies[0].originalJotting?.content == "First idea")
        #expect(copies[1].destinationFilePath == path2)
        #expect(copies[1].originalJotting?.content == "Second idea")
    }

    // MARK: - New File Creation

    @Test func createNewFileInDirectory() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let vm = EditorViewModel()
        vm.loadDirectory(at: tempDir, saveBookmark: false)
        vm.createNewFile(named: "test-note")

        let fileURL = tempDir.appendingPathComponent("test-note.md")
        #expect(fileManager.fileExists(atPath: fileURL.path))
        #expect(vm.selectedFileURL == fileURL)
    }

    @Test func createNewFileDoesNotOverwrite() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let fileURL = tempDir.appendingPathComponent("existing.md")
        try "important content".write(to: fileURL, atomically: true, encoding: .utf8)

        let vm = EditorViewModel()
        vm.loadDirectory(at: tempDir, saveBookmark: false)
        vm.createNewFile(named: "existing.md")

        // The original content should be preserved
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content == "important content")
    }
}
