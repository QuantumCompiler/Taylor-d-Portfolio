//
//  ResultsViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("ResultsViewModel")
struct ResultsViewModelTests {

    private func ranked(_ id: String) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t", company: "c", location: "l", description: "d"),
            match: JobMatch(jobId: id, score: 50, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    @Test func emptyByDefault() {
        #expect(ResultsViewModel().isEmpty)
    }

    @Test func selectSetsSelectedJob() {
        let job = ranked("a")
        let vm = ResultsViewModel(results: [job])
        #expect(vm.isEmpty == false)
        vm.select(job)
        #expect(vm.selectedJob?.id == "a")
    }
}
