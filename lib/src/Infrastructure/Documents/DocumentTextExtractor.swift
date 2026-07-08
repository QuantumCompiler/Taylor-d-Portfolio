//
//  DocumentTextExtractor.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Documents — extract plain text from a document file.
//

import Foundation

/// Extracts plain text from a document file (PDF, Word, RTF, plain text…).
///
/// Domain-agnostic Infrastructure plumbing: it turns bytes on disk into a `String`,
/// which higher layers feed into profile building.
protocol DocumentTextExtractor: Sendable {
    nonisolated func extractText(from url: URL) throws -> String
}

/// Errors raised while reading a document.
enum DocumentExtractionError: Error, Equatable {
    /// The file's extension isn't a supported document type.
    case unsupportedType(String)
    /// The document was read but contained no usable text.
    case emptyDocument
    /// The document couldn't be opened or decoded.
    case readFailed(String)
}
