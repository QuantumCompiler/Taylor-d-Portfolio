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

    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        try await generateJSON(
            prompt: Prompts.extractPosting(pageText: pageText),
            instructions: Prompts.extractInstructions,
            as: ExtractedPosting.self
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
        try await generateJSON(
            prompt: Prompts.generateApplication(job: job, profile: profile, brief: brief, grounding: grounding),
            instructions: Prompts.generateInstructions,
            as: ApplicationKit.self
        )
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
