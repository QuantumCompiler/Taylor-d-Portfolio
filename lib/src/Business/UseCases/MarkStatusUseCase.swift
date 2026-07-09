//
//  MarkStatusUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — advance a job's application status, auto-stamping the date.
//

import Foundation

/// Advances a job's ``ApplicationStatus`` to a new stage, auto-stamping the transition
/// date, and persists it. Creates a status on first mark. The clock is injectable so
/// the stamped date is deterministic in tests.
nonisolated struct MarkStatusUseCase: Sendable {
    let repository: SavedStatusRepository
    let now: @Sendable () -> Date

    init(repository: SavedStatusRepository, now: @escaping @Sendable () -> Date = { Date() }) {
        self.repository = repository
        self.now = now
    }

    @discardableResult
    func callAsFunction(jobID: String, stage: ApplicationStage) async throws -> ApplicationStatus {
        let current = (try? await repository.status(forJobID: jobID)) ?? ApplicationStatus()
        let updated = current.advanced(to: stage, on: now())
        try await repository.save(updated, forJobID: jobID)
        return updated
    }
}
