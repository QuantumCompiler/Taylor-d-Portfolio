//
//  ResultsSort.swift
//  Taylor'd Portfolio
//
//  Presentation · Results — a pure, live sort over the ranked results (v0.6.2 Milestone C).
//

import Foundation

/// A **live, non-destructive** sort applied to the Results list's `[RankedJob]` — the Results
/// analogue of ``TrackerSort``, giving that tab the capability the Tracker already had (the
/// Tracker gains the ``ResultsFilter`` in the same milestone). Pure and unit-tested; the view
/// model holds one and applies it **after** the filter (it never re-runs a search or mutates
/// persistence).
///
/// Deliberately a **parallel type** rather than a reuse of `TrackerSort`: that sorts
/// `[TrackedJob]` on **status-based** keys (recent activity / date applied / stage) which don't
/// exist for an un-triaged `RankedJob`. The keys here are the ones a ranked result actually has.
///
/// ``default`` is match-score-descending — the order the ranker already returns, so an untouched
/// sort reproduces today's list exactly. A title tie-break keeps every ordering stable.
struct ResultsSort: Equatable, Sendable {
    /// What to order by.
    enum Key: String, CaseIterable, Sendable, Identifiable {
        /// The job's fit score — the ranker's own order (the default).
        case matchScore
        case company
        case title
        /// The advertised salary (its top figure, falling back to the floor).
        case salary
        /// When the posting went up (`JobListing.postedDate`).
        case postedDate

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .matchScore: return "Match score"
            case .company:    return "Company"
            case .title:      return "Role title"
            case .salary:     return "Salary"
            case .postedDate: return "Date posted"
            }
        }
    }

    enum Direction: String, CaseIterable, Sendable, Identifiable {
        case descending
        case ascending

        var id: String { rawValue }

        var displayName: String { self == .descending ? "Descending" : "Ascending" }
    }

    var key: Key = .matchScore
    var direction: Direction = .descending

    /// The ranker's own order: best match first.
    static let `default` = ResultsSort()

    /// Whether this is the default order (drives a "reset" affordance).
    var isDefault: Bool { self == .default }

    /// The results ordered by the active key + direction. Order is stable — equal keys fall
    /// back to a case-insensitive role-title comparison.
    func apply(to jobs: [RankedJob]) -> [RankedJob] {
        jobs.sorted(by: sortsBefore)
    }

    // MARK: Comparators

    private func sortsBefore(_ a: RankedJob, _ b: RankedJob) -> Bool {
        switch key {
        case .matchScore: return byComparable(a.score, b.score, a, b)
        case .company:    return byString(a.listing.company, b.listing.company, a, b)
        case .title:      return byString(a.listing.title, b.listing.title, a, b)
        case .salary:     return byOptional(salary(a), salary(b), a, b)
        case .postedDate: return byOptional(a.listing.postedDate, b.listing.postedDate, a, b)
        }
    }

    private func byComparable<T: Comparable>(_ l: T, _ r: T, _ a: RankedJob, _ b: RankedJob) -> Bool {
        if l != r { return direction == .ascending ? l < r : l > r }
        return titleAscending(a, b)
    }

    /// Ordering for a facet a listing may simply not carry (salary, posted date). Known values
    /// sort per `direction`; **unknowns are always last** regardless of direction — same rule
    /// `TrackerSort` uses for undated jobs, so "unknown" never masquerades as the best or worst
    /// value. Ties break on title.
    private func byOptional<T: Comparable>(_ l: T?, _ r: T?, _ a: RankedJob, _ b: RankedJob) -> Bool {
        switch (l, r) {
        case let (l?, r?):
            if l != r { return direction == .ascending ? l < r : l > r }
            return titleAscending(a, b)
        case (_?, nil): return true    // known before unknown
        case (nil, _?): return false   // unknown after known
        case (nil, nil): return titleAscending(a, b)
        }
    }

    private func byString(_ l: String, _ r: String, _ a: RankedJob, _ b: RankedJob) -> Bool {
        let comparison = l.localizedCaseInsensitiveCompare(r)
        if comparison != .orderedSame {
            return direction == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
        return titleAscending(a, b)
    }

    /// The figure to rank a listing's pay on: the top of the advertised range, falling back to
    /// its floor (matching how `ResultsFilter`'s salary facet reads a range).
    private func salary(_ job: RankedJob) -> Double? {
        job.listing.salary?.max ?? job.listing.salary?.min
    }

    /// Stable tie-break: case-insensitive role title, ascending.
    private func titleAscending(_ a: RankedJob, _ b: RankedJob) -> Bool {
        a.listing.title.localizedCaseInsensitiveCompare(b.listing.title) == .orderedAscending
    }
}
