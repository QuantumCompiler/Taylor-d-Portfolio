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
    /// The live sort applied to each stage tab's rows (Milestone H). `.default` reproduces
    /// the historic most-recent-activity order; the view can change it without reloading.
    var sort: TrackerSort = .default
    /// The live filter applied to each stage tab's rows (v0.6.2 Milestone C) — the capability
    /// Results already had. This is **the same `ResultsFilter` type**, not a parallel one:
    /// `matches(_:isTracked:)` is generic over a `RankedJob` and a `TrackedJob` wraps one, so it
    /// applies directly to `tracked.job`. Session-only and non-destructive, like the sort.
    var filter = ResultsFilter()
    /// True while the tracked-jobs load is in flight — the view shows a spinner instead of
    /// flashing the "No tracked applications" empty state (Milestone S-B).
    private(set) var isLoading = false
    /// The cross-screen history per job id — so Tracker rows can show the same
    /// "generated" badge as Results (Milestone S-C).
    private(set) var historyByID: [String: JobHistory] = [:]
    /// The rows multi-selected for a bulk action (v0.6.2 Milestone B) — the Tracker half of
    /// the Results selection, over the same two removals its rows already offer. Distinct from
    /// ``selectedJob`` (the single job open for detail).
    var selectedIDs: Set<String> = []
    /// True while a bulk removal is in flight, so the action bar can't fire the batch twice.
    private(set) var isBulkActing = false

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

    // MARK: Multi-select + bulk actions (v0.6.2 Milestone B)

    /// The selected jobs **within the shown stage tab** — a selection made in one tab can't be
    /// acted on from another, and the count in the bar always matches the rows in front of you.
    func selectedJobs(in section: TrackerSection) -> [RankedJob] {
        jobs(in: section).filter { selectedIDs.contains($0.id) }.map(\.job)
    }
    func selectionCount(in section: TrackerSection) -> Int { selectedJobs(in: section).count }
    func hasSelection(in section: TrackerSection) -> Bool { !selectedJobs(in: section).isEmpty }

    func clearSelection() { selectedIDs.removeAll() }

    /// Returns every selected job to Results — clears their statuses, keeping the listings and
    /// any generated materials. Non-destructive, so it isn't confirmed.
    func returnSelectedToResults(in section: TrackerSection) async {
        await removeSelected(in: section, using: returnToResults)
    }

    /// Fully forgets every selected job (listing + status + materials).
    func deleteSelected(in section: TrackerSection) async {
        await removeSelected(in: section, using: delete)
    }

    /// Shared batch runner for the two removals: both are per-id use cases, so they loop,
    /// and each already drops its own row and history entry.
    private func removeSelected(in section: TrackerSection, using remove: (RankedJob) async -> Void) async {
        let jobs = selectedJobs(in: section)
        guard !jobs.isEmpty else { clearSelection(); return }
        isBulkActing = true
        defer { isBulkActing = false }
        clearSelection()
        for job in jobs { await remove(job) }
    }

    /// The tracked jobs that fall under `section`'s stage filter (`All` returns every
    /// tracked job), narrowed by the live ``filter`` (v0.6.2 Milestone C) and ordered by the
    /// active ``sort`` (Milestone H). Drives the Tracker inner-nav sub-views (v0.4.0 B).
    ///
    /// **Filter within the tab, then sort.** The filter runs alongside the stage predicate — so
    /// it narrows the rows the selected tab shows rather than reaching across tabs, matching how
    /// the sort already works per section. `isTracked` is `true` by definition here (everything
    /// in the Tracker is tracked), which is also why the view hides that facet.
    func jobs(in section: TrackerSection) -> [TrackedJob] {
        sort.apply(to: trackedJobs.filter {
            section.includes($0.status.stage) && filter.matches($0.job, isTracked: { _ in true })
        })
    }

    /// Whether the live filter is hiding rows the selected tab would otherwise show — the
    /// Tracker's analogue of `ResultsViewModel.isFilteredEmpty`, for a distinct empty state.
    func isFilteredEmpty(in section: TrackerSection) -> Bool {
        filter.isActive && jobs(in: section).isEmpty && !unfilteredJobs(in: section).isEmpty
    }

    func clearFilter() { filter = ResultsFilter() }

    /// Rows in the selected tab **before** the filter — the "Showing X of Y" denominator, and
    /// the set the location/company options are drawn from (so picking one doesn't erase the
    /// rest).
    private func unfilteredJobs(in section: TrackerSection) -> [TrackedJob] {
        trackedJobs.filter { section.includes($0.status.stage) }
    }
    func totalCount(in section: TrackerSection) -> Int { unfilteredJobs(in: section).count }
    func visibleCount(in section: TrackerSection) -> Int { jobs(in: section).count }

    /// Distinct locations / companies among the selected tab's tracked jobs, for the pickers.
    func locationOptions(in section: TrackerSection) -> [String] {
        ListFilterOptions.distinct(unfilteredJobs(in: section).map(\.job.listing.location))
    }
    func companyOptions(in section: TrackerSection) -> [String] {
        ListFilterOptions.distinct(unfilteredJobs(in: section).map(\.job.listing.company))
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

    /// Loads tracked jobs and the per-job history map for the badges. Row ordering is applied
    /// on read by ``jobs(in:)`` via the active ``sort`` (whose default reproduces the historic
    /// most-recent-activity order), so the load itself stores them as-fetched.
    func load() async {
        guard let loadTrackedJobs else { return }
        isLoading = true
        defer { isLoading = false }
        guard let jobs = try? await loadTrackedJobs() else { return }
        trackedJobs = jobs
        if let loadJobHistory, let history = try? await loadJobHistory() {
            historyByID = history
        }
    }
}
