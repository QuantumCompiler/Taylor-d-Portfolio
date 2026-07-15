//
//  JSearchJobSourceTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Jobs — JSearch URL building + response mapping (v0.6.0 Milestone F).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Captures the URL + headers of the last GET, and returns canned data.
private final class CapturingHTTPClient: HTTPClient, @unchecked Sendable {
    let data: Data
    private(set) var lastURL: URL?
    private(set) var lastHeaders: [String: String] = [:]
    init(data: Data) { self.data = data }
    func get(_ url: URL) async throws -> Data { lastURL = url; return data }
    func get(_ url: URL, headers: [String: String]) async throws -> Data {
        lastURL = url; lastHeaders = headers; return data
    }
}

@Suite("JSearchJobSource")
struct JSearchJobSourceTests {

    private let creds = JSearchJobSource.Credentials(apiKey: "KEY123")

    // MARK: URL building

    @Test func buildsQueryFromKeywordsAndLocation() throws {
        let query = JobQuery(keywords: "iOS Engineer", location: "Denver", page: 2)
        let url = try JSearchJobSource.buildURL(query: query)
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(comps.path == "/search")
        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(items["query"] == "iOS Engineer in Denver")
        #expect(items["page"] == "2")
        #expect(items["num_pages"] == "1")
    }

    @Test func mapsPositionTypeToEmploymentFilter() throws {
        let query = JobQuery(keywords: "x", positionType: .contract)
        let url = try JSearchJobSource.buildURL(query: query)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems ?? []
        #expect(items.contains { $0.name == "employment_types" && $0.value == "CONTRACTOR" })
    }

    // MARK: Headers

    @Test func sendsRapidAPIHeaders() async throws {
        let http = CapturingHTTPClient(data: Data(#"{"data":[]}"#.utf8))
        let source = JSearchJobSource(credentials: creds, http: http)
        _ = try await source.search(JobQuery(keywords: "ios"))
        #expect(http.lastHeaders["X-RapidAPI-Key"] == "KEY123")
        #expect(http.lastHeaders["X-RapidAPI-Host"] == "jsearch.p.rapidapi.com")
    }

    // MARK: Response mapping

    @Test func mapsAFixtureResponseIntoAnEnrichedListing() async throws {
        let json = """
        {"status":"OK","data":[{
          "job_id":"JS-1",
          "job_title":"Senior iOS Engineer",
          "employer_name":"Frontsteps",
          "job_city":"Denver","job_state":"Colorado","job_country":"US",
          "job_description":"The full posting body, sections and all.",
          "job_apply_link":"https://example.com/apply/1",
          "job_employment_type":"FULLTIME",
          "job_is_remote":true,
          "job_min_salary":115000,"job_max_salary":145000,"job_salary_currency":"USD",
          "job_posted_at_timestamp":1700000000,
          "job_highlights":{
            "Qualifications":["5 years Swift","CS degree"],
            "Responsibilities":["Ship features"],
            "Benefits":["401k match"]
          }
        }]}
        """
        let source = JSearchJobSource(credentials: creds, http: CapturingHTTPClient(data: Data(json.utf8)))
        let listings = try await source.search(JobQuery(keywords: "ios"))
        #expect(listings.count == 1)
        let job = try #require(listings.first)

        #expect(job.id == "JS-1")
        #expect(job.title == "Senior iOS Engineer")
        #expect(job.company == "Frontsteps")
        #expect(job.location == "Denver, Colorado, US")
        #expect(job.description == "The full posting body, sections and all.")
        #expect(job.url == URL(string: "https://example.com/apply/1"))
        #expect(job.salary?.min == 115000)
        #expect(job.salary?.max == 145000)
        #expect(job.salary?.currency == "USD")
        #expect(job.positionTypes == [.fullTime])
        #expect(job.postedDate == Date(timeIntervalSince1970: 1700000000))
        #expect(job.source == "JSearch")
        // Structured highlights map onto the enriched PostingDetails (Milestone A).
        #expect(job.details?.workType == .remote)
        #expect(job.details?.qualifications == ["5 years Swift", "CS degree"])
        #expect(job.details?.responsibilities == ["Ship features"])
        #expect(job.details?.benefits == ["401k match"])
    }

    @Test func emptyDataReturnsEmpty() async throws {
        let source = JSearchJobSource(credentials: creds, http: CapturingHTTPClient(data: Data(#"{"data":[]}"#.utf8)))
        #expect(try await source.search(JobQuery(keywords: "ios")).isEmpty)
    }

    @Test func listingWithNoHighlightsHasNoDetails() async throws {
        let json = #"{"data":[{"job_id":"x","job_title":"t","employer_name":"c","job_description":"d"}]}"#
        let source = JSearchJobSource(credentials: creds, http: CapturingHTTPClient(data: Data(json.utf8)))
        let job = try #require(try await source.search(JobQuery(keywords: "ios")).first)
        #expect(job.details == nil)   // nothing structured → no empty PostingDetails attached
    }
}
