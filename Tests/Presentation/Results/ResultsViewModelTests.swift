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

    @Test func loadsSavedJobsWhenEmpty() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("saved-1")])
        let vm = ResultsViewModel(loadSavedJobs: LoadSavedJobsUseCase(repository: repo))

        #expect(vm.isEmpty)
        await vm.loadSavedIfNeeded()
        #expect(vm.results.map(\.id) == ["saved-1"])
    }

    @Test func loadDoesNotClobberExistingResults() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("saved-1")])
        // A search already populated results — loading saved must not overwrite them.
        let vm = ResultsViewModel(results: [ranked("fresh")], loadSavedJobs: LoadSavedJobsUseCase(repository: repo))

        await vm.loadSavedIfNeeded()
        #expect(vm.results.map(\.id) == ["fresh"])
    }
}
