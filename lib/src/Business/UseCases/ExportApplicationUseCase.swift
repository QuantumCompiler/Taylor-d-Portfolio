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

    func callAsFunction(_ kit: ApplicationKit, as format: ExportFormat) throws -> Data {
        try exporter.export(markdown: Self.assembleMarkdown(from: kit), as: format)
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
