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
/// required before a search can run.
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

    private let searchAndRank: SearchAndRankUseCase

    init(searchAndRank: SearchAndRankUseCase) {
        self.searchAndRank = searchAndRank
    }

    var hasProfile: Bool { profile != nil }

    var canSearch: Bool {
        hasProfile
            && !keywords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSearching
    }

    func search() async {
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
            errorMessage = "Search failed. Check your Adzuna keys in Settings, then try again."
        }
    }
}
