//
//  MarkdownStructureTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Text — shared block + inline Markdown parsers (Q-C).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("MarkdownBlockParser")
struct MarkdownBlockParserTests {
    @Test func classifiesHeadingsBulletsBlanksAndParagraphs() {
        #expect(MarkdownBlockParser.classify("# Title") == .heading(level: 1, text: "Title"))
        #expect(MarkdownBlockParser.classify("### Deep") == .heading(level: 3, text: "Deep"))
        #expect(MarkdownBlockParser.classify("- item") == .bullet(text: "item"))
        #expect(MarkdownBlockParser.classify("* item") == .bullet(text: "item"))
        #expect(MarkdownBlockParser.classify("   ") == .blank)
        #expect(MarkdownBlockParser.classify("just text") == .paragraph(text: "just text"))
    }

    @Test func notAHeadingWithoutSpaceOrTooManyHashes() {
        #expect(MarkdownBlockParser.classify("#nospace") == .paragraph(text: "#nospace"))
        #expect(MarkdownBlockParser.classify("####### seven") == .paragraph(text: "####### seven"))
    }

    @Test func splitsAllLines() {
        let blocks = MarkdownBlockParser.blocks(from: "# H\n\nbody\n- b")
        #expect(blocks == [.heading(level: 1, text: "H"), .blank, .paragraph(text: "body"), .bullet(text: "b")])
    }

    @Test func classifiesThematicBreaks() {
        #expect(MarkdownBlockParser.classify("---") == .thematicBreak)
        #expect(MarkdownBlockParser.classify("***") == .thematicBreak)
        #expect(MarkdownBlockParser.classify("___") == .thematicBreak)
        #expect(MarkdownBlockParser.classify("-----") == .thematicBreak)
        #expect(MarkdownBlockParser.classify("- - -") == .thematicBreak)
        #expect(MarkdownBlockParser.classify("* * *") == .thematicBreak)
        #expect(MarkdownBlockParser.classify("  ---  ") == .thematicBreak)   // surrounding space
    }

    @Test func thematicBreakDoesNotSwallowBulletsOrShortRuns() {
        // A genuine bullet still parses as a bullet, not a break.
        #expect(MarkdownBlockParser.classify("- item") == .bullet(text: "item"))
        // Fewer than three markers, or a marker followed by text, stays a paragraph.
        #expect(MarkdownBlockParser.classify("--") == .paragraph(text: "--"))
        #expect(MarkdownBlockParser.classify("**") == .paragraph(text: "**"))
        #expect(MarkdownBlockParser.classify("-nospace") == .paragraph(text: "-nospace"))
        #expect(MarkdownBlockParser.classify("mix-of---dashes") == .paragraph(text: "mix-of---dashes"))
    }
}

@Suite("MarkdownInline")
struct MarkdownInlineTests {
    @Test func extractsBoldAndItalicRuns() {
        let runs = MarkdownInline.runs(from: "plain **bold** and *italic* end")
        #expect(runs.contains { $0.text.contains("bold") && $0.bold })
        #expect(runs.contains { $0.text.contains("italic") && $0.italic })
        #expect(runs.contains { $0.text.contains("plain") && !$0.bold && !$0.italic })
    }

    @Test func linkCollapsesToDisplayText() {
        let runs = MarkdownInline.runs(from: "see [my site](https://example.com)")
        let joined = runs.map(\.text).joined()
        #expect(joined.contains("my site"))
        #expect(!joined.contains("https://"))
    }

    @Test func plainTextIsASingleRun() {
        #expect(MarkdownInline.runs(from: "nothing special") == [MarkdownInlineRun(text: "nothing special")])
    }
}
