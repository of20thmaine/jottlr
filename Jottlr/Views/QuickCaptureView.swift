import SwiftUI
import SwiftData

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Jotting.createdAt, order: .reverse) private var recentJottings: [Jotting]
    @State private var inputText = ""
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Input area
            VStack(spacing: 12) {
                TextField("Jot something down...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .padding(12)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit(saveJotting)
                    .overlay {
                        if showConfirmation {
                            HStack {
                                Spacer()
                                Label("Saved", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .padding(.trailing, 12)
                                    .transition(.opacity)
                            }
                        }
                    }
            }
            .padding()

            // Recent jottings preview
            if !recentJottings.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 0) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ForEach(recentJottings.prefix(3)) { jotting in
                        HStack {
                            Text(jotting.content)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer()

                            Text(jotting.createdAt, format: .relative(presentation: .named))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.bottom, 8)
            }

            Divider()

            // Footer
            HStack {
                Text("⌘⇧J to capture from anywhere")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 400)
    }

    private func saveJotting() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let jotting = Jotting(content: trimmed)
        modelContext.insert(jotting)
        try? modelContext.save()

        inputText = ""

        withAnimation(.easeIn(duration: 0.2)) {
            showConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showConfirmation = false
            }
        }
    }
}

#Preview {
    QuickCaptureView()
        .modelContainer(for: Jotting.self, inMemory: true)
}
