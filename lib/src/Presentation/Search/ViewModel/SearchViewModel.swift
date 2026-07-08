//
//  SearchViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Search · ViewModel
//

import Foundation
import Observation

/// Drives the Search screen: collects query parameters and runs search + ranking.
///
/// `profile` is supplied by the app flow (built on the Portfolio screen) and is
/// required before a search can run. `adzunaConfigured` reflects whether the build
/// baked in Adzuna credentials (Milestone K) — when it didn't, search is disabled
/// with a clear "unavailable in this build" banner rather than failing at runtime.
@MainActor
@Observable
final class SearchViewModel {
    var keywords: String = ""
    var location: String = ""
    var salaryMin: String = ""
    var profile: CandidateProfile?

    private(set) var results: [RankedJob] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?

    /// Whether this build has baked Adzuna credentials. When `false`, search can't run.
    let adzunaConfigured: Bool

    private let searchAndRank: SearchAndRankUseCase

    init(searchAndRank: SearchAndRankUseCase, adzunaConfigured: Bool = true) {
        self.searchAndRank = searchAndRank
        self.adzunaConfigured = adzunaConfigured
    }

    var hasProfile: Bool { profile != nil }

    /// A build-level banner shown when search is unavailable because credentials
    /// weren't baked in. Distinct from `errorMessage`, which reports run failures.
    var unavailableMessage: String? {
        adzunaConfigured
            ? nil
            : "Search is unavailable in this build — Adzuna credentials weren't configured when it was built."
    }

    var canSearch: Bool {
        adzunaConfigured
            && hasProfile
            && !keywords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSearching
    }

    func search() async {
        guard adzunaConfigured else {
            errorMessage = unavailableMessage
            return
        }
        guard let profile else {
            errorMessage = "Build your profile on the Portfolio tab first."
            return
        }
        guard canSearch else { return }

        let query = JobQuery(
            keywords: keywords,
            location: location.isEmpty ? nil : location,
            salaryMin: Double(salaryMin)
        )
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            results = try await searchAndRank(query: query, profile: profile)
        } catch {
            errorMessage = "Search failed. Please check your connection and try again."
        }
    }
}
