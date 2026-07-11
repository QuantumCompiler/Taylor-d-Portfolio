//
//  LoadJobHistoryUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — assemble each job's cross-screen history.
//

import Foundation

/// Builds the ``JobHistory`` map that gives Results, saved jobs, and the Tracker a single
/// coherent story per job (Milestone S-C): whether its listing is saved ("seen"), whether
/// an application has been generated for it, and where its application status stands.
///
/// Reads the three persisted sources and joins them by job id — the read-side counterpart
/// to ``DeleteSavedJobUseCase`` (which forgets across the same three stores).
nonisolated struct LoadJobHistoryUseCase: Sendable {
    let jobs: SavedJobsRepository
    let statuses: SavedStatusRepository
    let applications: SavedApplicationsRepository

    init(jobs: SavedJobsRepository, statuses: SavedStatusRepository, applications: SavedApplicationsRepository) {
        self.jobs = jobs
        self.statuses = statuses
        self.applications = applications
    }

    /// The history for every job we have any record of, keyed by job id.
    func callAsFunction() async throws -> [String: JobHistory] {
        let statusByID = try await statuses.allStatuses()
        let savedIDs = Set(try await jobs.savedJobs().map(\.id))
        let generatedIDs = try await applications.savedJobIDs()

        let ids = savedIDs.union(statusByID.keys).union(generatedIDs)
        var history: [String: JobHistory] = [:]
        for id in ids {
            history[id] = JobHistory(
                isSaved: savedIDs.contains(id),
                isGenerated: generatedIDs.contains(id),
                status: statusByID[id]
            )
        }
        return history
    }
}
