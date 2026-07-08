//
//  SaveResultsUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — persist ranked results after a search/fetch.
//

import Foundation

/// Persists ranked results so they survive relaunch (Milestone O-B).
nonisolated struct SaveResultsUseCase: Sendable {
    let repository: SavedJobsRepository

    init(repository: SavedJobsRepository) {
        self.repository = repository
    }

    func callAsFunction(_ jobs: [RankedJob]) async throws {
        try await repository.save(jobs)
    }
}
