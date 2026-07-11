//
//  ResultsFilterTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results — the pure results view-filter (Milestone W).
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("ResultsFilter")
struct ResultsFilterTests {

    private func job(_ id: String, score: Int, title: String = "iOS Engineer", company: String = "Acme",
                     location: String = "Remote", description: String = "Swift work",
                     matched: [String] = [], salaryMax: Double? = nil) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: title, company: company, location: location,
                                description: description,
                                salary: salaryMax.map { SalaryRange(min: nil, max: $0, currency: nil) }),
            match: JobMatch(jobId: id, score: score, reason: "", matchedSkills: matched, missingSkills: [])
        )
    }

    private var jobs: [RankedJob] {
        [
            job("a", score: 80, title: "iOS Engineer", company: "Acme", location: "Remote", matched: ["Swift"]),
            job("b", score: 40, title: "Backend Engineer", company: "Globex", location: "Lehi, UT", salaryMax: 120_000),
            job("c", score: 60, title: "iOS Developer", company: "Acme", location: "Remote", description: "Kotlin"),
        ]
    }

    @Test func emptyFilterIsIdentity() {
        let filter = ResultsFilter()
        #expect(filter.isActive == false)
        #expect(filter.apply(to: jobs).map(\.id) == ["a", "b", "c"])
    }

    @Test func minScoreKeepsOnlyQualifying() {
        var filter = ResultsFilter(); filter.minScore = 60
        #expect(filter.apply(to: jobs).map(\.id) == ["a", "c"])   // 80 + 60, not 40
    }

    @Test func keywordSearchesTitleCompanyDescriptionAndMatchedSkills() {
        var kotlin = ResultsFilter(); kotlin.keywords = "kotlin"      // only in c's description
        #expect(kotlin.apply(to: jobs).map(\.id) == ["c"])
        var swift = ResultsFilter(); swift.keywords = "swift"          // a's matched skill / description
        #expect(swift.apply(to: jobs).map(\.id).contains("a"))
        var globex = ResultsFilter(); globex.keywords = "GLOBEX"       // company, case-insensitive
        #expect(globex.apply(to: jobs).map(\.id) == ["b"])
    }

    @Test func locationAndCompanyAreExactCaseInsensitive() {
        var loc = ResultsFilter(); loc.location = "remote"
        #expect(loc.apply(to: jobs).map(\.id) == ["a", "c"])
        var co = ResultsFilter(); co.company = "Acme"
        #expect(co.apply(to: jobs).map(\.id) == ["a", "c"])
    }

    @Test func salaryFloorExcludesUnknownAndBelow() {
        var filter = ResultsFilter(); filter.salaryMin = 100_000
        #expect(filter.apply(to: jobs).map(\.id) == ["b"])   // only b has a (qualifying) salary
    }

    @Test func trackedFacetUsesTheSuppliedClosure() {
        var tracked = ResultsFilter(); tracked.trackedStatus = .tracked
        let isTracked: (RankedJob) -> Bool = { $0.id == "a" }
        #expect(tracked.apply(to: jobs, isTracked: isTracked).map(\.id) == ["a"])
        var untracked = ResultsFilter(); untracked.trackedStatus = .untracked
        #expect(untracked.apply(to: jobs, isTracked: isTracked).map(\.id) == ["b", "c"])
    }

    @Test func facetsComposeWithAnd() {
        var filter = ResultsFilter()
        filter.company = "Acme"; filter.minScore = 70   // Acme AND ≥70 → only a
        #expect(filter.apply(to: jobs).map(\.id) == ["a"])
    }
}
