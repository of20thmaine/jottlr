import Foundation
import Testing
@testable import Jottlr

@Suite("FileSystemService Tests", .serialized)
struct FileSystemServiceTests {
    private let service = FileSystemService()
    private let fileManager = FileManager.default

    /// Creates a temporary directory for each test.
    private func makeTempDir() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("JottlrTests-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    /// Removes a temporary directory after a test.
    private func cleanUp(_ url: URL) {
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Read / Write

    @Test func readFileContents() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let fileURL = tempDir.appendingPathComponent("test.md")
        let content = "# Hello\nThis is a test."
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = try service.readFile(at: fileURL)
        #expect(result == content)
    }

    @Test func writeFileContents() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let fileURL = tempDir.appendingPathComponent("output.md")
        let content = "# Written\nBy FileSystemService."
        try service.writeFile(content, to: fileURL)

        let readBack = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(readBack == content)
    }

    @Test func writeOverwritesExistingFile() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let fileURL = tempDir.appendingPathComponent("overwrite.md")
        try "Original".write(to: fileURL, atomically: true, encoding: .utf8)

        let newContent = "Overwritten"
        try service.writeFile(newContent, to: fileURL)

        let result = try service.readFile(at: fileURL)
        #expect(result == newContent)
    }

    // MARK: - Directory Scanning

    @Test func scanFindsMarkdownFiles() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        try "# A".write(to: tempDir.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)
        try "# B".write(to: tempDir.appendingPathComponent("b.md"), atomically: true, encoding: .utf8)

        let root = service.scanDirectory(at: tempDir)
        let children = try #require(root?.children)
        #expect(children.count == 2)
        #expect(children.allSatisfy { !$0.isDirectory })

        let names = children.map(\.name).sorted()
        #expect(names == ["a.md", "b.md"])
    }

    @Test func scanFindsNestedMarkdownFiles() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let subDir = tempDir.appendingPathComponent("notes")
        try fileManager.createDirectory(at: subDir, withIntermediateDirectories: true)

        try "# Root".write(to: tempDir.appendingPathComponent("root.md"), atomically: true, encoding: .utf8)
        try "# Nested".write(to: subDir.appendingPathComponent("nested.md"), atomically: true, encoding: .utf8)

        let root = service.scanDirectory(at: tempDir)
        let children = try #require(root?.children)
        #expect(children.count == 2) // "notes" folder + "root.md"

        let folder = try #require(children.first(where: { $0.isDirectory }))
        #expect(folder.name == "notes")

        let folderChildren = try #require(folder.children)
        #expect(folderChildren.count == 1)
        #expect(folderChildren.first?.name == "nested.md")
    }

    @Test func scanExcludesNonMarkdownFiles() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        try "# Keep".write(to: tempDir.appendingPathComponent("keep.md"), atomically: true, encoding: .utf8)
        try "skip".write(to: tempDir.appendingPathComponent("skip.txt"), atomically: true, encoding: .utf8)
        try "{}".write(to: tempDir.appendingPathComponent("data.json"), atomically: true, encoding: .utf8)
        try "<html>".write(to: tempDir.appendingPathComponent("page.html"), atomically: true, encoding: .utf8)

        let root = service.scanDirectory(at: tempDir)
        let children = try #require(root?.children)
        #expect(children.count == 1)
        #expect(children.first?.name == "keep.md")
    }

    @Test func scanIncludesEmptySubdirectories() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let emptyDir = tempDir.appendingPathComponent("empty")
        try fileManager.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        try "# A".write(to: tempDir.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)

        let root = service.scanDirectory(at: tempDir)
        let children = try #require(root?.children)

        // Should contain both the .md file and the empty directory
        #expect(children.count == 2)

        let folder = children.first(where: { $0.isDirectory })
        #expect(folder?.name == "empty")
        #expect(folder?.children?.isEmpty == true)

        let file = children.first(where: { !$0.isDirectory })
        #expect(file?.name == "a.md")
    }

    @Test func scanReturnsNilForNonexistentPath() {
        let bogus = URL(fileURLWithPath: "/nonexistent/path/\(UUID().uuidString)")
        let result = service.scanDirectory(at: bogus)
        #expect(result == nil)
    }

    // MARK: - Directory Management

    @Test func createSubdirectory() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let subDirURL = tempDir.appendingPathComponent("new-folder")
        try service.createDirectory(at: subDirURL)

        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: subDirURL.path, isDirectory: &isDir)
        #expect(exists)
        #expect(isDir.boolValue)
    }

    @Test func renameFile() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let originalURL = tempDir.appendingPathComponent("old-name.md")
        try "# Content".write(to: originalURL, atomically: true, encoding: .utf8)

        let newURL = try service.renameItem(at: originalURL, to: "new-name.md")

        #expect(newURL.lastPathComponent == "new-name.md")
        #expect(!fileManager.fileExists(atPath: originalURL.path))
        #expect(fileManager.fileExists(atPath: newURL.path))

        let content = try String(contentsOf: newURL, encoding: .utf8)
        #expect(content == "# Content")
    }

    @Test func deleteFile() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        let fileURL = tempDir.appendingPathComponent("doomed.md")
        try "bye".write(to: fileURL, atomically: true, encoding: .utf8)
        #expect(fileManager.fileExists(atPath: fileURL.path))

        try service.deleteItem(at: fileURL)
        #expect(!fileManager.fileExists(atPath: fileURL.path))
    }

    @Test func treeRefreshesAfterChanges() throws {
        let tempDir = try makeTempDir()
        defer { cleanUp(tempDir) }

        try "# A".write(to: tempDir.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)

        let root1 = service.scanDirectory(at: tempDir)
        #expect(root1?.children?.count == 1)

        // Add a file and a subdirectory
        try "# B".write(to: tempDir.appendingPathComponent("b.md"), atomically: true, encoding: .utf8)
        try fileManager.createDirectory(
            at: tempDir.appendingPathComponent("sub"),
            withIntermediateDirectories: true
        )

        let root2 = service.scanDirectory(at: tempDir)
        #expect(root2?.children?.count == 3) // a.md, b.md, sub/

        // Delete a file
        try fileManager.removeItem(at: tempDir.appendingPathComponent("a.md"))

        let root3 = service.scanDirectory(at: tempDir)
        #expect(root3?.children?.count == 2) // b.md, sub/
    }
}
