//
//  SearchViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Search
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    private func makeVM(jobs: [JobListing] = [], matches: [JobMatch] = [], adzunaConfigured: Bool = true) -> SearchViewModel {
        let ranker = JobRanker(provider: PresentationStubProvider(matches: matches), shortlistLimit: 10)
        let useCase = SearchAndRankUseCase(jobSource: PresentationStubJobSource(jobs: jobs), ranker: ranker)
        return SearchViewModel(searchAndRank: useCase, adzunaConfigured: adzunaConfigured)
    }

    private var profile: CandidateProfile {
        CandidateProfile(seniority: "S", yearsExperience: 1, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }

    @Test func searchWithoutProfileSetsError() async {
        let vm = makeVM()
        vm.keywords = "swift"
        await vm.search()
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    @Test func searchWithProfileProducesResults() async {
        let jobs = [JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")]
        let matches = [JobMatch(jobId: "a", score: 70, reason: "", matchedSkills: [], missingSkills: [])]
        let vm = makeVM(jobs: jobs, matches: matches)
        vm.profile = profile
        vm.keywords = "swift"
        await vm.search()
        #expect(vm.results.map(\.id) == ["a"])
        #expect(vm.errorMessage == nil)
        #expect(vm.isSearching == false)
    }

    @Test func canSearchRequiresProfileAndKeywords() {
        let vm = makeVM()
        #expect(vm.canSearch == false)          // no profile, no keywords
        vm.keywords = "swift"
        #expect(vm.canSearch == false)          // still no profile
        vm.profile = profile
        #expect(vm.canSearch == true)
    }

    @Test func unconfiguredBuildDisablesSearch() async {
        let vm = makeVM(adzunaConfigured: false)
        vm.profile = profile
        vm.keywords = "swift"
        #expect(vm.canSearch == false)          // configured build required
        #expect(vm.unavailableMessage != nil)

        await vm.search()
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage == vm.unavailableMessage)
    }

    @Test func configuredBuildHasNoUnavailableBanner() {
        #expect(makeVM(adzunaConfigured: true).unavailableMessage == nil)
    }
}
