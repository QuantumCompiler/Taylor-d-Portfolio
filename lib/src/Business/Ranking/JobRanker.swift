//
//  JobRanker.swift
//  Taylor'd Portfolio
//
//  Business · Ranking — the two-stage ranking funnel.
//

import Foundation

/// Ranks jobs against a candidate profile with a cheap local prefilter followed by a
/// batched LLM re-rank.
///
/// `prefilter` is pure lexical overlap (upgradeable to embedding similarity later);
/// `rank` shortlists, calls the `LLMProvider`, then pairs and sorts the results.
nonisolated struct JobRanker: Sendable {
    let provider: any LLMProvider
    /// How many jobs survive the prefilter into the (more expensive) LLM re-rank.
    var shortlistLimit: Int

    init(provider: any LLMProvider, shortlistLimit: Int = 20) {
        self.provider = provider
        self.shortlistLimit = shortlistLimit
    }

    // MARK: Prefilter (pure)

    /// Trims `jobs` to the `limit` most lexically relevant to the profile. Returns the
    /// input unchanged when it already fits within `limit`.
    func prefilter(_ jobs: [JobListing], for profile: CandidateProfile, limit: Int) -> [JobListing] {
        guard jobs.count > limit else { return jobs }
        let terms = Self.lexicalTerms(for: profile)

        return jobs.enumerated()
            .map { (index: $0.offset, job: $0.element, score: Self.overlapScore(job: $0.element, terms: terms)) }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
            .prefix(limit)
            .map(\.job)
    }

    // MARK: Rank (LLM)

    /// Prefilters, re-ranks the shortlist with the LLM, pairs each score with its
    /// listing, and returns the matches sorted by descending score.
    func rank(_ jobs: [JobListing], for profile: CandidateProfile) async throws -> [RankedJob] {
        let shortlist = prefilter(jobs, for: profile, limit: shortlistLimit)
        guard !shortlist.isEmpty else { return [] }

        let matches = try await provider.rank(jobs: shortlist, against: profile)
        let listingsByID = Dictionary(shortlist.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return matches
            .compactMap { match in listingsByID[match.jobId].map { RankedJob(listing: $0, match: match) } }
            .sorted { $0.score > $1.score }
    }

    // MARK: Lexical scoring helpers

    /// The lowercased skill/title/domain tokens used for prefilter overlap.
    static func lexicalTerms(for profile: CandidateProfile) -> Set<String> {
        let sources = profile.coreSkills + profile.targetTitles + profile.domains
        return Set(sources.flatMap(tokenize))
    }

    /// How many profile `terms` appear in the job's title + description.
    static func overlapScore(job: JobListing, terms: Set<String>) -> Int {
        guard !terms.isEmpty else { return 0 }
        let haystack = Set(tokenize(job.title + " " + job.description))
        return terms.intersection(haystack).count
    }

    /// Splits text into lowercased word tokens of length ≥ 2.
    static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 2 }
    }
}
