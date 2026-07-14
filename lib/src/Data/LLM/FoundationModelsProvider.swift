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

    func rank(job: JobListing, against profile: CandidateProfile, instruction: String) async throws -> JobMatch {
        try await client.respond(
            to: Prompts.rankOne(job: job, profile: profile, instruction: instruction),
            generating: JobMatch.self,
            instructions: Prompts.rankInstructions
        )
    }

    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        try await client.respond(
            to: Prompts.extractPosting(pageText: pageText),
            generating: ExtractedPosting.self,
            instructions: Prompts.extractInstructions
        )
    }

    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails {
        try await client.respond(
            to: Prompts.enrichPosting(postingText: postingText),
            generating: PostingDetails.self,
            instructions: Prompts.enrichInstructions
        )
    }

    func tidyDocument(rawText: String) async throws -> String {
        try await client.generate(
            prompt: Prompts.tidyDocument(rawText: rawText),
            instructions: Prompts.tidyInstructions
        )
    }

    func refineSummary(profile: CandidateProfile, portfolio: String, instruction: String) async throws -> String {
        try await client.generate(
            prompt: Prompts.refineSummary(profile: profile, portfolio: portfolio, instruction: instruction),
            instructions: Prompts.refineSummaryInstructions
        )
    }

    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        try await client.respond(
            to: Prompts.buildTargetBrief(job: job),
            generating: TargetBrief.self,
            instructions: Prompts.briefInstructions
        )
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        try await generateApplication(for: job, profile: profile, brief: brief, grounding: nil)
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?) async throws -> ApplicationKit {
        try await generateApplication(for: job, profile: profile, brief: brief, grounding: grounding, settings: .default)
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?, settings: GenerationSettings) async throws -> ApplicationKit {
        try await client.respond(
            to: Prompts.generateApplication(job: job, profile: profile, brief: brief, grounding: grounding, settings: settings),
            generating: ApplicationKit.self,
            instructions: Prompts.generateInstructions
        )
    }

    func scoreApplication(for job: JobListing, brief: TargetBrief, kit: ApplicationKit) async throws -> JobMatch {
        try await client.respond(
            to: Prompts.scoreApplication(job: job, brief: brief, kit: kit),
            generating: JobMatch.self,
            instructions: Prompts.scoreInstructions
        )
    }
}
