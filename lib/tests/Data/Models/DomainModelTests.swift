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

    @Test func jobListingRoundTripsWithRicherPostingFields() throws {
        // v0.6.0 Milestone A-A — positionTypes / postedDate / category survive a round-trip.
        let listing = JobListing(
            id: "adzuna-123",
            title: "iOS Engineer",
            company: "Acme",
            location: "Remote",
            description: "Build apps.",
            positionTypes: [.permanent, .fullTime],
            postedDate: Date(timeIntervalSince1970: 1_705_309_200),
            category: "IT Jobs"
        )
        let decoded = try roundTrip(listing)
        #expect(decoded == listing)
    }

    @Test func jobListingDecodesLegacyBlobWithoutRicherFields() throws {
        // A listing persisted before Milestone A-A lacks the new keys; it must still decode,
        // with the richer fields defaulting to empty/nil (SavedJobsRepository drops undecodable
        // rows, so a throw here would silently lose legacy saved jobs).
        let legacy = #"{"id":"old-1","title":"Engineer","company":"Beta","location":"NYC","description":"A role."}"#
        let decoded = try JSONDecoder().decode(JobListing.self, from: Data(legacy.utf8))
        #expect(decoded.id == "old-1")
        #expect(decoded.positionTypes.isEmpty)
        #expect(decoded.postedDate == nil)
        #expect(decoded.category == nil)
    }

    @Test func postingDetailsRoundTripsAndMapsWorkType() throws {
        // v0.6.0 Milestone A-B — the @Generable enrichment type round-trips and parses its work type.
        let details = PostingDetails(
            workTypeRaw: "hybrid",
            qualifications: ["5+ years Swift"],
            responsibilities: ["Ship features"],
            niceToHaves: ["Kotlin"],
            aboutRole: "Build the app.",
            aboutCompany: "We do fintech.",
            benefits: ["Health"]
        )
        #expect(details.workType == .hybrid)
        #expect(details.hasContent)
        let decoded = try roundTrip(details)
        #expect(decoded == details)
    }

    @Test func emptyPostingDetailsHasNoContent() {
        // An enrichment that found nothing must report no content, so callers keep the snippet.
        let empty = PostingDetails()
        #expect(empty.workType == nil)
        #expect(!empty.hasContent)
    }

    @Test func workTypeParsesLooseModelStrings() {
        #expect(WorkType(loose: "On-Site") == .onSite)
        #expect(WorkType(loose: "in office") == .onSite)
        #expect(WorkType(loose: "Remote") == .remote)
        #expect(WorkType(loose: "fully remote") == .remote)
        #expect(WorkType(loose: "hybrid") == .hybrid)
        #expect(WorkType(loose: "") == nil)
        #expect(WorkType(loose: "whenever") == nil)
    }

    @Test func jobListingCarriesEnrichedDetailsThroughRoundTrip() throws {
        let listing = JobListing(
            id: "j1", title: "iOS", company: "Acme", location: "Remote", description: "d",
            details: PostingDetails(workTypeRaw: "remote", aboutCompany: "Fintech.")
        )
        let decoded = try roundTrip(listing)
        #expect(decoded == listing)
        #expect(decoded.details?.workType == .remote)
    }

    @Test func jobListingCarriesFullDescriptionThroughRoundTrip() throws {
        // v0.6.0 Milestone E — the recovered full posting text survives a round-trip.
        let listing = JobListing(
            id: "j2", title: "iOS", company: "Acme", location: "Remote", description: "short snippet…",
            fullDescription: "The entire posting body, sections and all."
        )
        let decoded = try roundTrip(listing)
        #expect(decoded == listing)
        #expect(decoded.fullDescription == "The entire posting body, sections and all.")
    }

    @Test func jobListingLegacyBlobDecodesWithoutFullDescription() throws {
        // A listing persisted before Milestone E lacks the key; it must decode with nil, and
        // effectiveDescription falls back to the snippet.
        let legacy = #"{"id":"old-2","title":"Eng","company":"Beta","location":"NYC","description":"snippet"}"#
        let decoded = try JSONDecoder().decode(JobListing.self, from: Data(legacy.utf8))
        #expect(decoded.fullDescription == nil)
        #expect(decoded.effectiveDescription == "snippet")
    }

    @Test func effectiveDescriptionPrefersFullText() {
        let snippetOnly = JobListing(id: "a", title: "t", company: "c", location: "l", description: "snippet")
        #expect(snippetOnly.effectiveDescription == "snippet")

        let withFull = JobListing(id: "b", title: "t", company: "c", location: "l",
                                  description: "snippet", fullDescription: "the full body")
        #expect(withFull.effectiveDescription == "the full body")
    }

    @Test func jobListingSourceRoundTripsAndDecodesLegacyAsNil() throws {
        // v0.6.0 Milestone F — the source label survives a round-trip; legacy blobs decode nil.
        let listing = JobListing(id: "j", title: "t", company: "c", location: "l", description: "d", source: "JSearch")
        #expect(try roundTrip(listing).source == "JSearch")

        let legacy = #"{"id":"o","title":"t","company":"c","location":"l","description":"d"}"#
        #expect(try JSONDecoder().decode(JobListing.self, from: Data(legacy.utf8)).source == nil)
    }

    @Test func jobListingFingerprintNormalizesAndIgnoresIDAndSource() {
        // Same posting from two sources: different id/source, same normalized fingerprint.
        let adzuna = JobListing(id: "adz-1", title: "iOS  Engineer", company: "ACME",
                                location: "Denver, CO", description: "d", source: "Adzuna")
        let jsearch = JobListing(id: "js-9", title: "ios engineer", company: "acme",
                                 location: "denver, co", description: "different", source: "JSearch")
        #expect(adzuna.fingerprint == jsearch.fingerprint)

        let other = JobListing(id: "x", title: "iOS Engineer", company: "Globex", location: "Denver, CO", description: "d")
        #expect(other.fingerprint != adzuna.fingerprint)   // different company → different posting
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

    @Test func extractedPostingRoundTripsAndMapsToListing() throws {
        let posting = ExtractedPosting(title: "iOS Engineer", company: "Acme", location: "Remote", description: "Swift + SwiftUI.")
        #expect(try roundTrip(posting) == posting)
        #expect(posting.looksReal)
        #expect(ExtractedPosting(title: "", company: "", location: "", description: "x").looksReal == false)

        let url = URL(string: "https://example.com/jobs/1")!
        let listing = posting.toListing(sourceURL: url)
        #expect(listing.id == url.absoluteString)
        #expect(listing.url == url)
        #expect(listing.title == "iOS Engineer")
    }

    @Test func applicationStatusRoundTrips() throws {
        let status = ApplicationStatus(
            stage: .interviewing,
            appliedDate: Date(timeIntervalSince1970: 1_700_000_000),
            interviewDate: Date(timeIntervalSince1970: 1_700_500_000),
            note: "Recruiter call went well."
        )
        #expect(try roundTrip(status) == status)
    }

    @Test func advancingStampsTheRightMilestoneAndAdvancesStage() {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let applied = ApplicationStatus().advanced(to: .applied, on: t0)
        #expect(applied.stage == .applied)
        #expect(applied.appliedDate == t0)
        #expect(applied.currentDate == t0)
        #expect(applied.interviewDate == nil)

        // Forward milestones stamp only the first time they're reached.
        let t1 = Date(timeIntervalSince1970: 2_000)
        let reApplied = applied.advanced(to: .applied, on: t1)
        #expect(reApplied.appliedDate == t0)   // original applied date preserved

        // Terminal outcome stamps closedDate (latest wins).
        let t2 = Date(timeIntervalSince1970: 3_000)
        let rejected = applied.advanced(to: .rejected, on: t2)
        #expect(rejected.stage == .rejected)
        #expect(rejected.closedDate == t2)
        #expect(rejected.currentDate == t2)
        #expect(rejected.appliedDate == t0)    // earlier milestones retained
    }

    @Test func settableStagesExcludeSaved() {
        #expect(ApplicationStage.settable.contains(.saved) == false)
        #expect(ApplicationStage.settable.contains(.applied))
        #expect(ApplicationStage.rejected.isClosed)
        #expect(ApplicationStage.applied.isClosed == false)
    }

    @Test func targetBriefRoundTrips() throws {
        let brief = TargetBrief(
            company: "Acme",
            roleTitle: "Senior iOS Engineer",
            mustHaveKeywords: ["Swift", "SwiftUI", "async/await"],
            niceToHaveKeywords: ["Kotlin"],
            techStack: ["Swift", "Combine"],
            domain: "Fintech",
            missionValues: "Make money management delightful."
        )
        let decoded = try roundTrip(brief)
        #expect(decoded == brief)
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
