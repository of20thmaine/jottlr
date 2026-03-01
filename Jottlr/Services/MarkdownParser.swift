import AppKit
import Markdown

// MARK: - Styling Configuration

/// Configurable styling parameters for markdown rendering.
/// This is the foundation for the theming system (Phase 5).
struct MarkdownStyleConfiguration {
    var headingFonts: [Int: NSFont]
    var bodyFont: NSFont
    var monoFont: NSFont
    var textColor: NSColor
    var syntaxColor: NSColor
    var headingColor: NSColor
    var linkColor: NSColor
    var codeBackgroundColor: NSColor
    var blockquoteBarColor: NSColor
    var paragraphSpacing: CGFloat
    var listIndent: CGFloat

    /// The default paragraph style applied to all text, including empty lines.
    /// Uses fixed line height to prevent layout jitter when attributes change.
    var defaultParagraphStyle: NSParagraphStyle {
        let ps = NSMutableParagraphStyle()
        let lineHeight = bodyFont.ascender - bodyFont.descender + bodyFont.leading
        ps.minimumLineHeight = lineHeight
        ps.maximumLineHeight = lineHeight
        ps.paragraphSpacing = paragraphSpacing
        return ps
    }

    /// Default attributes applied to all text before styling is overlaid.
    var defaultAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: textColor,
            .paragraphStyle: defaultParagraphStyle,
        ]
    }

    static var `default`: MarkdownStyleConfiguration {
        let bodyFont = NSFont.systemFont(ofSize: 14)
        let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        return MarkdownStyleConfiguration(
            headingFonts: [
                1: NSFont.boldSystemFont(ofSize: 24),
                2: NSFont.boldSystemFont(ofSize: 20),
                3: NSFont.boldSystemFont(ofSize: 17),
            ],
            bodyFont: bodyFont,
            monoFont: monoFont,
            textColor: NSColor.labelColor,
            syntaxColor: NSColor.tertiaryLabelColor,
            headingColor: NSColor.labelColor,
            linkColor: NSColor.linkColor,
            codeBackgroundColor: NSColor.quaternaryLabelColor,
            blockquoteBarColor: NSColor.controlAccentColor,
            paragraphSpacing: 12,
            listIndent: 24
        )
    }
}

// MARK: - UTF-16 Offset Table

/// Pre-computed mapping from UTF-8 byte offsets to UTF-16 code unit offsets.
/// Built once per string, then used for O(1) source-location-to-NSRange conversion.
struct OffsetTable {
    /// Maps each UTF-8 byte index to its corresponding UTF-16 offset.
    /// Index i gives the UTF-16 offset for UTF-8 byte position i.
    let utf8ToUtf16: [Int]
    /// Line start positions in UTF-8 byte offsets (1-indexed: lineStarts[0] is line 1).
    let lineStarts: [Int]

    init(_ string: String) {
        let utf8 = Array(string.utf8)
        var mapping = [Int](repeating: 0, count: utf8.count + 1)
        var lines: [Int] = [0] // Line 1 starts at byte 0
        var utf16Offset = 0
        var i = 0

        while i < utf8.count {
            mapping[i] = utf16Offset

            let byte = utf8[i]
            if byte == 0x0A { // newline
                lines.append(i + 1)
            }

            // Determine UTF-8 sequence length and corresponding UTF-16 length
            let seqLen: Int
            let utf16Len: Int
            if byte < 0x80 {
                seqLen = 1; utf16Len = 1
            } else if byte < 0xE0 {
                seqLen = 2; utf16Len = 1
            } else if byte < 0xF0 {
                seqLen = 3; utf16Len = 1
            } else {
                seqLen = 4; utf16Len = 2 // Supplementary plane → surrogate pair
            }

            // Fill continuation bytes with the same UTF-16 offset
            for j in 1..<seqLen where (i + j) < utf8.count {
                mapping[i + j] = utf16Offset
            }

            utf16Offset += utf16Len
            i += seqLen
        }
        mapping[utf8.count] = utf16Offset // End sentinel

        self.utf8ToUtf16 = mapping
        self.lineStarts = lines
    }

    /// Converts a SourceLocation (1-based line/column) to a UTF-16 offset for NSRange.
    func utf16Offset(for location: SourceLocation) -> Int? {
        let line = location.line
        let column = location.column
        guard line >= 1, line <= lineStarts.count else { return nil }
        let utf8Offset = lineStarts[line - 1] + (column - 1)
        guard utf8Offset >= 0, utf8Offset < utf8ToUtf16.count else { return nil }
        return utf8ToUtf16[utf8Offset]
    }

    /// Converts a swift-markdown SourceRange to an NSRange.
    func nsRange(for range: SourceRange, maxLength: Int) -> NSRange? {
        guard let start = utf16Offset(for: range.lowerBound),
              let end = utf16Offset(for: range.upperBound) else { return nil }
        let length = end - start
        guard length >= 0, start + length <= maxLength else { return nil }
        return NSRange(location: start, length: length)
    }
}

// MARK: - Markdown Parser

/// Parses raw markdown and applies styled attributes in-place on the raw text.
/// Uses swift-markdown to parse the AST, then maps source ranges back to
/// string positions to overlay styling without changing the text content.
struct MarkdownParser {

    let style: MarkdownStyleConfiguration

    init(style: MarkdownStyleConfiguration = .default) {
        self.style = style
    }

    /// Parses a markdown string and returns a styled NSAttributedString.
    /// The returned string's text content is identical to the input.
    func parse(_ markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: markdown,
            attributes: style.defaultAttributes
        )

        guard !markdown.isEmpty else { return result }

        let table = OffsetTable(markdown)
        let document = Document(parsing: markdown)
        var walker = AttributeWalker(
            result: result,
            table: table,
            style: style
        )
        walker.visit(document)

        return result
    }

    /// Applies styling to a specific NSRange within a text storage.
    /// Parses only the affected paragraphs — not the entire document.
    func applyAttributes(to storage: NSMutableAttributedString, in range: NSRange) {
        let fullText = storage.string
        guard !fullText.isEmpty, range.length > 0 else { return }

        // Extract the paragraph text and parse just that fragment
        let nsString = fullText as NSString
        let paragraphText = nsString.substring(with: range)

        // Reset attributes in the target range to defaults (includes paragraph style)
        storage.setAttributes(style.defaultAttributes, range: range)

        guard !paragraphText.isEmpty else { return }

        // Parse the paragraph fragment
        let table = OffsetTable(paragraphText)
        let document = Document(parsing: paragraphText)

        // Walk and apply, offsetting all positions by range.location
        var walker = AttributeWalker(
            result: storage,
            table: table,
            style: style,
            baseOffset: range.location
        )
        walker.visit(document)
    }

    /// Applies styling to the full document. Used for initial load and idle re-parse.
    func applyFullAttributes(to storage: NSMutableAttributedString) {
        let fullText = storage.string
        guard !fullText.isEmpty else { return }

        let fullRange = NSRange(location: 0, length: storage.length)
        storage.setAttributes(style.defaultAttributes, range: fullRange)

        let table = OffsetTable(fullText)
        let document = Document(parsing: fullText)
        var walker = AttributeWalker(
            result: storage,
            table: table,
            style: style
        )
        walker.visit(document)
    }

    /// Applies styling to a chunk of lines. Used for progressive initial load.
    /// Returns the NSRange that was actually styled.
    func applyChunk(
        to storage: NSMutableAttributedString,
        fullText: String,
        table: OffsetTable,
        document: Document,
        fromLine: Int,
        toLine: Int
    ) -> NSRange? {
        guard fromLine < table.lineStarts.count else { return nil }
        let startUTF8 = table.lineStarts[fromLine]
        let endUTF8: Int
        if toLine < table.lineStarts.count {
            endUTF8 = table.lineStarts[toLine]
        } else {
            endUTF8 = table.utf8ToUtf16.count - 1
        }

        guard startUTF8 < table.utf8ToUtf16.count,
              endUTF8 <= table.utf8ToUtf16.count else { return nil }

        let startUTF16 = table.utf8ToUtf16[startUTF8]
        let endUTF16 = table.utf8ToUtf16[min(endUTF8, table.utf8ToUtf16.count - 1)]
        let chunkRange = NSRange(location: startUTF16, length: endUTF16 - startUTF16)
        guard chunkRange.length > 0, chunkRange.location + chunkRange.length <= storage.length else {
            return nil
        }

        var walker = AttributeWalker(
            result: storage,
            table: table,
            style: style,
            restrictToRange: chunkRange
        )
        walker.visit(document)

        return chunkRange
    }
}

// MARK: - Attribute Walker

/// Walks the swift-markdown AST and applies attributes directly to an
/// NSMutableAttributedString, using source ranges to target the correct positions.
/// The raw text is never modified — only attributes are overlaid.
private struct AttributeWalker: MarkupWalker {

    let result: NSMutableAttributedString
    let table: OffsetTable
    let style: MarkdownStyleConfiguration
    /// Offset added to all computed positions (for paragraph-local parsing).
    let baseOffset: Int
    /// If set, only apply attributes that overlap this range.
    let restrictToRange: NSRange?
    /// Current list nesting depth.
    var listDepth: Int = 0

    init(
        result: NSMutableAttributedString,
        table: OffsetTable,
        style: MarkdownStyleConfiguration,
        baseOffset: Int = 0,
        restrictToRange: NSRange? = nil
    ) {
        self.result = result
        self.table = table
        self.style = style
        self.baseOffset = baseOffset
        self.restrictToRange = restrictToRange
    }

    // MARK: - Range Helpers

    private func nsRange(for range: SourceRange) -> NSRange? {
        guard var r = table.nsRange(for: range, maxLength: result.length - baseOffset) else {
            return nil
        }
        r.location += baseOffset
        guard r.location + r.length <= result.length else { return nil }
        return r
    }

    private func shouldApply(to range: NSRange) -> Bool {
        guard let restrict = restrictToRange else { return true }
        return NSIntersectionRange(range, restrict).length > 0
    }

    /// Only applies a paragraph style if it differs from what's already there,
    /// avoiding unnecessary layout invalidation.
    private func applyParagraphStyleIfChanged(_ newStyle: NSParagraphStyle, to range: NSRange) {
        guard range.location < result.length else { return }
        let existing = result.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
        if existing != newStyle {
            result.addAttribute(.paragraphStyle, value: newStyle, range: range)
        }
    }

    // MARK: - Block Visitors

    mutating func visitHeading(_ heading: Heading) {
        guard let range = heading.range, let fullNSRange = nsRange(for: range) else {
            descendInto(heading)
            return
        }

        let level = heading.level
        let font = style.headingFonts[level] ?? style.bodyFont

        if shouldApply(to: fullNSRange) {
            result.addAttribute(.font, value: font, range: fullNSRange)
            result.addAttribute(.foregroundColor, value: style.headingColor, range: fullNSRange)

            // Headings need a taller line height than the body default
            let headingLineHeight = font.ascender - font.descender + font.leading
            let paraStyle = style.defaultParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
            paraStyle.minimumLineHeight = headingLineHeight
            paraStyle.maximumLineHeight = headingLineHeight
            applyParagraphStyleIfChanged(paraStyle, to: fullNSRange)

            let prefixLength = level + 1
            if prefixLength <= fullNSRange.length {
                let syntaxRange = NSRange(location: fullNSRange.location, length: prefixLength)
                result.addAttribute(.foregroundColor, value: style.syntaxColor, range: syntaxRange)
            }
        }

        descendInto(heading)
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        guard let range = paragraph.range, let fullNSRange = nsRange(for: range) else {
            descendInto(paragraph)
            return
        }

        if shouldApply(to: fullNSRange) {
            if listDepth > 0 {
                let paraStyle = style.defaultParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
                let indent = style.listIndent * CGFloat(listDepth)
                paraStyle.headIndent = indent
                paraStyle.firstLineHeadIndent = indent - style.listIndent
                applyParagraphStyleIfChanged(paraStyle, to: fullNSRange)
            }
            // Non-list paragraphs already have the default paragraph style from the reset pass
        }

        descendInto(paragraph)
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        guard let range = blockQuote.range, let fullNSRange = nsRange(for: range) else {
            listDepth += 1
            descendInto(blockQuote)
            listDepth -= 1
            return
        }

        listDepth += 1

        if shouldApply(to: fullNSRange) {
            result.addAttribute(.foregroundColor, value: style.blockquoteBarColor, range: fullNSRange)

            let paraStyle = style.defaultParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
            paraStyle.headIndent = style.listIndent * CGFloat(listDepth)
            paraStyle.firstLineHeadIndent = 0
            paraStyle.paragraphSpacing = style.paragraphSpacing / 2
            applyParagraphStyleIfChanged(paraStyle, to: fullNSRange)

            // Color the > prefix as syntax
            let text = (result.string as NSString).substring(with: fullNSRange)
            var searchStart = 0
            for char in text {
                if char == ">" {
                    let syntaxLoc = fullNSRange.location + searchStart
                    let syntaxLen = min(2, fullNSRange.location + fullNSRange.length - syntaxLoc)
                    if syntaxLen > 0 {
                        result.addAttribute(.foregroundColor, value: style.syntaxColor,
                                            range: NSRange(location: syntaxLoc, length: syntaxLen))
                    }
                }
                searchStart += 1
            }
        }

        descendInto(blockQuote)
        listDepth -= 1
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        listDepth += 1
        descendInto(unorderedList)
        listDepth -= 1
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        listDepth += 1
        descendInto(orderedList)
        listDepth -= 1
    }

    mutating func visitListItem(_ listItem: ListItem) {
        guard let range = listItem.range, let fullNSRange = nsRange(for: range) else {
            descendInto(listItem)
            return
        }

        if shouldApply(to: fullNSRange) {
            let paraStyle = style.defaultParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
            let indent = style.listIndent * CGFloat(listDepth)
            paraStyle.headIndent = indent
            paraStyle.firstLineHeadIndent = indent - style.listIndent
            paraStyle.paragraphSpacing = style.paragraphSpacing / 3
            applyParagraphStyleIfChanged(paraStyle, to: fullNSRange)

            let itemText = (result.string as NSString).substring(with: fullNSRange)
            let markerLength = detectMarkerLength(in: itemText)
            if markerLength > 0 {
                let markerRange = NSRange(location: fullNSRange.location, length: markerLength)
                result.addAttribute(.foregroundColor, value: style.syntaxColor, range: markerRange)
            }
        }

        descendInto(listItem)
    }

    // MARK: - Inline Visitors

    mutating func visitStrong(_ strong: Strong) {
        guard let range = strong.range, let fullNSRange = nsRange(for: range) else {
            descendInto(strong)
            return
        }

        if shouldApply(to: fullNSRange) {
            let contentStart = fullNSRange.location + 2
            let contentEnd = fullNSRange.location + fullNSRange.length - 2
            let contentLength = contentEnd - contentStart
            if contentLength > 0 {
                let contentRange = NSRange(location: contentStart, length: contentLength)
                let currentFont = result.attribute(.font, at: contentStart, effectiveRange: nil) as? NSFont ?? style.bodyFont
                let boldFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
                result.addAttribute(.font, value: boldFont, range: contentRange)
            }

            let openRange = NSRange(location: fullNSRange.location, length: 2)
            let closeRange = NSRange(location: fullNSRange.location + fullNSRange.length - 2, length: 2)
            result.addAttribute(.foregroundColor, value: style.syntaxColor, range: openRange)
            result.addAttribute(.foregroundColor, value: style.syntaxColor, range: closeRange)
        }

        descendInto(strong)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        guard let range = emphasis.range, let fullNSRange = nsRange(for: range) else {
            descendInto(emphasis)
            return
        }

        if shouldApply(to: fullNSRange) {
            let contentStart = fullNSRange.location + 1
            let contentEnd = fullNSRange.location + fullNSRange.length - 1
            let contentLength = contentEnd - contentStart
            if contentLength > 0 {
                let contentRange = NSRange(location: contentStart, length: contentLength)
                let currentFont = result.attribute(.font, at: contentStart, effectiveRange: nil) as? NSFont ?? style.bodyFont
                let italicFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
                result.addAttribute(.font, value: italicFont, range: contentRange)
            }

            let openRange = NSRange(location: fullNSRange.location, length: 1)
            let closeRange = NSRange(location: fullNSRange.location + fullNSRange.length - 1, length: 1)
            result.addAttribute(.foregroundColor, value: style.syntaxColor, range: openRange)
            result.addAttribute(.foregroundColor, value: style.syntaxColor, range: closeRange)
        }

        descendInto(emphasis)
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        guard let range = inlineCode.range, let fullNSRange = nsRange(for: range) else {
            return
        }

        if shouldApply(to: fullNSRange) {
            result.addAttribute(.font, value: style.monoFont, range: fullNSRange)

            let contentStart = fullNSRange.location + 1
            let contentEnd = fullNSRange.location + fullNSRange.length - 1
            let contentLength = contentEnd - contentStart
            if contentLength > 0 {
                let contentRange = NSRange(location: contentStart, length: contentLength)
                result.addAttribute(.backgroundColor, value: style.codeBackgroundColor, range: contentRange)
            }

            let openRange = NSRange(location: fullNSRange.location, length: 1)
            let closeRange = NSRange(location: fullNSRange.location + fullNSRange.length - 1, length: 1)
            result.addAttribute(.foregroundColor, value: style.syntaxColor, range: openRange)
            result.addAttribute(.foregroundColor, value: style.syntaxColor, range: closeRange)
        }
    }

    mutating func visitLink(_ link: Link) {
        guard let range = link.range, let fullNSRange = nsRange(for: range) else {
            descendInto(link)
            return
        }

        if shouldApply(to: fullNSRange) {
            let linkText = (result.string as NSString).substring(with: fullNSRange)

            if let closeBracket = linkText.firstIndex(of: "]") {
                let textEnd = linkText.distance(from: linkText.startIndex, to: closeBracket)

                if textEnd > 1 {
                    let linkTextRange = NSRange(location: fullNSRange.location + 1, length: textEnd - 1)
                    result.addAttribute(.foregroundColor, value: style.linkColor, range: linkTextRange)
                    result.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: linkTextRange)
                    if let destination = link.destination, let url = URL(string: destination) {
                        result.addAttribute(.link, value: url, range: linkTextRange)
                    }
                }

                let openBracket = NSRange(location: fullNSRange.location, length: 1)
                result.addAttribute(.foregroundColor, value: style.syntaxColor, range: openBracket)

                let urlPartStart = fullNSRange.location + textEnd
                let urlPartLength = fullNSRange.length - textEnd
                if urlPartLength > 0 {
                    let urlPartRange = NSRange(location: urlPartStart, length: urlPartLength)
                    result.addAttribute(.foregroundColor, value: style.syntaxColor, range: urlPartRange)
                }
            }
        }

        descendInto(link)
    }

    // MARK: - Helpers

    private func detectMarkerLength(in text: String) -> Int {
        if text.hasPrefix("- [ ] ") || text.hasPrefix("- [x] ") || text.hasPrefix("- [X] ") {
            return 6
        }
        if text.hasPrefix("- ") || text.hasPrefix("* ") || text.hasPrefix("+ ") {
            return 2
        }
        var i = 0
        for char in text {
            if char.isNumber {
                i += 1
            } else if char == "." && i > 0 {
                i += 1
                let nextIndex = text.index(text.startIndex, offsetBy: i)
                if nextIndex < text.endIndex && text[nextIndex] == " " {
                    return i + 1
                }
                return i
            } else {
                break
            }
        }
        return 0
    }
}
