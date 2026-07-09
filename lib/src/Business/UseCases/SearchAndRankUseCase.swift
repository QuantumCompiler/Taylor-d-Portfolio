//
//  SearchAndRankUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — fan out title searches, merge, then rank once.
//

import Foundation

/// Fans a multi-title ``JobSearchRequest`` out into one search per title, merges and
/// de-duplicates the listings, then ranks the combined set against the profile once.
///
/// The fan-out lives here (above the seam), so `JobSource` stays the single-`what`
/// contract. Searches run with bounded concurrency to respect Adzuna's free-tier
/// rate limits, and a single failing title doesn't sink the run — it's reported as a
/// soft note in ``Output/failedTitles``. The run only throws if *every* title fails.
nonisolated struct SearchAndRankUseCase: Sendable {
    let jobSource: any JobSource
    let ranker: JobRanker
    /// Max title searches in flight at once (Adzuna free-tier rate-limit guard).
    var maxConcurrentSearches: Int
    /// Hard cap on how many titles a single run will search.
    var maxTitles: Int

    init(
        jobSource: any JobSource,
        ranker: JobRanker,
        maxConcurrentSearches: Int = 4,
        maxTitles: Int = 6
    ) {
        self.jobSource = jobSource
        self.ranker = ranker
        self.maxConcurrentSearches = maxConcurrentSearches
        self.maxTitles = maxTitles
    }

    /// The outcome of a multi-title search: the ranked jobs plus any titles whose
    /// individual search failed (surfaced to the user as a soft warning).
    struct Output: Sendable, Equatable {
        var rankedJobs: [RankedJob]
        var failedTitles: [String]

        init(rankedJobs: [RankedJob] = [], failedTitles: [String] = []) {
            self.rankedJobs = rankedJobs
            self.failedTitles = failedTitles
        }
    }

    func callAsFunction(request: JobSearchRequest, profile: CandidateProfile) async throws -> Output {
        let titles = Array(request.cleanedTitles.prefix(maxTitles))
        guard !titles.isEmpty else { return Output() }

        let outcomes = await searchAll(titles, request: request)

        // Flatten in title order, de-duplicating by listing id (first occurrence wins).
        var seen = Set<String>()
        var merged = [JobListing]()
        var failedTitles = [String]()
        var lastError: Error?

        for (index, title) in titles.enumerated() {
            switch outcomes[index] {
            case .success(let jobs):
                for job in jobs where seen.insert(job.id).inserted { merged.append(job) }
            case .failure(let error):
                failedTitles.append(title)
                lastError = error
            }
        }

        // Fail hard only when nothing succeeded.
        if failedTitles.count == titles.count, let lastError {
            throw lastError
        }

        let ranked = try await ranker.rank(merged, for: profile)
        return Output(rankedJobs: ranked, failedTitles: failedTitles)
    }

    // MARK: Bounded-concurrency fan-out

    /// Runs one search per title with at most `maxConcurrentSearches` in flight,
    /// returning each title's result (success or failure) indexed by title position.
    private func searchAll(
        _ titles: [String],
        request: JobSearchRequest
    ) async -> [Result<[JobListing], Error>] {
        let window = max(1, min(maxConcurrentSearches, titles.count))
        var outcomes = [Int: Result<[JobListing], Error>]()

        await withTaskGroup(of: (Int, Result<[JobListing], Error>).self) { group in
            var next = 0
            func schedule(_ index: Int) {
                let query = request.query(forTitle: titles[index])
                group.addTask {
                    do { return (index, .success(try await jobSource.search(query))) }
                    catch { return (index, .failure(error)) }
                }
            }

            while next < window { schedule(next); next += 1 }
            while let (index, result) = await group.next() {
                outcomes[index] = result
                if next < titles.count { schedule(next); next += 1 }
            }
        }

        // Reassemble in title order; every index was scheduled, so none is missing.
        return titles.indices.map { outcomes[$0] ?? .success([]) }
    }
}
