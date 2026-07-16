//
//  JobSearchRequest.swift
//  Taylor'd Portfolio
//
//  Data · Models — a multi-title search request (fanned out into JobQuerys).
//

import Foundation

/// What the user asks for on the Search screen: one or more role titles sharing a
/// single location and salary floor.
///
/// This is the multi-title unit the *use case* understands. `JobQuery` stays the
/// single-`what` unit a `JobSource` understands — `SearchAndRankUseCase` expands one
/// request into one `JobQuery` per title. `Codable` so searches can be saved later.
nonisolated struct JobSearchRequest: Codable, Equatable, Sendable {
    /// The role titles to search for (e.g. "iOS Developer", "iOS Engineer").
    var titles: [String]
    /// Optional location shared across all title searches.
    var location: String?
    /// Optional lower bound on annual salary, shared across all title searches.
    var salaryMin: Double?
    /// Optional employment-type filter, shared across all title searches (U-A).
    var positionType: PositionType?
    /// Optional best-effort target for how many listings to gather (U-D). Never a hard
    /// requirement — the search returns what it can and notes any shortfall.
    var desiredResultCount: Int?
    /// Optional minimum match score (0–100) to keep after ranking (U-E). Nil ⇒ no filter.
    var minimumScore: Int?
    /// The provider ids to search (Milestone H). `nil` ⇒ all available providers — kept
    /// optional so `SavedSearch`es saved before H (no `sources` key) decode to `nil` and
    /// re-run against everything, exactly as before.
    var sources: [String]?

    init(
        titles: [String],
        location: String? = nil,
        salaryMin: Double? = nil,
        positionType: PositionType? = nil,
        desiredResultCount: Int? = nil,
        minimumScore: Int? = nil,
        sources: [String]? = nil
    ) {
        self.titles = titles
        self.location = location
        self.salaryMin = salaryMin
        self.positionType = positionType
        self.desiredResultCount = desiredResultCount
        self.minimumScore = minimumScore
        self.sources = sources
    }

    /// Titles trimmed, emptied-dropped, and de-duplicated case-insensitively while
    /// preserving first-seen order — the actual set of searches to run.
    var cleanedTitles: [String] {
        var seen = Set<String>()
        var result = [String]()
        for title in titles {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            if seen.insert(key).inserted { result.append(trimmed) }
        }
        return result
    }

    /// The single-title `JobQuery` for one cleaned title, sharing this request's
    /// location, salary floor, and position type. `page` / `resultsPerPage` let the use
    /// case page toward a desired-result-count goal (U-D); they default to a single page.
    func query(forTitle title: String, page: Int = 1, resultsPerPage: Int = 25) -> JobQuery {
        JobQuery(
            keywords: title,
            location: (location?.isEmpty ?? true) ? nil : location,
            salaryMin: salaryMin,
            positionType: positionType,
            page: page,
            resultsPerPage: resultsPerPage,
            sources: sources
        )
    }
}
