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
