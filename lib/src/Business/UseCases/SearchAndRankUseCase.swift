//
//  SearchAndRankUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — search a source, then rank the results.
//

import Foundation

/// Runs a job search, then ranks the results against the candidate profile.
nonisolated struct SearchAndRankUseCase: Sendable {
    let jobSource: any JobSource
    let ranker: JobRanker

    init(jobSource: any JobSource, ranker: JobRanker) {
        self.jobSource = jobSource
        self.ranker = ranker
    }

    func callAsFunction(query: JobQuery, profile: CandidateProfile) async throws -> [RankedJob] {
        let jobs = try await jobSource.search(query)
        return try await ranker.rank(jobs, for: profile)
    }
}
