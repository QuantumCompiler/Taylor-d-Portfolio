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
protocol DocumentExporter: Sendable {
    nonisolated func export(markdown: String, as format: ExportFormat) throws -> Data
}

/// Errors raised while exporting.
enum ExportError: Error, Equatable {
    /// The exporter doesn't (yet) support this format.
    case unsupportedFormat(ExportFormat)
}
