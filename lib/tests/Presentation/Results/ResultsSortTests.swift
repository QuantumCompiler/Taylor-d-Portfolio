//
//  ResultsSortTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results — the pure ResultsSort value (v0.6.2 Milestone C).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("ResultsSort")
struct ResultsSortTests {

    /// A ranked job with a given id, title, company, score, salary and posted date.
    private func ranked(_ id: String, title: String = "Engineer", company: String = "Co",
                        score: Int = 50, salary: SalaryRange? = nil, posted: Date? = nil) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: title, company: company, location: "l",
                                description: "d", salary: salary, postedDate: posted),
            match: JobMatch(jobId: id, score: score, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    private func date(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }

    // MARK: Default

    /// The default must reproduce the ranker's own order, so a user who never touches the
    /// control sees exactly the list they saw before this milestone.
    @Test func defaultSortsBestMatchFirst() {
        let jobs = [ranked("mid", score: 50), ranked("top", score: 90), ranked("low", score: 10)]
        #expect(ResultsSort.default.apply(to: jobs).map(\.id) == ["top", "mid", "low"])
        #expect(ResultsSort.default.isDefault)
        #expect(ResultsSort(key: .company, direction: .descending).isDefault == false)
    }

    // MARK: Keys + direction

    @Test func sortsByMatchScoreBothWays() {
        let jobs = [ranked("mid", score: 50), ranked("top", score: 90), ranked("low", score: 10)]
        var sort = ResultsSort(key: .matchScore, direction: .ascending)
        #expect(sort.apply(to: jobs).map(\.id) == ["low", "mid", "top"])
        sort.direction = .descending
        #expect(sort.apply(to: jobs).map(\.id) == ["top", "mid", "low"])
    }

    @Test func sortsByCompanyCaseInsensitively() {
        let jobs = [ranked("b", company: "beta"), ranked("A", company: "Alpha"), ranked("c", company: "Gamma")]
        let sort = ResultsSort(key: .company, direction: .ascending)
        #expect(sort.apply(to: jobs).map(\.id) == ["A", "b", "c"])   // "beta" after "Alpha" despite case
    }

    @Test func sortsByRoleTitle() {
        let jobs = [ranked("z", title: "Zoologist"), ranked("a", title: "Analyst")]
        #expect(ResultsSort(key: .title, direction: .ascending).apply(to: jobs).map(\.id) == ["a", "z"])
        #expect(ResultsSort(key: .title, direction: .descending).apply(to: jobs).map(\.id) == ["z", "a"])
    }

    @Test func sortsBySalaryUsingTheTopOfTheRange() {
        let jobs = [
            ranked("narrow", salary: SalaryRange(min: 100, max: 120)),
            ranked("high", salary: SalaryRange(min: 90, max: 200)),   // lower floor, higher top
        ]
        #expect(ResultsSort(key: .salary, direction: .descending).apply(to: jobs).map(\.id) == ["high", "narrow"])
    }

    /// A range with only a floor still ranks — on that floor.
    @Test func salaryFallsBackToTheFloorWhenThereIsNoTop() {
        let jobs = [ranked("floorOnly", salary: SalaryRange(min: 150, max: nil)),
                    ranked("capped", salary: SalaryRange(min: 10, max: 120))]
        #expect(ResultsSort(key: .salary, direction: .descending).apply(to: jobs).map(\.id) == ["floorOnly", "capped"])
    }

    @Test func sortsByPostedDate() {
        let jobs = [ranked("old", posted: date(100)), ranked("new", posted: date(900))]
        #expect(ResultsSort(key: .postedDate, direction: .descending).apply(to: jobs).map(\.id) == ["new", "old"])
        #expect(ResultsSort(key: .postedDate, direction: .ascending).apply(to: jobs).map(\.id) == ["old", "new"])
    }

    // MARK: Unknown values

    /// Listings missing the sorted facet go **last in both directions** — the same rule
    /// `TrackerSort` applies to undated jobs, so "unknown" never reads as best or worst.
    @Test func unknownSalaryAndDateAlwaysSortLast() {
        let salaries = [
            ranked("none", title: "Aardvark"),                          // no salary at all
            ranked("low", salary: SalaryRange(min: 10, max: 20)),
            ranked("high", salary: SalaryRange(min: 90, max: 200)),
        ]
        #expect(ResultsSort(key: .salary, direction: .descending).apply(to: salaries).map(\.id) == ["high", "low", "none"])
        #expect(ResultsSort(key: .salary, direction: .ascending).apply(to: salaries).map(\.id) == ["low", "high", "none"])

        let dates = [ranked("none", title: "Aardvark"), ranked("old", posted: date(100)), ranked("new", posted: date(900))]
        #expect(ResultsSort(key: .postedDate, direction: .descending).apply(to: dates).map(\.id) == ["new", "old", "none"])
        #expect(ResultsSort(key: .postedDate, direction: .ascending).apply(to: dates).map(\.id) == ["old", "new", "none"])
    }

    // MARK: Stability

    /// Equal keys fall back to role title, so an ordering never shuffles between renders.
    @Test func tiesBreakOnTitleAscendingInBothDirections() {
        let jobs = [ranked("z", title: "Zebra", score: 70), ranked("a", title: "Ant", score: 70),
                    ranked("m", title: "Moose", score: 70)]
        #expect(ResultsSort(key: .matchScore, direction: .descending).apply(to: jobs).map(\.id) == ["a", "m", "z"])
        #expect(ResultsSort(key: .matchScore, direction: .ascending).apply(to: jobs).map(\.id) == ["a", "m", "z"])
    }

    @Test func emptyAndSingleInputAreHandled() {
        #expect(ResultsSort.default.apply(to: []).isEmpty)
        #expect(ResultsSort.default.apply(to: [ranked("a")]).map(\.id) == ["a"])
    }

    /// Every key is offered to the picker and labelled.
    @Test func everyKeyHasADisplayName() {
        #expect(ResultsSort.Key.allCases.count == 5)
        for key in ResultsSort.Key.allCases {
            #expect(key.displayName.isEmpty == false)
            #expect(key.id == key.rawValue)
        }
    }
}
