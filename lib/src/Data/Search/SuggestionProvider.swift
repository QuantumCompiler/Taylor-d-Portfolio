//
//  SuggestionProvider.swift
//  Taylor'd Portfolio
//
//  Data · Search — static suggestions for the search fields.
//

import Foundation

/// Supplies suggestions for the Search screen's location and salary fields, plus the
/// profile-seeded starting titles. On-device, no network.
///
/// Role-title *suggestions* are no longer a static vocabulary — the user curates their
/// own "common role titles" (persisted via ``RoleTitleStore``). This type keeps the
/// pieces that are genuinely static: the location list and salary brackets, and the
/// profile-derived starting chips.
nonisolated struct SuggestionProvider: Sendable {
    var locations: [String]

    init(locations: [String] = SuggestionProvider.defaultLocations) {
        self.locations = locations
    }

    /// The titles to pre-fill as chips when a profile loads: its target titles,
    /// cleaned and de-duplicated (empty when there's no profile).
    func seededTitles(for profile: CandidateProfile?) -> [String] {
        var seen = Set<String>()
        var result = [String]()
        for value in profile?.targetTitles ?? [] {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
        }
        return result
    }

    /// Location suggestions from the static list (already includes "Remote"). When
    /// `query` is non-empty, only entries containing it (case-insensitively) return.
    func locationSuggestions(matching query: String = "") -> [String] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return locations }
        return locations.filter { $0.lowercased().contains(needle) }
    }

    /// The static locations merged with the user's `saved` ones, de-duplicated
    /// case-insensitively while preserving the static order first (U-B).
    func locationSuggestions(saved: [String]) -> [String] {
        var seen = Set<String>()
        var result = [String]()
        for value in locations + saved {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
        }
        return result
    }

    /// The built-in salary brackets merged with the user's `saved` ones, de-duplicated
    /// and sorted ascending (U-C).
    static func salaryPresets(saved: [Int]) -> [Int] {
        Array(Set(salaryPresets + saved)).sorted()
    }

    /// Preset salary brackets offered instead of free-text entry.
    static let salaryPresets: [Int] = [50_000, 75_000, 100_000, 125_000, 150_000, 200_000]

    static let defaultLocations: [String] = [
        "Remote", "New York, NY", "San Francisco, CA", "Seattle, WA",
        "Austin, TX", "Denver, CO", "Boston, MA", "Chicago, IL",
        "Los Angeles, CA", "Lehi, UT",
    ]
}
