//
//  TidyDocumentUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — reflow imported document text into readable plain text.
//

import Foundation

/// Reflows an imported document's raw extracted text into readable plain text via the
/// LLM — the same engine that builds the profile (routed through the `.profile` task),
/// so the readable form pairs naturally with the profile it was built alongside.
///
/// **Never returns less than the whole document** (v0.6.2 Milestone E). The tidy prompt is
/// bounded by `Prompts.maxTidyDocumentCharacters` for the on-device context window, so a long
/// document's tail would otherwise be silently missing from the stored readable text — the real
/// cause of the "the preview truncates" report, and one no UI change could fix. Anything past
/// the bound is therefore **appended as-extracted**, behind a short notice: the result is
/// tidied where it could be and complete regardless. (Tidying the tail in chunks would be
/// nicer still — that's the follow-on; it costs one LLM call per chunk and has to keep
/// structure consistent across boundaries.)
nonisolated struct TidyDocumentUseCase: Sendable {
    let provider: any LLMProvider

    /// Separates the tidied head from the as-extracted tail, so the user can see where the
    /// clean-up stopped rather than wondering why the formatting changes mid-document.
    static let remainderNotice = "— The rest of this document was too long to tidy and is shown exactly as extracted —"

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func callAsFunction(rawText: String) async throws -> String {
        let bound = Prompts.maxTidyDocumentCharacters
        guard rawText.count > bound else {
            return try await provider.tidyDocument(rawText: rawText)
        }
        // Split explicitly rather than leaning on the prompt's own truncation, so what the
        // model saw and what's appended can't drift apart.
        let tidied = try await provider.tidyDocument(rawText: String(rawText.prefix(bound)))
        let remainder = String(rawText.dropFirst(bound))
        return tidied + "\n\n" + Self.remainderNotice + "\n\n" + remainder
    }
}
