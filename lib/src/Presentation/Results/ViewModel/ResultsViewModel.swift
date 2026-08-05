//
//  ResultsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Results · ViewModel
//

import Foundation
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
    /// The cross-screen history per job id — seen / generated / tracked (Milestone S-C).
    /// Drives the row badges and the "already tracked" state.
    private(set) var historyByID: [String: JobHistory] = [:]
    /// True while the initial persisted-results load is in flight — the view shows a
    /// spinner instead of flashing the "No results yet" empty state (Milestone S-B).
    private(set) var isLoading = false
    /// The live, non-destructive view filter over `results` (Milestone W).
    var filter = ResultsFilter()
    /// The live, non-destructive sort over the filtered results (v0.6.2 Milestone C) — the
    /// capability the Tracker already had. `.default` is match-score-descending, i.e. the
    /// ranker's own order, so an untouched sort changes nothing.
    var sort: ResultsSort = .default
    /// The rows the user has multi-selected for a bulk action (v0.6.2 Milestone B). Distinct
    /// from ``selectedJob``, which is the single job open for detail. Holds ids rather than
    /// jobs so it survives the list being re-derived (filter change, enrichment swap).
    var selectedIDs: Set<String> = []
    /// True while a bulk save/delete is in flight — the action bar disables itself so the
    /// same batch can't be fired twice.
    private(set) var isBulkActing = false
    /// Called with the ids of every deletion (single or bulk). The shell wires this to prune
    /// the same ids from the Search VM's in-memory copy of the list, so a background digest
    /// still running over the old set can't resurrect a deleted row on screen or re-write it
    /// to the saved-jobs store (v0.7.1 Milestone B).
    @ObservationIgnored var onResultsRemoved: ((Set<String>) -> Void)?
    /// How many postings a bulk save enriches at once. Bulk-saving N jobs would otherwise kick
    /// off N fetch+LLM enrichments at once, so it reuses the same window as the search-side
    /// digest (`SearchAndRankUseCase.maxConcurrentSearches`).
    private let maxConcurrentEnrichments = 4

    private let loadSavedJobs: LoadSavedJobsUseCase?
    private let loadTrackedJobs: LoadTrackedJobsUseCase?
    private let loadJobHistory: LoadJobHistoryUseCase?
    private let markStatus: MarkStatusUseCase?
    private let saveResults: SaveResultsUseCase?
    private let deleteSavedJob: DeleteSavedJobUseCase?
    private let enrichPosting: EnrichPostingUseCase?

    init(
        results: [RankedJob] = [],
        loadSavedJobs: LoadSavedJobsUseCase? = nil,
        loadTrackedJobs: LoadTrackedJobsUseCase? = nil,
        loadJobHistory: LoadJobHistoryUseCase? = nil,
        markStatus: MarkStatusUseCase? = nil,
        saveResults: SaveResultsUseCase? = nil,
        deleteSavedJob: DeleteSavedJobUseCase? = nil,
        enrichPosting: EnrichPostingUseCase? = nil
    ) {
        self.results = results
        self.loadSavedJobs = loadSavedJobs
        self.loadTrackedJobs = loadTrackedJobs
        self.loadJobHistory = loadJobHistory
        self.markStatus = markStatus
        self.saveResults = saveResults
        self.deleteSavedJob = deleteSavedJob
        self.enrichPosting = enrichPosting
    }

    var isEmpty: Bool { results.isEmpty }

    // MARK: Triage — tracked jobs leave the Results list (v0.4.1 Milestone C)

    /// The results that are **not** yet in the Tracker. Once a job has any application
    /// status (saved … withdrawn) it belongs to the Tracker, so Results shows only the
    /// un-triaged jobs — everything the list derives from is built on this set. Saving a
    /// job (which sets its status and calls `refreshHistory`) makes it drop out live.
    var untrackedResults: [RankedJob] { results.filter { !isTracked($0) } }

    /// True when results are loaded but every one has moved to the Tracker — a distinct
    /// empty state from "no results yet" (nothing searched).
    var allResultsTracked: Bool { !results.isEmpty && untrackedResults.isEmpty }

    // MARK: Filtering (Milestone W — view-only, non-destructive)

    /// The (un-tracked) results after applying the live `filter`, then the live `sort` — what
    /// the list shows. Tracked jobs are already excluded, so no row is tracked here.
    /// **Filter first, then sort** (mirroring `TrackerViewModel.jobs(in:)`): sorting only what
    /// survives the filter is the cheaper order and keeps the two tabs' pipelines identical.
    var filteredResults: [RankedJob] {
        sort.apply(to: filter.apply(to: untrackedResults, isTracked: { _ in false }))
    }
    var visibleCount: Int { filteredResults.count }
    var totalCount: Int { untrackedResults.count }
    /// True when a filter is active but hides every un-tracked row (a distinct empty state).
    var isFilteredEmpty: Bool { !untrackedResults.isEmpty && filter.isActive && filteredResults.isEmpty }

    /// Distinct locations present in the shown (un-tracked) results, for the location picker.
    /// Derived **before** the filter, so choosing one option doesn't erase the others.
    var locationOptions: [String] { ListFilterOptions.distinct(untrackedResults.map(\.listing.location)) }
    /// Distinct companies present in the shown (un-tracked) results, for the company picker.
    var companyOptions: [String] { ListFilterOptions.distinct(untrackedResults.map(\.listing.company)) }

    func clearFilter() { filter = ResultsFilter() }
    func resetSort() { sort = .default }

    func select(_ job: RankedJob) {
        selectedJob = job
    }

    /// The tracked status for a result row, if any (drives its badge).
    func status(for job: RankedJob) -> ApplicationStatus? { historyByID[job.id]?.status }

    /// The full cross-screen history for a row (seen / generated / tracked) — drives the
    /// row's badge story (Milestone S-C).
    func history(for job: RankedJob) -> JobHistory { historyByID[job.id] ?? JobHistory() }

    /// Whether the per-row save/delete actions are wired in this build.
    var supportsRowActions: Bool { markStatus != nil && deleteSavedJob != nil }

    /// Whether `job` is already tracked (its save icon reflects the tracked state).
    func isTracked(_ job: RankedJob) -> Bool { historyByID[job.id]?.status != nil }

    // MARK: Multi-select + bulk actions (v0.6.2 Milestone B)

    /// The selected jobs, **as currently shown** — derived from `filteredResults`, so an id
    /// that a filter change (or a save) has taken off the list can't be acted on by a later
    /// bulk action. The count in the action bar is this, not `selectedIDs.count`, so what the
    /// bar promises and what the button does can't disagree.
    var selectedJobs: [RankedJob] { filteredResults.filter { selectedIDs.contains($0.id) } }
    var selectionCount: Int { selectedJobs.count }
    var hasSelection: Bool { !selectedJobs.isEmpty }
    /// Whether the bulk actions are wired in this build — the same use cases the per-row
    /// actions need, since the bulk paths reuse them.
    var supportsBulkActions: Bool { supportsRowActions }

    func clearSelection() { selectedIDs.removeAll() }

    /// Saves every selected, not-yet-tracked job to the Tracker. The listings go in **one**
    /// batch write (`SaveResultsUseCase` takes an array); statuses are per-id, so they loop.
    /// History refreshes once at the end — so the saved rows drop out of Results together —
    /// and enrichment runs after that, bounded, never blocking the list update.
    func saveSelectedToTracker() async {
        guard let markStatus else { return }
        let jobs = selectedJobs.filter { !isTracked($0) }    // don't downgrade a later stage
        guard !jobs.isEmpty else { clearSelection(); return }
        isBulkActing = true
        defer { isBulkActing = false }

        try? await saveResults?(jobs)                        // one batch write for the listings
        for job in jobs {
            _ = try? await markStatus(jobID: job.id, stage: .saved)
        }
        await refreshHistory()
        clearSelection()
        await enrichSavedJobs(jobs)
    }

    /// Fully forgets every selected job — the list rows, the saved listings, their statuses and
    /// any generated materials. Drops them from the list first so the UI responds immediately,
    /// then clears each from the store.
    func deleteSelected() async {
        let jobs = selectedJobs
        guard !jobs.isEmpty else { clearSelection(); return }
        isBulkActing = true
        defer { isBulkActing = false }

        let ids = Set(jobs.map(\.id))
        results.removeAll { ids.contains($0.id) }
        for id in ids { historyByID[id] = nil }
        clearSelection()
        onResultsRemoved?(ids)
        for id in ids { try? await deleteSavedJob?(jobID: id) }
    }

    // MARK: Row actions (Milestone V)

    /// Saves `job` to the Tracker by marking it `.saved` (Milestone V-B). Persists the
    /// listing first so the tracker join has it, then refreshes the badge. Idempotent — an
    /// already-tracked job keeps its current (possibly later) stage; it never downgrades.
    /// Then best-effort **enriches** the saved posting (v0.6.0 A-D) — enrichment runs *after*
    /// the save so the row drops out of Results immediately, never blocking on the LLM call.
    func saveToTracker(_ job: RankedJob) async {
        guard let markStatus else { return }
        if isTracked(job) { return }                       // don't downgrade a later stage
        try? await saveResults?([job])                     // ensure the listing is persisted
        _ = try? await markStatus(jobID: job.id, stage: .saved)
        await refreshHistory()
        await enrichSavedJobs([job])
    }

    /// Best-effort enrichment of just-saved jobs (v0.6.0 Milestone A-D + E): fetches each full
    /// posting page and re-persists the job carrying its **full text** (`fullDescription`, E)
    /// and/or structured **detail** (A), so the Tracker and generation have richer signal to
    /// work from. Skipped when enrichment isn't wired or a job is already captured; a
    /// fetch/LLM failure leaves that plain saved job untouched.
    ///
    /// Takes an array so a **bulk** save (v0.6.2 Milestone B) can't fan out one fetch+LLM call
    /// per selected job at once: they run through the same **sliding window** the search-side
    /// digest uses (`SearchAndRankUseCase.digestStream`), at most `maxConcurrentEnrichments` in
    /// flight. A single save is just the one-element case. Runs *after* the rows have dropped
    /// out of Results, so nothing waits on it.
    private func enrichSavedJobs(_ jobs: [RankedJob]) async {
        guard let enrichPosting else { return }
        let pending = jobs.filter { $0.listing.details == nil && $0.listing.fullDescription == nil }
        guard !pending.isEmpty else { return }

        let window = max(1, min(maxConcurrentEnrichments, pending.count))
        let enriched: [RankedJob] = await withTaskGroup(of: RankedJob?.self) { group in
            var next = 0
            func schedule(_ index: Int) {
                let job = pending[index]
                group.addTask {
                    guard let listing = try? await enrichPosting(job.listing),
                          listing != job.listing else { return nil }   // unchanged → nothing to swap
                    return RankedJob(listing: listing, match: job.match)
                }
            }
            while next < window { schedule(next); next += 1 }
            var found: [RankedJob] = []
            while let result = await group.next() {
                if let result { found.append(result) }
                if next < pending.count { schedule(next); next += 1 }
            }
            return found
        }

        guard !enriched.isEmpty else { return }
        try? await saveResults?(enriched)                   // one batch write
        for job in enriched {
            if let index = results.firstIndex(where: { $0.id == job.id }) {
                results[index] = job                        // reflect enrichment in the in-memory list
            }
        }
    }

    /// Fully forgets `job` (Milestone V-A): removes it from the list and, by decision, from
    /// the saved-jobs store along with its status and any generated materials.
    func delete(_ job: RankedJob) async {
        results.removeAll { $0.id == job.id }
        historyByID[job.id] = nil
        onResultsRemoved?([job.id])
        try? await deleteSavedJob?(jobID: job.id)
    }

    /// Loads previously-saved results when the list is empty, and (always) refreshes the
    /// history badges — a fresh search's results are never clobbered (Milestone S-C).
    func loadSavedIfNeeded() async {
        if let loadSavedJobs, results.isEmpty {
            isLoading = true
            if let saved = try? await loadSavedJobs(), !saved.isEmpty { results = saved }
            isLoading = false
        }
        await refreshHistory()
    }

    /// Replaces the in-memory result for `job.id` with `job` — e.g. after a "Regenerate result"
    /// in a detail window overwrote the store (v0.6.0 Milestone C) — so the list shows the
    /// refreshed score/reason without re-reading the whole set (which would clobber fresh,
    /// unsaved search results, per Milestone S-C). No-op if the job isn't currently listed.
    func applyRefreshed(_ job: RankedJob) {
        if let index = results.firstIndex(where: { $0.id == job.id }) {
            results[index] = job
        }
    }

    /// Reloads the per-job history map (e.g. after the detail sheet closes). Prefers the
    /// full three-source join; falls back to statuses only when history isn't wired.
    func refreshHistory() async {
        if let loadJobHistory, let history = try? await loadJobHistory() {
            historyByID = history
        } else if let loadTrackedJobs, let tracked = try? await loadTrackedJobs() {
            historyByID = Dictionary(
                tracked.map { ($0.id, JobHistory(isSaved: true, status: $0.status)) },
                uniquingKeysWith: { first, _ in first }
            )
        }
    }
}
