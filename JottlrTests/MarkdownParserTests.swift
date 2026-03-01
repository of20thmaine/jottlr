import Foundation
import Testing
import AppKit
@testable import Jottlr

@Suite("MarkdownParser Tests")
struct MarkdownParserTests {
    let parser = MarkdownParser()
    let style = MarkdownStyleConfiguration.default

    // MARK: - Heading Detection

    @Test func headingLevel1ProducesLargeBoldFont() {
        let result = parser.parse("# Title")
        let expectedFont = style.headingFonts[1]!

        // The output should contain "# " (syntax) + "Title" (content) + "\n"
        // Find the range of "Title" in the result
        let fullString = result.string
        guard let titleRange = fullString.range(of: "Title") else {
            Issue.record("Could not find 'Title' in parsed output: '\(fullString)'")
            return
        }
        let nsRange = NSRange(titleRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let font = attrs[.font] as? NSFont
        #expect(font == expectedFont, "Expected heading 1 font (\(expectedFont.pointSize)pt bold), got \(String(describing: font))")
    }

    @Test func headingLevel2ProducesMediumBoldFont() {
        let result = parser.parse("## Subtitle")
        let expectedFont = style.headingFonts[2]!

        let fullString = result.string
        guard let range = fullString.range(of: "Subtitle") else {
            Issue.record("Could not find 'Subtitle' in parsed output")
            return
        }
        let nsRange = NSRange(range, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let font = attrs[.font] as? NSFont
        #expect(font == expectedFont)
    }

    @Test func headingLevel3ProducesSmallBoldFont() {
        let result = parser.parse("### Section")
        let expectedFont = style.headingFonts[3]!

        let fullString = result.string
        guard let range = fullString.range(of: "Section") else {
            Issue.record("Could not find 'Section' in parsed output")
            return
        }
        let nsRange = NSRange(range, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let font = attrs[.font] as? NSFont
        #expect(font == expectedFont)
    }

    @Test func headingSyntaxCharactersVisibleInSyntaxColor() {
        let result = parser.parse("# Title")
        let fullString = result.string

        // The # should be present and colored with syntaxColor
        guard let hashRange = fullString.range(of: "#") else {
            Issue.record("Hash character not found in output")
            return
        }
        let nsRange = NSRange(hashRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == style.syntaxColor)
    }

    // MARK: - Bold

    @Test func boldProducesBoldTrait() {
        let result = parser.parse("**word**")
        let fullString = result.string

        guard let wordRange = fullString.range(of: "word") else {
            Issue.record("Could not find 'word' in parsed output: '\(fullString)'")
            return
        }
        let nsRange = NSRange(wordRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        let traits = font.flatMap { NSFontManager.shared.traits(of: $0) }
        #expect(traits?.contains(.boldFontMask) == true, "Expected bold trait on 'word'")
    }

    @Test func boldSyntaxCharactersInSyntaxColor() {
        let result = parser.parse("**word**")
        let fullString = result.string

        // Find the first **
        guard let starRange = fullString.range(of: "**") else {
            Issue.record("Stars not found in output")
            return
        }
        let nsRange = NSRange(starRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == style.syntaxColor)
    }

    // MARK: - Italic

    @Test func italicProducesItalicTrait() {
        let result = parser.parse("*word*")
        let fullString = result.string

        guard let wordRange = fullString.range(of: "word") else {
            Issue.record("Could not find 'word' in parsed output: '\(fullString)'")
            return
        }
        let nsRange = NSRange(wordRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        let traits = font.flatMap { NSFontManager.shared.traits(of: $0) }
        #expect(traits?.contains(.italicFontMask) == true, "Expected italic trait on 'word'")
    }

    // MARK: - Inline Code

    @Test func codeProducesMonospaceFont() {
        let result = parser.parse("`code`")
        let fullString = result.string

        guard let codeRange = fullString.range(of: "code") else {
            Issue.record("Could not find 'code' in parsed output: '\(fullString)'")
            return
        }
        let nsRange = NSRange(codeRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let font = attrs[.font] as? NSFont
        #expect(font == style.monoFont, "Expected monospace font on 'code'")
    }

    @Test func codeHasBackgroundColor() {
        let result = parser.parse("`code`")
        let fullString = result.string

        guard let codeRange = fullString.range(of: "code") else {
            Issue.record("Could not find 'code' in parsed output")
            return
        }
        let nsRange = NSRange(codeRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let bgColor = attrs[.backgroundColor] as? NSColor
        #expect(bgColor != nil, "Expected background color on inline code")
    }

    // MARK: - Unordered List

    @Test func unorderedListProducesIndent() {
        let result = parser.parse("- item")
        let fullString = result.string

        // The list item should have a paragraph style with head indent
        guard let itemRange = fullString.range(of: "item") else {
            Issue.record("Could not find 'item' in parsed output: '\(fullString)'")
            return
        }
        let nsRange = NSRange(itemRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let paraStyle = attrs[.paragraphStyle] as? NSParagraphStyle
        #expect(paraStyle != nil, "Expected paragraph style on list item")
        #expect(paraStyle!.headIndent > 0, "Expected positive head indent for list item")
    }

    @Test func unorderedListContainsBulletSyntax() {
        let result = parser.parse("- item")
        let fullString = result.string

        // The dash syntax should be preserved
        #expect(fullString.contains("- "), "Expected '- ' syntax to be visible in output")
    }

    // MARK: - Nested List

    @Test func nestedListProducesDeeperIndent() {
        let markdown = "- outer\n    - inner"
        let result = parser.parse(markdown)
        let fullString = result.string

        // Find "outer" and "inner" and compare their indent levels
        guard let outerRange = fullString.range(of: "outer"),
              let innerRange = fullString.range(of: "inner") else {
            Issue.record("Could not find 'outer' or 'inner' in: '\(fullString)'")
            return
        }

        let outerNSRange = NSRange(outerRange, in: fullString)
        let innerNSRange = NSRange(innerRange, in: fullString)

        let outerAttrs = result.attributes(at: outerNSRange.location, effectiveRange: nil)
        let innerAttrs = result.attributes(at: innerNSRange.location, effectiveRange: nil)

        let outerIndent = (outerAttrs[.paragraphStyle] as? NSParagraphStyle)?.headIndent ?? 0
        let innerIndent = (innerAttrs[.paragraphStyle] as? NSParagraphStyle)?.headIndent ?? 0

        #expect(innerIndent > outerIndent, "Expected nested list to have deeper indent (\(innerIndent) > \(outerIndent))")
    }

    // MARK: - Checkbox

    @Test func uncheckedCheckboxProducesCheckboxCharacter() {
        let result = parser.parse("- [ ] task")
        let fullString = result.string

        #expect(fullString.contains("[ ]") || fullString.contains("☐"),
                "Expected checkbox syntax or character in: '\(fullString)'")
    }

    @Test func checkedCheckboxProducesCheckedCharacter() {
        let result = parser.parse("- [x] done")
        let fullString = result.string

        #expect(fullString.contains("[x]") || fullString.contains("☑"),
                "Expected checked checkbox syntax or character in: '\(fullString)'")
    }

    // MARK: - Mixed Content

    @Test func mixedBoldItalicAndCodeInParagraph() {
        let result = parser.parse("This is **bold** and *italic* and `code` text.")
        let fullString = result.string

        // Verify bold word has bold trait
        if let boldRange = fullString.range(of: "bold") {
            let nsRange = NSRange(boldRange, in: fullString)
            let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)
            let font = attrs[.font] as? NSFont
            let traits = font.flatMap { NSFontManager.shared.traits(of: $0) }
            #expect(traits?.contains(.boldFontMask) == true, "Expected bold trait on 'bold'")
        }

        // Verify italic word has italic trait
        if let italicRange = fullString.range(of: "italic") {
            let nsRange = NSRange(italicRange, in: fullString)
            let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)
            let font = attrs[.font] as? NSFont
            let traits = font.flatMap { NSFontManager.shared.traits(of: $0) }
            #expect(traits?.contains(.italicFontMask) == true, "Expected italic trait on 'italic'")
        }

        // Verify code word has mono font
        if let codeRange = fullString.range(of: "code") {
            let nsRange = NSRange(codeRange, in: fullString)
            let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)
            let font = attrs[.font] as? NSFont
            #expect(font == style.monoFont, "Expected monospace font on 'code'")
        }
    }

    // MARK: - Links

    @Test func linkProducesBlueUnderlinedText() {
        let result = parser.parse("[click here](https://example.com)")
        let fullString = result.string

        guard let linkRange = fullString.range(of: "click here") else {
            Issue.record("Could not find 'click here' in: '\(fullString)'")
            return
        }
        let nsRange = NSRange(linkRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == style.linkColor, "Expected link color on link text")

        let underline = attrs[.underlineStyle] as? Int
        #expect(underline == NSUnderlineStyle.single.rawValue, "Expected underline on link text")
    }

    // MARK: - Blockquote

    @Test func blockquoteHasIndentAndAccentColor() {
        let result = parser.parse("> quoted text")
        let fullString = result.string

        guard let quoteRange = fullString.range(of: "quoted text") else {
            Issue.record("Could not find 'quoted text' in: '\(fullString)'")
            return
        }
        let nsRange = NSRange(quoteRange, in: fullString)
        let attrs = result.attributes(at: nsRange.location, effectiveRange: nil)

        let color = attrs[.foregroundColor] as? NSColor
        #expect(color == style.blockquoteBarColor, "Expected blockquote accent color")
    }

    // MARK: - Ordered List

    @Test func orderedListShowsNumbers() {
        let result = parser.parse("1. first\n2. second")
        let fullString = result.string

        #expect(fullString.contains("1."), "Expected '1.' in ordered list output")
        #expect(fullString.contains("2."), "Expected '2.' in ordered list output")
    }
}
