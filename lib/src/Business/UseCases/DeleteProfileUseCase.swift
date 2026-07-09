//
//  DeleteProfileUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — remove a saved profile from the library.
//

import Foundation

/// Deletes a ``SavedProfile`` from the library by id.
nonisolated struct DeleteProfileUseCase: Sendable {
    let repository: SavedProfilesRepository

    init(repository: SavedProfilesRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws {
        try await repository.delete(id: id)
    }
}
