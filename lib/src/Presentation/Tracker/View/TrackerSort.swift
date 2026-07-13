//
//  TrackerSort.swift
//  Taylor'd Portfolio
//
//  Presentation · Tracker — a pure, live sort over the tracked jobs (Milestone H).
//

import Foundation

/// A **live, non-destructive** sort applied to the Tracker's `[TrackedJob]` — the Tracker
/// analogue of ``ResultsFilter``. Pure and unit-tested; the view holds one and applies it to
/// the jobs shown for the selected stage tab (it never re-runs a load or mutates persistence).
///
/// ``default`` reproduces the historic load order — most-recent status activity first, with
/// undated jobs last. A title tie-break keeps every ordering stable.
struct TrackerSort: Equatable, Sendable {
    /// What to order by.
    enum Key: String, CaseIterable, Sendable, Identifiable {
        /// The stamped date of the current stage (the historic default).
        case recentActivity
        /// When the job was marked applied.
        case dateApplied
        /// Application stage, in progression order (Saved → … → Withdrawn).
        case stage
        /// The job's fit score.
        case matchScore
        case company
        case title

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .recentActivity: return "Recent activity"
            case .dateApplied: return "Date applied"
            case .stage: return "Stage"
            case .matchScore: return "Match score"
            case .company: return "Company"
            case .title: return "Role title"
            }
        }
    }

    enum Direction: String, CaseIterable, Sendable, Identifiable {
        case descending
        case ascending

        var id: String { rawValue }

        var displayName: String { self == .descending ? "Descending" : "Ascending" }
    }

    var key: Key = .recentActivity
    var direction: Direction = .descending

    /// The historic load order: most-recent activity first, undated last.
    static let `default` = TrackerSort()

    /// Whether this is the default order (drives a "reset" affordance).
    var isDefault: Bool { self == .default }

    /// The tracked jobs ordered by the active key + direction. Order is stable — equal keys
    /// fall back to a case-insensitive role-title comparison.
    func apply(to jobs: [TrackedJob]) -> [TrackedJob] {
        jobs.sorted(by: sortsBefore)
    }

    // MARK: Comparators

    private func sortsBefore(_ a: TrackedJob, _ b: TrackedJob) -> Bool {
        switch key {
        case .recentActivity: return byDate(a.status.currentDate, b.status.currentDate, a, b)
        case .dateApplied:    return byDate(a.status.appliedDate, b.status.appliedDate, a, b)
        case .stage:          return byComparable(stageOrder(a), stageOrder(b), a, b)
        case .matchScore:     return byComparable(a.job.score, b.job.score, a, b)
        case .company:        return byString(a.job.listing.company, b.job.listing.company, a, b)
        case .title:          return byString(a.job.listing.title, b.job.listing.title, a, b)
        }
    }

    /// Date ordering. Dated jobs sort by date per `direction`; **undated jobs are always last**
    /// regardless of direction (they have no activity to rank). Ties break on title.
    private func byDate(_ l: Date?, _ r: Date?, _ a: TrackedJob, _ b: TrackedJob) -> Bool {
        switch (l, r) {
        case let (l?, r?):
            if l != r { return direction == .ascending ? l < r : l > r }
            return titleAscending(a, b)
        case (_?, nil): return true    // dated before undated
        case (nil, _?): return false   // undated after dated
        case (nil, nil): return titleAscending(a, b)
        }
    }

    private func byComparable<T: Comparable>(_ l: T, _ r: T, _ a: TrackedJob, _ b: TrackedJob) -> Bool {
        if l != r { return direction == .ascending ? l < r : l > r }
        return titleAscending(a, b)
    }

    private func byString(_ l: String, _ r: String, _ a: TrackedJob, _ b: TrackedJob) -> Bool {
        let comparison = l.localizedCaseInsensitiveCompare(r)
        if comparison != .orderedSame {
            return direction == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
        return titleAscending(a, b)
    }

    /// Progression index of the job's stage (Saved = 0 … Withdrawn = last).
    private func stageOrder(_ job: TrackedJob) -> Int {
        ApplicationStage.allCases.firstIndex(of: job.status.stage) ?? 0
    }

    /// Stable tie-break: case-insensitive role title, ascending.
    private func titleAscending(_ a: TrackedJob, _ b: TrackedJob) -> Bool {
        a.job.listing.title.localizedCaseInsensitiveCompare(b.job.listing.title) == .orderedAscending
    }
}
