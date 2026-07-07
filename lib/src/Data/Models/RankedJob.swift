//
//  RankedJob.swift
//  Taylor'd Portfolio
//
//  Data · Models — a listing paired with its fit assessment.
//

import Foundation

/// A `JobListing` paired with its `JobMatch` — the unit rendered in the ranked
/// results list. Composed internally, so it is `Codable` but not `Generable`.
nonisolated struct RankedJob: Codable, Equatable, Sendable, Identifiable {
    var listing: JobListing
    var match: JobMatch

    /// Stable identity for SwiftUI lists — the underlying listing's id.
    var id: String { listing.id }

    /// Convenience accessor for the fit score.
    var score: Int { match.score }

    init(listing: JobListing, match: JobMatch) {
        self.listing = listing
        self.match = match
    }
}
