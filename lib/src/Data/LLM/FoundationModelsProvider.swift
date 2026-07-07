//
//  FoundationModelsProvider.swift
//  Taylor'd Portfolio
//
//  Data · LLM — LLMProvider backed by the on-device model (constrained decoding).
//

import Foundation

/// `LLMProvider` implemented against Apple's on-device model, using constrained
/// decoding against the `@Generable` domain types (no JSON round-trip).
nonisolated struct FoundationModelsProvider: LLMProvider {
    let client: FoundationModelsClient

    init(client: FoundationModelsClient = FoundationModelsClient()) {
        self.client = client
    }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        try await client.respond(
            to: Prompts.buildProfile(portfolio: portfolio),
            generating: CandidateProfile.self,
            instructions: Prompts.profileInstructions
        )
    }

    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        let batch = try await client.respond(
            to: Prompts.rank(jobs: jobs, profile: profile),
            generating: JobMatchBatch.self,
            instructions: Prompts.rankInstructions
        )
        return batch.matches
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
        try await client.respond(
            to: Prompts.generateApplication(job: job, profile: profile),
            generating: ApplicationKit.self,
            instructions: Prompts.generateInstructions
        )
    }
}
