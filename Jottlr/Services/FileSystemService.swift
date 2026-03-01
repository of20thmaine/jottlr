import Foundation

struct FileNode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.url == rhs.url
    }
}

struct FileSystemService {
    private let fileManager = FileManager.default

    /// Recursively scans a directory for `.md` files, returning a tree of FileNodes.
    func scanDirectory(at url: URL) -> FileNode? {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir),
              isDir.boolValue else {
            return nil
        }

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return FileNode(name: url.lastPathComponent, url: url, isDirectory: true, children: [])
        }

        var children: [FileNode] = []

        for itemURL in contents.sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }) {
            var itemIsDir: ObjCBool = false
            fileManager.fileExists(atPath: itemURL.path, isDirectory: &itemIsDir)

            if itemIsDir.boolValue {
                // Recurse into subdirectories
                if let subNode = scanDirectory(at: itemURL) {
                    // Only include folders that contain .md files (directly or nested)
                    if let subChildren = subNode.children, !subChildren.isEmpty {
                        children.append(subNode)
                    }
                }
            } else if itemURL.pathExtension.lowercased() == "md" {
                children.append(FileNode(name: itemURL.lastPathComponent, url: itemURL, isDirectory: false, children: nil))
            }
        }

        return FileNode(name: url.lastPathComponent, url: url, isDirectory: true, children: children)
    }

    /// Reads the contents of a file at the given URL.
    func readFile(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    /// Writes string contents to a file at the given URL.
    func writeFile(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
