//
//  SavedSearchesRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — persisting re-runnable searches (Milestone R).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("SavedSearchesRepository")
struct SavedSearchesRepositoryTests {

    private func saved(_ id: String, titles: [String], at seconds: TimeInterval) -> SavedSearch {
        let request = JobSearchRequest(titles: titles, location: "Remote", positionType: .contract, minimumScore: 60)
        return SavedSearch(id: id, name: SavedSearch.defaultName(for: request),
                           request: request, createdAt: Date(timeIntervalSince1970: seconds))
    }

    @Test func saveThenLoadRoundTripsNewestFirst() async throws {
        let repo = SavedSearchesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", titles: ["iOS"], at: 10))
        try await repo.save(saved("b", titles: ["Backend"], at: 20))

        let all = try await repo.all()
        #expect(all.map(\.id) == ["b", "a"])                 // newest first
        // The full request round-trips, including the new U-A/U-E fields.
        #expect(all.first?.request.positionType == .contract)
        #expect(all.first?.request.minimumScore == 60)
    }

    @Test func upsertByIDReplacesRatherThanDuplicates() async throws {
        let repo = SavedSearchesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", titles: ["iOS"], at: 10))
        try await repo.save(saved("a", titles: ["iOS Engineer"], at: 10))   // same id
        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.request.titles == ["iOS Engineer"])
    }

    @Test func deleteRemovesByID() async throws {
        let repo = SavedSearchesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", titles: ["iOS"], at: 10))
        try await repo.delete(id: "a")
        #expect(try await repo.all().isEmpty)
    }

    @Test func defaultNameSummarisesTheRequest() {
        let request = JobSearchRequest(titles: ["iOS Engineer", "Swift Dev"], location: "Lehi, UT")
        #expect(SavedSearch.defaultName(for: request) == "iOS Engineer, Swift Dev · Lehi, UT")
    }
}
