//
//  MarkdownDocumentExporter.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — Markdown + plain-text DocumentExporter (Q-A).
//

import Foundation

/// A ``DocumentExporter`` for the text formats: Markdown (passed through as UTF-8 bytes)
/// and plain text (Markdown reduced via ``MarkdownPlainText``). PDF and DOCX are added in
/// later milestones (Q-B / Q-C) — until then they throw ``ExportError/unsupportedFormat(_:)``
/// so a caller never silently gets empty bytes.
nonisolated struct MarkdownDocumentExporter: DocumentExporter {
    /// Text formats are content-only — the `template` (styling) is intentionally ignored.
    nonisolated func export(markdown: String, as format: ExportFormat, template: ExportTemplate) throws -> Data {
        switch format {
        case .markdown:
            return Data(markdown.utf8)
        case .plainText:
            return Data(MarkdownPlainText.plainText(from: markdown).utf8)
        case .pdf, .docx:
            throw ExportError.unsupportedFormat(format)
        }
    }
}
