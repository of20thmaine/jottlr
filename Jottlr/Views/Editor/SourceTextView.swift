import SwiftUI
import AppKit

/// A plain-text source editor with a line number gutter.
/// Displays raw markdown with no attribute styling — just monospaced text.
///
/// Implementation: Returns an NSView wrapper containing an NSScrollView with
/// an NSTextView, plus a GutterView overlay that draws line numbers.
/// The GutterView passes all mouse events through via hitTest returning nil,
/// and the text container's lineFragmentPadding offsets text past the gutter.
struct SourceTextView: NSViewRepresentable {
    @Binding var text: String
    var initialCursorLocation: Int?
    var initialScrollFraction: CGFloat?
    var onCursorChange: ((Int) -> Void)?
    var onScrollChange: ((CGFloat) -> Void)?

    private static let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    private static let gutterWidth: CGFloat = 40

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSView {
        // Container NSView that holds both the scroll view and gutter overlay
        let container = NSView()

        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            container.addSubview(scrollView)
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: container.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            return container
        }

        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.font = Self.monoFont
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .labelColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.autoresizingMask = [.width]

        // Reserve space for the gutter via line fragment padding
        textView.textContainer?.lineFragmentPadding = Self.gutterWidth
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.textStorage?.delegate = context.coordinator
        context.coordinator.textView = textView

        // Set text and apply plain attributes
        context.coordinator.isUpdatingFromSwiftUI = true
        textView.string = text
        if let storage = textView.textStorage, storage.length > 0 {
            storage.beginEditing()
            storage.setAttributes([
                .font: Self.monoFont,
                .foregroundColor: NSColor.labelColor,
            ], range: NSRange(location: 0, length: storage.length))
            storage.endEditing()
        }
        context.coordinator.isUpdatingFromSwiftUI = false

        // Restore cursor position and scroll to it
        if let loc = initialCursorLocation {
            let clamped = min(loc, (textView.string as NSString).length)
            let range = NSRange(location: clamped, length: 0)
            textView.setSelectedRange(range)
            // Defer scrollRangeToVisible until after layout
            DispatchQueue.main.async {
                textView.scrollRangeToVisible(range)
            }
        }

        // Layout: scroll view fills the container
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // Gutter overlay — floats above the scroll view, passes mouse events through
        let gutterView = GutterView()
        gutterView.textView = textView
        container.addSubview(gutterView)
        gutterView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gutterView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            gutterView.topAnchor.constraint(equalTo: container.topAnchor),
            gutterView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            gutterView.widthAnchor.constraint(equalToConstant: Self.gutterWidth + 16), // +16 for textContainerInset.width
        ])
        context.coordinator.gutterView = gutterView

        // Observe selection changes for cursor tracking
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionDidChange(_:)),
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )

        // Observe scroll changes
        let clipView = scrollView.contentView
        clipView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: clipView
        )
        // Also redraw gutter on scroll
        NotificationCenter.default.addObserver(
            gutterView,
            selector: #selector(GutterView.scrollViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: clipView
        )

        if let fraction = initialScrollFraction {
            context.coordinator.pendingScrollFraction = fraction
        }

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        if textView.string != text {
            context.coordinator.isUpdatingFromSwiftUI = true
            let selectedRanges = textView.selectedRanges
            textView.string = text
            if let storage = textView.textStorage, storage.length > 0 {
                storage.beginEditing()
                storage.setAttributes([
                    .font: Self.monoFont,
                    .foregroundColor: NSColor.labelColor,
                ], range: NSRange(location: 0, length: storage.length))
                storage.endEditing()
            }
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
            context.coordinator.gutterView?.needsDisplay = true
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextStorageDelegate {
        var parent: SourceTextView
        weak var textView: NSTextView?
        weak var gutterView: GutterView?
        var isUpdatingFromSwiftUI = false
        var isStyling = false
        var pendingScrollFraction: CGFloat?
        private var hasRestoredScroll = false

        init(_ parent: SourceTextView) {
            self.parent = parent
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

                parent.text = textStorage.string

                // Re-apply plain attributes to the edited paragraph
                let nsString = textStorage.string as NSString
                let paragraphRange = nsString.paragraphRange(for: editedRange)
                let fullRange = NSRange(location: 0, length: textStorage.length)
                let clampedRange = NSIntersectionRange(paragraphRange, fullRange)
                guard clampedRange.length > 0 else { return }

                isStyling = true
                textStorage.setAttributes([
                    .font: SourceTextView.monoFont,
                    .foregroundColor: NSColor.labelColor,
                ], range: clampedRange)
                isStyling = false

                gutterView?.needsDisplay = true
            }
        }

        @objc func selectionDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI, let textView else { return }
            parent.onCursorChange?(textView.selectedRange().location)
        }

        @objc func boundsDidChange(_ notification: Notification) {
            guard let textView,
                  let scrollView = textView.enclosingScrollView else { return }

            if !hasRestoredScroll, let fraction = pendingScrollFraction {
                hasRestoredScroll = true
                pendingScrollFraction = nil
                let maxY = textView.frame.height - scrollView.contentView.bounds.height
                if maxY > 0 {
                    scrollView.contentView.setBoundsOrigin(NSPoint(x: 0, y: fraction * maxY))
                }
                return
            }

            let maxY = textView.frame.height - scrollView.contentView.bounds.height
            if maxY > 0 {
                let frac = scrollView.contentView.bounds.origin.y / maxY
                parent.onScrollChange?(min(max(frac, 0), 1))
            }
        }
    }

    // MARK: - Gutter View

    /// Draws line numbers and a separator. Passes all mouse events through.
    final class GutterView: NSView {
        weak var textView: NSTextView?

        override var isFlipped: Bool { true }

        private static let lineNumberFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        private static let lineNumberColor = NSColor.tertiaryLabelColor
        private static let separatorColor = NSColor.separatorColor

        /// All mouse events pass through to the text view underneath
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }

        @objc func scrollViewDidScroll(_ notification: Notification) {
            needsDisplay = true
        }

        override func draw(_ dirtyRect: NSRect) {
            guard let textView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            let visibleRect = textView.visibleRect
            let insetY = textView.textContainerInset.height

            // Draw gutter background
            NSColor.textBackgroundColor.setFill()
            bounds.fill()

            // Draw separator — starts at text area top, not above it
            Self.separatorColor.setStroke()
            let separatorX = bounds.width - 0.5
            let textAreaTop = max(insetY - visibleRect.minY, 0)
            let path = NSBezierPath()
            path.move(to: NSPoint(x: separatorX, y: textAreaTop))
            path.line(to: NSPoint(x: separatorX, y: bounds.height))
            path.lineWidth = 0.5
            path.stroke()

            // Determine visible glyph range
            let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
            guard glyphRange.length > 0 else { return }
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let nsString = textView.string as NSString
            guard nsString.length > 0 else { return }

            // Count lines up to the visible range
            var lineNumber = 1
            var searchStart = 0
            while searchStart < charRange.location {
                let lineRange = nsString.lineRange(for: NSRange(location: searchStart, length: 0))
                let nextStart = lineRange.location + lineRange.length
                if nextStart <= searchStart { break }
                searchStart = nextStart
                lineNumber += 1
            }

            // Draw line numbers
            let attrs: [NSAttributedString.Key: Any] = [
                .font: Self.lineNumberFont,
                .foregroundColor: Self.lineNumberColor,
            ]

            var glyphIndex = glyphRange.location
            while glyphIndex < NSMaxRange(glyphRange) {
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
                let lineRange = nsString.lineRange(for: NSRange(location: charIndex, length: 0))

                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
                // Convert from text view coords to gutter coords (both flipped)
                let yInGutter = lineRect.origin.y + insetY - visibleRect.minY

                let numStr = "\(lineNumber)" as NSString
                let size = numStr.size(withAttributes: attrs)
                let drawPoint = NSPoint(
                    x: bounds.width - size.width - 8,
                    y: yInGutter + (lineRect.height - size.height) / 2
                )
                numStr.draw(at: drawPoint, withAttributes: attrs)

                lineNumber += 1

                // Advance past all glyphs for this line
                let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
                glyphIndex = NSMaxRange(lineGlyphRange)
            }
        }
    }
}
