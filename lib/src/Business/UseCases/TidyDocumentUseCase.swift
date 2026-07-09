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
nonisolated struct TidyDocumentUseCase: Sendable {
    let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func callAsFunction(rawText: String) async throws -> String {
        try await provider.tidyDocument(rawText: rawText)
    }
}
