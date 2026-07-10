//
//  MarkdownDocumentExporterTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Export — Markdown + plain-text rendering (Q-A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("MarkdownDocumentExporter")
struct MarkdownDocumentExporterTests {
    private let exporter = MarkdownDocumentExporter()
    private let markdown = "# Résumé\n\n**Senior** iOS Engineer\n\n- Swift\n- SwiftUI\n\n[portfolio](https://example.com)"

    @Test func markdownIsReturnedVerbatim() throws {
        let data = try exporter.export(markdown: markdown, as: .markdown)
        #expect(String(decoding: data, as: UTF8.self) == markdown)
    }

    @Test func plainTextStripsMarkdownSyntax() throws {
        let data = try exporter.export(markdown: markdown, as: .plainText)
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("#"))
        #expect(!text.contains("**"))
        #expect(!text.contains("]("))       // link syntax gone
        #expect(text.contains("Senior iOS Engineer"))
        #expect(text.contains("• Swift"))    // bullets become dots
        #expect(text.contains("portfolio"))  // link text kept
        #expect(!text.contains("https://"))  // link URL dropped
    }

    @Test func pdfAndDocxAreUnsupportedForNow() {
        #expect(throws: ExportError.unsupportedFormat(.pdf)) {
            _ = try exporter.export(markdown: markdown, as: .pdf)
        }
        #expect(throws: ExportError.unsupportedFormat(.docx)) {
            _ = try exporter.export(markdown: markdown, as: .docx)
        }
    }

    @Test func formatMetadataIsConsistent() {
        #expect(ExportFormat.markdown.fileExtension == "md")
        #expect(ExportFormat.plainText.fileExtension == "txt")
        #expect(ExportFormat.pdf.fileExtension == "pdf")
        #expect(ExportFormat.docx.fileExtension == "docx")
    }
}

@Suite("MarkdownPlainText")
struct MarkdownPlainTextTests {
    @Test func stripsHeadingsBulletsEmphasisLinksAndCode() {
        let md = "## Why Me\n\nI ship **fast** and _clean_ `code`.\n\n- item one\n* item two\n\nSee [my site](https://x.com)."
        let text = MarkdownPlainText.plainText(from: md)
        #expect(text.contains("Why Me"))
        #expect(!text.contains("##"))
        #expect(text.contains("I ship fast and clean code."))
        #expect(text.contains("• item one"))
        #expect(text.contains("• item two"))
        #expect(text.contains("See my site."))
        #expect(!text.contains("https://x.com"))
    }

    @Test func collapsesExcessBlankLinesAndTrims() {
        let md = "\n\nA\n\n\n\nB\n\n"
        #expect(MarkdownPlainText.plainText(from: md) == "A\n\nB")
    }
}
