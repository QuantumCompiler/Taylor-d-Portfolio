//
//  SearchViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Search
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// A `JobSource` that fails for specific titles, for the partial-failure warning test.
private struct FailingTitleJobSource: JobSource {
    var byTitle: [String: [JobListing]] = [:]
    var failingTitles: Set<String> = []
    struct Boom: Error {}
    func search(_ query: JobQuery) async throws -> [JobListing] {
        if failingTitles.contains(query.keywords) { throw Boom() }
        return byTitle[query.keywords] ?? []
    }
}

/// A `JobSource` that records the last `JobQuery` it was handed (to assert request assembly).
private actor CapturingJobSource: JobSource {
    private(set) var lastQuery: JobQuery?
    func search(_ query: JobQuery) async throws -> [JobListing] {
        lastQuery = query
        return []
    }
}

/// A `JobPostingSource` stub for the link/paste flow: returns a canned listing or throws.
private struct StubPostingSource: JobPostingSource {
    var listing = JobListing(id: "link-1", title: "iOS Engineer", company: "Acme", location: "Remote", description: "Swift.")
    var error: Error?
    func fetchPosting(from url: URL) async throws -> JobListing {
        if let error { throw error }
        return listing
    }
    func extractPosting(fromText text: String, sourceURL: URL?) async throws -> JobListing {
        if let error { throw error }
        return listing
    }
}

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    private func makeVM(
        jobs: [JobListing] = [],
        matches: [JobMatch] = [],
        configuredProviderIDs: Set<String> = Set(JobProviderRegistry.all.map(\.id)),
        roleTitleStore: RoleTitleStore = RoleTitleStore(store: PresentationMemoryStore())
    ) -> SearchViewModel {
        let ranker = JobRanker(provider: PresentationStubProvider(matches: matches), shortlistLimit: 10)
        let useCase = SearchAndRankUseCase(jobSource: PresentationStubJobSource(jobs: jobs), ranker: ranker)
        return SearchViewModel(searchAndRank: useCase, roleTitleStore: roleTitleStore,
                               configuredProviderIDs: configuredProviderIDs)
    }

    /// Builds a VM with the link-fetch flow wired to `postingSource`.
    private func makeLinkVM(postingSource: StubPostingSource) -> SearchViewModel {
        let searchUseCase = SearchAndRankUseCase(
            jobSource: PresentationStubJobSource(jobs: []),
            ranker: JobRanker(provider: PresentationStubProvider())
        )
        let fetch = FetchPostingUseCase(
            postingSource: postingSource,
            ranker: JobRanker(provider: PresentationStubProvider())
        )
        return SearchViewModel(
            searchAndRank: searchUseCase,
            roleTitleStore: RoleTitleStore(store: PresentationMemoryStore()),
            fetchPosting: fetch
        )
    }

    private var profile: CandidateProfile {
        CandidateProfile(seniority: "S", yearsExperience: 1, coreSkills: [], domains: [],
                         targetTitles: ["iOS Engineer", "Swift Developer"], summary: "")
    }

    @Test func searchWithoutProfileSetsError() async {
        let vm = makeVM()
        vm.titleInput = "swift"
        await vm.search()
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    @Test func searchWithProfileProducesResults() async {
        let jobs = [JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")]
        let matches = [JobMatch(jobId: "a", score: 70, reason: "", matchedSkills: [], missingSkills: [])]
        let vm = makeVM(jobs: jobs, matches: matches)
        vm.profile = profile
        vm.titleInput = "iOS Engineer"       // searched even without adding a chip
        await vm.search()
        #expect(vm.results.map(\.id) == ["a"])
        #expect(vm.errorMessage == nil)
        #expect(vm.isSearching == false)
    }

    @Test func canSearchRequiresProfileAndAtLeastOneTitle() {
        let vm = makeVM()
        vm.titles = []                        // clear the profile-seeded chips
        #expect(vm.canSearch == false)        // no profile, no title
        vm.titleInput = "swift"
        #expect(vm.canSearch == false)        // still no profile
        vm.profile = profile
        vm.titles = []                        // ignore seeding for this assertion
        #expect(vm.canSearch == true)         // profile + the in-progress title
    }

    @Test func profileSeedsTitleChipsFromTargetTitles() {
        let vm = makeVM()
        #expect(vm.titles.isEmpty)
        vm.profile = profile
        #expect(vm.titles == ["iOS Engineer", "Swift Developer"])
    }

    @Test func addAndRemoveChips() {
        let vm = makeVM()
        vm.titleInput = "Backend Engineer"
        vm.addTitle()
        #expect(vm.titles.contains("Backend Engineer"))
        #expect(vm.titleInput.isEmpty)        // input cleared after adding
        vm.addTitle("backend engineer")       // case-insensitive dedupe
        #expect(vm.titles.filter { $0.lowercased() == "backend engineer" }.count == 1)
        vm.removeTitle("Backend Engineer")
        #expect(!vm.titles.contains("Backend Engineer"))
    }

    @Test func longPressSavesChipToPersistedCommonTitles() {
        let backing = PresentationMemoryStore()
        let vm = makeVM(roleTitleStore: RoleTitleStore(store: backing))
        vm.addTitle("Backend Engineer")
        #expect(!vm.isCommonRoleTitle("Backend Engineer"))

        vm.saveAsCommonRoleTitle("Backend Engineer")
        #expect(vm.isCommonRoleTitle("Backend Engineer"))
        #expect(vm.commonRoleTitles.contains("Backend Engineer"))
        // Case-insensitive dedupe — saving again is a no-op.
        vm.saveAsCommonRoleTitle("backend engineer")
        #expect(vm.commonRoleTitles.filter { $0.lowercased() == "backend engineer" }.count == 1)

        // Persisted: a fresh VM over the same backing loads it.
        let reloaded = makeVM(roleTitleStore: RoleTitleStore(store: backing))
        #expect(reloaded.commonRoleTitles.contains("Backend Engineer"))
    }

    @Test func togglingACommonTitleIncludesItInTheSearch() {
        let store = RoleTitleStore(store: PresentationMemoryStore())
        store.save(["Platform Engineer"])
        let vm = makeVM(roleTitleStore: store)
        vm.profile = profile
        vm.titles = []                        // ignore seeding; start clean

        #expect(!vm.isCommonTitleSelected("Platform Engineer"))
        #expect(!vm.effectiveTitles.contains("Platform Engineer"))

        vm.toggleCommonTitle("Platform Engineer")
        #expect(vm.isCommonTitleSelected("Platform Engineer"))
        #expect(vm.effectiveTitles.contains("Platform Engineer"))
        #expect(vm.canSearch)                 // a selected common title alone enables search

        vm.toggleCommonTitle("Platform Engineer")
        #expect(!vm.isCommonTitleSelected("Platform Engineer"))
        #expect(!vm.effectiveTitles.contains("Platform Engineer"))
    }

    @Test func removingACommonTitleDeletesFromLibraryAndDeselects() {
        let backing = PresentationMemoryStore()
        let store = RoleTitleStore(store: backing)
        store.save(["Platform Engineer"])
        let vm = makeVM(roleTitleStore: store)
        vm.toggleCommonTitle("Platform Engineer")
        #expect(vm.isCommonTitleSelected("Platform Engineer"))

        vm.removeCommonRoleTitle("Platform Engineer")
        #expect(!vm.commonRoleTitles.contains("Platform Engineer"))   // gone from library
        #expect(!vm.isCommonTitleSelected("Platform Engineer"))       // and de-selected
        #expect(!vm.effectiveTitles.contains("Platform Engineer"))
        // Removal is persisted.
        #expect(RoleTitleStore(store: backing).load().isEmpty)
    }

    @Test func partialFailureSetsWarningNotError() async {
        let source = FailingTitleJobSource(
            byTitle: ["good": [JobListing(id: "1", title: "t", company: "c", location: "l", description: "d")]],
            failingTitles: ["bad"]
        )
        let useCase = SearchAndRankUseCase(
            jobSource: source,
            ranker: JobRanker(provider: PresentationStubProvider(
                matches: [JobMatch(jobId: "1", score: 50, reason: "", matchedSkills: [], missingSkills: [])]
            ), shortlistLimit: 10)
        )
        let vm = SearchViewModel(searchAndRank: useCase, roleTitleStore: RoleTitleStore(store: PresentationMemoryStore()))
        vm.profile = profile
        vm.titles = ["good", "bad"]
        await vm.search()
        #expect(vm.results.map(\.id) == ["1"])
        #expect(vm.errorMessage == nil)
        #expect(vm.warningMessage?.contains("bad") == true)
    }

    @Test func noConfiguredProviderDisablesSearch() async {
        let vm = makeVM(configuredProviderIDs: [])   // no provider has a key
        vm.profile = profile
        vm.titleInput = "swift"
        #expect(vm.canSearch == false)
        #expect(vm.unavailableMessage != nil)

        await vm.search()
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage == vm.unavailableMessage)
    }

    @Test func configuredProviderHasNoUnavailableBanner() {
        #expect(makeVM().unavailableMessage == nil)   // defaults to all providers configured
    }

    // MARK: Provider selection (Milestone H)

    @Test func searchRequiresAtLeastOneSelectedConfiguredProvider() {
        let vm = makeVM(configuredProviderIDs: ["adzuna"])   // only Adzuna configured
        vm.profile = profile
        vm.titleInput = "swift"
        #expect(vm.canSearch)                                // adzuna selected + configured

        vm.setProvider("adzuna", selected: false)            // deselect the only configured one
        #expect(!vm.canSearch)
        #expect(vm.unavailableMessage != nil)
    }

    @Test func buildRequestCarriesTheSelectedProviders() {
        let vm = makeVM(configuredProviderIDs: ["adzuna", "jsearch"])
        vm.titleInput = "swift"
        vm.setProvider("jsearch", selected: false)           // Adzuna only
        #expect(vm.buildRequest().sources == ["adzuna"])
    }

    @Test func errorMessagesAreActionable() {
        // Search-stage failures.
        #expect(SearchViewModel.message(for: HTTPError.status(code: 401, body: Data())).contains("credentials"))
        #expect(SearchViewModel.message(for: HTTPError.status(code: 429, body: Data())).contains("Wait"))
        #expect(SearchViewModel.message(for: HTTPError.status(code: 503, body: Data())).contains("problems"))
        #expect(SearchViewModel.message(for: URLError(.notConnectedToInternet)).contains("internet connection"))
        // Ranking-stage (LLM engine) failures.
        #expect(SearchViewModel.message(for: FoundationModelsError.unavailable(nil)).contains("Apple Intelligence"))
        #expect(SearchViewModel.message(for: ClaudeProcessError.launchFailed("blocked")).contains("sandboxed"))
        #expect(SearchViewModel.message(for: LLMProviderError.noProviderAvailable).contains("No AI engine"))
    }

    @Test func searchPersistsResultsWhenSavingIsWired() async throws {
        let jobs = [JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")]
        let matches = [JobMatch(jobId: "a", score: 70, reason: "", matchedSkills: [], missingSkills: [])]
        let ranker = JobRanker(provider: PresentationStubProvider(matches: matches), shortlistLimit: 10)
        let useCase = SearchAndRankUseCase(jobSource: PresentationStubJobSource(jobs: jobs), ranker: ranker)
        let repo = SavedJobsRepository(store: InMemoryRecordStore())

        let vm = SearchViewModel(
            searchAndRank: useCase,
            roleTitleStore: RoleTitleStore(store: PresentationMemoryStore()),
            saveResults: SaveResultsUseCase(repository: repo)
        )
        vm.profile = profile
        vm.titleInput = "iOS Engineer"
        await vm.search()

        #expect(vm.results.map(\.id) == ["a"])
        #expect(try await repo.savedJobs().map(\.id) == ["a"])   // persisted as a side effect
    }

    @Test func allTitlesFailingSurfacesTheUnderlyingError() async {
        let source = FailingTitleJobSource(failingTitles: ["bad"])
        let useCase = SearchAndRankUseCase(jobSource: source, ranker: JobRanker(provider: PresentationStubProvider()))
        let vm = SearchViewModel(searchAndRank: useCase, roleTitleStore: RoleTitleStore(store: PresentationMemoryStore()))
        vm.profile = profile
        vm.titles = ["bad"]
        await vm.search()
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage != nil)          // a message is surfaced, not a silent failure
    }

    // MARK: Link fetch / pasted text (Hotfix — M-A regression)

    @Test func fetchFromLinkSuccessPushesSingleRankedResult() async {
        let vm = makeLinkVM(postingSource: StubPostingSource())
        vm.profile = profile
        vm.postingURL = "https://example.com/jobs/1"

        #expect(vm.canFetchLink)                 // profile + URL + wired
        await vm.fetchFromLink()

        // A single ranked job lands in `results` (so RootView propagates it + jumps),
        // indistinguishable from a keyword-search result.
        #expect(vm.results.map(\.id) == ["link-1"])
        #expect(vm.linkErrorMessage == nil)
        #expect(vm.errorMessage == nil)          // the search-stage error is untouched
        #expect(vm.isFetchingLink == false)
    }

    @Test func fetchFromLinkUnreadableShowsVisibleErrorAndLeavesResultsUntouched() async {
        let vm = makeLinkVM(postingSource: StubPostingSource(error: JobPostingSourceError.unreadable))
        vm.profile = profile
        vm.postingURL = "https://example.com/jobs/1"

        await vm.fetchFromLink()

        #expect(vm.results.isEmpty)                        // nothing pushed to Results
        #expect(vm.linkErrorMessage != nil)               // failure surfaced at the Fetch action
        #expect(vm.linkErrorMessage?.contains("paste") == true)   // points to the paste fallback…
        #expect(vm.linkErrorMessage?.contains("JSearch") == true) // …and the aggregator path
        #expect(vm.errorMessage == nil)                   // not the search-button error slot
    }

    @Test func fetchFromABotWalledBoardNamesItInTheError() async {
        let vm = makeLinkVM(postingSource: StubPostingSource(error: JobPostingSourceError.unreadable))
        vm.profile = profile
        vm.postingURL = "https://www.indeed.com/viewjob?jk=abc123"
        await vm.fetchFromLink()
        #expect(vm.linkErrorMessage?.contains("Indeed") == true)   // board-aware message
    }

    @Test func fetchFromLinkRequiresValidHTTPURL() async {
        let vm = makeLinkVM(postingSource: StubPostingSource())
        vm.profile = profile
        vm.postingURL = "not a url"
        await vm.fetchFromLink()
        #expect(vm.results.isEmpty)
        #expect(vm.linkErrorMessage != nil)
    }

    @Test func canFetchLinkGating() {
        let vm = makeLinkVM(postingSource: StubPostingSource())
        #expect(vm.canUseLink)
        #expect(vm.canFetchLink == false)        // no profile, no URL
        vm.profile = profile
        #expect(vm.canFetchLink == false)        // still no URL
        vm.postingURL = "https://example.com/jobs/1"
        #expect(vm.canFetchLink)                 // profile + URL + wired
    }

    @Test func linkFlowUnavailableWhenNotWired() {
        let vm = makeVM()                        // no fetchPosting injected
        #expect(vm.canUseLink == false)
        #expect(vm.canFetchLink == false)
    }

    @Test func generateFromPastedTextSuccessPushesResult() async {
        let vm = makeLinkVM(postingSource: StubPostingSource())
        vm.profile = profile
        vm.pastedPosting = "iOS Engineer at Acme. Swift, SwiftUI."
        await vm.generateFromPastedText()
        #expect(vm.results.map(\.id) == ["link-1"])
        #expect(vm.linkErrorMessage == nil)
    }

    @Test func generateFromPastedTextEmptyShowsError() async {
        let vm = makeLinkVM(postingSource: StubPostingSource())
        vm.profile = profile
        vm.pastedPosting = "   "
        await vm.generateFromPastedText()
        #expect(vm.results.isEmpty)
        #expect(vm.linkErrorMessage != nil)
    }

    // MARK: Expanded search parameters (Milestone U)

    /// A VM wired with in-memory location + salary stores for the U-F tests.
    private func makeParamVM(
        capture: CapturingJobSource,
        matches: [JobMatch] = []
    ) -> SearchViewModel {
        let useCase = SearchAndRankUseCase(jobSource: capture,
                                           ranker: JobRanker(provider: PresentationStubProvider(matches: matches), shortlistLimit: 50))
        return SearchViewModel(
            searchAndRank: useCase,
            roleTitleStore: RoleTitleStore(store: PresentationMemoryStore()),
            locationStore: LocationStore(store: PresentationMemoryStore()),
            salaryPresetStore: SalaryPresetStore(store: PresentationMemoryStore())
        )
    }

    @Test func allBlankFieldsProduceTodaysRequest() async {
        let capture = CapturingJobSource()
        let vm = makeParamVM(capture: capture)
        vm.profile = profile
        vm.titles = ["iOS Engineer"]
        await vm.search()

        let query = await capture.lastQuery
        #expect(query?.location == nil)
        #expect(query?.salaryMin == nil)
        #expect(query?.positionType == nil)
        #expect(query?.resultsPerPage == 25)      // no goal ⇒ single default page
    }

    @Test func optionalFieldsAssembleIntoTheRequest() async {
        let capture = CapturingJobSource()
        let vm = makeParamVM(capture: capture)
        vm.profile = profile
        vm.titles = ["iOS Engineer"]
        vm.location = "Lehi, UT"
        vm.salaryText = "$120,000"                 // parsed leniently
        vm.positionType = .contract
        vm.desiredResultText = "40"
        vm.minimumScore = 60
        await vm.search()

        let query = await capture.lastQuery
        #expect(query?.location == "Lehi, UT")
        #expect(query?.salaryMin == 120_000)
        #expect(query?.positionType == .contract)
        #expect(query?.resultsPerPage == 50)       // a goal switches to the larger page size
        #expect(vm.effectiveMinimumScore == 60)
        #expect(vm.desiredResultCount == 40)
    }

    @Test func salaryAndDesiredCountParseLenientlyAndZeroSliderMeansNoFilter() {
        let vm = makeParamVM(capture: CapturingJobSource())
        vm.salaryText = "abc"
        #expect(vm.effectiveSalaryMin == nil)
        vm.salaryText = "90k"                       // digits extracted
        #expect(vm.effectiveSalaryMin == 90)
        vm.desiredResultText = ""
        #expect(vm.desiredResultCount == nil)
        vm.minimumScore = 0
        #expect(vm.effectiveMinimumScore == nil)
    }

    @Test func savedLocationsAndSalariesRoundTripAndDeduplicate() {
        let vm = makeParamVM(capture: CapturingJobSource())
        vm.location = "Boston, MA"
        vm.saveCurrentLocation()
        vm.location = "boston, ma"                  // case-insensitive dupe
        vm.saveCurrentLocation()
        #expect(vm.savedLocations == ["Boston, MA"])
        #expect(vm.locationOptions.contains("Boston, MA"))

        vm.salaryText = "175000"
        vm.saveCurrentSalary()
        #expect(vm.savedSalaries == [175_000])
        #expect(vm.salaryPresetOptions.contains(175_000))

        vm.removeSavedLocation("Boston, MA")
        vm.removeSavedSalary(175_000)
        #expect(vm.savedLocations.isEmpty)
        #expect(vm.savedSalaries.isEmpty)
    }

    @Test func searchNotesCombineShortfallAndNoneMetMinimum() {
        let shortfall = SearchAndRankUseCase.Output(
            rankedJobs: [], failedTitles: ["bad"],
            resultShortfall: .init(found: 12, desired: 25), noneMetMinimum: true
        )
        let note = SearchViewModel.note(for: shortfall, minimumScore: 70)
        #expect(note?.contains("bad") == true)
        #expect(note?.contains("12 of a desired 25") == true)
        #expect(note?.contains("minimum rank of 70") == true)

        let clean = SearchAndRankUseCase.Output(rankedJobs: [])
        #expect(SearchViewModel.note(for: clean, minimumScore: nil) == nil)
    }

    // MARK: Saved / re-runnable searches (Milestone R)

    /// A VM wired with a saved-searches repo (+ optional saved-jobs for the dedupe note).
    private func makeSavedSearchVM(
        jobs: [JobListing] = [],
        matches: [JobMatch] = [],
        savedJobsRepo: SavedJobsRepository? = nil
    ) -> (SearchViewModel, SavedSearchesRepository) {
        let repo = SavedSearchesRepository(store: InMemoryRecordStore())
        let useCase = SearchAndRankUseCase(
            jobSource: PresentationStubJobSource(jobs: jobs),
            ranker: JobRanker(provider: PresentationStubProvider(matches: matches), shortlistLimit: 50)
        )
        let vm = SearchViewModel(
            searchAndRank: useCase,
            roleTitleStore: RoleTitleStore(store: PresentationMemoryStore()),
            saveResults: savedJobsRepo.map(SaveResultsUseCase.init(repository:)),
            loadSavedJobs: savedJobsRepo.map(LoadSavedJobsUseCase.init(repository:)),
            saveSearch: SaveSearchUseCase(repository: repo, makeID: { "s-1" }, now: { Date(timeIntervalSince1970: 1) }),
            loadSavedSearches: LoadSavedSearchesUseCase(repository: repo),
            deleteSavedSearch: DeleteSavedSearchUseCase(repository: repo)
        )
        return (vm, repo)
    }

    @Test func saveThenListSavedSearches() async {
        let (vm, _) = makeSavedSearchVM()
        vm.profile = profile
        vm.titles = ["iOS Engineer"]
        vm.location = "Remote"
        vm.positionType = .contract
        #expect(vm.canSaveSearch)

        await vm.saveCurrentSearch()
        #expect(vm.savedSearches.count == 1)
        #expect(vm.savedSearches[0].request.titles == ["iOS Engineer"])
        #expect(vm.savedSearches[0].request.positionType == .contract)
    }

    @Test func cannotSaveASearchWithoutProfileOrTitles() {
        let (vm, _) = makeSavedSearchVM()
        vm.titles = ["iOS"]
        #expect(vm.canSaveSearch == false)          // no profile
        vm.profile = profile
        vm.titles = []
        #expect(vm.canSaveSearch == false)          // no title
        vm.titles = ["iOS"]
        #expect(vm.canSaveSearch)
    }

    @Test func runningASavedSearchRepopulatesTheFormAndProducesResults() async {
        let jobs = [JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")]
        let matches = [JobMatch(jobId: "a", score: 70, reason: "", matchedSkills: [], missingSkills: [])]
        let (vm, _) = makeSavedSearchVM(jobs: jobs, matches: matches)
        vm.profile = profile

        let request = JobSearchRequest(titles: ["Swift Dev"], location: "Lehi, UT", positionType: .permanent, minimumScore: 50)
        let saved = SavedSearch(id: "x", name: "Saved", request: request, createdAt: Date(timeIntervalSince1970: 0))
        await vm.runSavedSearch(saved)

        #expect(vm.titles == ["Swift Dev"])         // form repopulated from the saved request
        #expect(vm.location == "Lehi, UT")
        #expect(vm.positionType == .permanent)
        #expect(vm.results.map(\.id) == ["a"])       // and it actually ran
    }

    @Test func rerunReportsHowManyResultsAreNewSinceLastTime() async throws {
        let jobs = [
            JobListing(id: "a", title: "t", company: "c", location: "l", description: "d"),
            JobListing(id: "b", title: "t", company: "c", location: "l", description: "d"),
        ]
        let matches = [
            JobMatch(jobId: "a", score: 70, reason: "", matchedSkills: [], missingSkills: []),
            JobMatch(jobId: "b", score: 60, reason: "", matchedSkills: [], missingSkills: []),
        ]
        let savedJobsRepo = SavedJobsRepository(store: InMemoryRecordStore())
        // "a" was already seen in a prior search.
        try await savedJobsRepo.save([RankedJob(listing: jobs[0], match: matches[0])])

        let (vm, _) = makeSavedSearchVM(jobs: jobs, matches: matches, savedJobsRepo: savedJobsRepo)
        vm.profile = profile
        let saved = SavedSearch(id: "x", name: "S",
                                request: JobSearchRequest(titles: ["iOS"]), createdAt: Date(timeIntervalSince1970: 0))
        await vm.runSavedSearch(saved)

        // Two results, one already seen → "1 new".
        #expect(vm.results.count == 2)
        #expect(vm.warningMessage?.contains("1 new since your last search") == true)
    }

    @Test func deleteSavedSearchRemovesIt() async {
        let (vm, _) = makeSavedSearchVM()
        vm.profile = profile
        vm.titles = ["iOS"]
        await vm.saveCurrentSearch()
        #expect(vm.savedSearches.count == 1)

        await vm.deleteSavedSearch(vm.savedSearches[0])
        #expect(vm.savedSearches.isEmpty)
    }

    @Test func savedSearchesUnavailableWithoutWiring() {
        let vm = makeVM()                            // no saveSearch use case
        #expect(vm.supportsSavedSearches == false)
        #expect(vm.canSaveSearch == false)
    }

    // MARK: Saved-profile selection

    /// A VM whose saved-profile library is prepopulated with `profiles`.
    private func makeVMWithProfiles(_ profiles: [SavedProfile]) async -> SearchViewModel {
        let repo = SavedProfilesRepository(store: InMemoryRecordStore())
        for saved in profiles { try? await repo.save(saved) }
        let useCase = SearchAndRankUseCase(
            jobSource: PresentationStubJobSource(jobs: []),
            ranker: JobRanker(provider: PresentationStubProvider())
        )
        return SearchViewModel(
            searchAndRank: useCase,
            roleTitleStore: RoleTitleStore(store: PresentationMemoryStore()),
            loadProfiles: LoadProfilesUseCase(repository: repo)
        )
    }

    private func savedProfile(_ id: String, titles: [String]) -> SavedProfile {
        SavedProfile(
            id: id, name: "Profile \(id)",
            profile: CandidateProfile(seniority: "S", yearsExperience: 1, coreSkills: [],
                                      domains: [], targetTitles: titles, summary: ""),
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func reloadProfilesPopulatesLibrary() async {
        let vm = await makeVMWithProfiles([savedProfile("a", titles: ["iOS Engineer"])])
        #expect(vm.savedProfiles.isEmpty)          // not loaded until asked
        await vm.reloadProfiles()
        #expect(vm.savedProfiles.map(\.id) == ["a"])
        #expect(vm.supportsSavedProfiles)
    }

    @Test func selectingASavedProfileSetsProfileAndSeedsTitles() async {
        let vm = await makeVMWithProfiles([savedProfile("a", titles: ["iOS Engineer", "Swift Dev"])])
        await vm.reloadProfiles()

        vm.selectedProfileID = "a"
        #expect(vm.hasProfile)
        #expect(vm.selectedProfileID == "a")       // getter reflects the active profile
        #expect(vm.titles.contains("iOS Engineer")) // chips seeded from the selected profile
    }

    @Test func selectedProfileIDIsNilForAnUnsavedProfile() async {
        let vm = await makeVMWithProfiles([savedProfile("a", titles: ["iOS Engineer"])])
        await vm.reloadProfiles()
        // An externally-set profile that isn't in the library reads as "unsaved".
        vm.profile = CandidateProfile(seniority: "X", yearsExperience: 0, coreSkills: [],
                                      domains: [], targetTitles: [], summary: "")
        #expect(vm.selectedProfileID == nil)
    }
}
