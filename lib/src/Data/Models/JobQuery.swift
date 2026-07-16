//
//  JobQuery.swift
//  Taylor'd Portfolio
//
//  Data · Models — user-specified search parameters.
//

import Foundation

/// The parameters a user sets on the Search screen, handed to a `JobSource`.
///
/// `Codable` so searches can be saved and restored later (see ROADMAP fast-follow).
nonisolated struct JobQuery: Codable, Equatable, Sendable {
    /// Free-text role / title / keyword search (e.g. "iOS engineer").
    var keywords: String
    /// Optional location filter (city, region, or "remote").
    var location: String?
    /// Optional lower bound on annual salary.
    var salaryMin: Double?
    /// Optional employment-type filter (nil ⇒ any).
    var positionType: PositionType?
    /// 1-based page index for paginated sources.
    var page: Int
    /// How many listings to request per page.
    var resultsPerPage: Int
    /// The provider ids to query (Milestone H). `nil` (or empty) ⇒ every configured provider —
    /// only ``CompositeJobSource`` reads it, to restrict the fan-out to the user's selection.
    var sources: [String]?

    init(
        keywords: String,
        location: String? = nil,
        salaryMin: Double? = nil,
        positionType: PositionType? = nil,
        page: Int = 1,
        resultsPerPage: Int = 25,
        sources: [String]? = nil
    ) {
        self.keywords = keywords
        self.location = location
        self.salaryMin = salaryMin
        self.positionType = positionType
        self.page = page
        self.resultsPerPage = resultsPerPage
        self.sources = sources
    }
}
