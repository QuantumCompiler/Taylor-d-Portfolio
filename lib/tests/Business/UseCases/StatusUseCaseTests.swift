//
//  StatusUseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — mark/load status + tracked-jobs join.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("Status use cases")
struct StatusUseCaseTests {

    private func ranked(_ id: String) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t", company: "c", location: "l", description: "d"),
            match: JobMatch(jobId: id, score: 50, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    @Test func markStampsWithInjectedClockAndPersists() async throws {
        let repo = SavedStatusRepository(store: InMemoryRecordStore())
        let fixed = Date(timeIntervalSince1970: 12_345)
        let mark = MarkStatusUseCase(repository: repo, now: { fixed })

        let status = try await mark(jobID: "a", stage: .applied)
        #expect(status.stage == .applied)
        #expect(status.appliedDate == fixed)
        // Persisted with the same stamp.
        #expect(try await repo.status(forJobID: "a")?.appliedDate == fixed)
    }

    @Test func markAdvancesExistingStatusKeepingEarlierStamps() async throws {
        let repo = SavedStatusRepository(store: InMemoryRecordStore())
        let t0 = Date(timeIntervalSince1970: 1_000)
        let t1 = Date(timeIntervalSince1970: 2_000)
        _ = try await MarkStatusUseCase(repository: repo, now: { t0 })(jobID: "a", stage: .applied)
        let after = try await MarkStatusUseCase(repository: repo, now: { t1 })(jobID: "a", stage: .interviewing)

        #expect(after.stage == .interviewing)
        #expect(after.appliedDate == t0)        // earlier milestone retained
        #expect(after.interviewDate == t1)
    }

    @Test func loadStatusReturnsNilWhenUntracked() async throws {
        let repo = SavedStatusRepository(store: InMemoryRecordStore())
        let load = LoadStatusUseCase(repository: repo)
        #expect(try await load(forJobID: "a") == nil)
    }

    @Test func trackedJobsJoinStatusesWithSavedDetails() async throws {
        let store = InMemoryRecordStore()
        let jobsRepo = SavedJobsRepository(store: store)
        let statusRepo = SavedStatusRepository(store: store)
        try await jobsRepo.save([ranked("a"), ranked("b")])          // both saved
        try await statusRepo.save(ApplicationStatus(stage: .applied), forJobID: "a")  // only "a" tracked

        let tracked = try await LoadTrackedJobsUseCase(jobs: jobsRepo, statuses: statusRepo)()
        #expect(tracked.map(\.id) == ["a"])                          // only tracked jobs
        #expect(tracked.first?.status.stage == .applied)
        #expect(tracked.first?.job.listing.company == "c")           // joined with saved details
    }

    @Test func trackedJobsEmptyWhenNothingTracked() async throws {
        let store = InMemoryRecordStore()
        let jobsRepo = SavedJobsRepository(store: store)
        try await jobsRepo.save([ranked("a")])
        let tracked = try await LoadTrackedJobsUseCase(jobs: jobsRepo, statuses: SavedStatusRepository(store: store))()
        #expect(tracked.isEmpty)
    }
}
