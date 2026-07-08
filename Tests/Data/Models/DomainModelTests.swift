//
//  DomainModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Models — Codable round-trips + RankedJob derivation.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Encodes then decodes a value so tests can assert the round-trip preserves everything.
private func roundTrip<T: Codable>(_ value: T) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}

@Suite("Domain models")
struct DomainModelTests {

    @Test func candidateProfileRoundTrips() throws {
        let profile = CandidateProfile(
            seniority: "Senior",
            yearsExperience: 8,
            coreSkills: ["Swift", "SwiftUI", "Concurrency"],
            domains: ["Fintech", "Developer tools"],
            targetTitles: ["Senior iOS Engineer", "Staff Engineer"],
            summary: "Eight years building native Apple apps."
        )
        let decoded = try roundTrip(profile)
        #expect(decoded == profile)
    }

    @Test func jobListingRoundTripsWithSalaryAndURL() throws {
        let listing = JobListing(
            id: "adzuna-123",
            title: "iOS Engineer",
            company: "Acme",
            location: "Remote",
            description: "Build delightful apps.",
            url: URL(string: "https://example.com/jobs/123"),
            salary: SalaryRange(min: 120_000, max: 160_000, currency: "USD")
        )
        let decoded = try roundTrip(listing)
        #expect(decoded == listing)
    }

    @Test func jobListingRoundTripsWithoutOptionals() throws {
        let listing = JobListing(
            id: "x",
            title: "Engineer",
            company: "Beta",
            location: "NYC",
            description: "A role."
        )
        #expect(listing.url == nil)
        #expect(listing.salary == nil)
        let decoded = try roundTrip(listing)
        #expect(decoded == listing)
    }

    @Test func jobQueryAppliesDefaultsAndRoundTrips() throws {
        let query = JobQuery(keywords: "swift developer")
        #expect(query.page == 1)
        #expect(query.resultsPerPage == 25)
        #expect(query.location == nil)
        let decoded = try roundTrip(query)
        #expect(decoded == query)
    }

    @Test func jobMatchRoundTrips() throws {
        let match = JobMatch(
            jobId: "adzuna-123",
            score: 87,
            reason: "Strong Swift and SwiftUI overlap.",
            matchedSkills: ["Swift", "SwiftUI"],
            missingSkills: ["Kotlin"]
        )
        let decoded = try roundTrip(match)
        #expect(decoded == match)
    }

    @Test func applicationKitRoundTrips() throws {
        let kit = ApplicationKit(
            resumeMarkdown: "# Jane Doe\nSenior iOS Engineer",
            coverLetter: "Dear hiring manager, …",
            gapNote: "No direct Kotlin experience."
        )
        let decoded = try roundTrip(kit)
        #expect(decoded == kit)
    }

    @Test func rankedJobDerivesIdentityAndScoreAndRoundTrips() throws {
        let listing = JobListing(
            id: "adzuna-123", title: "iOS Engineer", company: "Acme",
            location: "Remote", description: "A role."
        )
        let match = JobMatch(
            jobId: "adzuna-123", score: 87, reason: "Good fit.",
            matchedSkills: ["Swift"], missingSkills: []
        )
        let ranked = RankedJob(listing: listing, match: match)
        #expect(ranked.id == listing.id)   // identity derived from the listing
        #expect(ranked.score == match.score) // score derived from the match
        let decoded = try roundTrip(ranked)
        #expect(decoded == ranked)
    }
}
