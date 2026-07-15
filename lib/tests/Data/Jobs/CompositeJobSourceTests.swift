//
//  CompositeJobSourceTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Jobs — fan-out, cross-source dedup, and soft partial failure (v0.6.0 F).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

private struct StubSource: JobSource {
    var listings: [JobListing] = []
    var error: Error?
    func search(_ query: JobQuery) async throws -> [JobListing] {
        if let error { throw error }
        return listings
    }
}

private struct Boom: Error {}

private func listing(id: String, title: String = "iOS Engineer", company: String = "Acme",
                     location: String = "Denver, CO", source: String? = nil) -> JobListing {
    JobListing(id: id, title: title, company: company, location: location, description: "d", source: source)
}

@Suite("CompositeJobSource")
struct CompositeJobSourceTests {

    private let query = JobQuery(keywords: "ios")

    @Test func mergesDistinctListingsFromAllSources() async throws {
        let a = StubSource(listings: [listing(id: "a1", title: "iOS"), listing(id: "a2", title: "Backend")])
        let b = StubSource(listings: [listing(id: "b1", title: "Frontend")])
        let composite = CompositeJobSource(sources: [a, b])

        let merged = try await composite.search(query)
        #expect(merged.count == 3)
        #expect(Set(merged.map(\.id)) == ["a1", "a2", "b1"])
    }

    @Test func dedupsSamePostingAcrossSourcesByFingerprint() async throws {
        // Same title/company/location from two providers → different ids, one fingerprint.
        let adzuna = StubSource(listings: [listing(id: "adz-1", source: "Adzuna")])
        let jsearch = StubSource(listings: [listing(id: "js-1", source: "JSearch")])
        let composite = CompositeJobSource(sources: [adzuna, jsearch])

        let merged = try await composite.search(query)
        #expect(merged.count == 1)
        #expect(merged.first?.source == "Adzuna")   // first source in the list wins the tie
        #expect(merged.first?.id == "adz-1")         // its own id kept (for persistence)
    }

    @Test func keepsDistinctPostingsThatDifferInAnyField() async throws {
        let a = StubSource(listings: [listing(id: "a1", company: "Acme")])
        let b = StubSource(listings: [listing(id: "b1", company: "Globex")])   // different company
        let composite = CompositeJobSource(sources: [a, b])

        #expect(try await composite.search(query).count == 2)
    }

    @Test func fingerprintIgnoresCaseAndWhitespace() async throws {
        let a = StubSource(listings: [listing(id: "a", title: "iOS  Engineer", company: "ACME")])
        let b = StubSource(listings: [listing(id: "b", title: "ios engineer", company: "acme")])
        let composite = CompositeJobSource(sources: [a, b])
        #expect(try await composite.search(query).count == 1)   // same posting, normalized
    }

    @Test func partialFailureIsSoftAndReturnsTheSuccesses() async throws {
        let ok = StubSource(listings: [listing(id: "ok")])
        let bad = StubSource(error: Boom())
        let composite = CompositeJobSource(sources: [ok, bad])

        let merged = try await composite.search(query)
        #expect(merged.map(\.id) == ["ok"])
    }

    @Test func throwsOnlyWhenEverySourceFails() async {
        let composite = CompositeJobSource(sources: [StubSource(error: Boom()), StubSource(error: Boom())])
        await #expect(throws: (any Error).self) { try await composite.search(query) }
    }

    @Test func emptySourcesReturnsEmpty() async throws {
        let composite = CompositeJobSource(sources: [])
        #expect(try await composite.search(query).isEmpty)
    }
}
