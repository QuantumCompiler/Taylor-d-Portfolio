//
//  PlatformDocumentTextExtractor.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Documents — PDFKit + AppKit-backed text extraction.
//

import Foundation
import PDFKit
#if canImport(AppKit)
import AppKit
#endif

/// The production `DocumentTextExtractor`: PDFKit for PDFs, `NSAttributedString` for
/// Word/RTF/OpenDocument, and a direct read for plain text.
nonisolated struct PlatformDocumentTextExtractor: DocumentTextExtractor {

    /// File extensions handled via `NSAttributedString`'s document importers.
    private static let attributedExtensions: Set<String> = ["rtf", "rtfd", "doc", "docx", "odt"]
    /// Extensions treated as plain UTF-8 text.
    private static let plainExtensions: Set<String> = ["txt", "text", "md", "markdown"]

    func extractText(from url: URL) throws -> String {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()
        let raw: String
        switch ext {
        case "pdf":
            raw = try pdfText(url)
        case _ where Self.plainExtensions.contains(ext):
            raw = try plainText(url)
        case _ where Self.attributedExtensions.contains(ext):
            raw = try attributedText(url)
        default:
            throw DocumentExtractionError.unsupportedType(ext.isEmpty ? "unknown" : ext)
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DocumentExtractionError.emptyDocument }
        return trimmed
    }

    // MARK: Per-format readers

    private func pdfText(_ url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw DocumentExtractionError.readFailed("Couldn't open the PDF.")
        }
        return document.string ?? ""
    }

    private func plainText(_ url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) { return utf8 }
        // Fall back to the document importers for non-UTF-8 text files.
        return try attributedText(url)
    }

    private func attributedText(_ url: URL) throws -> String {
        do {
            return try NSAttributedString(url: url, options: [:], documentAttributes: nil).string
        } catch {
            throw DocumentExtractionError.readFailed(error.localizedDescription)
        }
    }
}
