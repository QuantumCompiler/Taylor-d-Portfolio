//
//  SavedProfilesRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — SavedProfile ↔ store mapping, upsert, order, delete.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("SavedProfilesRepository")
struct SavedProfilesRepositoryTests {

    private func profile(_ seniority: String) -> CandidateProfile {
        CandidateProfile(seniority: seniority, yearsExperience: 5, coreSkills: ["Swift"],
                         domains: [], targetTitles: ["iOS Engineer"], summary: "")
    }

    private func saved(_ id: String, _ name: String, at seconds: TimeInterval) -> SavedProfile {
        SavedProfile(id: id, name: name, profile: profile(name),
                     createdAt: Date(timeIntervalSince1970: seconds))
    }

    @Test func saveThenLoadRoundTripsNewestFirst() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "Older", at: 100))
        try await repo.save(saved("b", "Newer", at: 200))

        let all = try await repo.all()
        #expect(all.map(\.id) == ["b", "a"])              // newest first
        #expect(all.first == saved("b", "Newer", at: 200)) // full value round-trips
    }

    @Test func upsertByIDReplacesRatherThanDuplicates() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "First name", at: 100))
        try await repo.save(saved("a", "Renamed", at: 100))  // same id

        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.name == "Renamed")
    }

    @Test func deleteRemovesByID() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "Keep", at: 100))
        try await repo.save(saved("b", "Drop", at: 200))

        try await repo.delete(id: "b")
        let all = try await repo.all()
        #expect(all.map(\.id) == ["a"])
    }

    @Test func emptyStoreLoadsNothing() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        #expect(try await repo.all().isEmpty)
    }

    @Test func pairedDocumentFieldsRoundTrip() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        let withDoc = SavedProfile(
            id: "a", name: "CV", profile: profile("Senior"),
            sourceFileName: "resume.pdf", sourceText: "raw", readableText: "readable",
            createdAt: Date(timeIntervalSince1970: 1)
        )
        try await repo.save(withDoc)

        let loaded = try #require(try await repo.all().first)
        #expect(loaded.sourceFileName == "resume.pdf")
        #expect(loaded.sourceText == "raw")
        #expect(loaded.readableText == "readable")
        #expect(loaded == withDoc)
    }

    @Test func decodesLegacyBlobWithoutDocumentFields() throws {
        // A profile persisted before the document fields existed must still decode.
        let legacy = #"""
        {"id":"a","name":"Old","createdAt":0,"profile":{"seniority":"S","yearsExperience":1,"coreSkills":[],"domains":[],"targetTitles":[],"summary":""}}
        """#
        let decoded = try JSONDecoder().decode(SavedProfile.self, from: Data(legacy.utf8))
        #expect(decoded.name == "Old")
        #expect(decoded.sourceFileName == nil)
        #expect(decoded.sourceText.isEmpty)
        #expect(decoded.readableText.isEmpty)
    }
}
