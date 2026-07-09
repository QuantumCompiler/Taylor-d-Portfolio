//
//  TrackerViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Tracker · ViewModel
//

import Observation

/// Drives the Tracker screen: lists the jobs the user has marked with an application
/// status, most-recent activity first, and tracks which one is open for detail.
@MainActor
@Observable
final class TrackerViewModel {
    private(set) var trackedJobs: [TrackedJob] = []
    var selectedJob: RankedJob?

    private let loadTrackedJobs: LoadTrackedJobsUseCase?

    init(loadTrackedJobs: LoadTrackedJobsUseCase? = nil) {
        self.loadTrackedJobs = loadTrackedJobs
    }

    var isEmpty: Bool { trackedJobs.isEmpty }

    func select(_ job: RankedJob) { selectedJob = job }

    /// Loads tracked jobs, sorted by most-recent status activity (undated last).
    func load() async {
        guard let loadTrackedJobs, let jobs = try? await loadTrackedJobs() else { return }
        trackedJobs = jobs.sorted { lhs, rhs in
            switch (lhs.status.currentDate, rhs.status.currentDate) {
            case let (l?, r?): return l > r
            case (nil, _?): return false
            case (_?, nil): return true
            case (nil, nil): return lhs.job.listing.title < rhs.job.listing.title
            }
        }
    }
}
