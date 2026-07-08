//
//  BuildProfileUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — portfolio text → structured profile.
//

import Foundation

/// Distils a raw portfolio into a structured ``CandidateProfile`` via the LLM.
nonisolated struct BuildProfileUseCase: Sendable {
    let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func callAsFunction(portfolio: String) async throws -> CandidateProfile {
        try await provider.buildProfile(fromPortfolio: portfolio)
    }
}
