import Foundation
import SwiftData

@Model
final class JottingCopy {
    var id: UUID = UUID()
    var copiedAt: Date = Date()
    var destinationFilePath: String = ""

    @Relationship(deleteRule: .nullify)
    var originalJotting: Jotting?

    init(destinationFilePath: String, originalJotting: Jotting?) {
        self.id = UUID()
        self.copiedAt = Date()
        self.destinationFilePath = destinationFilePath
        self.originalJotting = originalJotting
    }
}
