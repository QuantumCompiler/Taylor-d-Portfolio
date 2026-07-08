//
//  ResultsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · ViewModel
//

import Observation

/// Drives the Results screen: presents a ranked list and tracks which job the user
/// picked (which drives the detail view). On launch it can load jobs persisted by
/// earlier searches (Milestone O-B) so results survive relaunch.
@MainActor
@Observable
final class ResultsViewModel {
    var results: [RankedJob]
    var selectedJob: RankedJob?

    private let loadSavedJobs: LoadSavedJobsUseCase?

    init(results: [RankedJob] = [], loadSavedJobs: LoadSavedJobsUseCase? = nil) {
        self.results = results
        self.loadSavedJobs = loadSavedJobs
    }

    var isEmpty: Bool { results.isEmpty }

    func select(_ job: RankedJob) {
        selectedJob = job
    }

    /// Loads previously-saved results when the list is empty (e.g. a fresh launch with
    /// no search yet). A no-op if persistence isn't wired or a search already ran.
    func loadSavedIfNeeded() async {
        guard let loadSavedJobs, results.isEmpty else { return }
        if let saved = try? await loadSavedJobs(), !saved.isEmpty {
            results = saved
        }
    }
}
