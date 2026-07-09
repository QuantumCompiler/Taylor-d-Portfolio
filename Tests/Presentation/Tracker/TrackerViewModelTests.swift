//
//  TrackerViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Tracker
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@MainActor
@Suite("TrackerViewModel")
struct TrackerViewModelTests {

    private func ranked(_ id: String) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t-\(id)", company: "c", location: "l", description: "d"),
            match: JobMatch(jobId: id, score: 50, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    /// Builds a VM over an in-memory store seeded with saved jobs + statuses.
    private func makeVM(seed: (SavedJobsRepository, SavedStatusRepository) async throws -> Void) async throws -> TrackerViewModel {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        try await seed(jobs, statuses)
        return TrackerViewModel(loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses))
    }

    @Test func emptyWhenNothingTracked() async throws {
        let vm = try await makeVM { jobs, _ in try await jobs.save([self.ranked("a")]) }
        await vm.load()
        #expect(vm.isEmpty)
    }

    @Test func listsTrackedJobsMostRecentFirst() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a"), self.ranked("b")])
            try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: "a")
            try await statuses.save(ApplicationStatus(stage: .offer, offerDate: Date(timeIntervalSince1970: 900)), forJobID: "b")
        }
        await vm.load()
        #expect(vm.trackedJobs.map(\.id) == ["b", "a"])   // b's date is later → first
        #expect(vm.isEmpty == false)
    }

    @Test func selectSetsSelectedJob() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a")])
            try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")
        }
        await vm.load()
        vm.select(ranked("a"))
        #expect(vm.selectedJob?.id == "a")
    }
}
