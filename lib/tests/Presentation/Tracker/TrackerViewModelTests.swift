//
//  TrackerViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Tracker
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@MainActor
@Suite("TrackerViewModel")
struct TrackerViewModelTests {

    /// A ranked job. The company / location / score defaults keep the older tests unchanged;
    /// the filter tests (v0.6.2 Milestone C) vary them.
    private func ranked(_ id: String, company: String = "c", location: String = "l", score: Int = 50) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t-\(id)", company: company, location: location, description: "d"),
            match: JobMatch(jobId: id, score: score, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    /// Builds a VM over an in-memory store seeded with saved jobs + statuses.
    private func makeVM(seed: (SavedJobsRepository, SavedStatusRepository) async throws -> Void) async throws -> TrackerViewModel {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        try await seed(jobs, statuses)
        return TrackerViewModel(loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses))
    }

    @Test func emptyWhenNothingTracked() async throws {
        let vm = try await makeVM { jobs, _ in try await jobs.save([self.ranked("a")]) }
        await vm.load()
        #expect(vm.isEmpty)
    }

    @Test func listsTrackedJobsMostRecentFirst() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a"), self.ranked("b")])
            try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: "a")
            try await statuses.save(ApplicationStatus(stage: .offer, offerDate: Date(timeIntervalSince1970: 900)), forJobID: "b")
        }
        await vm.load()
        // The default sort (most-recent activity) is applied on read by jobs(in:); the raw
        // trackedJobs store is order-agnostic (Milestone H).
        #expect(vm.jobs(in: .all).map(\.id) == ["b", "a"])   // b's date is later → first
        #expect(vm.isEmpty == false)
    }

    // MARK: Stage-filtered sub-views (v0.4.0 Milestone B)

    @Test func jobsInSectionFilterByStage() async throws {
        // One job per stage; each lands in exactly its own tab, and every one under All
        // (v0.4.1 Milestone D — a tab per status; Saved/Accepted/… now directly reachable).
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("sv"), self.ranked("ap"), self.ranked("iv"), self.ranked("of"),
                                 self.ranked("ac"), self.ranked("dc"), self.ranked("rj"), self.ranked("wd")])
            try await statuses.save(ApplicationStatus(stage: .saved), forJobID: "sv")
            try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "ap")
            try await statuses.save(ApplicationStatus(stage: .interviewing), forJobID: "iv")
            try await statuses.save(ApplicationStatus(stage: .offer), forJobID: "of")
            try await statuses.save(ApplicationStatus(stage: .accepted), forJobID: "ac")
            try await statuses.save(ApplicationStatus(stage: .declined), forJobID: "dc")
            try await statuses.save(ApplicationStatus(stage: .rejected), forJobID: "rj")
            try await statuses.save(ApplicationStatus(stage: .withdrawn), forJobID: "wd")
        }
        await vm.load()

        #expect(Set(vm.jobs(in: .all).map(\.id)) == ["sv", "ap", "iv", "of", "ac", "dc", "rj", "wd"])
        #expect(vm.jobs(in: .saved).map(\.id) == ["sv"])
        #expect(vm.jobs(in: .applied).map(\.id) == ["ap"])
        #expect(vm.jobs(in: .interviewing).map(\.id) == ["iv"])
        #expect(vm.jobs(in: .offer).map(\.id) == ["of"])          // Offer only — not accepted
        #expect(vm.jobs(in: .accepted).map(\.id) == ["ac"])       // Accepted is its own tab now
        #expect(vm.jobs(in: .declined).map(\.id) == ["dc"])
        #expect(vm.jobs(in: .rejected).map(\.id) == ["rj"])       // rejected now has its own tab
        #expect(vm.jobs(in: .withdrawn).map(\.id) == ["wd"])
    }

    @Test func selectSetsSelectedJob() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a")])
            try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")
        }
        await vm.load()
        vm.select(ranked("a"))
        #expect(vm.selectedJob?.id == "a")
    }

    // MARK: Loading state (Milestone S-B)

    @Test func isLoadingIsFalseInitiallyAndResetsAfterLoad() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a")])
            try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")
        }
        #expect(vm.isLoading == false)          // no spinner before the load runs
        await vm.load()
        #expect(vm.isLoading == false)          // and it isn't left stuck on
        #expect(vm.isEmpty == false)
    }

    @Test func isLoadingStaysFalseWhenUnwired() async {
        let vm = TrackerViewModel()             // no loadTrackedJobs
        await vm.load()
        #expect(vm.isLoading == false)
    }

    // MARK: History story (Milestone S-C)

    @Test func historyIncludesGeneratedFacetWhenWired() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 10)), forJobID: "a")
        try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "", gapNote: ""), forJobID: "a")
        let vm = TrackerViewModel(
            loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses),
            loadJobHistory: LoadJobHistoryUseCase(jobs: jobs, statuses: statuses, applications: apps)
        )

        await vm.load()

        let history = vm.history(for: ranked("a"))
        #expect(history.status?.stage == .applied)
        #expect(history.isGenerated)
        #expect(history.facets.contains(.generated))
    }

    @Test func historyFallsBackToTrackedStatusWhenUnwired() async throws {
        // Without loadJobHistory, the row still shows its status (a tracked job is saved).
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a")])
            try await statuses.save(ApplicationStatus(stage: .interviewing, interviewDate: Date(timeIntervalSince1970: 20)), forJobID: "a")
        }
        await vm.load()
        let history = vm.history(for: ranked("a"))
        #expect(history.isSaved)
        #expect(history.status?.stage == .interviewing)
        #expect(history.isGenerated == false)
    }

    // MARK: Row actions — remove from Tracker (v0.5.0)

    /// Builds a VM wired with the untrack + delete use cases over one in-memory store.
    private func makeActionableVM(
        store: InMemoryRecordStore,
        jobs: SavedJobsRepository, statuses: SavedStatusRepository, applications: SavedApplicationsRepository
    ) -> TrackerViewModel {
        TrackerViewModel(
            loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses),
            untrackJob: UntrackJobUseCase(statuses: statuses),
            deleteSavedJob: DeleteSavedJobUseCase(jobs: jobs, statuses: statuses, applications: applications)
        )
    }

    @Test func returnToResultsClearsStatusButKeepsListing() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: "a")
        let vm = makeActionableVM(store: store, jobs: jobs, statuses: statuses, applications: apps)
        await vm.load()
        #expect(vm.trackedJobs.map(\.id) == ["a"])

        await vm.returnToResults(ranked("a"))

        #expect(vm.trackedJobs.isEmpty)
        // Status cleared (so it's un-tracked → returns to Results)…
        #expect(try await statuses.status(forJobID: "a") == nil)
        // …but the saved listing is kept.
        #expect(try await jobs.savedJobs().map(\.id) == ["a"])
    }

    @Test func deleteForgetsListingStatusAndMaterials() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: "a")
        try await apps.save(ApplicationKit(resumeMarkdown: "r", coverLetter: "c", gapNote: ""), forJobID: "a")
        let vm = makeActionableVM(store: store, jobs: jobs, statuses: statuses, applications: apps)
        await vm.load()

        await vm.delete(ranked("a"))

        #expect(vm.trackedJobs.isEmpty)
        #expect(try await jobs.savedJobs().isEmpty)
        #expect(try await statuses.status(forJobID: "a") == nil)
        #expect(try await apps.kit(forJobID: "a") == nil)
    }

    /// The gate the row icons, context menu and swipes all share (v0.6.2 Milestone A) — every
    /// affordance appears only when **both** use cases are wired, so no path can half-work.
    @Test func rowActionsRequireBothUseCases() async throws {
        #expect(TrackerViewModel().supportsRowActions == false)

        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        #expect(TrackerViewModel(untrackJob: UntrackJobUseCase(statuses: statuses)).supportsRowActions == false)
        #expect(TrackerViewModel(
            deleteSavedJob: DeleteSavedJobUseCase(jobs: jobs, statuses: statuses, applications: apps)
        ).supportsRowActions == false)
        #expect(TrackerViewModel(
            untrackJob: UntrackJobUseCase(statuses: statuses),
            deleteSavedJob: DeleteSavedJobUseCase(jobs: jobs, statuses: statuses, applications: apps)
        ).supportsRowActions)
    }

    // MARK: Filter (v0.6.2 Milestone C — the reused ResultsFilter)

    /// The filter narrows rows **within** the selected stage tab, and composes with the sort
    /// (filter first, then order what survives).
    @Test func filterAppliesWithinTheStageTabAndBeforeTheSort() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        try await jobs.save([
            ranked("a", company: "Alpha", score: 90),
            ranked("b", company: "Beta", score: 30),
            ranked("c", company: "Alpha", score: 60),
        ])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: "a")
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 200)), forJobID: "b")
        try await statuses.save(ApplicationStatus(stage: .interviewing, interviewDate: Date(timeIntervalSince1970: 300)), forJobID: "c")
        let vm = TrackerViewModel(loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses))
        await vm.load()

        vm.filter.company = "Alpha"
        #expect(vm.jobs(in: .all).map(\.id) == ["c", "a"])       // default sort: most recent first
        #expect(vm.jobs(in: .applied).map(\.id) == ["a"])        // and only within the tab
        #expect(vm.jobs(in: .interviewing).map(\.id) == ["c"])

        vm.sort = TrackerSort(key: .matchScore, direction: .ascending)
        #expect(vm.jobs(in: .all).map(\.id) == ["c", "a"])       // 60 then 90, filter still applied
    }

    /// Everything in the Tracker is tracked, so the (hidden) tracked facet must not exclude
    /// rows if a filter carrying it is ever applied.
    @Test func trackedFacetNeverHidesTrackedRows() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a")])
            try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")
        }
        await vm.load()
        vm.filter.trackedStatus = .tracked
        #expect(vm.jobs(in: .all).map(\.id) == ["a"])
        vm.filter.trackedStatus = .untracked                    // would hide everything…
        #expect(vm.jobs(in: .all).isEmpty)                       // …which is why the UI hides the facet
    }

    /// Counts and options drive the bar: the denominator and the pickers come from the tab's
    /// rows **before** filtering, so choosing one option doesn't erase the others.
    @Test func countsAndOptionsComeFromTheUnfilteredTab() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        try await jobs.save([
            ranked("a", company: "Alpha", location: "Denver"),
            ranked("b", company: "Beta", location: "Remote"),
        ])
        for id in ["a", "b"] {
            try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: id)
        }
        let vm = TrackerViewModel(loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses))
        await vm.load()

        vm.filter.company = "Alpha"
        #expect(vm.visibleCount(in: .applied) == 1)
        #expect(vm.totalCount(in: .applied) == 2)
        #expect(vm.companyOptions(in: .applied) == ["Alpha", "Beta"])     // both still offered
        #expect(vm.locationOptions(in: .applied) == ["Denver", "Remote"])
        #expect(vm.isFilteredEmpty(in: .applied) == false)
    }

    /// "A filter hid this tab's rows" is a distinct state from "this stage is empty" — the one
    /// that keeps the filter bar reachable so it can be cleared.
    @Test func isFilteredEmptyOnlyWhenAFilterHidesRealRows() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("a", company: "Alpha")])
            try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")
        }
        await vm.load()

        #expect(vm.isFilteredEmpty(in: .applied) == false)      // no filter active
        #expect(vm.isFilteredEmpty(in: .offer) == false)        // genuinely empty stage, not filtered

        vm.filter.company = "Nope"
        #expect(vm.isFilteredEmpty(in: .applied))               // rows exist but are hidden
        #expect(vm.isFilteredEmpty(in: .offer) == false)        // still just an empty stage

        vm.clearFilter()
        #expect(vm.filter.isActive == false)
        #expect(vm.jobs(in: .applied).map(\.id) == ["a"])
    }

    // MARK: Multi-select + bulk actions (v0.6.2 Milestone B)

    /// Selection is scoped to the **shown** stage tab, so a row selected under All can't be
    /// removed while a different tab is open.
    @Test func selectionIsScopedToTheShownStageTab() async throws {
        let vm = try await makeVM { jobs, statuses in
            try await jobs.save([self.ranked("ap"), self.ranked("iv")])
            try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "ap")
            try await statuses.save(ApplicationStatus(stage: .interviewing), forJobID: "iv")
        }
        await vm.load()
        vm.selectedIDs = ["ap", "iv"]

        #expect(vm.selectionCount(in: .all) == 2)
        #expect(vm.selectionCount(in: .applied) == 1)
        #expect(vm.selectedJobs(in: .applied).map(\.id) == ["ap"])
        #expect(vm.hasSelection(in: .offer) == false)
    }

    @Test func bulkReturnToResultsUntracksEverySelectedJob() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        try await jobs.save([ranked("a"), ranked("b"), ranked("c")])
        for id in ["a", "b", "c"] {
            try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: id)
        }
        let vm = makeActionableVM(store: store, jobs: jobs, statuses: statuses, applications: apps)
        await vm.load()
        vm.selectedIDs = ["a", "c"]

        await vm.returnSelectedToResults(in: .all)

        #expect(vm.jobs(in: .all).map(\.id) == ["b"])
        // Untracked, so their statuses are gone but every listing is kept.
        #expect(try await statuses.status(forJobID: "a") == nil)
        #expect(try await statuses.status(forJobID: "c") == nil)
        #expect(try await statuses.status(forJobID: "b")?.stage == .applied)
        #expect(Set(try await jobs.savedJobs().map(\.id)) == ["a", "b", "c"])
        #expect(vm.selectedIDs.isEmpty)
        #expect(vm.isBulkActing == false)
    }

    @Test func bulkDeleteForgetsEverySelectedJobOnly() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        try await jobs.save([ranked("a"), ranked("b"), ranked("c")])
        for id in ["a", "b", "c"] {
            try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: id)
            try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "", gapNote: ""), forJobID: id)
        }
        let vm = makeActionableVM(store: store, jobs: jobs, statuses: statuses, applications: apps)
        await vm.load()
        vm.selectedIDs = ["a", "c"]

        await vm.deleteSelected(in: .all)

        #expect(vm.jobs(in: .all).map(\.id) == ["b"])
        for id in ["a", "c"] {
            #expect(try await jobs.savedJobs().contains { $0.id == id } == false)
            #expect(try await statuses.status(forJobID: id) == nil)
            #expect(try await apps.kit(forJobID: id) == nil)
        }
        #expect(try await apps.kit(forJobID: "b") != nil)     // untouched
        #expect(vm.selectedIDs.isEmpty)
    }

    /// An empty selection is a no-op, not a wipe.
    @Test func bulkRemovalsWithNothingSelectedDoNothing() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: "a")
        let vm = makeActionableVM(store: store, jobs: jobs, statuses: statuses, applications: apps)
        await vm.load()

        await vm.returnSelectedToResults(in: .all)
        await vm.deleteSelected(in: .all)

        #expect(vm.jobs(in: .all).map(\.id) == ["a"])
        #expect(try await statuses.status(forJobID: "a")?.stage == .applied)
    }

    /// Both removals are unwired no-ops rather than crashes when persistence is unavailable —
    /// the affordances are hidden then, but the VM methods must stay safe to call.
    @Test func removalsAreNoOpsWhenUnwired() async {
        let vm = TrackerViewModel()
        await vm.returnToResults(ranked("a"))
        await vm.delete(ranked("a"))
        #expect(vm.trackedJobs.isEmpty)
    }

    /// Whichever affordance triggers it — row icon, context menu or swipe — a removal drops
    /// only its own row; the rest of the Tracker is untouched.
    @Test func removingOneJobLeavesTheOthers() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        try await jobs.save([ranked("a"), ranked("b")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 100)), forJobID: "a")
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 200)), forJobID: "b")
        let vm = makeActionableVM(store: store, jobs: jobs, statuses: statuses, applications: apps)
        await vm.load()

        await vm.returnToResults(ranked("b"))
        #expect(vm.jobs(in: .all).map(\.id) == ["a"])

        await vm.delete(ranked("a"))
        #expect(vm.jobs(in: .all).isEmpty)
        // "b" was only untracked, so its listing survives; "a" was deleted outright.
        #expect(try await jobs.savedJobs().map(\.id) == ["b"])
    }
}
