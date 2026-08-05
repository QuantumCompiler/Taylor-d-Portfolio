//
//  ResultsFilter.swift
//  Taylor'd Portfolio
//
//  Presentation · Results — a pure, live view-filter over the loaded results (Milestone W).
//

import Foundation

/// A **non-destructive** filter applied to the already-loaded `[RankedJob]` in the Results
/// view — it only hides rows, never re-runs the search or mutates persistence (distinct from
/// Milestone U-E's search-time min-rank filter). Pure and unit-tested; the view holds one and
/// applies it live.
///
/// Active facets combine with **AND**; an all-empty filter is the identity. Keyword matching is
/// case-insensitive substring over the job's **title + company + description + matched skills**.
/// The tracked-status facet needs each job's tracked state, supplied by the caller as a closure
/// (the status lives in the ViewModel, not on `RankedJob`).
struct ResultsFilter: Equatable, Sendable {
    /// Keep only jobs scoring ≥ this (nil ⇒ no floor).
    var minScore: Int?
    /// Case-insensitive substring the job must contain (empty ⇒ ignored).
    var keywords: String = ""
    /// Exact location match (nil/empty ⇒ ignored).
    var location: String?
    /// Exact company match (nil/empty ⇒ ignored).
    var company: String?
    /// Keep only jobs whose known salary reaches this floor (nil ⇒ ignored; jobs with no
    /// salary info are excluded while this facet is active).
    var salaryMin: Double?
    /// Filter by whether the job is tracked.
    var trackedStatus: TrackedFilter = .any

    enum TrackedFilter: String, CaseIterable, Sendable {
        case any, tracked, untracked
    }

    // MARK: Bounded salary input (v0.7.1 Milestone H)

    /// Ceiling on a typed salary floor — beyond any real salary in any supported currency, and
    /// comfortably inside the range where `Double` → `Int` is exact. The bound is what makes
    /// the field's display round-trip (`String(Int(_:))`) structurally unable to trap: a 19+
    /// digit entry used to parse to ~1e19 and crash the very next render.
    static let maxSalaryInput: Double = 1_000_000_000

    /// Parses the Min-salary text field: digits only, positive, capped at ``maxSalaryInput``.
    /// `nil` ⇒ no floor ("Any").
    static func salaryInput(_ text: String) -> Double? {
        guard let value = Double(text.filter(\.isNumber)), value >= 1 else { return nil }
        return min(value, maxSalaryInput)
    }

    /// The field's display text for a stored floor — clamped before the `Int` conversion, so
    /// even a value persisted before the input bound existed renders instead of trapping.
    static func salaryDisplay(_ value: Double?) -> String {
        guard let value, value >= 1 else { return "" }
        return String(Int(min(value, maxSalaryInput)))
    }

    /// Whether any facet is active (drives the Clear affordance).
    var isActive: Bool {
        minScore != nil
            || !keywords.trimmingCharacters(in: .whitespaces).isEmpty
            || (location.map { !$0.isEmpty } ?? false)
            || (company.map { !$0.isEmpty } ?? false)
            || salaryMin != nil
            || trackedStatus != .any
    }

    /// The subset of `jobs` matching every active facet, order preserved.
    func apply(to jobs: [RankedJob], isTracked: (RankedJob) -> Bool = { _ in false }) -> [RankedJob] {
        guard isActive else { return jobs }
        return jobs.filter { matches($0, isTracked: isTracked) }
    }

    /// Whether one job passes every active facet.
    func matches(_ job: RankedJob, isTracked: (RankedJob) -> Bool = { _ in false }) -> Bool {
        if let minScore, job.score < minScore { return false }

        let needle = keywords.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !needle.isEmpty {
            let haystack = ([job.listing.title, job.listing.company, job.listing.description]
                + job.match.matchedSkills).joined(separator: " ").lowercased()
            if !haystack.contains(needle) { return false }
        }

        if let location, !location.isEmpty,
           job.listing.location.caseInsensitiveCompare(location) != .orderedSame { return false }

        if let company, !company.isEmpty,
           job.listing.company.caseInsensitiveCompare(company) != .orderedSame { return false }

        if let salaryMin {
            guard let top = job.listing.salary?.max ?? job.listing.salary?.min, top >= salaryMin else {
                return false
            }
        }

        switch trackedStatus {
        case .any: break
        case .tracked: if !isTracked(job) { return false }
        case .untracked: if isTracked(job) { return false }
        }
        return true
    }
}
