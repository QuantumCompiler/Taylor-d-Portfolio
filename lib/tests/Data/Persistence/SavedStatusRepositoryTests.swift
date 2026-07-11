//
//  SavedStatusRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — ApplicationStatus by job id + allStatuses map.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("SavedStatusRepository")
struct SavedStatusRepositoryTests {

    @Test func saveThenLoadByJobID() async throws {
        let repo = SavedStatusRepository(store: InMemoryRecordStore())
        let status = ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100))
        try await repo.save(status, forJobID: "job-a")

        #expect(try await repo.status(forJobID: "job-a") == status)
        #expect(try await repo.status(forJobID: "nope") == nil)
    }

    @Test func upsertReplacesPerJob() async throws {
        let repo = SavedStatusRepository(store: InMemoryRecordStore())
        try await repo.save(ApplicationStatus(stage: .applied), forJobID: "job-a")
        try await repo.save(ApplicationStatus(stage: .interviewing), forJobID: "job-a")
        #expect(try await repo.status(forJobID: "job-a")?.stage == .interviewing)
    }

    @Test func allStatusesKeyedByJobID() async throws {
        let repo = SavedStatusRepository(store: InMemoryRecordStore())
        try await repo.save(ApplicationStatus(stage: .applied), forJobID: "a")
        try await repo.save(ApplicationStatus(stage: .offer), forJobID: "b")

        let all = try await repo.allStatuses()
        #expect(all.count == 2)
        #expect(all["a"]?.stage == .applied)
        #expect(all["b"]?.stage == .offer)
    }
}
