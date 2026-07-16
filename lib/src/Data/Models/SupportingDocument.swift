//
//  SupportingDocument.swift
//  Taylor'd Portfolio
//
//  Data · Models — an additional factual document baked into a profile (v0.6.0 Milestone I).
//

import Foundation

/// An **additional supporting document** attached to a ``SavedProfile`` — e.g. a complete
/// career portfolio of every role, skill, and project — baked into the profile as **factual
/// grounding** for both ranking/search and application generation.
///
/// Unlike the cover letter (a voice/tone exemplar whose facts are never imported), a
/// supporting document is treated like the résumé source: its content **may** be used. Mirrors
/// the résumé/cover-letter triple — `rawText` is the imported document's extracted text and
/// `readableText` its LLM-tidied form; `fileName` names the imported file when one was used.
/// `Codable` so it persists with the profile via the record store.
nonisolated struct SupportingDocument: Identifiable, Codable, Equatable, Sendable {
    let id: String
    /// The imported document's file name (nil when the text was pasted, not imported).
    var fileName: String?
    /// The raw text the document was imported with.
    var rawText: String
    /// The LLM-tidied, readable form of `rawText` (empty until tidied — falls back to raw).
    var readableText: String

    init(id: String, fileName: String? = nil, rawText: String, readableText: String = "") {
        self.id = id
        self.fileName = fileName
        self.rawText = rawText
        self.readableText = readableText
    }

    /// The best available text for grounding: the tidied `readableText`, or the raw text
    /// when tidying hasn't run (or failed).
    var effectiveText: String {
        readableText.isEmpty ? rawText : readableText
    }
}
