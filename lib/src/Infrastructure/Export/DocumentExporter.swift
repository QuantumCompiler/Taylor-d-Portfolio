//
//  DocumentExporter.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — the port that renders a Markdown document to a file format.
//

import Foundation

/// Renders a Markdown document to the bytes of an ``ExportFormat``. Declared in
/// Infrastructure and kept **domain-agnostic**: it speaks only Markdown `String` in and
/// `Data` out, so it never depends on `ApplicationKit` (a Data-layer type). The Business
/// ``ExportApplicationUseCase`` assembles the kit into Markdown and calls this; the
/// Presentation layer owns the file dialog and writes the returned bytes.
///
/// The `template` selects an ``ExportTemplate`` (Milestone X) — the PDF exporter renders
/// against its typography/layout; text formats ignore it. `pageCount` measures the paginated
/// length for the one-page gate (non-paginated formats are a single "page").
protocol DocumentExporter: Sendable {
    nonisolated func export(markdown: String, as format: ExportFormat, template: ExportTemplate) throws -> Data
    nonisolated func pageCount(markdown: String, template: ExportTemplate) throws -> Int
}

extension DocumentExporter {
    /// Convenience: export with the default (``ExportTemplate/classic``) template, so callers
    /// that don't care about styling keep the original call site.
    nonisolated func export(markdown: String, as format: ExportFormat) throws -> Data {
        try export(markdown: markdown, as: format, template: .classic)
    }

    /// Non-paginated exporters (Markdown / plain text / DOCX) report a single page.
    nonisolated func pageCount(markdown: String, template: ExportTemplate) throws -> Int { 1 }
}

/// Errors raised while exporting.
enum ExportError: Error, Equatable {
    /// The exporter doesn't (yet) support this format.
    case unsupportedFormat(ExportFormat)
}
