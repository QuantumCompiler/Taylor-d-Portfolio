//
//  GenerationPresetsRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — persisting generation presets (Milestone D-D).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("GenerationPresetsRepository")
struct GenerationPresetsRepositoryTests {

    private func preset(_ id: String, _ settings: GenerationSettings, at seconds: TimeInterval) -> GenerationPreset {
        GenerationPreset(id: id, name: GenerationPreset.defaultName(for: settings),
                         settings: settings, createdAt: Date(timeIntervalSince1970: seconds))
    }

    @Test func saveThenLoadRoundTripsNewestFirst() async throws {
        let repo = GenerationPresetsRepository(store: InMemoryRecordStore())
        try await repo.save(preset("a", GenerationSettings(fidelity: 0.5, aspects: [.summary]), at: 10))
        try await repo.save(preset("b", GenerationSettings(desiredRankMatch: 85), at: 20))

        let all = try await repo.all()
        #expect(all.map(\.id) == ["b", "a"])                 // newest first
        #expect(all.first?.settings.desiredRankMatch == 85)  // full settings round-trip
        #expect(all.last?.settings.aspects == [.summary])
    }

    @Test func upsertByIDReplacesRatherThanDuplicates() async throws {
        let repo = GenerationPresetsRepository(store: InMemoryRecordStore())
        try await repo.save(preset("a", GenerationSettings(fidelity: 0.3), at: 10))
        try await repo.save(preset("a", GenerationSettings(fidelity: 0.9), at: 10))   // same id
        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.settings.fidelity == 0.9)
    }

    @Test func deleteRemovesByID() async throws {
        let repo = GenerationPresetsRepository(store: InMemoryRecordStore())
        try await repo.save(preset("a", .default, at: 10))
        try await repo.delete(id: "a")
        #expect(try await repo.all().isEmpty)
    }

    @Test func defaultNameSummarisesTheSettings() {
        #expect(GenerationPreset.defaultName(for: GenerationSettings(desiredRankMatch: 80)) == "Rank ≥ 80")
        #expect(GenerationPreset.defaultName(for: GenerationSettings(fidelity: 0.5)) == "Curated")
        // Aspects are ordered by rawValue (skills < summary), matching the prompt's ordering.
        #expect(GenerationPreset.defaultName(for: GenerationSettings(fidelity: 0.5, aspects: [.summary, .skills]))
                == "Curated · Skills, Summary / Headline")
    }

    // MARK: Use cases

    @Test func saveUseCaseAutoNamesAndAssignsIDAndDate() async throws {
        let repo = GenerationPresetsRepository(store: InMemoryRecordStore())
        let save = SaveGenerationPresetUseCase(
            repository: repo,
            makeID: { "fixed-id" },
            now: { Date(timeIntervalSince1970: 42) }
        )
        let saved = try await save(GenerationSettings(fidelity: 0.5))
        #expect(saved.id == "fixed-id")
        #expect(saved.name == "Curated")
        #expect(saved.createdAt == Date(timeIntervalSince1970: 42))
        #expect(try await LoadGenerationPresetsUseCase(repository: repo)().count == 1)
    }

    @Test func saveUseCasePreservesIDAndDateWhenUpdatingExisting() async throws {
        let repo = GenerationPresetsRepository(store: InMemoryRecordStore())
        let existing = GenerationPreset(id: "keep", name: "Mine", settings: .default,
                                        createdAt: Date(timeIntervalSince1970: 5))
        let save = SaveGenerationPresetUseCase(repository: repo, makeID: { "new" }, now: { Date(timeIntervalSince1970: 99) })
        let updated = try await save(GenerationSettings(fidelity: 0.9), name: "Mine", existing: existing)
        #expect(updated.id == "keep")                          // id preserved
        #expect(updated.createdAt == Date(timeIntervalSince1970: 5))   // date preserved
        #expect(updated.settings.fidelity == 0.9)
    }
}
