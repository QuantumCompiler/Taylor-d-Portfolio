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

    private func ranked(_ id: String) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t-\(id)", company: "c", location: "l", description: "d"),
            match: JobMatch(jobId: id, score: 50, reason: "", matchedSkills: [], missingSkills: [])
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

    @Test func rowActionsRequireBothUseCases() {
        #expect(TrackerViewModel().supportsRowActions == false)
    }
}
