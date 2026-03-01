import SwiftUI
import AppKit
import Markdown

/// A SwiftUI wrapper around NSTextView that provides WYSIWYG markdown editing.
///
/// Performance strategy for large files (200k+ words):
/// - **Keystroke edits**: Only the affected paragraph(s) are re-parsed and re-styled.
///   The paragraph text is extracted, parsed as a standalone fragment, and attributes
///   are applied with an offset — no full-document parse on every keystroke.
/// - **Debounced full re-parse**: After 500ms of idle time following a burst of edits,
///   a full document re-parse runs to fix any cross-paragraph context (e.g. lists).
/// - **Chunked initial load**: Large files show raw text immediately, then styling is
///   applied progressively in line-based chunks on a background queue so the UI
///   never freezes.
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var style: MarkdownStyleConfiguration

    init(text: Binding<String>, style: MarkdownStyleConfiguration = .default) {
        self._text = text
        self.style = style
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = false
        textView.font = style.bodyFont
        textView.textColor = style.textColor
        textView.defaultParagraphStyle = style.defaultParagraphStyle
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .labelColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.autoresizingMask = [.width]

        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.textStorage?.delegate = context.coordinator
        context.coordinator.textView = textView

        // Set initial content — styling applied progressively
        context.coordinator.isUpdatingFromSwiftUI = true
        textView.string = text
        context.coordinator.applyInitialStyling()
        context.coordinator.isUpdatingFromSwiftUI = false

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        if textView.string != text {
            context.coordinator.isUpdatingFromSwiftUI = true
            let selectedRanges = textView.selectedRanges
            textView.string = text
            context.coordinator.applyInitialStyling()
            let maxLength = (textView.string as NSString).length
            let restoredRanges = selectedRanges.compactMap { rangeValue -> NSValue? in
                let range = rangeValue.rangeValue
                if range.location <= maxLength {
                    let clampedLength = min(range.length, maxLength - range.location)
                    return NSValue(range: NSRange(location: range.location, length: clampedLength))
                }
                return nil
            }
            if !restoredRanges.isEmpty {
                textView.setSelectedRanges(restoredRanges, affinity: .downstream, stillSelecting: false)
            }
            context.coordinator.isUpdatingFromSwiftUI = false
        }

        context.coordinator.style = style
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextStorageDelegate {
        var parent: MarkdownTextView
        weak var textView: NSTextView?
        var style: MarkdownStyleConfiguration
        var isUpdatingFromSwiftUI = false
        /// Prevents re-entrant styling during attribute edits.
        var isStyling = false
        /// Task handle for debounced full re-parse after idle.
        private var debounceTask: Task<Void, Never>?
        /// Task handle for progressive chunked styling on initial load.
        private var chunkTask: Task<Void, Never>?
        /// Threshold (in characters) above which initial load uses chunked styling.
        private let chunkThreshold = 50_000
        /// Number of lines to style per chunk during progressive load.
        private let linesPerChunk = 500

        init(_ parent: MarkdownTextView) {
            self.parent = parent
            self.style = parent.style
            super.init()
        }

        // MARK: - NSTextStorageDelegate

        nonisolated func textStorage(
            _ textStorage: NSTextStorage,
            didProcessEditing editedMask: NSTextStorageEditActions,
            range editedRange: NSRange,
            changeInLength delta: Int
        ) {
            MainActor.assumeIsolated {
                guard editedMask.contains(.editedCharacters),
                      !isUpdatingFromSwiftUI,
                      !isStyling else { return }

                // Sync binding
                parent.text = textStorage.string

                // Cancel any pending chunked styling — user is editing
                chunkTask?.cancel()
                chunkTask = nil

                // Incremental: re-style only the affected paragraph(s).
                let nsString = textStorage.string as NSString
                let fullRange = NSRange(location: 0, length: textStorage.length)
                var paragraphRange = nsString.paragraphRange(for: editedRange)

                // When a newline is inserted (delta > 0 and the inserted text
                // contains a newline), also cover the next paragraph so the new
                // empty line gets the default paragraph style synchronously.
                if delta > 0 {
                    let inserted = nsString.substring(with: editedRange)
                    if inserted.contains("\n") {
                        let afterEdit = paragraphRange.location + paragraphRange.length
                        if afterEdit < textStorage.length {
                            let nextPara = nsString.paragraphRange(
                                for: NSRange(location: afterEdit, length: 0)
                            )
                            paragraphRange.length =
                                (nextPara.location + nextPara.length) - paragraphRange.location
                        }
                    }
                }

                let clampedRange = NSIntersectionRange(paragraphRange, fullRange)
                guard clampedRange.length > 0 else { return }

                // Save scroll position before attribute changes
                let clipView = textView?.enclosingScrollView?.contentView
                let savedOrigin = clipView?.bounds.origin

                isStyling = true

                // Block layout invalidation during attribute changes to prevent
                // intermediate layout passes that cause visual jitter
                let layoutManager = textView?.layoutManager
                layoutManager?.backgroundLayoutEnabled = false

                // Apply attributes directly — we're already inside a text storage
                // editing session from the character edit. Avoid an extra
                // beginEditing/endEditing cycle which would trigger a redundant
                // processEditing notification and layout pass.
                let parser = MarkdownParser(style: style)
                parser.applyAttributes(to: textStorage, in: clampedRange)

                layoutManager?.backgroundLayoutEnabled = true
                isStyling = false

                // Restore scroll position if it shifted due to attribute changes
                if let clipView, let savedOrigin, clipView.bounds.origin != savedOrigin {
                    clipView.setBoundsOrigin(savedOrigin)
                }

                // Schedule debounced full re-parse for cross-paragraph context
                scheduleFullReparse()
            }
        }

        // MARK: - Debounced Full Re-parse

        /// Schedules a full document re-parse after 500ms of idle time.
        /// Fixes cross-paragraph styling (e.g., multi-line lists, blockquotes).
        private func scheduleFullReparse() {
            debounceTask?.cancel()
            debounceTask = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(for: .milliseconds(500))
                } catch {
                    return // Cancelled
                }
                guard let self, let textView = self.textView,
                      let textStorage = textView.textStorage else { return }
                guard !Task.isCancelled else { return }

                let clipView = textView.enclosingScrollView?.contentView
                let savedOrigin = clipView?.bounds.origin

                self.isStyling = true
                let parser = MarkdownParser(style: self.style)
                textStorage.beginEditing()
                parser.applyFullAttributes(to: textStorage)
                textStorage.endEditing()
                self.isStyling = false

                // Restore scroll position if it shifted
                if let clipView, let savedOrigin, clipView.bounds.origin != savedOrigin {
                    clipView.setBoundsOrigin(savedOrigin)
                }
            }
        }

        // MARK: - Initial Styling

        /// Applies styling for initial file load. For small files, styles synchronously.
        /// For large files, shows raw text immediately then applies styling in chunks.
        func applyInitialStyling() {
            debounceTask?.cancel()
            chunkTask?.cancel()

            guard let textStorage = textView?.textStorage else { return }
            guard textStorage.length > 0 else { return }

            if textStorage.length < chunkThreshold {
                // Small file — style synchronously
                isStyling = true
                let parser = MarkdownParser(style: style)
                textStorage.beginEditing()
                parser.applyFullAttributes(to: textStorage)
                textStorage.endEditing()
                isStyling = false
            } else {
                // Large file — apply default styling immediately, then chunk
                isStyling = true
                textStorage.beginEditing()
                textStorage.setAttributes(style.defaultAttributes, range: NSRange(location: 0, length: textStorage.length))
                textStorage.endEditing()
                isStyling = false

                applyChunkedStyling()
            }
        }

        /// Progressively applies styling in line-based chunks on a background queue.
        /// Each chunk parses the full document AST once (cached) but only applies
        /// attributes to the lines in the current chunk.
        private func applyChunkedStyling() {
            guard let textStorage = textView?.textStorage else { return }
            let currentText = textStorage.string
            let currentStyle = style
            let linesPerChunk = self.linesPerChunk

            chunkTask = Task { @MainActor [weak self] in
                guard let self else { return }

                // Parse the full AST and build the offset table once — these are
                // value types so they're safe to hold across awaits
                let table = OffsetTable(currentText)
                let document = Document(parsing: currentText)
                let totalLines = table.lineStarts.count
                let parser = MarkdownParser(style: currentStyle)

                var lineStart = 0
                while lineStart < totalLines {
                    guard !Task.isCancelled else { return }

                    let lineEnd = min(lineStart + linesPerChunk, totalLines)

                    // Verify text hasn't changed (user started editing)
                    guard let storage = self.textView?.textStorage,
                          storage.string == currentText else { return }

                    self.isStyling = true
                    storage.beginEditing()
                    _ = parser.applyChunk(
                        to: storage,
                        fullText: currentText,
                        table: table,
                        document: document,
                        fromLine: lineStart,
                        toLine: lineEnd
                    )
                    storage.endEditing()
                    self.isStyling = false

                    lineStart = lineEnd

                    // Yield to the run loop so the UI stays responsive
                    try? await Task.sleep(for: .milliseconds(10))
                }
            }
        }
    }
}
