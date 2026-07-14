//
//  RegenerateResultUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — re-rank (and optionally re-enrich) one saved result (v0.6.0 C).
//

import Foundation

/// Refreshes a single saved ``RankedJob`` against a chosen profile: optionally re-enriches the
/// posting (backfilling the richer detail on legacy entries — Milestone A), re-ranks it with an
/// optional free-text steering `instruction`, and persists the refreshed result (latest-wins).
///
/// The motivating case is **legacy entries** ranked against an older profile and lacking the
/// richer posting fields; "regenerate result" re-scores them against a current profile and fills
/// out the posting detail. Re-ranking re-assesses fit **honestly** (the score may go up *or*
/// down); enrichment structures what the posting says. Neither invents.
nonisolated struct RegenerateResultUseCase: Sendable {
    let provider: any LLMProvider
    let saveResults: SaveResultsUseCase
    /// Optional posting enrichment (composes with Milestone A). Skipped when nil; when wired it
    /// backfills detail on a not-yet-enriched listing (`EnrichPostingUseCase` no-ops otherwise).
    let enrichPosting: EnrichPostingUseCase?

    init(provider: any LLMProvider, saveResults: SaveResultsUseCase, enrichPosting: EnrichPostingUseCase? = nil) {
        self.provider = provider
        self.saveResults = saveResults
        self.enrichPosting = enrichPosting
    }

    /// Re-enriches (best-effort), re-ranks against `profile` honouring `instruction`, persists,
    /// and returns the refreshed result. A re-enrich failure is swallowed (the re-rank still
    /// runs on the existing listing); a re-rank failure propagates.
    func callAsFunction(_ job: RankedJob, profile: CandidateProfile, instruction: String = "") async throws -> RankedJob {
        // Re-enrich first so the refreshed match sees the richer signal in its prompt.
        var listing = job.listing
        if let enrichPosting {
            listing = (try? await enrichPosting(listing)) ?? listing
        }
        let match = try await provider.rank(job: listing, against: profile, instruction: instruction)
        let refreshed = RankedJob(listing: listing, match: match)
        try await saveResults([refreshed])
        return refreshed
    }
}
