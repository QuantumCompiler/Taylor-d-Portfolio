//
//  SaveApplicationUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — persist a generated ApplicationKit (O-C).
//

import Foundation

/// Persists a generated ``ApplicationKit`` — with the ``TargetBrief`` it was tailored
/// against (v0.6.1 Milestone B) — for a job so it can be reopened later.
nonisolated struct SaveApplicationUseCase: Sendable {
    let repository: SavedApplicationsRepository

    init(repository: SavedApplicationsRepository) {
        self.repository = repository
    }

    func callAsFunction(_ kit: ApplicationKit, brief: TargetBrief? = nil, forJobID jobID: String) async throws {
        try await repository.save(kit, brief: brief, forJobID: jobID)
    }
}
