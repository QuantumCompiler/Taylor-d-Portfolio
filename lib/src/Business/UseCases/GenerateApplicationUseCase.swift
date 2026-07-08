//
//  GenerateApplicationUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — generate tailored application materials for one job.
//

import Foundation

/// Generates a tailored ``ApplicationKit`` for a chosen job via the LLM.
nonisolated struct GenerateApplicationUseCase: Sendable {
    let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func callAsFunction(job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
        try await provider.generateApplication(for: job, profile: profile)
    }
}
