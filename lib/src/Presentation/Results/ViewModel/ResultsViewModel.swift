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

    /// The (un-tracked) results after applying the live `filter` — what the list shows.
    /// Tracked jobs are already excluded, so no row is tracked here.
    var filteredResults: [RankedJob] {
        filter.apply(to: untrackedResults, isTracked: { _ in false })
    }
    var visibleCount: Int { filteredResults.count }
    var totalCount: Int { untrackedResults.count }
    /// True when a filter is active but hides every un-tracked row (a distinct empty state).
    var isFilteredEmpty: Bool { !untrackedResults.isEmpty && filter.isActive && filteredResults.isEmpty }

    /// Distinct locations present in the shown (un-tracked) results, for the location picker.
    var locationOptions: [String] { distinct(untrackedResults.map(\.listing.location)) }
    /// Distinct companies present in the shown (un-tracked) results, for the company picker.
    var companyOptions: [String] { distinct(untrackedResults.map(\.listing.company)) }

    func clearFilter() { filter = ResultsFilter() }

    private func distinct(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result = [String]()
        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
        }
        return result.sorted()
    }

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
        await enrichSavedJob(job)
    }

    /// Best-effort enrichment of a just-saved job (v0.6.0 Milestone A-D + E): fetches the full
    /// posting page and re-persists the job carrying its **full text** (`fullDescription`, E)
    /// and/or structured **detail** (A), so the Tracker and generation have richer signal to
    /// work from. Skipped when enrichment isn't wired or the job is already captured; a
    /// fetch/LLM failure leaves the plain saved job untouched.
    private func enrichSavedJob(_ job: RankedJob) async {
        guard let enrichPosting,
              job.listing.details == nil, job.listing.fullDescription == nil else { return }
        guard let listing = try? await enrichPosting(job.listing), listing != job.listing else { return }
        let enriched = RankedJob(listing: listing, match: job.match)
        try? await saveResults?([enriched])
        if let index = results.firstIndex(where: { $0.id == enriched.id }) {
            results[index] = enriched                       // reflect enrichment in the in-memory list
        }
    }

    /// Fully forgets `job` (Milestone V-A): removes it from the list and, by decision, from
    /// the saved-jobs store along with its status and any generated materials.
    func delete(_ job: RankedJob) async {
        results.removeAll { $0.id == job.id }
        historyByID[job.id] = nil
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
