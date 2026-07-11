//
//  ExportFormat.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — the file formats a generated application can be exported to.
//

import UniformTypeIdentifiers

/// A format the generated résumé + cover letter can be exported to. Markdown and plain
/// text ship in Q-A; PDF (Q-B) and DOCX (Q-C) are added behind the same ``DocumentExporter``
/// port. Domain-agnostic — declared in Infrastructure alongside the exporter.
enum ExportFormat: String, CaseIterable, Sendable, Identifiable {
    case markdown
    case plainText
    case pdf
    case docx

    var id: String { rawValue }

    /// Human-readable name for menus.
    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .plainText: return "Plain Text"
        case .pdf: return "PDF"
        case .docx: return "Word (DOCX)"
        }
    }

    /// The file extension (no dot) for a save dialog's default filename.
    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .plainText: return "txt"
        case .pdf: return "pdf"
        case .docx: return "docx"
        }
    }

    /// The uniform type for the save panel.
    var contentType: UTType {
        switch self {
        case .markdown: return UTType(filenameExtension: "md") ?? .plainText
        case .plainText: return .plainText
        case .pdf: return .pdf
        case .docx: return UTType(filenameExtension: "docx") ?? .data
        }
    }
}
