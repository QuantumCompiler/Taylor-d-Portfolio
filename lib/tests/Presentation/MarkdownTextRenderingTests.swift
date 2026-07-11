//
//  MarkdownTextRenderingTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation — the parsing `MarkdownText` renders from (S-A).
//
//  `MarkdownText` is a SwiftUI view (not unit-testable without ViewInspector), but it renders
//  purely from `MarkdownBlockParser` + `MarkdownInline`. These assert a realistic generated
//  document decomposes into the block/inline structure the view turns into styled Text.
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("MarkdownText rendering inputs")
struct MarkdownTextRenderingTests {
    private let resume = """
    # Jane Dev
    **Senior iOS Engineer**

    ## Experience
    - Led the *SwiftUI* rewrite
    - Shipped offline sync
    """

    @Test func decomposesHeadingsBulletsAndParagraphs() {
        let blocks = MarkdownBlockParser.blocks(from: resume)
        #expect(blocks.contains(.heading(level: 1, text: "Jane Dev")))
        #expect(blocks.contains(.heading(level: 2, text: "Experience")))
        #expect(blocks.contains(.bullet(text: "Led the *SwiftUI* rewrite")))
        #expect(blocks.contains(.bullet(text: "Shipped offline sync")))
        // A paragraph carrying inline bold.
        #expect(blocks.contains(.paragraph(text: "**Senior iOS Engineer**")))
    }

    @Test func inlineRunsCarryBoldAndItalic() {
        let bold = MarkdownInline.runs(from: "**Senior iOS Engineer**")
        #expect(bold.contains { $0.text.contains("Senior") && $0.bold })

        let bulletRuns = MarkdownInline.runs(from: "Led the *SwiftUI* rewrite")
        #expect(bulletRuns.contains { $0.text.contains("SwiftUI") && $0.italic })
        #expect(bulletRuns.contains { $0.text.contains("Led the") && !$0.bold && !$0.italic })
    }
}
