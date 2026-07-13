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

/// A `LaTeXCompiling` stub that records what it was asked to compile and returns scripted bytes.
private final class RecordingCompiler: LaTeXCompiling, @unchecked Sendable {
    let available: Bool
    let result: Result<Data, Error>
    private(set) var lastTex: String?
    private(set) var lastJobName: String?

    init(available: Bool = true, result: Result<Data, Error> = .success(Data("%PDF-stub".utf8))) {
        self.available = available
        self.result = result
    }

    var isAvailable: Bool { available }
    func compile(tex: String, jobName: String) async throws -> Data {
        lastTex = tex
        lastJobName = jobName
        return try result.get()
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

    // MARK: Milestone G — per-document export

    @Test func exportsResumeDocumentAloneWithoutCoverLetterOrWrapperHeading() throws {
        let exporter = RecordingExporter()
        let useCase = ExportApplicationUseCase(exporter: exporter)
        _ = try useCase(kit, .resume, as: .markdown)
        let md = try #require(exporter.lastMarkdown)
        #expect(md.contains("Senior iOS Engineer"))
        #expect(!md.contains("I build apps."))      // no cover-letter content
        #expect(!md.contains("# Résumé"))           // no combined-wrapper heading — the file IS the résumé
    }

    @Test func exportsCoverLetterDocumentAloneWithoutResume() throws {
        let exporter = RecordingExporter()
        let useCase = ExportApplicationUseCase(exporter: exporter)
        _ = try useCase(kit, .coverLetter, as: .markdown)
        let md = try #require(exporter.lastMarkdown)
        #expect(md.contains("I build apps."))
        #expect(!md.contains("Senior iOS Engineer"))
    }

    @Test func documentPresenceReflectsEmptySections() {
        let resumeOnly = ApplicationKit(resumeMarkdown: "Just a résumé.", coverLetter: "   ", gapNote: "")
        #expect(ExportApplicationUseCase.isPresent(.resume, in: resumeOnly))
        #expect(!ExportApplicationUseCase.isPresent(.coverLetter, in: resumeOnly))
    }

    @Test func documentFilenameSuffixes() {
        #expect(ApplicationDocument.resume.filenameSuffix == "Résumé")
        #expect(ApplicationDocument.coverLetter.filenameSuffix == "Cover Letter")
    }

    // MARK: Milestone D — awesome-cv LaTeX route

    @Test func texSourceEmitsPerDocumentDrivers() {
        let useCase = ExportApplicationUseCase(exporter: RecordingExporter())
        #expect(useCase.texSource(kit, .resume).contains("\\documentclass[6pt]{Class/Resume}"))
        #expect(useCase.texSource(kit, .coverLetter).contains("{Class/CoverLetter}"))
    }

    @Test func latexAvailabilityReflectsTheCompiler() {
        #expect(ExportApplicationUseCase(exporter: RecordingExporter()).isLaTeXAvailable == false)      // no compiler
        #expect(ExportApplicationUseCase(exporter: RecordingExporter(), compiler: RecordingCompiler(available: false)).isLaTeXAvailable == false)
        #expect(ExportApplicationUseCase(exporter: RecordingExporter(), compiler: RecordingCompiler(available: true)).isLaTeXAvailable)
    }

    @Test func latexPDFThrowsWithoutACompiler() async {
        let useCase = ExportApplicationUseCase(exporter: RecordingExporter())
        await #expect(throws: LaTeXProcessError.notInstalled) { _ = try await useCase.latexPDF(kit, .resume) }
    }

    @Test func latexPDFCompilesTheDocumentSourceViaTheCompiler() async throws {
        let compiler = RecordingCompiler(result: .success(Data("%PDF-1.5".utf8)))
        let useCase = ExportApplicationUseCase(exporter: RecordingExporter(), compiler: compiler)
        let pdf = try await useCase.latexPDF(kit, .resume)
        #expect(pdf == Data("%PDF-1.5".utf8))
        #expect(compiler.lastJobName == "Résumé")
        #expect(compiler.lastTex?.contains("\\documentclass[6pt]{Class/Resume}") == true)   // the résumé source
    }

    @Test func latexPDFCompilesEndToEndWhenAvailable() async throws {
        let compiler = LaTeXProcessClient()
        guard compiler.isAvailable, compiler.assets?.isComplete == true else { return }   // no TeX → skip
        let useCase = ExportApplicationUseCase(exporter: RoutingDocumentExporter(), compiler: compiler)
        let pdf = try await useCase.latexPDF(kit, .resume)
        #expect(pdf.prefix(4).elementsEqual(Data("%PDF".utf8)))
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
