//
//  SavedSearchUseCases.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — save / load / delete re-runnable searches (Milestone R).
//

import Foundation

/// Saves (or updates) a ``JobSearchRequest`` under a name so it can be re-run later.
/// `makeID` / `now` are injected for deterministic tests. Pass `existing` to update a
/// saved search already in the library (its id and `createdAt` are preserved).
nonisolated struct SaveSearchUseCase: Sendable {
    let repository: SavedSearchesRepository
    let makeID: @Sendable () -> String
    let now: @Sendable () -> Date

    init(
        repository: SavedSearchesRepository,
        makeID: @escaping @Sendable () -> String = { UUID().uuidString },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.makeID = makeID
        self.now = now
    }

    @discardableResult
    func callAsFunction(
        _ request: JobSearchRequest,
        name: String? = nil,
        existing: SavedSearch? = nil
    ) async throws -> SavedSearch {
        let saved = SavedSearch(
            id: existing?.id ?? makeID(),
            name: name ?? SavedSearch.defaultName(for: request),
            request: request,
            createdAt: existing?.createdAt ?? now()
        )
        try await repository.save(saved)
        return saved
    }
}

/// Loads the user's saved searches, newest first.
nonisolated struct LoadSavedSearchesUseCase: Sendable {
    let repository: SavedSearchesRepository

    init(repository: SavedSearchesRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [SavedSearch] {
        try await repository.all()
    }
}

/// Deletes a saved search by id.
nonisolated struct DeleteSavedSearchUseCase: Sendable {
    let repository: SavedSearchesRepository

    init(repository: SavedSearchesRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws {
        try await repository.delete(id: id)
    }
}
