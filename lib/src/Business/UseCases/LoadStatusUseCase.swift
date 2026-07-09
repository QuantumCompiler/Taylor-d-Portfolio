//
//  LoadStatusUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — load a single job's application status.
//

import Foundation

/// Loads the ``ApplicationStatus`` for one job (for the detail view's status control).
nonisolated struct LoadStatusUseCase: Sendable {
    let repository: SavedStatusRepository

    init(repository: SavedStatusRepository) {
        self.repository = repository
    }

    func callAsFunction(forJobID jobID: String) async throws -> ApplicationStatus? {
        try await repository.status(forJobID: jobID)
    }
}
