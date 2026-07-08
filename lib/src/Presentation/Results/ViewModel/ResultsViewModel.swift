//
//  ResultsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · ViewModel
//

import Observation

/// Drives the Results screen: presents a ranked list and tracks which job the user
/// picked (which drives the Application sheet).
@MainActor
@Observable
final class ResultsViewModel {
    var results: [RankedJob]
    var selectedJob: RankedJob?

    init(results: [RankedJob] = []) {
        self.results = results
    }

    var isEmpty: Bool { results.isEmpty }

    func select(_ job: RankedJob) {
        selectedJob = job
    }
}
