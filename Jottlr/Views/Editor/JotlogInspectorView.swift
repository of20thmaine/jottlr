import SwiftUI
import SwiftData

struct JotlogInspectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Jotting.createdAt, order: .reverse) private var jottings: [Jotting]
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Jotlog")
                .font(.headline)
                .padding()

            Divider()

            if jottings.isEmpty {
                ContentUnavailableView {
                    Label("No Jottings", systemImage: "text.bubble")
                } description: {
                    Text("Capture ideas from the menu bar.")
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(jottings) { jotting in
                        JotlogInspectorRow(jotting: jotting) {
                            copyJottingToEditor(jotting)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .inspectorColumnWidth(min: 200, ideal: 260, max: 350)
    }

    private func copyJottingToEditor(_ jotting: Jotting) {
        guard let fileURL = viewModel.selectedFileURL else { return }

        // Append jotting text to the document
        if viewModel.documentText.isEmpty {
            viewModel.documentText = jotting.content
        } else {
            viewModel.documentText += "\n\(jotting.content)"
        }

        // Create a JottingCopy record
        let copy = JottingCopy(
            destinationFilePath: fileURL.path,
            originalJotting: jotting
        )
        modelContext.insert(copy)
        try? modelContext.save()

        // Trigger auto-save for the document
        viewModel.scheduleAutoSave()
    }
}

private struct JotlogInspectorRow: View {
    let jotting: Jotting
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(jotting.content)
                .lineLimit(3)

            HStack {
                Text(jotting.createdAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    onCopy()
                } label: {
                    Label("Copy to Editor", systemImage: "arrow.right.doc.on.clipboard")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding(.vertical, 4)
    }
}
