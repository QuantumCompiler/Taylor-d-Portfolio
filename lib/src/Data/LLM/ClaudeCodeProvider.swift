//
//  ClaudeCodeProvider.swift
//  Taylor'd Portfolio
//
//  Data · LLM — LLMProvider backed by the `claude -p` CLI (asks for JSON, decodes).
//

import Foundation

/// `LLMProvider` implemented against any `TextGenerating` engine (in practice the
/// `claude -p` CLI): it appends a JSON-only instruction, then decodes the reply into
/// the expected domain type.
nonisolated struct ClaudeCodeProvider: LLMProvider {
    let generator: any TextGenerating

    init(generator: any TextGenerating) {
        self.generator = generator
    }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        try await generateJSON(
            prompt: Prompts.buildProfile(portfolio: portfolio),
            instructions: Prompts.profileInstructions,
            as: CandidateProfile.self
        )
    }

    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        let batch = try await generateJSON(
            prompt: Prompts.rank(jobs: jobs, profile: profile),
            instructions: Prompts.rankInstructions,
            as: JobMatchBatch.self
        )
        return batch.matches
    }

    func rank(job: JobListing, against profile: CandidateProfile, instruction: String) async throws -> JobMatch {
        try await generateJSON(
            prompt: Prompts.rankOne(job: job, profile: profile, instruction: instruction),
            instructions: Prompts.rankInstructions,
            as: JobMatch.self
        )
    }

    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        try await generateJSON(
            prompt: Prompts.extractPosting(pageText: pageText),
            instructions: Prompts.extractInstructions,
            as: ExtractedPosting.self
        )
    }

    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails {
        try await generateJSON(
            prompt: Prompts.enrichPosting(postingText: postingText),
            instructions: Prompts.enrichInstructions,
            as: PostingDetails.self
        )
    }

    /// Plain-text task (no JSON envelope): ask the engine to reflow the document and
    /// return its text directly.
    func tidyDocument(rawText: String) async throws -> String {
        try await generator.generate(
            prompt: Prompts.tidyDocument(rawText: rawText),
            instructions: Prompts.tidyInstructions
        )
    }

    /// Plain-text task: extract the full job posting from a fetched page, de-chromed (E).
    func cleanPostingText(fromPageText pageText: String) async throws -> String {
        try await generator.generate(
            prompt: Prompts.cleanPosting(pageText: pageText),
            instructions: Prompts.cleanPostingInstructions
        )
    }

    /// Plain-text task: rewrite the summary and return it directly (no JSON envelope).
    func refineSummary(profile: CandidateProfile, portfolio: String, instruction: String) async throws -> String {
        try await generator.generate(
            prompt: Prompts.refineSummary(profile: profile, portfolio: portfolio, instruction: instruction),
            instructions: Prompts.refineSummaryInstructions
        )
    }

    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        try await generateJSON(
            prompt: Prompts.buildTargetBrief(job: job),
            instructions: Prompts.briefInstructions,
            as: TargetBrief.self
        )
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        try await generateApplication(for: job, profile: profile, brief: brief, grounding: nil)
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?) async throws -> ApplicationKit {
        try await generateApplication(for: job, profile: profile, brief: brief, grounding: grounding, settings: .default)
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?, settings: GenerationSettings) async throws -> ApplicationKit {
        try await generateJSON(
            prompt: Prompts.generateApplication(job: job, profile: profile, brief: brief, grounding: grounding, settings: settings),
            instructions: Prompts.generateInstructions(settings),
            as: ApplicationKit.self
        )
    }

    func scoreApplication(for job: JobListing, brief: TargetBrief, kit: ApplicationKit) async throws -> JobMatch {
        try await generateJSON(
            prompt: Prompts.scoreApplication(job: job, brief: brief, kit: kit),
            instructions: Prompts.scoreInstructions,
            as: JobMatch.self
        )
    }

    func searchJobs(query: JobQuery, grounding: PortfolioGrounding?) async throws -> [GeneratedJobLead] {
        let result = try await generateJSON(
            prompt: Prompts.searchJobs(query: query, grounding: grounding),
            instructions: Prompts.searchJobsInstructions,
            as: GeneratedJobLeads.self
        )
        return Array(result.leads.prefix(Prompts.maxJobLeads))
    }

    /// Adds the JSON-only instruction, runs the engine, and decodes the reply.
    private func generateJSON<T: Decodable>(
        prompt: String,
        instructions: String,
        as type: T.Type
    ) async throws -> T {
        let jsonPrompt = prompt + "\n\n" + Prompts.jsonOnlySuffix
        let raw = try await generator.generate(prompt: jsonPrompt, instructions: instructions)

        guard let data = raw.data(using: .utf8) else {
            throw LLMProviderError.decodingFailed(raw)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LLMProviderError.decodingFailed(raw)
        }
    }
}
