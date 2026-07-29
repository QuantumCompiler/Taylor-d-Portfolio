//
//  AdzunaJobSourceTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Jobs — URL building and JSON → JobListing mapping.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Returns canned bytes for any URL.
private struct StubHTTPClient: HTTPClient {
    let data: Data
    func get(_ url: URL) async throws -> Data { data }
}

/// Always throws the given error.
private struct FailingHTTPClient: HTTPClient {
    let error: Error
    func get(_ url: URL) async throws -> Data { throw error }
}

@Suite("AdzunaJobSource")
struct AdzunaJobSourceTests {

    private let creds = AdzunaJobSource.Credentials(appID: "ID", appKey: "KEY", country: "us")

    // MARK: buildURL

    @Test func buildURLHasHostPathAndAllQueryItems() throws {
        let query = JobQuery(keywords: "swift developer", location: "Remote",
                             salaryMin: 100_000, page: 2, resultsPerPage: 10)
        let url = try AdzunaJobSource.buildURL(credentials: creds, query: query)

        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(comps.host == "api.adzuna.com")
        #expect(comps.path == "/v1/api/jobs/us/search/2")

        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(items["app_id"] == "ID")
        #expect(items["app_key"] == "KEY")
        #expect(items["what"] == "swift developer")
        #expect(items["where"] == "Remote")
        #expect(items["salary_min"] == "100000")
        #expect(items["results_per_page"] == "10")
    }

    @Test func buildURLOmitsOptionalItemsWhenAbsent() throws {
        let query = JobQuery(keywords: "ios") // no location, no salaryMin, no positionType
        let url = try AdzunaJobSource.buildURL(credentials: creds, query: query, baseURL: AdzunaJobSource.defaultBaseURL)

        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let names = Set((comps.queryItems ?? []).map(\.name))
        #expect(!names.contains("where"))
        #expect(!names.contains("salary_min"))
        #expect(!names.contains("full_time"))
        #expect(!names.contains("contract"))
        #expect(comps.path == "/v1/api/jobs/us/search/1") // default page 1
    }

    @Test func buildURLMapsPositionTypeToTheContractFlag() throws {
        let cases: [(PositionType, String)] = [
            (.fullTime, "full_time"), (.partTime, "part_time"), (.contract, "contract"), (.permanent, "permanent"),
        ]
        for (type, flag) in cases {
            let url = try AdzunaJobSource.buildURL(credentials: creds, query: JobQuery(keywords: "ios", positionType: type))
            let items = Dictionary(uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems ?? []).map { ($0.name, $0.value) })
            #expect(items[flag] == "1")
        }
    }

    @Test func requestPropagatesPositionTypeAndPagingIntoTheQuery() {
        let request = JobSearchRequest(titles: ["iOS"], location: "Remote", salaryMin: 90_000, positionType: .contract)
        let query = request.query(forTitle: "iOS", page: 3, resultsPerPage: 50)
        #expect(query.positionType == .contract)
        #expect(query.page == 3)
        #expect(query.resultsPerPage == 50)
        #expect(query.location == "Remote")
        #expect(query.salaryMin == 90_000)
    }

    // MARK: search / mapping

    @Test func searchMapsResultsToListings() async throws {
        let json = """
        {"results":[
          {"id":"111","title":"iOS Engineer","company":{"display_name":"Acme"},
           "location":{"display_name":"Remote"},"description":"Build apps.",
           "redirect_url":"https://adzuna.example/job/111","salary_min":120000,"salary_max":160000},
          {"id":"222","title":"Backend Dev","description":"APIs."}
        ]}
        """
        let source = AdzunaJobSource(credentials: creds, http: StubHTTPClient(data: Data(json.utf8)))
        let listings = try await source.search(JobQuery(keywords: "dev"))

        #expect(listings.count == 2)

        let first = listings[0]
        #expect(first.id == "111")
        #expect(first.company == "Acme")
        #expect(first.location == "Remote")
        #expect(first.url == URL(string: "https://adzuna.example/job/111"))
        #expect(first.salary == SalaryRange(min: 120_000, max: 160_000, currency: nil))

        // Second listing is missing company/location/url/salary — mapped to sensible defaults.
        let second = listings[1]
        #expect(second.company == "")
        #expect(second.location == "")
        #expect(second.url == nil)
        #expect(second.salary == nil)
    }

    @Test func searchDecodesRicherPostingFields() async throws {
        // v0.6.0 Milestone A-A: contract_type / contract_time / category / created are now mapped.
        let json = """
        {"results":[
          {"id":"111","title":"iOS Engineer","company":{"display_name":"Acme"},
           "location":{"display_name":"Remote"},"description":"Build apps.",
           "contract_type":"permanent","contract_time":"full_time",
           "category":{"label":"IT Jobs","tag":"it-jobs"},"created":"2024-01-15T09:00:00Z"},
          {"id":"222","title":"Backend Dev","description":"APIs.","contract_time":"part_time"}
        ]}
        """
        let source = AdzunaJobSource(credentials: creds, http: StubHTTPClient(data: Data(json.utf8)))
        let listings = try await source.search(JobQuery(keywords: "dev"))

        let first = listings[0]
        #expect(first.positionTypes == [.permanent, .fullTime])
        #expect(first.category == "IT Jobs")
        #expect(first.postedDate == ISO8601DateFormatter().date(from: "2024-01-15T09:00:00Z"))

        // Only one of the two contract fields present, and no category/created → partial map.
        let second = listings[1]
        #expect(second.positionTypes == [.partTime])
        #expect(second.category == nil)
        #expect(second.postedDate == nil)
    }

    @Test func searchLeavesRicherFieldsEmptyWhenAbsent() async throws {
        // A posting with none of the richer fields maps to empty/nil defaults (back-compat).
        let json = #"{"results":[{"id":"1","title":"Dev","description":"x"}]}"#
        let source = AdzunaJobSource(credentials: creds, http: StubHTTPClient(data: Data(json.utf8)))
        let listing = try await source.search(JobQuery(keywords: "dev"))[0]
        #expect(listing.positionTypes.isEmpty)
        #expect(listing.postedDate == nil)
        #expect(listing.category == nil)
    }

    @Test func searchPropagatesHTTPErrors() async {
        let source = AdzunaJobSource(
            credentials: creds,
            http: FailingHTTPClient(error: HTTPError.status(code: 401, body: Data()))
        )
        await #expect(throws: HTTPError.self) {
            _ = try await source.search(JobQuery(keywords: "dev"))
        }
    }
}
