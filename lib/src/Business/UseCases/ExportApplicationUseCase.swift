//
//  ExportApplicationUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — assemble an ApplicationKit into a document and export it.
//

import Foundation

/// One of the two deliverables in an ``ApplicationKit`` — the résumé or the cover letter.
/// They export as **separate** documents (a résumé and a cover letter are sent as two files,
/// named differently, and often only one is wanted), so the export API is per-document.
nonisolated enum ApplicationDocument: String, CaseIterable, Sendable, Identifiable {
    case resume
    case coverLetter

    var id: String { rawValue }

    /// Menu / heading label.
    var displayName: String {
        switch self {
        case .resume: return "Résumé"
        case .coverLetter: return "Cover Letter"
        }
    }

    /// The suffix appended to an export's base filename (e.g. `… - Résumé.pdf`).
    var filenameSuffix: String { displayName }
}

/// Turns a generated ``ApplicationKit`` into exportable bytes. Each deliverable — the résumé
/// and the cover letter — exports as its **own** document (the factual, grounded output; the
/// internal `gapNote` is advisory and never part of a deliverable), rendered by the
/// domain-agnostic ``DocumentExporter`` for the requested ``ExportFormat``. A combined
/// résumé+cover-letter assembly is retained for "copy everything" callers.
nonisolated struct ExportApplicationUseCase: Sendable {
    let exporter: any DocumentExporter
    /// The awesome-cv LaTeX compiler for the high-fidelity PDF route (Milestone D); `nil` (or an
    /// unavailable one) means the LaTeX route isn't offered.
    let compiler: (any LaTeXCompiling)?

    init(exporter: any DocumentExporter, compiler: (any LaTeXCompiling)? = nil) {
        self.exporter = exporter
        self.compiler = compiler
    }

    // MARK: LaTeX (awesome-cv) route — Milestone D

    /// Whether the awesome-cv LaTeX PDF route is available (a `lualatex` install was found).
    var isLaTeXAvailable: Bool { compiler?.isAvailable ?? false }

    /// The awesome-cv `.tex` **source** for one document — deterministic, no compile, so it works
    /// even without a TeX install (a handoff into the manual `PortfolioBuddy` pipeline).
    func texSource(_ kit: ApplicationKit, _ document: ApplicationDocument) -> String {
        switch document {
        case .resume: return TexDocumentBuilder.resume(fromMarkdown: kit.resumeMarkdown)
        case .coverLetter: return TexDocumentBuilder.coverLetter(fromMarkdown: kit.coverLetter)
        }
    }

    /// Compiles one document into an awesome-cv **PDF** via `lualatex`. Throws
    /// ``LaTeXProcessError/notInstalled`` when no compiler is wired/available.
    func latexPDF(_ kit: ApplicationKit, _ document: ApplicationDocument) async throws -> Data {
        guard let compiler else { throw LaTeXProcessError.notInstalled }
        return try await compiler.compile(tex: texSource(kit, document), jobName: document.displayName)
    }

    /// Exports a **single** document (résumé or cover letter) — the primary path. Each file
    /// contains only that document's Markdown (no combined wrapper heading).
    func callAsFunction(_ kit: ApplicationKit, _ document: ApplicationDocument,
                        as format: ExportFormat, template: ExportTemplate = .classic) throws -> Data {
        try exporter.export(markdown: Self.markdown(for: document, from: kit), as: format, template: template)
    }

    /// The trimmed Markdown for one document (empty when that section wasn't generated).
    static func markdown(for document: ApplicationDocument, from kit: ApplicationKit) -> String {
        switch document {
        case .resume: return kit.resumeMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        case .coverLetter: return kit.coverLetter.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Whether `document` has content to export (an all-blank section isn't offered).
    static func isPresent(_ document: ApplicationDocument, in kit: ApplicationKit) -> Bool {
        !markdown(for: document, from: kit).isEmpty
    }

    /// Exports the **combined** résumé + cover letter as one document — kept for the
    /// "copy everything" affordance, not the per-document file export.
    func callAsFunction(_ kit: ApplicationKit, as format: ExportFormat, template: ExportTemplate = .classic) throws -> Data {
        try exporter.export(markdown: Self.assembleMarkdown(from: kit), as: format, template: template)
    }

    /// How many pages the **résumé alone** occupies in `template`'s print layout — the
    /// measurement behind the one-page gate (Milestone X). Returns 0 when there's no résumé
    /// (nothing to gate). The cover letter is deliberately excluded: the one-page discipline
    /// is a résumé rule.
    func resumePageCount(_ kit: ApplicationKit, template: ExportTemplate = .classic) throws -> Int {
        let resume = kit.resumeMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resume.isEmpty else { return 0 }
        return try exporter.pageCount(markdown: resume, template: template)
    }

    /// Combines the résumé and cover letter under clear headings. Empty sections are
    /// omitted so a kit with only one populated document exports cleanly.
    static func assembleMarkdown(from kit: ApplicationKit) -> String {
        var sections: [String] = []
        let resume = kit.resumeMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if !resume.isEmpty { sections.append("# Résumé\n\n\(resume)") }
        let cover = kit.coverLetter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cover.isEmpty { sections.append("# Cover Letter\n\n\(cover)") }
        return sections.joined(separator: "\n\n")
    }
}
