//
//  DocumentStyleUseCases.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — save / load / delete document styles (v0.7.0 Milestone D).
//

import Foundation

/// Saves (or updates) a ``LaTeXStyle`` under a name so it can be reused on any export.
/// `makeID` / `now` are injected for deterministic tests. Pass `existing` to update a style
/// already in the library (its id and `createdAt` are preserved, so an update renames or
/// re-styles in place rather than adding a second row).
nonisolated struct SaveDocumentStyleUseCase: Sendable {
    let repository: SavedDocumentStylesRepository
    let makeID: @Sendable () -> String
    let now: @Sendable () -> Date

    init(
        repository: SavedDocumentStylesRepository,
        makeID: @escaping @Sendable () -> String = { UUID().uuidString },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.makeID = makeID
        self.now = now
    }

    @discardableResult
    func callAsFunction(
        _ style: LaTeXStyle,
        name: String? = nil,
        existing: SavedDocumentStyle? = nil
    ) async throws -> SavedDocumentStyle {
        let saved = SavedDocumentStyle(
            id: existing?.id ?? makeID(),
            name: name ?? SavedDocumentStyle.defaultName(for: style),
            style: style,
            createdAt: existing?.createdAt ?? now()
        )
        try await repository.save(saved)
        return saved
    }
}

/// Loads the user's saved document styles, newest first.
nonisolated struct LoadDocumentStylesUseCase: Sendable {
    let repository: SavedDocumentStylesRepository

    init(repository: SavedDocumentStylesRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [SavedDocumentStyle] {
        try await repository.all()
    }
}

/// Deletes a document style by id.
nonisolated struct DeleteDocumentStyleUseCase: Sendable {
    let repository: SavedDocumentStylesRepository

    init(repository: SavedDocumentStylesRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws {
        try await repository.delete(id: id)
    }
}
