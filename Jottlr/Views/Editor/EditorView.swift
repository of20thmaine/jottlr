import SwiftUI
import SwiftData

struct EditorView: View {
    @Bindable var viewModel: EditorViewModel
    @State private var showJotlog = false
    @State private var showNewFileSheet = false
    @State private var newFileName = ""
    @State private var showSaveIndicator = false
    @State private var saveDismissTask: Task<Void, Never>?

    var body: some View {
        NavigationSplitView {
            FileTreeView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 350)
        } detail: {
            if viewModel.selectedFileURL != nil {
                TextEditor(text: $viewModel.documentText)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: viewModel.documentText) {
                        viewModel.scheduleAutoSave()
                    }
            } else {
                ContentUnavailableView {
                    Label("No File Selected", systemImage: "doc.text")
                } description: {
                    Text("Select a markdown file from the sidebar to start editing.")
                }
            }
        }
        .inspector(isPresented: $showJotlog) {
            JotlogInspectorView(viewModel: viewModel)
        }
        .navigationTitle(viewModel.selectedFileURL?.lastPathComponent ?? "Jottlr Editor")
        .overlay(alignment: .bottom) {
            if showSaveIndicator {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .onChange(of: viewModel.saveStatus) { _, newStatus in
            if newStatus == .saved {
                showSaveConfirmation()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showJotlog.toggle()
                } label: {
                    Label("Jotlog", systemImage: "text.bubble")
                }
                .help("Toggle Jotlog Panel")
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            viewModel.restoreDirectory()
        }
        .keyboardShortcut(for: .save) {
            viewModel.saveCurrentFile()
            viewModel.saveStatus = .saved
        }
        .keyboardShortcut(for: .newFile) {
            guard viewModel.rootNode != nil else { return }
            newFileName = ""
            showNewFileSheet = true
        }
        .sheet(isPresented: $showNewFileSheet) {
            NewFileSheet(fileName: $newFileName) {
                viewModel.createNewFile(named: newFileName)
                showNewFileSheet = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewFileSheet)) { _ in
            guard viewModel.rootNode != nil else { return }
            newFileName = ""
            showNewFileSheet = true
        }
    }

    private func showSaveConfirmation() {
        saveDismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.2)) {
            showSaveIndicator = true
        }
        saveDismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                showSaveIndicator = false
            }
            viewModel.saveStatus = .idle
        }
    }
}

// MARK: - Keyboard Shortcut Modifier

private struct KeyboardShortcutModifier: ViewModifier {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .background {
                Button("") { action() }
                    .keyboardShortcut(key, modifiers: modifiers)
                    .hidden()
            }
    }
}

private enum EditorShortcut {
    case save
    case newFile
}

private extension View {
    func keyboardShortcut(for shortcut: EditorShortcut, action: @escaping () -> Void) -> some View {
        switch shortcut {
        case .save:
            return AnyView(modifier(KeyboardShortcutModifier(key: "s", modifiers: .command, action: action)))
        case .newFile:
            return AnyView(modifier(KeyboardShortcutModifier(key: "n", modifiers: .command, action: action)))
        }
    }
}

// MARK: - New File Sheet

private struct NewFileSheet: View {
    @Binding var fileName: String
    let onCreate: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("New Markdown File")
                .font(.headline)

            TextField("Filename", text: $fileName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    guard !fileName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onCreate()
                }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    guard !fileName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onCreate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    EditorView(viewModel: EditorViewModel())
        .modelContainer(for: Jotting.self, inMemory: true)
}
