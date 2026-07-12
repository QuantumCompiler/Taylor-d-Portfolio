//
//  GenerationPresetUseCases.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — save / load / delete generation presets (Milestone D-D).
//

import Foundation

/// Saves (or updates) a ``GenerationSettings`` under a name so it can be reused on any job.
/// `makeID` / `now` are injected for deterministic tests. Pass `existing` to update a preset
/// already in the library (its id and `createdAt` are preserved).
nonisolated struct SaveGenerationPresetUseCase: Sendable {
    let repository: GenerationPresetsRepository
    let makeID: @Sendable () -> String
    let now: @Sendable () -> Date

    init(
        repository: GenerationPresetsRepository,
        makeID: @escaping @Sendable () -> String = { UUID().uuidString },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.makeID = makeID
        self.now = now
    }

    @discardableResult
    func callAsFunction(
        _ settings: GenerationSettings,
        name: String? = nil,
        existing: GenerationPreset? = nil
    ) async throws -> GenerationPreset {
        let preset = GenerationPreset(
            id: existing?.id ?? makeID(),
            name: name ?? GenerationPreset.defaultName(for: settings),
            settings: settings,
            createdAt: existing?.createdAt ?? now()
        )
        try await repository.save(preset)
        return preset
    }
}

/// Loads the user's saved generation presets, newest first.
nonisolated struct LoadGenerationPresetsUseCase: Sendable {
    let repository: GenerationPresetsRepository

    init(repository: GenerationPresetsRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [GenerationPreset] {
        try await repository.all()
    }
}

/// Deletes a generation preset by id.
nonisolated struct DeleteGenerationPresetUseCase: Sendable {
    let repository: GenerationPresetsRepository

    init(repository: GenerationPresetsRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws {
        try await repository.delete(id: id)
    }
}
