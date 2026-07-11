//
//  ExportApplicationUseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — assemble + route an ApplicationKit export (Q-A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Records the Markdown + format + template it was asked to export, for assembly assertions.
private final class RecordingExporter: DocumentExporter, @unchecked Sendable {
    private(set) var lastMarkdown: String?
    private(set) var lastFormat: ExportFormat?
    private(set) var lastTemplate: ExportTemplate?
    private(set) var lastPageCountMarkdown: String?
    var pageCountToReturn = 1

    func export(markdown: String, as format: ExportFormat, template: ExportTemplate) throws -> Data {
        lastMarkdown = markdown
        lastFormat = format
        lastTemplate = template
        return Data(markdown.utf8)
    }

    func pageCount(markdown: String, template: ExportTemplate) throws -> Int {
        lastPageCountMarkdown = markdown
        lastTemplate = template
        return pageCountToReturn
    }
}

@Suite("ExportApplicationUseCase")
struct ExportApplicationUseCaseTests {
    private let kit = ApplicationKit(
        resumeMarkdown: "# Jane Dev\nSenior iOS Engineer",
        coverLetter: "## About Me\nI build apps.",
        gapNote: "No Kotlin experience."
    )

    @Test func assemblesResumeAndCoverUnderHeadingsAndOmitsGapNote() throws {
        let exporter = RecordingExporter()
        let useCase = ExportApplicationUseCase(exporter: exporter)
        _ = try useCase(kit, as: .markdown)

        let assembled = try #require(exporter.lastMarkdown)
        #expect(assembled.contains("# Résumé"))
        #expect(assembled.contains("Senior iOS Engineer"))
        #expect(assembled.contains("# Cover Letter"))
        #expect(assembled.contains("I build apps."))
        #expect(!assembled.contains("No Kotlin experience."))   // gapNote is advisory, not exported
        #expect(exporter.lastFormat == .markdown)
    }

    @Test func emptySectionsAreOmitted() {
        let resumeOnly = ApplicationKit(resumeMarkdown: "Just a résumé.", coverLetter: "   ", gapNote: "")
        let assembled = ExportApplicationUseCase.assembleMarkdown(from: resumeOnly)
        #expect(assembled.contains("# Résumé"))
        #expect(!assembled.contains("# Cover Letter"))
    }

    @Test func routesFormatToTheExporterEndToEnd() throws {
        let useCase = ExportApplicationUseCase(exporter: MarkdownDocumentExporter())
        let text = String(decoding: try useCase(kit, as: .plainText), as: UTF8.self)
        #expect(!text.contains("#"))                 // plain-text path ran
        #expect(text.contains("Résumé"))
        #expect(throws: ExportError.unsupportedFormat(.pdf)) { _ = try useCase(kit, as: .pdf) }
    }

    // MARK: Template + one-page gate (Milestone X)

    @Test func forwardsTheChosenTemplateToTheExporter() throws {
        let exporter = RecordingExporter()
        let useCase = ExportApplicationUseCase(exporter: exporter)
        _ = try useCase(kit, as: .pdf, template: .modern)
        #expect(exporter.lastTemplate == .modern)
    }

    @Test func defaultsToTheClassicTemplate() throws {
        let exporter = RecordingExporter()
        let useCase = ExportApplicationUseCase(exporter: exporter)
        _ = try useCase(kit, as: .pdf)
        #expect(exporter.lastTemplate == .classic)
    }

    @Test func resumePageCountMeasuresResumeOnlyWithTemplate() throws {
        let exporter = RecordingExporter()
        exporter.pageCountToReturn = 2
        let useCase = ExportApplicationUseCase(exporter: exporter)

        let pages = try useCase.resumePageCount(kit, template: .compact)

        #expect(pages == 2)
        #expect(exporter.lastTemplate == .compact)
        // Only the résumé is measured — the cover letter is excluded from the gate.
        let measured = try #require(exporter.lastPageCountMarkdown)
        #expect(measured.contains("Senior iOS Engineer"))
        #expect(!measured.contains("I build apps."))
    }

    @Test func resumePageCountIsZeroWhenThereIsNoResume() throws {
        let exporter = RecordingExporter()
        let useCase = ExportApplicationUseCase(exporter: exporter)
        let coverOnly = ApplicationKit(resumeMarkdown: "  ", coverLetter: "Hello.", gapNote: "")
        #expect(try useCase.resumePageCount(coverOnly) == 0)
        #expect(exporter.lastPageCountMarkdown == nil)   // never called the exporter
    }
}
