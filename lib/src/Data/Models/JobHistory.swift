//
//  JobHistory.swift
//  Taylor'd Portfolio
//
//  Data · Models — the cross-screen "history" of a single job.
//

import Foundation

/// The one-history story for a job, assembled from the three persisted sources so the
/// UI can tell — in one glance — where a listing stands across Results, saved jobs, and
/// the Tracker (Milestone S-C):
///
/// - `isSaved` — its listing is persisted ("already seen"),
/// - `isGenerated` — an ``ApplicationKit`` has been generated for it ("already generated"),
/// - `status` — its ``ApplicationStatus`` when tracked ("applied", "interviewing", …).
///
/// Pure value type, so the badge-assembly logic (``facets``) is unit-tested without any
/// store or view.
nonisolated struct JobHistory: Equatable, Sendable {
    /// The listing is persisted — we've pulled/saved it before.
    var isSaved: Bool
    /// An ``ApplicationKit`` has been generated for this job.
    var isGenerated: Bool
    /// The application status when the job is tracked (nil ⇒ merely seen, not tracked).
    var status: ApplicationStatus?

    init(isSaved: Bool = false, isGenerated: Bool = false, status: ApplicationStatus? = nil) {
        self.isSaved = isSaved
        self.isGenerated = isGenerated
        self.status = status
    }

    /// Whether the job is tracked (has an explicit application status).
    var isTracked: Bool { status != nil }

    /// Whether there is any history at all to surface (a brand-new result has none).
    var hasHistory: Bool { isSaved || isGenerated || status != nil }

    /// A single badge in the history story.
    enum Facet: Equatable {
        /// Where the application stands (Saved / Applied / Interviewing / …).
        case status(ApplicationStatus)
        /// Seen before — the listing is saved, but not yet tracked.
        case seen
        /// An application has already been generated for this job.
        case generated
    }

    /// The badges to render, in a consistent order and without redundancy: the status
    /// badge subsumes "seen" (a tracked job is obviously saved), while "generated" is
    /// always its own distinct fact and comes last.
    var facets: [Facet] {
        var facets: [Facet] = []
        if let status {
            facets.append(.status(status))
        } else if isSaved {
            facets.append(.seen)
        }
        if isGenerated {
            facets.append(.generated)
        }
        return facets
    }
}
