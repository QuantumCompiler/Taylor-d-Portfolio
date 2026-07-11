//
//  ExportApplicationUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — assemble an ApplicationKit into a document and export it.
//

import Foundation

/// Turns a generated ``ApplicationKit`` into exportable bytes: it assembles the résumé and
/// cover letter into a single Markdown document (the factual, grounded output — the
/// internal `gapNote` is advisory and not part of the deliverable), then hands that Markdown
/// to the domain-agnostic ``DocumentExporter`` for the requested ``ExportFormat``.
nonisolated struct ExportApplicationUseCase: Sendable {
    let exporter: any DocumentExporter

    init(exporter: any DocumentExporter) {
        self.exporter = exporter
    }

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
