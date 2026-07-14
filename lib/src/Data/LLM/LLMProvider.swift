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

    /// Re-ranks a SINGLE job against the profile, honouring optional free-text `instruction`
    /// that steers emphasis/interpretation (v0.6.0 Milestone C — "regenerate result"). Has a
    /// forwarding default that ignores the instruction and reuses the batch `rank`, so stubs
    /// and engines that don't support it need no change; the real engines and the router
    /// override it to honour the guidance.
    func rank(job: JobListing, against profile: CandidateProfile, instruction: String) async throws -> JobMatch

    /// Extracts a single job posting from the (stripped) text of a page or pasted text.
    /// Has a default that reports unavailability, so only engines that support it need
    /// implement it (the router forwards to a real engine).
    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting

    /// Enriches a posting's text into a structured ``PostingDetails`` (v0.6.0 Milestone A-B):
    /// work type + qualifications / responsibilities / nice-to-haves / about-role / about-company
    /// / benefits. Extracts only what the posting states — never invents. Has a throwing
    /// default, so only real engines implement it; the router forwards to one.
    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails

    /// Extracts the **full job posting** verbatim from a fetched page's raw text (v0.6.0
    /// Milestone E), stripping site chrome — navigation, search boxes, "similar jobs", ads,
    /// cookie/footer boilerplate — while preserving the posting's own content and order.
    /// Returns clean markdown, or empty when the page holds no real posting. Reorders/removes
    /// nothing of the posting and invents nothing. Has a throwing default, so only real engines
    /// implement it; the router forwards to one.
    func cleanPostingText(fromPageText pageText: String) async throws -> String

    /// Reflows an imported document's raw extracted text into readable plain text (same
    /// facts, repaired layout). Has a throwing default, so only real engines implement it.
    func tidyDocument(rawText: String) async throws -> String

    /// Rewrites the profile's summary following `instruction`, grounded in the profile and
    /// portfolio. Returns the new summary text. Has a throwing default, so only real engines
    /// implement it.
    func refineSummary(profile: CandidateProfile, portfolio: String, instruction: String) async throws -> String

    /// Stage 1 of generation: distils a posting into a structured ``TargetBrief``.
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief

    /// Stage 2 of generation: tailors application materials for one job against the
    /// stage-1 ``TargetBrief``.
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit

    /// Stage 2 with optional two-document ``PortfolioGrounding`` (Milestone T): the real
    /// résumé text as factual grounding, plus a cover-letter voice exemplar. Has a default
    /// that **ignores grounding** and forwards to the base method, so stubs and engines that
    /// don't support it need no change; real engines override it.
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?) async throws -> ApplicationKit

    /// Stage 2 with grounding **and** generation controls (Milestone D): fidelity/aspects
    /// shape how much latitude the generation has. Has a default that **ignores settings**
    /// and forwards to the grounding method, so stubs and engines that don't support it need
    /// no change; the real engines and the router override it.
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?, settings: GenerationSettings) async throws -> ApplicationKit

    /// Scores a generated application's résumé against the role (Milestone D-F, the
    /// rank-target loop). Has a throwing default, so only real engines implement it; the
    /// router forwards to one.
    func scoreApplication(for job: JobListing, brief: TargetBrief, kit: ApplicationKit) async throws -> JobMatch
}

extension LLMProvider {
    /// Default: extraction isn't supported. Real engines (Foundation Models, Claude)
    /// override this; stubs that don't need it inherit the default. Because it's a
    /// protocol requirement, calls through `any LLMProvider` still dispatch to overrides.
    func extractPosting(fromPageText pageText: String) async throws -> ExtractedPosting {
        throw LLMProviderError.noProviderAvailable
    }

    /// Default: posting enrichment isn't supported. Real engines override this; the router
    /// forwards to one.
    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails {
        throw LLMProviderError.noProviderAvailable
    }

    /// Default: posting-text cleaning isn't supported. Real engines override this; the router
    /// forwards to one.
    func cleanPostingText(fromPageText pageText: String) async throws -> String {
        throw LLMProviderError.noProviderAvailable
    }

    /// Default: re-rank a single job by reusing the batch `rank` (ignoring the instruction), so
    /// stubs work unchanged. Real engines override this to honour the guidance; the router
    /// forwards to one. Falls back to a neutral, jobId-keyed match when the batch returns none.
    func rank(job: JobListing, against profile: CandidateProfile, instruction: String) async throws -> JobMatch {
        let matches = try await rank(jobs: [job], against: profile)
        return matches.first ?? JobMatch(jobId: job.id, score: 0, reason: "Not scored.", matchedSkills: [], missingSkills: [])
    }

    /// Default: document tidying isn't supported. Real engines override this.
    func tidyDocument(rawText: String) async throws -> String {
        throw LLMProviderError.noProviderAvailable
    }

    /// Default: summary refinement isn't supported. Real engines override this.
    func refineSummary(profile: CandidateProfile, portfolio: String, instruction: String) async throws -> String {
        throw LLMProviderError.noProviderAvailable
    }

    /// Default: ignore grounding and fall back to profile-only generation. Real engines
    /// (Foundation Models, Claude) and the router override this to inject the documents.
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?) async throws -> ApplicationKit {
        try await generateApplication(for: job, profile: profile, brief: brief)
    }

    /// Default: ignore generation controls and fall back to grounded generation. Real
    /// engines (Foundation Models, Claude) and the router override this.
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?, settings: GenerationSettings) async throws -> ApplicationKit {
        try await generateApplication(for: job, profile: profile, brief: brief, grounding: grounding)
    }

    /// Default: scoring isn't supported. Real engines override this; the router forwards.
    func scoreApplication(for job: JobListing, brief: TargetBrief, kit: ApplicationKit) async throws -> JobMatch {
        throw LLMProviderError.noProviderAvailable
    }
}

/// Errors surfaced by the LLM gateway.
enum LLMProviderError: Error, Equatable {
    /// The engine returned text that couldn't be decoded into the expected type.
    /// The associated value is the raw text, for logging/debugging.
    case decodingFailed(String)
    /// No engine was available to service the request (router with an empty order).
    case noProviderAvailable
}
