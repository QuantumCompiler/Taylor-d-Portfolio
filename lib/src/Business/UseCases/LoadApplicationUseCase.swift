//
//  LoadApplicationUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — load a previously-saved ApplicationKit (O-C).
//

import Foundation

/// Loads the ``ApplicationKit`` saved for a job, if any — so opening a posting with
/// prior output shows it without a fresh (costly) generation.
nonisolated struct LoadApplicationUseCase: Sendable {
    let repository: SavedApplicationsRepository

    init(repository: SavedApplicationsRepository) {
        self.repository = repository
    }

    func callAsFunction(forJobID jobID: String) async throws -> ApplicationKit? {
        try await repository.kit(forJobID: jobID)
    }

    /// The ``TargetBrief`` the saved kit was generated against (v0.6.1 Milestone B), or `nil`
    /// when none was stored — records written before the brief was paired in stay readable,
    /// they just can't report keyword coverage.
    func brief(forJobID jobID: String) async throws -> TargetBrief? {
        try await repository.brief(forJobID: jobID)
    }
}
