//
//  ExportApplicationUseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — assemble + route an ApplicationKit export (Q-A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Records the Markdown + format it was asked to export, for assembly assertions.
private final class RecordingExporter: DocumentExporter, @unchecked Sendable {
    private(set) var lastMarkdown: String?
    private(set) var lastFormat: ExportFormat?
    func export(markdown: String, as format: ExportFormat) throws -> Data {
        lastMarkdown = markdown
        lastFormat = format
        return Data(markdown.utf8)
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
}
