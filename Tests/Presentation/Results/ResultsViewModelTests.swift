//
//  ResultsViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results
//

import Testing
import Foundation
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

    /// A VM wired to real in-memory persistence for the row-action tests, over one store.
    private func makeRowActionVM(results: [RankedJob]) -> (ResultsViewModel, SavedJobsRepository, SavedStatusRepository, SavedApplicationsRepository) {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        let vm = ResultsViewModel(
            results: results,
            loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses),
            markStatus: MarkStatusUseCase(repository: statuses, now: { Date(timeIntervalSince1970: 0) }),
            saveResults: SaveResultsUseCase(repository: jobs),
            deleteSavedJob: DeleteSavedJobUseCase(jobs: jobs, statuses: statuses, applications: apps)
        )
        return (vm, jobs, statuses, apps)
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

    // MARK: Row actions (Milestone V)

    @Test func saveToTrackerMarksSavedPersistsAndBadges() async throws {
        let (vm, jobs, statuses, _) = makeRowActionVM(results: [ranked("a")])
        #expect(vm.supportsRowActions)

        await vm.saveToTracker(ranked("a"))
        #expect(vm.isTracked(ranked("a")))
        #expect(vm.status(for: ranked("a"))?.stage == .saved)     // badge reflects .saved
        #expect(try await jobs.contains(jobID: "a"))              // listing persisted for the join
        #expect(try await statuses.status(forJobID: "a")?.stage == .saved)
    }

    @Test func saveToTrackerDoesNotDowngradeALaterStage() async throws {
        let (vm, jobs, statuses, _) = makeRowActionVM(results: [ranked("a")])
        try await jobs.save([ranked("a")])                                         // already a saved/tracked job…
        try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")  // …further along than .saved
        await vm.refreshStatuses()
        #expect(vm.isTracked(ranked("a")))

        await vm.saveToTracker(ranked("a"))
        #expect(vm.status(for: ranked("a"))?.stage == .applied)   // not knocked back to .saved
    }

    @Test func deleteRemovesFromListAndForgetsEverything() async throws {
        let (vm, jobs, statuses, apps) = makeRowActionVM(results: [ranked("a"), ranked("b")])
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")
        try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "", gapNote: ""), forJobID: "a")

        await vm.delete(ranked("a"))
        #expect(vm.results.map(\.id) == ["b"])                    // gone from the list
        #expect(try await jobs.contains(jobID: "a") == false)     // and from every store
        #expect(try await statuses.status(forJobID: "a") == nil)
        #expect(try await apps.kit(forJobID: "a") == nil)
    }

    @Test func rowActionsUnavailableWithoutWiring() {
        let vm = ResultsViewModel(results: [ranked("a")])
        #expect(vm.supportsRowActions == false)
    }

    // MARK: Filtering (Milestone W)

    private func ranked(_ id: String, score: Int, company: String = "Acme", location: String = "Remote") -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t", company: company, location: location, description: "d"),
            match: JobMatch(jobId: id, score: score, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    @Test func filteredResultsCountsAndClear() {
        let vm = ResultsViewModel(results: [ranked("a", score: 80), ranked("b", score: 40), ranked("c", score: 60)])
        #expect(vm.filteredResults.count == 3)          // no filter ⇒ identity
        #expect(vm.totalCount == 3)

        vm.filter.minScore = 60
        #expect(vm.filteredResults.map(\.id) == ["a", "c"])
        #expect(vm.visibleCount == 2)
        #expect(vm.totalCount == 3)                     // total is unfiltered
        #expect(vm.isFilteredEmpty == false)

        vm.clearFilter()
        #expect(vm.filteredResults.count == 3)
        #expect(vm.filter.isActive == false)
    }

    @Test func isFilteredEmptyWhenFilterHidesEverything() {
        let vm = ResultsViewModel(results: [ranked("a", score: 40)])
        vm.filter.minScore = 90
        #expect(vm.filteredResults.isEmpty)
        #expect(vm.isFilteredEmpty)                     // distinct from "no results yet"
    }

    @Test func filterOptionsAreDistinctValuesFromResults() {
        let vm = ResultsViewModel(results: [
            ranked("a", score: 80, company: "Acme", location: "Remote"),
            ranked("b", score: 40, company: "Globex", location: "Lehi, UT"),
            ranked("c", score: 60, company: "Acme", location: "Remote"),
        ])
        #expect(vm.companyOptions == ["Acme", "Globex"])
        #expect(vm.locationOptions == ["Lehi, UT", "Remote"])
    }

    @Test func trackedFacetUsesTheStatusMap() async throws {
        let (vm, jobs, statuses, _) = makeRowActionVM(results: [ranked("a"), ranked("b")])
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .saved), forJobID: "a")
        await vm.refreshStatuses()

        vm.filter.trackedStatus = .tracked
        #expect(vm.filteredResults.map(\.id) == ["a"])
        vm.filter.trackedStatus = .untracked
        #expect(vm.filteredResults.map(\.id) == ["b"])
    }
}
