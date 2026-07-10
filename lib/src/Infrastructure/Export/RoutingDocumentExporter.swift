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

    nonisolated func export(markdown: String, as format: ExportFormat) throws -> Data {
        switch format {
        case .markdown, .plainText:
            return try text.export(markdown: markdown, as: format)
        case .pdf:
            return try pdf.export(markdown: markdown, as: format)
        case .docx:
            return try docx.export(markdown: markdown, as: format)
        }
    }
}
