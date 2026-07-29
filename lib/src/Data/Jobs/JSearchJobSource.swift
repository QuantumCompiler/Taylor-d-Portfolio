//
//  JSearchJobSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — JobSource backed by JSearch (Google-for-Jobs aggregator via RapidAPI).
//

import Foundation

/// A ``JobSource`` backed by **JSearch** (RapidAPI) — a Google-for-Jobs aggregator that pulls
/// LinkedIn / Indeed / Glassdoor / ZipRecruiter into one call (v0.6.0 Milestone F).
///
/// JSearch's response is already rich: the **full** description plus structured highlights
/// (qualifications / responsibilities / benefits), employment type, remote flag, salary, and
/// posted date. Those map straight onto the domain `JobListing`'s Milestone A/E fields, so a
/// JSearch result arrives already-enriched (no page-fetch / LLM pass needed downstream).
///
/// JSearch-specific request/response shapes stay private to this type; callers only ever see
/// `JobQuery` in and `[JobListing]` out. The API key is sent per-request as a RapidAPI header.
nonisolated struct JSearchJobSource: JobSource {
    /// RapidAPI credential — a single API key.
    struct Credentials: Sendable, Equatable {
        var apiKey: String
    }

    static let host = "jsearch.p.rapidapi.com"
    static let defaultBaseURL = URL(string: "https://jsearch.p.rapidapi.com")!

    let credentials: Credentials
    let http: any HTTPClient
    let baseURL: URL

    init(credentials: Credentials, http: any HTTPClient, baseURL: URL = JSearchJobSource.defaultBaseURL) {
        self.credentials = credentials
        self.http = http
        self.baseURL = baseURL
    }

    func search(_ query: JobQuery) async throws -> [JobListing] {
        let url = try Self.buildURL(query: query, baseURL: baseURL)
        let headers = [
            "X-RapidAPI-Key": credentials.apiKey,
            "X-RapidAPI-Host": Self.host,
        ]
        let data = try await http.get(url, headers: headers)
        let response = try JSONDecoder().decode(Response.self, from: data)
        return (response.data ?? []).map { $0.toDomain() }
    }

    // MARK: - URL building (pure, unit-tested)

    static func buildURL(query: JobQuery, baseURL: URL = defaultBaseURL) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw JobSourceError.invalidURL
        }
        components.path = "/search"

        // JSearch takes a single free-text `query`; fold the location into it ("<what> in <where>").
        var queryText = query.keywords
        if let location = query.location, !location.isEmpty {
            queryText += " in \(location)"
        }

        var items = [
            URLQueryItem(name: "query", value: queryText),
            URLQueryItem(name: "page", value: String(query.page)),
            URLQueryItem(name: "num_pages", value: "1"),
        ]
        if let positionType = query.positionType, let employment = employmentType(for: positionType) {
            items.append(URLQueryItem(name: "employment_types", value: employment))
        }
        components.queryItems = items

        guard let url = components.url else { throw JobSourceError.invalidURL }
        return url
    }

    /// Maps our `PositionType` to JSearch's `employment_types` token, or `nil` when JSearch
    /// has no matching filter (leaves it off rather than guessing).
    static func employmentType(for positionType: PositionType) -> String? {
        switch positionType {
        case .fullTime, .permanent: return "FULLTIME"   // permanent ≈ a permanent full-time role
        case .partTime:             return "PARTTIME"
        case .contract:             return "CONTRACTOR"
        }
    }

    // MARK: - JSearch wire types (private; never leak past `search`)

    private struct Response: Decodable {
        var data: [Job]?
    }

    private struct Job: Decodable {
        var jobID: String
        var title: String?
        var employerName: String?
        var city: String?
        var state: String?
        var country: String?
        var description: String?
        var applyLink: String?
        var employmentType: String?
        var isRemote: Bool?
        var minSalary: Double?
        var maxSalary: Double?
        var salaryCurrency: String?
        var postedAtTimestamp: Double?
        var highlights: Highlights?

        struct Highlights: Decodable {
            var qualifications: [String]?
            var responsibilities: [String]?
            var benefits: [String]?
            enum CodingKeys: String, CodingKey {
                case qualifications = "Qualifications"
                case responsibilities = "Responsibilities"
                case benefits = "Benefits"
            }
        }

        enum CodingKeys: String, CodingKey {
            case jobID = "job_id"
            case title = "job_title"
            case employerName = "employer_name"
            case city = "job_city"
            case state = "job_state"
            case country = "job_country"
            case description = "job_description"
            case applyLink = "job_apply_link"
            case employmentType = "job_employment_type"
            case isRemote = "job_is_remote"
            case minSalary = "job_min_salary"
            case maxSalary = "job_max_salary"
            case salaryCurrency = "job_salary_currency"
            case postedAtTimestamp = "job_posted_at_timestamp"
            case highlights = "job_highlights"
        }

        func toDomain() -> JobListing {
            let location = [city, state, country]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")

            let salary: SalaryRange? = (minSalary != nil || maxSalary != nil)
                ? SalaryRange(min: minSalary, max: maxSalary, currency: salaryCurrency)
                : nil

            let positionTypes = employmentType
                .flatMap(JSearchJobSource.positionType(forEmployment:))
                .map { [$0] } ?? []

            // JSearch's structured highlights map straight onto our enriched PostingDetails
            // (Milestone A). Attach only when there's content.
            let details = PostingDetails(
                workTypeRaw: (isRemote == true) ? "remote" : "",
                qualifications: highlights?.qualifications ?? [],
                responsibilities: highlights?.responsibilities ?? [],
                benefits: highlights?.benefits ?? []
            )

            return JobListing(
                id: jobID,
                title: title ?? "",
                company: employerName ?? "",
                location: location,
                description: description ?? "",   // JSearch gives the full posting text
                url: applyLink.flatMap { URL(string: $0) },
                salary: salary,
                positionTypes: positionTypes,
                postedDate: postedAtTimestamp.map { Date(timeIntervalSince1970: $0) },
                details: details.hasContent ? details : nil,
                source: "JSearch"
            )
        }
    }

    /// Maps a JSearch `job_employment_type` token to our `PositionType` (nil when unknown,
    /// e.g. "INTERN").
    static func positionType(forEmployment token: String) -> PositionType? {
        switch token.uppercased() {
        case "FULLTIME":   return .fullTime
        case "PARTTIME":   return .partTime
        case "CONTRACTOR": return .contract
        default:           return nil
        }
    }
}
