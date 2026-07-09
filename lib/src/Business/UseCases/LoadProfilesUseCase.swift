//
//  LoadProfilesUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — load the saved-profile library.
//

import Foundation

/// Loads the user's saved ``SavedProfile`` library (newest first).
nonisolated struct LoadProfilesUseCase: Sendable {
    let repository: SavedProfilesRepository

    init(repository: SavedProfilesRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [SavedProfile] {
        try await repository.all()
    }
}
