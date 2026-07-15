//
//  CompositeJobSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — aggregate several JobSources behind one JobSource (v0.6.0 Milestone F).
//

import Foundation

/// A ``JobSource`` that fans a query out across several providers (Adzuna, JSearch, …),
/// runs them with **bounded concurrency**, and merges their results into one de-duplicated
/// list — so the fan-out over *providers* sits below the seam and callers
/// (`SearchAndRankUseCase`, which fans out over *titles*) are unchanged.
///
/// **Cross-source de-dup:** `JobListing.id` is source-specific, so the same posting from two
/// providers would double-list under a naïve union. The merge keys on
/// ``JobListing/fingerprint`` (normalized title + company + location) instead, keeping the
/// **first** occurrence in `sources` order (so the earlier-listed provider wins a tie) while
/// preserving each listing's own `id` for persistence.
///
/// **Partial failure is soft:** a provider that throws is skipped and the others still return.
/// It only throws when **every** provider fails (surfacing the last error), matching how
/// `SearchAndRankUseCase` treats a whole-run failure.
nonisolated struct CompositeJobSource: JobSource {
    let sources: [any JobSource]
    /// Cap on providers queried concurrently (they're few, but keep it bounded for N).
    let maxConcurrent: Int

    init(sources: [any JobSource], maxConcurrent: Int = 4) {
        self.sources = sources
        self.maxConcurrent = maxConcurrent
    }

    func search(_ query: JobQuery) async throws -> [JobListing] {
        guard !sources.isEmpty else { return [] }

        let outcomes = await run(query)

        // All failed → surface the last error (like SearchAndRankUseCase's whole-run failure).
        let succeeded = outcomes.contains { if case .success = $0 { return true } else { return false } }
        if !succeeded, let lastError = outcomes.reversed().compactMap({ $0.failureError }).first {
            throw lastError
        }

        // Merge in source order, keeping the first listing per fingerprint.
        var seen = Set<String>()
        var merged = [JobListing]()
        for case .success(let listings) in outcomes {
            for listing in listings where seen.insert(listing.fingerprint).inserted {
                merged.append(listing)
            }
        }
        return merged
    }

    /// Runs each source's search with at most `maxConcurrent` in flight, returning each
    /// source's result (success or failure) in `sources` order.
    private func run(_ query: JobQuery) async -> [Result<[JobListing], Error>] {
        let window = max(1, min(maxConcurrent, sources.count))
        var outcomes = [Int: Result<[JobListing], Error>]()

        await withTaskGroup(of: (Int, Result<[JobListing], Error>).self) { group in
            var next = 0
            func schedule(_ index: Int) {
                let source = sources[index]
                group.addTask {
                    do { return (index, .success(try await source.search(query))) }
                    catch { return (index, .failure(error)) }
                }
            }

            for _ in 0..<window { schedule(next); next += 1 }
            while let (index, result) = await group.next() {
                outcomes[index] = result
                if next < sources.count { schedule(next); next += 1 }
            }
        }

        return (0..<sources.count).map { outcomes[$0] ?? .success([]) }
    }
}

private extension Result where Failure == Error {
    var failureError: Error? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
