//
//  LLMProvider.swift
//  Taylor'd Portfolio
//
//  Data · LLM — the task-oriented LLM gateway seam.
//

import Foundation

/// The task-oriented LLM gateway the Business layer depends on.
///
/// Deliberately *not* a generic `generate<T>` — the two engines structure output
/// differently (`FoundationModelsProvider` uses constrained decoding against
/// `@Generable` types; `ClaudeCodeProvider` asks for JSON and decodes it), so the
/// seam is expressed as domain tasks instead.
protocol LLMProvider: Sendable {
    /// Distils a raw portfolio into a structured ``CandidateProfile``.
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile

    /// Scores each job against the profile. Returns one ``JobMatch`` per input job.
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch]

    /// Stage 1 of generation: distils a posting into a structured ``TargetBrief``.
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief

    /// Stage 2 of generation: tailors application materials for one job against the
    /// stage-1 ``TargetBrief``.
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit
}

/// Errors surfaced by the LLM gateway.
enum LLMProviderError: Error, Equatable {
    /// The engine returned text that couldn't be decoded into the expected type.
    /// The associated value is the raw text, for logging/debugging.
    case decodingFailed(String)
    /// No engine was available to service the request (router with an empty order).
    case noProviderAvailable
}
