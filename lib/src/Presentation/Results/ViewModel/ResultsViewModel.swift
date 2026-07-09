//
//  ResultsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · ViewModel
//

import Observation

/// Drives the Results screen: presents a ranked list and tracks which job the user
/// picked (which drives the detail view). On launch it can load jobs persisted by
/// earlier searches (Milestone O-B) and their application statuses (Milestone P) so
/// results survive relaunch and show a status badge.
@MainActor
@Observable
final class ResultsViewModel {
    var results: [RankedJob]
    var selectedJob: RankedJob?
    private(set) var statusesByID: [String: ApplicationStatus] = [:]

    private let loadSavedJobs: LoadSavedJobsUseCase?
    private let loadTrackedJobs: LoadTrackedJobsUseCase?

    init(
        results: [RankedJob] = [],
        loadSavedJobs: LoadSavedJobsUseCase? = nil,
        loadTrackedJobs: LoadTrackedJobsUseCase? = nil
    ) {
        self.results = results
        self.loadSavedJobs = loadSavedJobs
        self.loadTrackedJobs = loadTrackedJobs
    }

    var isEmpty: Bool { results.isEmpty }

    func select(_ job: RankedJob) {
        selectedJob = job
    }

    /// The tracked status for a result row, if any (drives its badge).
    func status(for job: RankedJob) -> ApplicationStatus? { statusesByID[job.id] }

    /// Loads previously-saved results when the list is empty, and (always) refreshes
    /// the status badges.
    func loadSavedIfNeeded() async {
        if let loadSavedJobs, results.isEmpty, let saved = try? await loadSavedJobs(), !saved.isEmpty {
            results = saved
        }
        await refreshStatuses()
    }

    /// Reloads the status-by-id map (e.g. after the detail sheet closes).
    func refreshStatuses() async {
        guard let loadTrackedJobs, let tracked = try? await loadTrackedJobs() else { return }
        statusesByID = Dictionary(tracked.map { ($0.id, $0.status) }, uniquingKeysWith: { first, _ in first })
    }
}
