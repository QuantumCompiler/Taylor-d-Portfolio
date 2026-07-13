//
//  PDFDocumentExporterTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Export — Markdown → PDF (Q-B).
//

import Testing
import Foundation
import PDFKit
@testable import Taylor_d_Portfolio

@Suite("PDFDocumentExporter")
struct PDFDocumentExporterTests {
    private let exporter = PDFDocumentExporter()
    private let sample = "# Résumé\n\n**Senior** iOS Engineer\n\n- Swift\n- SwiftUI\n\n## Cover Letter\n\nI build apps."

    @Test func producesValidNonEmptyPDF() throws {
        let data = try exporter.export(markdown: sample, as: .pdf)
        #expect(data.count > 0)
        #expect(data.prefix(4).elementsEqual(Data("%PDF".utf8)))   // PDF magic header
        let doc = try #require(PDFDocument(data: data))
        #expect(doc.pageCount >= 1)
    }

    @Test func longDocumentPaginatesToMultiplePages() throws {
        let long = (1...400).map { "Line \($0): experience, projects, and impact." }.joined(separator: "\n\n")
        let data = try exporter.export(markdown: long, as: .pdf)
        let doc = try #require(PDFDocument(data: data))
        #expect(doc.pageCount >= 2)          // flows past one page without looping forever
    }

    @Test func emptyMarkdownStillProducesAValidPDF() throws {
        let data = try exporter.export(markdown: "", as: .pdf)
        let doc = try #require(PDFDocument(data: data))
        #expect(doc.pageCount >= 1)
    }

    @Test func rejectsNonPDFFormats() {
        #expect(throws: ExportError.unsupportedFormat(.markdown)) {
            _ = try exporter.export(markdown: "x", as: .markdown)
        }
        #expect(throws: ExportError.unsupportedFormat(.docx)) {
            _ = try exporter.export(markdown: "x", as: .docx)
        }
    }

    // MARK: Templates + one-page gate (Milestone X)

    @Test func pageCountMatchesTheRenderedPDF() throws {
        let long = (1...400).map { "Line \($0): experience, projects, and impact." }.joined(separator: "\n\n")
        let counted = try exporter.pageCount(markdown: long, template: .classic)
        let rendered = try #require(PDFDocument(data: try exporter.export(markdown: long, as: .pdf, template: .classic)))
        #expect(counted == rendered.pageCount)   // the gate agrees with the real output
        #expect(counted >= 2)
    }

    @Test func emptyDocumentIsOnePage() throws {
        #expect(try exporter.pageCount(markdown: "", template: .classic) == 1)
    }

    @Test func compactTemplateFitsAtLeastAsMuchAsClassic() throws {
        // A borderline-length résumé should never take *more* pages in Compact than Classic.
        let resume = (1...60).map { "- Accomplishment number \($0) with measurable, quantified impact." }
            .joined(separator: "\n")
        let classicPages = try exporter.pageCount(markdown: resume, template: .classic)
        let compactPages = try exporter.pageCount(markdown: resume, template: .compact)
        #expect(compactPages <= classicPages)
    }

    @Test func templateChangesTheRenderedBytes() throws {
        let sample = "# Name\n\nSenior Engineer with a track record of shipping."
        let classic = try exporter.export(markdown: sample, as: .pdf, template: .classic)
        let modern = try exporter.export(markdown: sample, as: .pdf, template: .modern)
        #expect(classic != modern)   // serif + accent headings produce different output
    }

    @Test func thematicBreakRendersAsARuleNotLiteralDashes() {
        let rendered = MarkdownAttributedRenderer.attributedString(from: "Summary\n\n---\n\nSkills")
        #expect(!rendered.string.contains("---"))   // no literal dashes reach the PDF text
        var hasUnderline = false
        rendered.enumerateAttribute(.underlineStyle, in: NSRange(location: 0, length: rendered.length)) { value, _, _ in
            if let raw = value as? Int, raw != 0 { hasUnderline = true }
        }
        #expect(hasUnderline)   // the break is drawn as an underlined (rule) run
    }
}

@Suite("ExportTemplate")
struct ExportTemplateTests {
    @Test func allTemplatesHaveDistinctResolvedStyles() {
        let styles = ExportTemplate.allCases.map(\.style)
        #expect(Set(ExportTemplate.allCases.map(\.displayName)).count == ExportTemplate.allCases.count)
        #expect(styles[0] != styles[1])
        #expect(styles[1] != styles[2])
    }

    @Test func compactUsesSmallerTypeAndTighterMarginsThanClassic() {
        let classic = ExportTemplate.classic.style
        let compact = ExportTemplate.compact.style
        #expect(compact.bodySize < classic.bodySize)
        #expect(compact.margin < classic.margin)
    }

    @Test func modernUsesSerifAndAnAccentHeadingColour() {
        let modern = ExportTemplate.modern.style
        #expect(modern.usesSerif)
        #expect(modern.headingColor != .black)
    }

    @Test func headingSizeClampsDeepLevelsToH3() {
        let style = ExportTemplate.classic.style
        #expect(style.headingSize(forLevel: 1) == style.h1Size)
        #expect(style.headingSize(forLevel: 2) == style.h2Size)
        #expect(style.headingSize(forLevel: 5) == style.h3Size)   // deeper levels clamp to h3
    }
}

@Suite("RoutingDocumentExporter")
struct RoutingDocumentExporterTests {
    private let router = RoutingDocumentExporter()

    @Test func dispatchesTextFormatsToTheMarkdownExporter() throws {
        #expect(String(decoding: try router.export(markdown: "# H", as: .markdown), as: UTF8.self) == "# H")
        #expect(String(decoding: try router.export(markdown: "# H", as: .plainText), as: UTF8.self).contains("#") == false)
    }

    @Test func dispatchesPDFToThePDFExporter() throws {
        let data = try router.export(markdown: "# H\n\nbody", as: .pdf)
        #expect(data.prefix(4).elementsEqual(Data("%PDF".utf8)))
    }

    @Test func dispatchesDOCXToTheDocxExporter() throws {
        let data = try router.export(markdown: "# H\n\nbody", as: .docx)
        #expect(data.prefix(4).elementsEqual(Data([0x50, 0x4b, 0x03, 0x04])))  // PK zip header
    }
}
