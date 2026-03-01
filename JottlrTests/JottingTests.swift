import Testing
import SwiftData
@testable import Jottlr

@Suite("Jotting Model Tests")
struct JottingTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Jotting.self, JottingCopy.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func defaultValues() throws {
        let jotting = Jotting(content: "Test idea")

        #expect(jotting.content == "Test idea")
        #expect(jotting.tags.isEmpty)
        #expect(jotting.isPinned == false)
        #expect(jotting.copies?.isEmpty == true)
    }

    @Test func persistenceRoundTrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let jotting = Jotting(content: "Persisted idea", tags: ["swift", "test"])
        context.insert(jotting)
        try context.save()

        let descriptor = FetchDescriptor<Jotting>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.content == "Persisted idea")
        #expect(fetched.first?.tags == ["swift", "test"])
        #expect(fetched.first?.isPinned == false)
    }

    @Test func jottingCopyRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let jotting = Jotting(content: "Original idea")
        context.insert(jotting)

        let copy = JottingCopy(destinationFilePath: "/notes/ideas.md", originalJotting: jotting)
        context.insert(copy)
        try context.save()

        let copyDescriptor = FetchDescriptor<JottingCopy>()
        let fetchedCopies = try context.fetch(copyDescriptor)

        #expect(fetchedCopies.count == 1)
        #expect(fetchedCopies.first?.originalJotting?.content == "Original idea")
        #expect(fetchedCopies.first?.destinationFilePath == "/notes/ideas.md")

        let jottingDescriptor = FetchDescriptor<Jotting>()
        let fetchedJottings = try context.fetch(jottingDescriptor)
        #expect(fetchedJottings.first?.copies?.count == 1)
    }

    @Test func deleteJottingNullifiesCopy() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let jotting = Jotting(content: "Will be deleted")
        context.insert(jotting)

        let copy = JottingCopy(destinationFilePath: "/notes/temp.md", originalJotting: jotting)
        context.insert(copy)
        try context.save()

        context.delete(jotting)
        try context.save()

        let copyDescriptor = FetchDescriptor<JottingCopy>()
        let fetchedCopies = try context.fetch(copyDescriptor)

        #expect(fetchedCopies.count == 1)
        #expect(fetchedCopies.first?.originalJotting == nil)
    }
}
