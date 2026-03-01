import Foundation
import Testing
import SwiftData
@testable import Jottlr

@Suite("Jotlog ViewModel Tests", .serialized)
struct JotlogViewModelTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Jotting.self, JottingCopy.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func searchFiltering() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let contents = ["Build the UI", "Fix the bug", "Design mockup", "Build API", "Write tests"]
        for content in contents {
            context.insert(Jotting(content: content))
        }
        try context.save()

        let descriptor = FetchDescriptor<Jotting>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 5)

        let searchTerm = "Build"
        let filtered = all.filter { $0.content.localizedCaseInsensitiveContains(searchTerm) }
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.content.contains("Build") })
    }

    @Test func sortOrderNewestFirst() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let now = Date()
        let jotting1 = Jotting(content: "Oldest")
        jotting1.createdAt = now.addingTimeInterval(-3600)
        let jotting2 = Jotting(content: "Middle")
        jotting2.createdAt = now.addingTimeInterval(-1800)
        let jotting3 = Jotting(content: "Newest")
        jotting3.createdAt = now

        context.insert(jotting1)
        context.insert(jotting2)
        context.insert(jotting3)
        try context.save()

        var descriptor = FetchDescriptor<Jotting>(
            sortBy: [SortDescriptor(\Jotting.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 3
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 3)
        #expect(fetched[0].content == "Newest")
        #expect(fetched[1].content == "Middle")
        #expect(fetched[2].content == "Oldest")
    }

    @Test func pinToggle() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let jotting = Jotting(content: "Pin me")
        context.insert(jotting)
        try context.save()

        #expect(jotting.isPinned == false)

        jotting.isPinned.toggle()
        try context.save()

        let descriptor = FetchDescriptor<Jotting>()
        let fetched = try context.fetch(descriptor)
        let saved = try #require(fetched.first)
        #expect(saved.isPinned == true)

        saved.isPinned.toggle()
        try context.save()

        let refetched = try context.fetch(descriptor)
        #expect(refetched.first?.isPinned == false)
    }

    @Test func deleteJotting() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let jotting1 = Jotting(content: "Keep me")
        let jotting2 = Jotting(content: "Delete me")
        context.insert(jotting1)
        context.insert(jotting2)
        try context.save()

        let beforeDescriptor = FetchDescriptor<Jotting>()
        let before = try context.fetch(beforeDescriptor)
        #expect(before.count == 2)

        context.delete(jotting2)
        try context.save()

        let afterDescriptor = FetchDescriptor<Jotting>()
        let after = try context.fetch(afterDescriptor)
        #expect(after.count == 1)
        #expect(after.first?.content == "Keep me")
    }
}
