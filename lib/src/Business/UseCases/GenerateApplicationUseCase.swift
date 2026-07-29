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
    /// What one generation produced. The stage-1 brief is returned alongside the kit
    /// (v0.6.1 Milestone B) rather than discarded, because the posting's keywords live only
    /// there — keyword coverage compares them against the résumé this same run generated.
    /// Mirrors ``GenerateToTargetUseCase/Outcome`` so both paths hand back the same pair.
    struct Outcome: Sendable, Equatable {
        let kit: ApplicationKit
        let brief: TargetBrief
    }

    let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    func callAsFunction(
        job: JobListing,
        profile: CandidateProfile,
        grounding: PortfolioGrounding? = nil,
        settings: GenerationSettings = .default
    ) async throws -> Outcome {
        let brief = try await provider.buildTargetBrief(for: job)
        let kit = try await provider.generateApplication(
            for: job, profile: profile, brief: brief, grounding: grounding, settings: settings
        )
        return Outcome(kit: kit, brief: brief)
    }
}
