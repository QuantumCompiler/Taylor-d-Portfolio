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
    /// The LLM-enriched structure of the posting (work type + qualifications / responsibilities
    /// / about-role/company / benefits), attached by the enrichment pass (A-B); nil until a
    /// listing is enriched.
    var details: PostingDetails?

    // MARK: Full posting text (v0.6.0 Milestone E)

    /// The **full** posting body, recovered from the posting page behind `url` when Adzuna's
    /// `description` is only a truncated ~500-char snippet. `nil` until captured (or when the
    /// page can't be fetched — JS-gated / paywalled / blocked). The snippet is never
    /// overwritten; both are kept, and ``effectiveDescription`` prefers this when present.
    var fullDescription: String?

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
        category: String? = nil,
        details: PostingDetails? = nil,
        fullDescription: String? = nil
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
        self.details = details
        self.fullDescription = fullDescription
    }

    /// The fullest posting text available for grounding and display — the recovered full page
    /// when present, else the (possibly truncated) API snippet. Ranking, brief-building, and
    /// the detail view read this so they work from the whole posting when it's been captured.
    var effectiveDescription: String { fullDescription ?? description }

    enum CodingKeys: String, CodingKey {
        case id, title, company, location, description, url, salary
        case positionTypes, postedDate, category, details, fullDescription
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
        details = try container.decodeIfPresent(PostingDetails.self, forKey: .details)
        fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
    }
}
