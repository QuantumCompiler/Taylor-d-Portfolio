//
//  RefineSummaryUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — regenerate a profile's summary from a user instruction.
//

import Foundation

/// Rewrites a ``CandidateProfile``'s summary following the user's instruction, grounded in
/// the profile and the real portfolio text via the LLM (same engine that built the profile,
/// routed through the `.profile` task). Returns only the new summary text.
nonisolated struct RefineSummaryUseCase: Sendable {
    let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func callAsFunction(profile: CandidateProfile, portfolio: String, instruction: String) async throws -> String {
        try await provider.refineSummary(profile: profile, portfolio: portfolio, instruction: instruction)
    }
}
