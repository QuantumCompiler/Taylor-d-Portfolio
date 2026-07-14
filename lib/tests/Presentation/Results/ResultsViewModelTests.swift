//
//  ResultsViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Results
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@MainActor
@Suite("ResultsViewModel")
struct ResultsViewModelTests {

    private func ranked(_ id: String) -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t", company: "c", location: "l", description: "d"),
            match: JobMatch(jobId: id, score: 50, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    /// A VM wired to real in-memory persistence for the row-action tests, over one store.
    private func makeRowActionVM(results: [RankedJob]) -> (ResultsViewModel, SavedJobsRepository, SavedStatusRepository, SavedApplicationsRepository) {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        let vm = ResultsViewModel(
            results: results,
            loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses),
            loadJobHistory: LoadJobHistoryUseCase(jobs: jobs, statuses: statuses, applications: apps),
            markStatus: MarkStatusUseCase(repository: statuses, now: { Date(timeIntervalSince1970: 0) }),
            saveResults: SaveResultsUseCase(repository: jobs),
            deleteSavedJob: DeleteSavedJobUseCase(jobs: jobs, statuses: statuses, applications: apps)
        )
        return (vm, jobs, statuses, apps)
    }

    @Test func emptyByDefault() {
        #expect(ResultsViewModel().isEmpty)
    }

    @Test func selectSetsSelectedJob() {
        let job = ranked("a")
        let vm = ResultsViewModel(results: [job])
        #expect(vm.isEmpty == false)
        vm.select(job)
        #expect(vm.selectedJob?.id == "a")
    }

    @Test func loadsSavedJobsWhenEmpty() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("saved-1")])
        let vm = ResultsViewModel(loadSavedJobs: LoadSavedJobsUseCase(repository: repo))

        #expect(vm.isEmpty)
        await vm.loadSavedIfNeeded()
        #expect(vm.results.map(\.id) == ["saved-1"])
    }

    @Test func loadDoesNotClobberExistingResults() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("saved-1")])
        // A search already populated results — loading saved must not overwrite them.
        let vm = ResultsViewModel(results: [ranked("fresh")], loadSavedJobs: LoadSavedJobsUseCase(repository: repo))

        await vm.loadSavedIfNeeded()
        #expect(vm.results.map(\.id) == ["fresh"])
    }

    // MARK: Row actions (Milestone V)

    @Test func saveToTrackerMarksSavedPersistsAndBadges() async throws {
        let (vm, jobs, statuses, _) = makeRowActionVM(results: [ranked("a")])
        #expect(vm.supportsRowActions)

        await vm.saveToTracker(ranked("a"))
        #expect(vm.isTracked(ranked("a")))
        #expect(vm.status(for: ranked("a"))?.stage == .saved)     // badge reflects .saved
        #expect(try await jobs.contains(jobID: "a"))              // listing persisted for the join
        #expect(try await statuses.status(forJobID: "a")?.stage == .saved)
    }

    @Test func saveToTrackerDoesNotDowngradeALaterStage() async throws {
        let (vm, jobs, statuses, _) = makeRowActionVM(results: [ranked("a")])
        try await jobs.save([ranked("a")])                                         // already a saved/tracked job…
        try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")  // …further along than .saved
        await vm.refreshHistory()
        #expect(vm.isTracked(ranked("a")))

        await vm.saveToTracker(ranked("a"))
        #expect(vm.status(for: ranked("a"))?.stage == .applied)   // not knocked back to .saved
    }

    @Test func deleteRemovesFromListAndForgetsEverything() async throws {
        let (vm, jobs, statuses, apps) = makeRowActionVM(results: [ranked("a"), ranked("b")])
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .applied), forJobID: "a")
        try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "", gapNote: ""), forJobID: "a")

        await vm.delete(ranked("a"))
        #expect(vm.results.map(\.id) == ["b"])                    // gone from the list
        #expect(try await jobs.contains(jobID: "a") == false)     // and from every store
        #expect(try await statuses.status(forJobID: "a") == nil)
        #expect(try await apps.kit(forJobID: "a") == nil)
    }

    @Test func rowActionsUnavailableWithoutWiring() {
        let vm = ResultsViewModel(results: [ranked("a")])
        #expect(vm.supportsRowActions == false)
    }

    // MARK: Filtering (Milestone W)

    private func ranked(_ id: String, score: Int, company: String = "Acme", location: String = "Remote") -> RankedJob {
        RankedJob(
            listing: JobListing(id: id, title: "t", company: company, location: location, description: "d"),
            match: JobMatch(jobId: id, score: score, reason: "", matchedSkills: [], missingSkills: [])
        )
    }

    @Test func filteredResultsCountsAndClear() {
        let vm = ResultsViewModel(results: [ranked("a", score: 80), ranked("b", score: 40), ranked("c", score: 60)])
        #expect(vm.filteredResults.count == 3)          // no filter ⇒ identity
        #expect(vm.totalCount == 3)

        vm.filter.minScore = 60
        #expect(vm.filteredResults.map(\.id) == ["a", "c"])
        #expect(vm.visibleCount == 2)
        #expect(vm.totalCount == 3)                     // total is unfiltered
        #expect(vm.isFilteredEmpty == false)

        vm.clearFilter()
        #expect(vm.filteredResults.count == 3)
        #expect(vm.filter.isActive == false)
    }

    @Test func isFilteredEmptyWhenFilterHidesEverything() {
        let vm = ResultsViewModel(results: [ranked("a", score: 40)])
        vm.filter.minScore = 90
        #expect(vm.filteredResults.isEmpty)
        #expect(vm.isFilteredEmpty)                     // distinct from "no results yet"
    }

    @Test func filterOptionsAreDistinctValuesFromResults() {
        let vm = ResultsViewModel(results: [
            ranked("a", score: 80, company: "Acme", location: "Remote"),
            ranked("b", score: 40, company: "Globex", location: "Lehi, UT"),
            ranked("c", score: 60, company: "Acme", location: "Remote"),
        ])
        #expect(vm.companyOptions == ["Acme", "Globex"])
        #expect(vm.locationOptions == ["Lehi, UT", "Remote"])
    }

    // MARK: Loading state (Milestone S-B)

    @Test func isLoadingResetsAfterLoadAndPopulates() async throws {
        let repo = SavedJobsRepository(store: InMemoryRecordStore())
        try await repo.save([ranked("a", score: 60)])
        let vm = ResultsViewModel(loadSavedJobs: LoadSavedJobsUseCase(repository: repo))
        #expect(vm.isLoading == false)          // nothing loading before appear
        await vm.loadSavedIfNeeded()
        #expect(vm.isLoading == false)          // and not left stuck on
        #expect(vm.results.map(\.id) == ["a"])
    }

    @Test func isLoadingStaysFalseWhenUnwiredOrAlreadyPopulated() async {
        #expect(ResultsViewModel().isLoading == false)
        // Results already present (from a search) → skips the load, no spinner.
        let vm = ResultsViewModel(results: [ranked("fresh", score: 50)],
                                  loadSavedJobs: nil)
        await vm.loadSavedIfNeeded()
        #expect(vm.isLoading == false)
    }

    // MARK: History story (Milestone S-C)

    @Test func historyBadgesReflectSeenGeneratedApplied() async throws {
        let (vm, jobs, statuses, apps) = makeRowActionVM(
            results: [ranked("seen"), ranked("applied"), ranked("generated"), ranked("fresh")]
        )
        // "seen": saved listing, no status, no kit.
        try await jobs.save([ranked("seen")])
        // "applied": saved + tracked at .applied.
        try await jobs.save([ranked("applied")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 10)), forJobID: "applied")
        // "generated": saved + tracked at .saved + a generated kit.
        try await jobs.save([ranked("generated")])
        try await statuses.save(ApplicationStatus(stage: .saved), forJobID: "generated")
        try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "C", gapNote: ""), forJobID: "generated")

        await vm.loadSavedIfNeeded()

        #expect(vm.history(for: ranked("seen")).facets == [.seen])
        #expect(vm.history(for: ranked("applied")).facets.first.map { $0 == .status(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 10))) } == true)
        #expect(vm.history(for: ranked("applied")).facets.contains(.generated) == false)
        let generated = vm.history(for: ranked("generated"))
        #expect(generated.isGenerated)
        #expect(generated.facets.contains(.generated))
        #expect(generated.status?.stage == .saved)
        #expect(vm.history(for: ranked("fresh")).facets.isEmpty)   // brand-new: no badges
    }

    @Test func loadKeepsFreshSearchResultsButStillPopulatesHistory() async throws {
        // A fresh search already put results in place; one of them was saved+generated before.
        let (vm, jobs, statuses, apps) = makeRowActionVM(results: [ranked("fresh"), ranked("known")])
        try await jobs.save([ranked("known")])
        try await statuses.save(ApplicationStatus(stage: .applied, appliedDate: Date(timeIntervalSince1970: 5)), forJobID: "known")
        try await apps.save(ApplicationKit(resumeMarkdown: "R", coverLetter: "", gapNote: ""), forJobID: "known")

        await vm.loadSavedIfNeeded()

        #expect(vm.results.map(\.id) == ["fresh", "known"])        // fresh search not clobbered
        #expect(vm.history(for: ranked("fresh")).hasHistory == false)
        let known = vm.history(for: ranked("known"))
        #expect(known.status?.stage == .applied)
        #expect(known.isGenerated)
    }

    // MARK: Tracked jobs leave the Results list (v0.4.1 Milestone C)

    @Test func trackedJobsAreExcludedFromResults() async throws {
        let (vm, jobs, statuses, _) = makeRowActionVM(results: [ranked("a"), ranked("b")])
        try await jobs.save([ranked("a")])
        try await statuses.save(ApplicationStatus(stage: .saved), forJobID: "a")   // a is in the Tracker
        await vm.refreshHistory()

        // a (tracked) drops out; only the un-triaged b shows, and the count reflects it.
        #expect(vm.untrackedResults.map(\.id) == ["b"])
        #expect(vm.filteredResults.map(\.id) == ["b"])
        #expect(vm.totalCount == 1)
        #expect(vm.results.map(\.id) == ["a", "b"])   // underlying list is untouched
        #expect(vm.allResultsTracked == false)
    }

    @Test func savingAJobRemovesItFromResultsLive() async throws {
        let (vm, _, _, _) = makeRowActionVM(results: [ranked("a"), ranked("b")])
        #expect(vm.filteredResults.map(\.id) == ["a", "b"])

        await vm.saveToTracker(ranked("a"))                // marks .saved + refreshes history

        #expect(vm.filteredResults.map(\.id) == ["b"])     // gone from the list immediately
    }

    @Test func allResultsTrackedWhenEveryJobIsSaved() async throws {
        let (vm, _, _, _) = makeRowActionVM(results: [ranked("a"), ranked("b")])
        await vm.saveToTracker(ranked("a"))
        await vm.saveToTracker(ranked("b"))

        #expect(vm.untrackedResults.isEmpty)
        #expect(vm.allResultsTracked)                      // distinct empty state
        #expect(vm.isEmpty == false)                       // results are still loaded
    }

    @Test func filterStillAppliesToTheUntrackedSet() async throws {
        let (vm, jobs, statuses, _) = makeRowActionVM(
            results: [ranked("a", score: 80), ranked("b", score: 40), ranked("c", score: 60)]
        )
        try await jobs.save([ranked("a", score: 80)])
        try await statuses.save(ApplicationStatus(stage: .saved), forJobID: "a")   // a tracked → excluded
        await vm.refreshHistory()

        vm.filter.minScore = 60
        // From the un-tracked set {b:40, c:60}, min-rank 60 keeps only c.
        #expect(vm.filteredResults.map(\.id) == ["c"])
        #expect(vm.totalCount == 2)                        // un-tracked total, not 3
    }

    // MARK: Enrich on save (v0.6.0 Milestone A-D)

    @Test func savingEnrichesAndPersistsTheDetails() async throws {
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        let provider = EnrichingStubProvider(details: PostingDetails(workTypeRaw: "remote", aboutCompany: "Fintech."))
        let vm = ResultsViewModel(
            results: [ranked("a")],
            loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses),
            loadJobHistory: LoadJobHistoryUseCase(jobs: jobs, statuses: statuses, applications: apps),
            markStatus: MarkStatusUseCase(repository: statuses, now: { Date(timeIntervalSince1970: 0) }),
            saveResults: SaveResultsUseCase(repository: jobs),
            deleteSavedJob: DeleteSavedJobUseCase(jobs: jobs, statuses: statuses, applications: apps),
            enrichPosting: EnrichPostingUseCase(provider: provider, postingSource: nil)   // snippet-only
        )

        await vm.saveToTracker(ranked("a"))

        // The persisted saved job now carries the enriched details…
        let saved = try await jobs.savedJobs().first { $0.id == "a" }
        #expect(saved?.listing.details?.workType == .remote)
        #expect(saved?.listing.details?.aboutCompany == "Fintech.")
        // …and the in-memory list reflects it too.
        #expect(vm.results.first { $0.id == "a" }?.listing.details != nil)
    }

    @Test func savingWithoutEnrichmentWiringLeavesDetailsNil() async throws {
        let (vm, jobs, _, _) = makeRowActionVM(results: [ranked("a")])   // no enrichPosting wired
        await vm.saveToTracker(ranked("a"))
        let saved = try await jobs.savedJobs().first { $0.id == "a" }
        #expect(saved?.listing.details == nil)   // save still works; nothing enriched
    }

    @Test func savingCapturesFullDescriptionFromThePostingPage() async throws {
        // v0.6.0 Milestone E — a fuller posting page is captured on save, even when the
        // structuring pass finds nothing to add.
        let store = InMemoryRecordStore()
        let jobs = SavedJobsRepository(store: store)
        let statuses = SavedStatusRepository(store: store)
        let apps = SavedApplicationsRepository(store: store)
        let page = String(repeating: "Full posting page. ", count: 20)
        let provider = EnrichingStubProvider(details: PostingDetails())   // no structure found
        let job = RankedJob(
            listing: JobListing(id: "u", title: "t", company: "c", location: "l",
                                description: "snippet", url: URL(string: "https://ex.com/j")!),
            match: JobMatch(jobId: "u", score: 50, reason: "", matchedSkills: [], missingSkills: [])
        )
        let vm = ResultsViewModel(
            results: [job],
            loadTrackedJobs: LoadTrackedJobsUseCase(jobs: jobs, statuses: statuses),
            loadJobHistory: LoadJobHistoryUseCase(jobs: jobs, statuses: statuses, applications: apps),
            markStatus: MarkStatusUseCase(repository: statuses, now: { Date(timeIntervalSince1970: 0) }),
            saveResults: SaveResultsUseCase(repository: jobs),
            deleteSavedJob: DeleteSavedJobUseCase(jobs: jobs, statuses: statuses, applications: apps),
            enrichPosting: EnrichPostingUseCase(provider: provider, postingSource: ResultsReadableStub(pageText: page))
        )

        await vm.saveToTracker(job)

        let saved = try await jobs.savedJobs().first { $0.id == "u" }
        #expect(saved?.listing.fullDescription == page)   // full text persisted…
        #expect(saved?.listing.details == nil)            // …even though structuring found nothing
    }
}

/// A `JobPostingSource` whose `readableText` returns a canned full page.
private struct ResultsReadableStub: JobPostingSource {
    var pageText: String
    func fetchPosting(from url: URL) async throws -> JobListing { throw JobPostingSourceError.unreadable }
    func extractPosting(fromText text: String, sourceURL: URL?) async throws -> JobListing { throw JobPostingSourceError.unreadable }
    func readableText(from url: URL) async throws -> String { pageText }
}

/// An `LLMProvider` that returns a canned `PostingDetails` (only `enrichPosting` matters here).
private struct EnrichingStubProvider: LLMProvider {
    var details: PostingDetails
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        .init(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        .init(company: "", roleTitle: "", mustHaveKeywords: [], niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        .init(resumeMarkdown: "", coverLetter: "", gapNote: "")
    }
    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails { details }
    // Cleaning is a no-op here (echo the page), so the captured full text equals the fetched page.
    func cleanPostingText(fromPageText pageText: String) async throws -> String { pageText }
}
