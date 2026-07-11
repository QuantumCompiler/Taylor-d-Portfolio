//
//  RoutingDocumentExporter.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — dispatches each ExportFormat to a specialised exporter.
//

import Foundation

/// The composed ``DocumentExporter`` the app injects: it routes each ``ExportFormat`` to the
/// exporter that handles it, so adding a format is a new sub-exporter + one `case` rather than
/// a change to any existing one. DOCX (Q-C) is not yet wired and throws until then.
nonisolated struct RoutingDocumentExporter: DocumentExporter {
    var text: any DocumentExporter = MarkdownDocumentExporter()
    var pdf: any DocumentExporter = PDFDocumentExporter()
    var docx: any DocumentExporter = DocxDocumentExporter()

    nonisolated func export(markdown: String, as format: ExportFormat, template: ExportTemplate) throws -> Data {
        switch format {
        case .markdown, .plainText:
            return try text.export(markdown: markdown, as: format, template: template)
        case .pdf:
            return try pdf.export(markdown: markdown, as: format, template: template)
        case .docx:
            return try docx.export(markdown: markdown, as: format, template: template)
        }
    }

    /// The one-page gate is a print/PDF concern, so measurement always routes to the PDF
    /// exporter regardless of the format the user ultimately exports (Milestone X).
    nonisolated func pageCount(markdown: String, template: ExportTemplate) throws -> Int {
        try pdf.pageCount(markdown: markdown, template: template)
    }
}
