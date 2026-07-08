//
//  FetchPostingUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — read one posting (URL or pasted text), then rank it.
//

import Foundation

/// Reads a single job posting — from a URL or pasted text — and ranks it against the
/// profile, so a link the user found drops into the same rank → detail → generate flow
/// as a searched job.
nonisolated struct FetchPostingUseCase: Sendable {
    let postingSource: any JobPostingSource
    let ranker: JobRanker

    init(postingSource: any JobPostingSource, ranker: JobRanker) {
        self.postingSource = postingSource
        self.ranker = ranker
    }

    /// Fetch the posting at `url`, extract it, and rank it.
    func callAsFunction(url: URL, profile: CandidateProfile) async throws -> RankedJob {
        let listing = try await postingSource.fetchPosting(from: url)
        return try await rank(listing, for: profile)
    }

    /// Extract the posting from pasted text (the fallback for un-fetchable pages), then rank it.
    func callAsFunction(pastedText text: String, sourceURL: URL? = nil, profile: CandidateProfile) async throws -> RankedJob {
        let listing = try await postingSource.extractPosting(fromText: text, sourceURL: sourceURL)
        return try await rank(listing, for: profile)
    }

    /// Ranks the single listing; falls back to a neutral, unscored pairing if the LLM
    /// returns no match, so the posting still reaches the detail/generate flow.
    private func rank(_ listing: JobListing, for profile: CandidateProfile) async throws -> RankedJob {
        let ranked = try await ranker.rank([listing], for: profile)
        return ranked.first ?? RankedJob(
            listing: listing,
            match: JobMatch(jobId: listing.id, score: 0, reason: "Not scored.", matchedSkills: [], missingSkills: [])
        )
    }
}
