//
//  CompositeJobSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — aggregate several JobSources behind one JobSource (v0.6.0 Milestone F/H).
//

import Foundation

/// A ``JobSource`` that fans a query out across several **labeled** providers (Adzuna,
/// JSearch, …), runs them with **bounded concurrency**, and merges their results into one
/// de-duplicated list — so the fan-out over *providers* sits below the seam and callers
/// (`SearchAndRankUseCase`, which fans out over *titles*) are unchanged.
///
/// **Selection (Milestone H):** when a query names `sources`, only providers whose `id` is in
/// that list run; `nil`/empty ⇒ every provider. This is how the Search-view provider selector
/// restricts a search without the use case knowing about providers.
///
/// **Cross-source de-dup:** `JobListing.id` is source-specific, so the merge keys on
/// ``JobListing/fingerprint`` (normalized title + company + location), keeping the **first**
/// occurrence in provider order while preserving each listing's own `id` for persistence.
///
/// **Partial failure is soft:** a provider that throws is skipped and the others still return;
/// it only throws when **every** active provider fails (surfacing the last error).
nonisolated struct CompositeJobSource: JobSource {
    /// A provider labeled by its id (matches the registry / `JobProvider.rawValue`), so a
    /// search can restrict the fan-out to a selection.
    struct Provider: Sendable {
        let id: String
        let source: any JobSource
    }

    let providers: [Provider]
    /// Cap on providers queried concurrently (they're few, but keep it bounded for N).
    let maxConcurrent: Int

    init(providers: [Provider], maxConcurrent: Int = 4) {
        self.providers = providers
        self.maxConcurrent = maxConcurrent
    }

    /// Convenience for callers/tests that don't need selection — ids are assigned positionally.
    init(sources: [any JobSource], maxConcurrent: Int = 4) {
        self.init(
            providers: sources.enumerated().map { Provider(id: String($0.offset), source: $0.element) },
            maxConcurrent: maxConcurrent
        )
    }

    func search(_ query: JobQuery) async throws -> [JobListing] {
        let active = selectedProviders(for: query.sources)
        guard !active.isEmpty else { return [] }

        let outcomes = await run(query, providers: active)

        // All failed → surface the last error (like SearchAndRankUseCase's whole-run failure).
        let succeeded = outcomes.contains { if case .success = $0 { return true } else { return false } }
        if !succeeded, let lastError = outcomes.reversed().compactMap({ $0.failureError }).first {
            throw lastError
        }

        // Merge in provider order, keeping the first listing per fingerprint.
        var seen = Set<String>()
        var merged = [JobListing]()
        for case .success(let listings) in outcomes {
            for listing in listings where seen.insert(listing.fingerprint).inserted {
                merged.append(listing)
            }
        }
        return merged
    }

    /// The providers a search should run: those named in `sources`, or all when `sources` is
    /// `nil`/empty (order preserved from `providers`).
    private func selectedProviders(for sources: [String]?) -> [Provider] {
        guard let sources, !sources.isEmpty else { return providers }
        let selected = Set(sources)
        return providers.filter { selected.contains($0.id) }
    }

    /// Runs each active provider's search with at most `maxConcurrent` in flight, returning
    /// each provider's result (success or failure) in `active` order.
    private func run(_ query: JobQuery, providers active: [Provider]) async -> [Result<[JobListing], Error>] {
        let window = max(1, min(maxConcurrent, active.count))
        var outcomes = [Int: Result<[JobListing], Error>]()

        await withTaskGroup(of: (Int, Result<[JobListing], Error>).self) { group in
            var next = 0
            func schedule(_ index: Int) {
                let source = active[index].source
                group.addTask {
                    do { return (index, .success(try await source.search(query))) }
                    catch { return (index, .failure(error)) }
                }
            }

            for _ in 0..<window { schedule(next); next += 1 }
            while let (index, result) = await group.next() {
                outcomes[index] = result
                if next < active.count { schedule(next); next += 1 }
            }
        }

        return (0..<active.count).map { outcomes[$0] ?? .success([]) }
    }
}

private extension Result where Failure == Error {
    var failureError: Error? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
