//
//  JobListing.swift
//  Taylor'd Portfolio
//
//  Data · Models — a single job posting from a JobSource.
//

import Foundation

/// A single job posting as returned by a `JobSource`.
///
/// Plain `Codable` data — deliberately *not* `Generable`, because it comes from a
/// job API, not from the language model.
nonisolated struct JobListing: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var company: String
    var location: String
    var description: String
    var url: URL?
    var salary: SalaryRange?

    // MARK: Richer posting detail (v0.6.0 Milestone A)

    /// The employment-type flags the source reported for this posting — e.g.
    /// `[.permanent, .fullTime]` — or empty when the source gives none. Distinct from a
    /// *search filter*: this is what the job actually is. `PositionType`'s raw values match
    /// the source flag names, but the mapping stays inside the source (A-A: Adzuna decode).
    var positionTypes: [PositionType]
    /// When the posting was published, when the source provides it (Adzuna `created`).
    var postedDate: Date?
    /// The source's job-category label (e.g. "IT Jobs"), when provided (Adzuna `category`).
    var category: String?

    init(
        id: String,
        title: String,
        company: String,
        location: String,
        description: String,
        url: URL? = nil,
        salary: SalaryRange? = nil,
        positionTypes: [PositionType] = [],
        postedDate: Date? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.title = title
        self.company = company
        self.location = location
        self.description = description
        self.url = url
        self.salary = salary
        self.positionTypes = positionTypes
        self.postedDate = postedDate
        self.category = category
    }

    enum CodingKeys: String, CodingKey {
        case id, title, company, location, description, url, salary
        case positionTypes, postedDate, category
    }

    /// Custom decoding so listings persisted before the richer fields existed still load —
    /// the new keys decode-with-defaults (empty/nil). Without this, a legacy `RankedJob`
    /// blob would fail to decode and `SavedJobsRepository` would silently drop the row.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        company = try container.decode(String.self, forKey: .company)
        location = try container.decode(String.self, forKey: .location)
        description = try container.decode(String.self, forKey: .description)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        salary = try container.decodeIfPresent(SalaryRange.self, forKey: .salary)
        positionTypes = try container.decodeIfPresent([PositionType].self, forKey: .positionTypes) ?? []
        postedDate = try container.decodeIfPresent(Date.self, forKey: .postedDate)
        category = try container.decodeIfPresent(String.self, forKey: .category)
    }
}
