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
    /// True while the tracked-jobs load is in flight — the view shows a spinner instead of
    /// flashing the "No tracked applications" empty state (Milestone S-B).
    private(set) var isLoading = false
    /// The cross-screen history per job id — so Tracker rows can show the same
    /// "generated" badge as Results (Milestone S-C).
    private(set) var historyByID: [String: JobHistory] = [:]

    private let loadTrackedJobs: LoadTrackedJobsUseCase?
    private let loadJobHistory: LoadJobHistoryUseCase?
    private let untrackJob: UntrackJobUseCase?
    private let deleteSavedJob: DeleteSavedJobUseCase?

    init(
        loadTrackedJobs: LoadTrackedJobsUseCase? = nil,
        loadJobHistory: LoadJobHistoryUseCase? = nil,
        untrackJob: UntrackJobUseCase? = nil,
        deleteSavedJob: DeleteSavedJobUseCase? = nil
    ) {
        self.loadTrackedJobs = loadTrackedJobs
        self.loadJobHistory = loadJobHistory
        self.untrackJob = untrackJob
        self.deleteSavedJob = deleteSavedJob
    }

    var isEmpty: Bool { trackedJobs.isEmpty }

    /// Whether the per-row remove-from-Tracker / delete actions are wired in this build.
    var supportsRowActions: Bool { untrackJob != nil && deleteSavedJob != nil }

    // MARK: Row actions (v0.5.0)

    /// Removes `job` from the Tracker but keeps it: clears its status so it returns to the
    /// Results list as an un-triaged result (the saved listing + any generated materials are
    /// preserved). Drops the row locally for instant feedback.
    func returnToResults(_ job: RankedJob) async {
        guard let untrackJob else { return }
        try? await untrackJob(jobID: job.id)
        trackedJobs.removeAll { $0.id == job.id }
        historyByID[job.id] = nil
    }

    /// Fully forgets `job`: removes the saved listing, its status, and any generated
    /// materials, so it disappears from both the Tracker and Results.
    func delete(_ job: RankedJob) async {
        guard let deleteSavedJob else { return }
        try? await deleteSavedJob(jobID: job.id)
        trackedJobs.removeAll { $0.id == job.id }
        historyByID[job.id] = nil
    }

    /// The tracked jobs that fall under `section`'s stage filter (`All` returns every
    /// tracked job). Drives the Tracker inner-nav sub-views (v0.4.0 Milestone B).
    func jobs(in section: TrackerSection) -> [TrackedJob] {
        trackedJobs.filter { section.includes($0.status.stage) }
    }

    func select(_ job: RankedJob) { selectedJob = job }

    /// The row's badge story. Prefers the joined history map; falls back to the tracked
    /// job's own status (a tracked job is, by definition, saved).
    func history(for job: RankedJob) -> JobHistory {
        if let history = historyByID[job.id] { return history }
        if let tracked = trackedJobs.first(where: { $0.id == job.id }) {
            return JobHistory(isSaved: true, status: tracked.status)
        }
        return JobHistory()
    }

    /// Loads tracked jobs, sorted by most-recent status activity (undated last), and the
    /// per-job history map for the badges.
    func load() async {
        guard let loadTrackedJobs else { return }
        isLoading = true
        defer { isLoading = false }
        guard let jobs = try? await loadTrackedJobs() else { return }
        trackedJobs = jobs.sorted { lhs, rhs in
            switch (lhs.status.currentDate, rhs.status.currentDate) {
            case let (l?, r?): return l > r
            case (nil, _?): return false
            case (_?, nil): return true
            case (nil, nil): return lhs.job.listing.title < rhs.job.listing.title
            }
        }
        if let loadJobHistory, let history = try? await loadJobHistory() {
            historyByID = history
        }
    }
}
