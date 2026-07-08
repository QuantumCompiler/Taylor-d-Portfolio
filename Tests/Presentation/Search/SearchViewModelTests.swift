//
//  SearchViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Search
//

import Testing
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

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    private func makeVM(
        jobs: [JobListing] = [],
        matches: [JobMatch] = [],
        adzunaConfigured: Bool = true,
        roleTitleStore: RoleTitleStore = RoleTitleStore(store: PresentationMemoryStore())
    ) -> SearchViewModel {
        let ranker = JobRanker(provider: PresentationStubProvider(matches: matches), shortlistLimit: 10)
        let useCase = SearchAndRankUseCase(jobSource: PresentationStubJobSource(jobs: jobs), ranker: ranker)
        return SearchViewModel(searchAndRank: useCase, roleTitleStore: roleTitleStore, adzunaConfigured: adzunaConfigured)
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

    @Test func unconfiguredBuildDisablesSearch() async {
        let vm = makeVM(adzunaConfigured: false)
        vm.profile = profile
        vm.titleInput = "swift"
        #expect(vm.canSearch == false)
        #expect(vm.unavailableMessage != nil)

        await vm.search()
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage == vm.unavailableMessage)
    }

    @Test func configuredBuildHasNoUnavailableBanner() {
        #expect(makeVM(adzunaConfigured: true).unavailableMessage == nil)
    }
}
