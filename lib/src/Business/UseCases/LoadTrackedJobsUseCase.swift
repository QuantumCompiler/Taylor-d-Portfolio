//
//  LoadTrackedJobsUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — join saved jobs with their statuses for the Tracker.
//

import Foundation

/// Produces the ``TrackedJob`` list backing the Tracker screen: every job that has an
/// ``ApplicationStatus``, joined with its saved ``RankedJob`` details.
nonisolated struct LoadTrackedJobsUseCase: Sendable {
    let jobs: SavedJobsRepository
    let statuses: SavedStatusRepository

    init(jobs: SavedJobsRepository, statuses: SavedStatusRepository) {
        self.jobs = jobs
        self.statuses = statuses
    }

    func callAsFunction() async throws -> [TrackedJob] {
        let statusByID = try await statuses.allStatuses()
        guard !statusByID.isEmpty else { return [] }
        let savedByID = Dictionary(
            try await jobs.savedJobs().map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        // Only jobs we still have saved details for can be shown.
        return statusByID.compactMap { id, status in
            savedByID[id].map { TrackedJob(job: $0, status: status) }
        }
    }
}
