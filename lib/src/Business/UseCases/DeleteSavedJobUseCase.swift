//
//  DeleteSavedJobUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — fully forget a saved job (Milestone V-A).
//

import Foundation

/// Deletes a saved job **and everything derived from it**, by decision: the saved listing +
/// match (`SavedJobsRepository`), its tracked status (`SavedStatusRepository`), and any saved
/// generated materials (`SavedApplicationsRepository`) — so deleting a result never leaves an
/// orphaned status or `ApplicationKit` behind.
nonisolated struct DeleteSavedJobUseCase: Sendable {
    let jobs: SavedJobsRepository
    let statuses: SavedStatusRepository
    let applications: SavedApplicationsRepository

    init(
        jobs: SavedJobsRepository,
        statuses: SavedStatusRepository,
        applications: SavedApplicationsRepository
    ) {
        self.jobs = jobs
        self.statuses = statuses
        self.applications = applications
    }

    func callAsFunction(jobID: String) async throws {
        try await jobs.delete(jobID: jobID)
        try await statuses.delete(jobID: jobID)
        try await applications.delete(jobID: jobID)
    }
}
