//
//  AdzunaJobSource.swift
//  Taylor'd Portfolio
//
//  Data · Jobs — JobSource backed by the Adzuna REST API.
//

import Foundation

/// A `JobSource` backed by the Adzuna REST API (free tier).
///
/// Adzuna-specific request/response shapes stay private to this type; callers only
/// ever see `JobQuery` in and `[JobListing]` out.
nonisolated struct AdzunaJobSource: JobSource {

    /// Adzuna account credentials plus the country to search.
    struct Credentials: Sendable, Equatable {
        var appID: String
        var appKey: String
        /// ISO-ish country code Adzuna expects in the path, e.g. "us", "gb".
        var country: String
    }

    static let defaultBaseURL = URL(string: "https://api.adzuna.com")!

    let credentials: Credentials
    let http: any HTTPClient
    let baseURL: URL

    init(credentials: Credentials, http: any HTTPClient, baseURL: URL = AdzunaJobSource.defaultBaseURL) {
        self.credentials = credentials
        self.http = http
        self.baseURL = baseURL
    }

    func search(_ query: JobQuery) async throws -> [JobListing] {
        let url = try Self.buildURL(credentials: credentials, query: query, baseURL: baseURL)
        let data = try await http.get(url)
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.results.map { $0.toDomain() }
    }

    // MARK: - URL building (pure, unit-tested)

    static func buildURL(credentials: Credentials, query: JobQuery, baseURL: URL = defaultBaseURL) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw JobSourceError.invalidURL
        }
        components.path = "/v1/api/jobs/\(credentials.country)/search/\(query.page)"

        var items = [
            URLQueryItem(name: "app_id", value: credentials.appID),
            URLQueryItem(name: "app_key", value: credentials.appKey),
            URLQueryItem(name: "results_per_page", value: String(query.resultsPerPage)),
            URLQueryItem(name: "what", value: query.keywords),
        ]
        if let location = query.location, !location.isEmpty {
            items.append(URLQueryItem(name: "where", value: location))
        }
        if let salaryMin = query.salaryMin {
            items.append(URLQueryItem(name: "salary_min", value: String(Int(salaryMin))))
        }
        // Adzuna expresses employment type as boolean flags (full_time / part_time /
        // contract / permanent); the enum's raw value is exactly the flag name.
        if let positionType = query.positionType {
            items.append(URLQueryItem(name: positionType.rawValue, value: "1"))
        }
        components.queryItems = items

        guard let url = components.url else { throw JobSourceError.invalidURL }
        return url
    }

    // MARK: - Adzuna wire types (private; never leak past `search`)

    private struct Response: Decodable {
        var results: [Job]
    }

    private struct Job: Decodable {
        var id: String
        var title: String
        var company: Named?
        var location: Named?
        var description: String
        var redirectURL: String?
        var salaryMin: Double?
        var salaryMax: Double?
        // Richer posting detail (v0.6.0 Milestone A-A) — structured fields Adzuna already
        // returns but we previously discarded.
        var contractType: String?   // "permanent" | "contract"
        var contractTime: String?   // "full_time" | "part_time"
        var category: Category?
        var created: String?        // ISO-8601 timestamp, e.g. "2024-01-15T09:00:00Z"

        struct Named: Decodable {
            var displayName: String?
            enum CodingKeys: String, CodingKey { case displayName = "display_name" }
        }

        /// Adzuna returns `category` as an object; we keep only its human label.
        struct Category: Decodable {
            var label: String?
        }

        enum CodingKeys: String, CodingKey {
            case id, title, company, location, description, category, created
            case redirectURL = "redirect_url"
            case salaryMin = "salary_min"
            case salaryMax = "salary_max"
            case contractType = "contract_type"
            case contractTime = "contract_time"
        }

        func toDomain() -> JobListing {
            let salary: SalaryRange? = (salaryMin != nil || salaryMax != nil)
                ? SalaryRange(min: salaryMin, max: salaryMax, currency: nil)
                : nil
            // Adzuna splits employment type across two orthogonal fields (contract_type =
            // permanent/contract, contract_time = full_time/part_time); both raw values are
            // exactly `PositionType` cases, so map whichever are present into the flag list.
            let positionTypes = [contractType, contractTime]
                .compactMap { $0 }
                .compactMap(PositionType.init(rawValue:))
            return JobListing(
                id: id,
                title: title,
                company: company?.displayName ?? "",
                location: location?.displayName ?? "",
                description: description,
                url: redirectURL.flatMap { URL(string: $0) },
                salary: salary,
                positionTypes: positionTypes,
                postedDate: created.flatMap(Self.parseTimestamp),
                category: category?.label
            )
        }

        /// Parses Adzuna's ISO-8601 `created` timestamp (with or without fractional
        /// seconds). Returns nil for an absent/unparseable value — a missing posted date is
        /// not an error.
        static func parseTimestamp(_ string: String) -> Date? {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: string)
        }
    }
}
