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

    init(titles: [String], location: String? = nil, salaryMin: Double? = nil) {
        self.titles = titles
        self.location = location
        self.salaryMin = salaryMin
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
    /// location and salary floor.
    func query(forTitle title: String) -> JobQuery {
        JobQuery(
            keywords: title,
            location: (location?.isEmpty ?? true) ? nil : location,
            salaryMin: salaryMin
        )
    }
}
