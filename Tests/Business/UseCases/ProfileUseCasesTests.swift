//
//  ProfileUseCasesTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — save/load/delete for the saved-profile library.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("Profile use cases")
struct ProfileUseCasesTests {

    private func profile(_ seniority: String = "Senior") -> CandidateProfile {
        CandidateProfile(seniority: seniority, yearsExperience: 8, coreSkills: ["Swift"],
                         domains: [], targetTitles: ["iOS Engineer"], summary: "")
    }

    private func makeSave(_ repo: SavedProfilesRepository) -> SaveProfileUseCase {
        SaveProfileUseCase(
            repository: repo,
            makeID: { "fixed-id" },
            now: { Date(timeIntervalSince1970: 1_000) }
        )
    }

    @Test func saveNewAssignsInjectedIDAndDate() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        let saved = try await makeSave(repo)(profile(), name: "My Profile")

        #expect(saved.id == "fixed-id")
        #expect(saved.name == "My Profile")
        #expect(saved.createdAt == Date(timeIntervalSince1970: 1_000))
        #expect(try await LoadProfilesUseCase(repository: repo)().count == 1)
    }

    @Test func savePersistsPairedDocument() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        let saved = try await makeSave(repo)(
            profile(), name: "CV",
            sourceFileName: "resume.pdf", sourceText: "raw text", readableText: "readable text"
        )

        #expect(saved.sourceFileName == "resume.pdf")
        #expect(saved.sourceText == "raw text")
        #expect(saved.readableText == "readable text")
        #expect(try await LoadProfilesUseCase(repository: repo)().first?.readableText == "readable text")
    }

    @Test func saveExistingPreservesIDAndCreatedAt() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        let save = makeSave(repo)
        let original = try await save(profile("Junior"), name: "Original")

        // Re-save under the same slot with a new name + a (would-be) later timestamp.
        let laterSave = SaveProfileUseCase(repository: repo, makeID: { "other" },
                                           now: { Date(timeIntervalSince1970: 9_999) })
        let updated = try await laterSave(profile("Staff"), name: "Renamed", existing: original)

        #expect(updated.id == original.id)                       // id preserved
        #expect(updated.createdAt == original.createdAt)          // createdAt preserved
        #expect(updated.name == "Renamed")
        #expect(updated.profile.seniority == "Staff")             // content updated

        let all = try await LoadProfilesUseCase(repository: repo)()
        #expect(all.count == 1)                                   // updated, not duplicated
    }

    @Test func deleteRemovesFromLibrary() async throws {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        let saved = try await makeSave(repo)(profile(), name: "Doomed")

        try await DeleteProfileUseCase(repository: repo)(id: saved.id)
        #expect(try await LoadProfilesUseCase(repository: repo)().isEmpty)
    }
}
