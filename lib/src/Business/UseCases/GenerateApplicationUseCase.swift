//
//  GenerateApplicationUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — generate tailored application materials for one job.
//

import Foundation

/// Generates a tailored ``ApplicationKit`` for a chosen job via the LLM.
///
/// Two-stage (AGENT.md discipline): first distil the posting into a ``TargetBrief``,
/// then tailor the application against that brief. Orchestrating both stages here
/// keeps the providers atomic and the pipeline visible in the Business layer.
nonisolated struct GenerateApplicationUseCase: Sendable {
    let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func callAsFunction(
        job: JobListing,
        profile: CandidateProfile,
        grounding: PortfolioGrounding? = nil,
        settings: GenerationSettings = .default
    ) async throws -> ApplicationKit {
        let brief = try await provider.buildTargetBrief(for: job)
        return try await provider.generateApplication(
            for: job, profile: profile, brief: brief, grounding: grounding, settings: settings
        )
    }
}
