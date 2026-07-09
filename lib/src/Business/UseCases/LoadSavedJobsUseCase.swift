//
//  LoadSavedJobsUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — load previously-saved ranked results.
//

import Foundation

/// Loads the ranked jobs persisted by earlier searches so they can be revisited after
/// relaunch (Milestone O-B).
nonisolated struct LoadSavedJobsUseCase: Sendable {
    let repository: SavedJobsRepository

    init(repository: SavedJobsRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [RankedJob] {
        try await repository.savedJobs()
    }
}
