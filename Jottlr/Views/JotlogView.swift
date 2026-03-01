import SwiftUI
import SwiftData

struct JotlogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Jotting.createdAt, order: .reverse) private var allJottings: [Jotting]
    @State private var searchText = ""

    private var filteredJottings: [Jotting] {
        guard !searchText.isEmpty else { return allJottings }
        return allJottings.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedJottings: [(key: String, jottings: [Jotting])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredJottings) { jotting -> String in
            if calendar.isDateInToday(jotting.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(jotting.createdAt) {
                return "Yesterday"
            } else {
                return jotting.createdAt.formatted(date: .abbreviated, time: .omitted)
            }
        }

        // Sort groups by the most recent jotting in each group
        return grouped.map { (key: $0.key, jottings: $0.value) }
            .sorted { group1, group2 in
                guard let date1 = group1.jottings.first?.createdAt,
                      let date2 = group2.jottings.first?.createdAt else { return false }
                return date1 > date2
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search jottings...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if filteredJottings.isEmpty {
                ContentUnavailableView {
                    Label(searchText.isEmpty ? "No Jottings Yet" : "No Results",
                          systemImage: searchText.isEmpty ? "text.bubble" : "magnifyingglass")
                } description: {
                    Text(searchText.isEmpty
                         ? "Your captured ideas will appear here."
                         : "No jottings match \"\(searchText)\".")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedJottings, id: \.key) { group in
                            Section {
                                ForEach(group.jottings) { jotting in
                                    JottingRow(jotting: jotting)
                                        .contextMenu {
                                            Button {
                                                jotting.isPinned.toggle()
                                                try? modelContext.save()
                                            } label: {
                                                Label(jotting.isPinned ? "Unpin" : "Pin",
                                                      systemImage: jotting.isPinned ? "pin.slash" : "pin")
                                            }

                                            Button {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(jotting.content, forType: .string)
                                            } label: {
                                                Label("Copy Text", systemImage: "doc.on.doc")
                                            }

                                            Divider()

                                            Button(role: .destructive) {
                                                modelContext.delete(jotting)
                                                try? modelContext.save()
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                Text(group.key)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.bar)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct JottingRow: View {
    let jotting: Jotting

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if jotting.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.top, 3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(jotting.content)
                    .lineLimit(3)

                Text(jotting.createdAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    JotlogView()
        .modelContainer(for: Jotting.self, inMemory: true)
        .frame(width: 400, height: 500)
}
