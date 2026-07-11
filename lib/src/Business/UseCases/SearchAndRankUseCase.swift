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
    /// Listings requested per page when there's no desired-result-count goal.
    var defaultResultsPerPage: Int
    /// Listings requested per page when paging toward a goal (Adzuna's max is 50).
    var maxResultsPerPage: Int
    /// Hard cap on pages fetched per title when paging toward a goal (rate-limit guard).
    var maxPagesPerTitle: Int

    init(
        jobSource: any JobSource,
        ranker: JobRanker,
        maxConcurrentSearches: Int = 4,
        maxTitles: Int = 6,
        defaultResultsPerPage: Int = 25,
        maxResultsPerPage: Int = 50,
        maxPagesPerTitle: Int = 5
    ) {
        self.jobSource = jobSource
        self.ranker = ranker
        self.maxConcurrentSearches = maxConcurrentSearches
        self.maxTitles = maxTitles
        self.defaultResultsPerPage = defaultResultsPerPage
        self.maxResultsPerPage = maxResultsPerPage
        self.maxPagesPerTitle = maxPagesPerTitle
    }

    /// How far a desired-result-count goal fell short (U-D).
    struct Shortfall: Sendable, Equatable {
        var found: Int
        var desired: Int
    }

    /// The outcome of a multi-title search: the ranked jobs, any titles whose search
    /// failed (a soft warning), and the optional U-D/U-E notes.
    struct Output: Sendable, Equatable {
        var rankedJobs: [RankedJob]
        var failedTitles: [String]
        /// Set when a desired-result-count goal couldn't be met (U-D) — never fatal.
        var resultShortfall: Shortfall?
        /// True when a minimum-rank filter (U-E) removed *every* result from a non-empty
        /// ranked set — distinct from "no results found at all".
        var noneMetMinimum: Bool

        init(
            rankedJobs: [RankedJob] = [],
            failedTitles: [String] = [],
            resultShortfall: Shortfall? = nil,
            noneMetMinimum: Bool = false
        ) {
            self.rankedJobs = rankedJobs
            self.failedTitles = failedTitles
            self.resultShortfall = resultShortfall
            self.noneMetMinimum = noneMetMinimum
        }
    }

    func callAsFunction(request: JobSearchRequest, profile: CandidateProfile) async throws -> Output {
        let titles = Array(request.cleanedTitles.prefix(maxTitles))
        guard !titles.isEmpty else { return Output() }

        let goal = request.desiredResultCount
        let perPage = goal != nil ? maxResultsPerPage : defaultResultsPerPage
        let pageCap = goal != nil ? maxPagesPerTitle : 1

        var seen = Set<String>()
        var merged = [JobListing]()
        var failedTitles = [String]()

        // Round 1 (page 1) establishes each title's success/failure and seeds the results.
        let firstOutcomes = await searchAll(titles, request: request, page: 1, resultsPerPage: perPage)
        var lastError: Error?
        var activeTitles = [String]()      // titles worth paging further (a full page came back)
        for (index, title) in titles.enumerated() {
            switch firstOutcomes[index] {
            case .success(let jobs):
                for job in jobs where seen.insert(job.id).inserted { merged.append(job) }
                if jobs.count >= perPage { activeTitles.append(title) }
            case .failure(let error):
                failedTitles.append(title)
                lastError = error
            }
        }

        // Fail hard only when nothing succeeded.
        if failedTitles.count == titles.count, let lastError {
            throw lastError
        }

        // Additional pages toward the desired-result-count goal (U-D). Round-robin a page
        // across all still-active titles, then re-check the goal — bounded by the page cap.
        if let goal {
            var page = 2
            while merged.count < goal, page <= pageCap, !activeTitles.isEmpty {
                let outcomes = await searchAll(activeTitles, request: request, page: page, resultsPerPage: perPage)
                var stillActive = [String]()
                for (index, title) in activeTitles.enumerated() {
                    if case .success(let jobs) = outcomes[index] {
                        for job in jobs where seen.insert(job.id).inserted { merged.append(job) }
                        if jobs.count >= perPage { stillActive.append(title) }
                    }
                    // A failure on a later page just stops paging that title (best-effort).
                }
                activeTitles = stillActive
                page += 1
            }
        }

        // Shortfall is measured on the fetched/ranked candidate count, *before* the U-E
        // score filter trims what's shown (documented so the user isn't surprised).
        let shortfall: Shortfall? = goal.flatMap {
            merged.count < $0 ? Shortfall(found: merged.count, desired: $0) : nil
        }

        let ranked = try await ranker.rank(merged, for: profile)

        // Minimum-rank filter (U-E): keep only scores ≥ the floor, and flag when that
        // empties a non-empty set so the UI can say "none met your minimum".
        var shown = ranked
        var noneMetMinimum = false
        if let minimum = request.minimumScore {
            let filtered = ranked.filter { $0.match.score >= minimum }
            noneMetMinimum = filtered.isEmpty && !ranked.isEmpty
            shown = filtered
        }

        return Output(
            rankedJobs: shown,
            failedTitles: failedTitles,
            resultShortfall: shortfall,
            noneMetMinimum: noneMetMinimum
        )
    }

    // MARK: Bounded-concurrency fan-out

    /// Runs one search per title (at `page`, `resultsPerPage`) with at most
    /// `maxConcurrentSearches` in flight, returning each title's result (success or
    /// failure) indexed by its position in `titles`.
    private func searchAll(
        _ titles: [String],
        request: JobSearchRequest,
        page: Int,
        resultsPerPage: Int
    ) async -> [Result<[JobListing], Error>] {
        let window = max(1, min(maxConcurrentSearches, titles.count))
        var outcomes = [Int: Result<[JobListing], Error>]()

        await withTaskGroup(of: (Int, Result<[JobListing], Error>).self) { group in
            var next = 0
            func schedule(_ index: Int) {
                let query = request.query(forTitle: titles[index], page: page, resultsPerPage: resultsPerPage)
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
