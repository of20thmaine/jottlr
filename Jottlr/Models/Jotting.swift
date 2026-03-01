import Foundation
import SwiftData

@Model
final class Jotting {
    var id: UUID = UUID()
    var content: String = ""
    var createdAt: Date = Date()
    var tags: [String] = []
    var isPinned: Bool = false

    @Relationship(deleteRule: .nullify)
    var copies: [JottingCopy]? = []

    init(content: String, tags: [String] = []) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.tags = tags
        self.isPinned = false
    }
}
