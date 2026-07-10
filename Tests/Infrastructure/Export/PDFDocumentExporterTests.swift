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

    @Test func docxIsStillUnsupported() {
        #expect(throws: ExportError.unsupportedFormat(.docx)) {
            _ = try router.export(markdown: "x", as: .docx)
        }
    }
}
