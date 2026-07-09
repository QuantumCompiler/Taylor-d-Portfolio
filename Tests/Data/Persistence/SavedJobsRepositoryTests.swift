//
//  SavedJobsRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — RankedJob ↔ store mapping, upsert, contains.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("SavedJobsRepository")
struct SavedJobsRepositoryTests {

    private func ranked(_ id: String, score: Int) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "iOS Engineer", company: "Acme", location: "Remote", description: "Swift."),
            match: JobMatch(jobId: id, score: score, reason: "Fit.", matchedSkills: ["Swift"], missingSkills: [])
        )
    }

    @Test func saveThenLoadRoundTripsSortedByScore() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("a", score: 40), ranked("b", score: 90)])

        let loaded = try await repo.savedJobs()
        #expect(loaded.map(\.id) == ["b", "a"])          // sorted by score desc
        #expect(loaded.first == ranked("b", score: 90))  // full domain value round-trips
    }

    @Test func upsertByListingIDCollapsesDuplicates() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("a", score: 40)])
        try await repo.save([ranked("a", score: 75)])   // same id, re-pulled with a new score

        let loaded = try await repo.savedJobs()
        #expect(loaded.count == 1)
        #expect(loaded.first?.score == 75)               // latest wins
    }

    @Test func containsReflectsSavedIDs() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("a", score: 50)])
        #expect(try await repo.contains(jobID: "a"))
        #expect(try await repo.contains(jobID: "nope") == false)
    }

    @Test func emptyStoreLoadsNothing() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        #expect(try await repo.savedJobs().isEmpty)
    }
}
