//
//  UseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — delegation and search→rank composition.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// An `LLMProvider` that tags its outputs so delegation can be observed.
private struct TaggingProvider: LLMProvider {
    let tag: String
    var matches: [JobMatch] = []

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        CandidateProfile(seniority: tag, yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { matches }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        TargetBrief(company: job.company, roleTitle: job.title, mustHaveKeywords: [],
                    niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        // Tag the resume with the brief's role title so two-stage delegation is observable.
        ApplicationKit(resumeMarkdown: "\(tag):\(brief.roleTitle)", coverLetter: "", gapNote: "")
    }
}

/// A `JobSource` that returns canned listings.
private struct StubJobSource: JobSource {
    let jobs: [JobListing]
    func search(_ query: JobQuery) async throws -> [JobListing] { jobs }
}

/// A `JobSource` that returns listings per title (the query's `keywords`) and can be
/// told which titles should throw, for fan-out / partial-failure tests.
private struct PerTitleJobSource: JobSource {
    var byTitle: [String: [JobListing]] = [:]
    var failingTitles: Set<String> = []
    struct Boom: Error {}
    func search(_ query: JobQuery) async throws -> [JobListing] {
        if failingTitles.contains(query.keywords) { throw Boom() }
        return byTitle[query.keywords] ?? []
    }
}

/// A `JobSource` with a fixed pool of `totalAvailable` unique listings per title, sliced
/// by the query's `page` / `resultsPerPage` — so paging toward a goal accumulates (U-D).
private struct PagingJobSource: JobSource {
    let totalAvailable: Int
    func search(_ query: JobQuery) async throws -> [JobListing] {
        let start = (query.page - 1) * query.resultsPerPage
        guard start < totalAvailable else { return [] }
        let end = min(start + query.resultsPerPage, totalAvailable)
        return (start..<end).map { listing(String($0 + 1)) }
    }
}

/// An `LLMProvider` whose `rank` records how many jobs it was asked to rank (to prove
/// the merged set is ranked exactly once) and scores each job by its trailing digits.
private actor CountingRankProvider: LLMProvider {
    private(set) var rankCallJobCounts: [Int] = []
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        CandidateProfile(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        rankCallJobCounts.append(jobs.count)
        return jobs.map { JobMatch(jobId: $0.id, score: Int($0.id) ?? 0, reason: "", matchedSkills: [], missingSkills: []) }
    }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        TargetBrief(company: "", roleTitle: "", mustHaveKeywords: [], niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        ApplicationKit(resumeMarkdown: "", coverLetter: "", gapNote: "")
    }
}

private func listing(_ id: String) -> JobListing {
    JobListing(id: id, title: "t", company: "c", location: "l", description: "d")
}

@Suite("Use cases")
struct UseCaseTests {

    private let profile = CandidateProfile(
        seniority: "s", yearsExperience: 1, coreSkills: [], domains: [], targetTitles: [], summary: ""
    )

    @Test func buildProfileDelegatesToProvider() async throws {
        let useCase = BuildProfileUseCase(provider: TaggingProvider(tag: "PROFILE"))
        let profile = try await useCase(portfolio: "some portfolio")
        #expect(profile.seniority == "PROFILE")
    }

    @Test func generateApplicationRunsBothStagesAndThreadsTheBrief() async throws {
        let useCase = GenerateApplicationUseCase(provider: TaggingProvider(tag: "KIT"))
        let job = JobListing(id: "a", title: "iOS Engineer", company: "c", location: "l", description: "d")
        let kit = try await useCase(job: job, profile: profile)
        // "KIT" proves stage 2 ran; ":iOS Engineer" proves the stage-1 brief threaded in.
        #expect(kit.resumeMarkdown == "KIT:iOS Engineer")
    }

    @Test func searchAndRankSearchesThenRanks() async throws {
        let jobs = [
            JobListing(id: "40", title: "t", company: "c", location: "l", description: "d"),
            JobListing(id: "80", title: "t", company: "c", location: "l", description: "d"),
        ]
        let ranker = JobRanker(provider: CountingRankProvider(), shortlistLimit: 10)
        let useCase = SearchAndRankUseCase(jobSource: StubJobSource(jobs: jobs), ranker: ranker)

        let output = try await useCase(request: JobSearchRequest(titles: ["anything"]), profile: profile)
        // Searched jobs flowed into ranking, and results came back sorted by score desc.
        #expect(output.rankedJobs.map(\.id) == ["80", "40"])
        #expect(output.failedTitles.isEmpty)
    }

    @Test func multipleTitlesMergeDedupeAndRankOnce() async throws {
        // "a" appears under both titles; it must be searched twice but ranked once.
        let source = PerTitleJobSource(byTitle: [
            "iOS Developer": [listing("30"), listing("10")],
            "iOS Engineer": [listing("30"), listing("20")],
        ])
        let provider = CountingRankProvider()
        let useCase = SearchAndRankUseCase(jobSource: source, ranker: JobRanker(provider: provider, shortlistLimit: 20))

        let output = try await useCase(
            request: JobSearchRequest(titles: ["iOS Developer", "iOS Engineer"]),
            profile: profile
        )
        // Deduped by id (30 seen once), ranked once, sorted by score desc.
        #expect(output.rankedJobs.map(\.id) == ["30", "20", "10"])
        let counts = await provider.rankCallJobCounts
        #expect(counts == [3])   // exactly one rank call, over the 3 merged listings
    }

    @Test func oneFailingTitleStillReturnsTheRestWithANote() async throws {
        let source = PerTitleJobSource(
            byTitle: ["good": [listing("10")]],
            failingTitles: ["bad"]
        )
        let useCase = SearchAndRankUseCase(jobSource: source, ranker: JobRanker(provider: CountingRankProvider()))

        let output = try await useCase(request: JobSearchRequest(titles: ["good", "bad"]), profile: profile)
        #expect(output.rankedJobs.map(\.id) == ["10"])
        #expect(output.failedTitles == ["bad"])
    }

    @Test func allTitlesFailingThrows() async {
        let source = PerTitleJobSource(failingTitles: ["x", "y"])
        let useCase = SearchAndRankUseCase(jobSource: source, ranker: JobRanker(provider: CountingRankProvider()))
        await #expect(throws: PerTitleJobSource.Boom.self) {
            _ = try await useCase(request: JobSearchRequest(titles: ["x", "y"]), profile: profile)
        }
    }

    @Test func emptyTitlesReturnNothing() async throws {
        let useCase = SearchAndRankUseCase(jobSource: StubJobSource(jobs: [listing("1")]), ranker: JobRanker(provider: CountingRankProvider()))
        let output = try await useCase(request: JobSearchRequest(titles: ["   ", ""]), profile: profile)
        #expect(output.rankedJobs.isEmpty)
        #expect(output.failedTitles.isEmpty)
    }

    // MARK: FetchPostingUseCase (M-A)

    // MARK: U-D — desired-result-count goal

    @Test func nilGoalFetchesASinglePage() async throws {
        let useCase = SearchAndRankUseCase(jobSource: PagingJobSource(totalAvailable: 500),
                                           ranker: JobRanker(provider: CountingRankProvider(), shortlistLimit: 1000))
        let output = try await useCase(request: JobSearchRequest(titles: ["ios"]), profile: profile)
        #expect(output.rankedJobs.count == 25)      // one default page, no paging
        #expect(output.resultShortfall == nil)
    }

    @Test func goalPagesUntilReachedThenStopsEarly() async throws {
        let useCase = SearchAndRankUseCase(jobSource: PagingJobSource(totalAvailable: 500),
                                           ranker: JobRanker(provider: CountingRankProvider(), shortlistLimit: 1000))
        let output = try await useCase(request: JobSearchRequest(titles: ["ios"], desiredResultCount: 60), profile: profile)
        #expect(output.rankedJobs.count >= 60)      // goal met…
        #expect(output.rankedJobs.count < 500)      // …without draining the whole source
        #expect(output.resultShortfall == nil)
    }

    @Test func unreachableGoalReturnsWhatsAvailableWithAShortfallNote() async throws {
        let useCase = SearchAndRankUseCase(jobSource: PagingJobSource(totalAvailable: 20),
                                           ranker: JobRanker(provider: CountingRankProvider(), shortlistLimit: 1000))
        let output = try await useCase(request: JobSearchRequest(titles: ["ios"], desiredResultCount: 100), profile: profile)
        #expect(output.rankedJobs.count == 20)      // never throws on a shortfall
        #expect(output.resultShortfall == .init(found: 20, desired: 100))
    }

    @Test func pageCapBoundsTheEffort() async throws {
        // 5 pages × 50/page = 250 max, even though 10_000 exist and the goal is higher.
        let useCase = SearchAndRankUseCase(jobSource: PagingJobSource(totalAvailable: 10_000),
                                           ranker: JobRanker(provider: CountingRankProvider(), shortlistLimit: 100_000))
        let output = try await useCase(request: JobSearchRequest(titles: ["ios"], desiredResultCount: 10_000), profile: profile)
        #expect(output.rankedJobs.count == 250)
        #expect(output.resultShortfall == .init(found: 250, desired: 10_000))
    }

    // MARK: U-E — minimum-rank filter

    @Test func minimumScoreKeepsOnlyQualifyingResults() async throws {
        let jobs = ["80", "40", "20"].map { listing($0) }   // scores 80/40/20
        let useCase = SearchAndRankUseCase(jobSource: StubJobSource(jobs: jobs),
                                           ranker: JobRanker(provider: CountingRankProvider(), shortlistLimit: 10))
        let output = try await useCase(request: JobSearchRequest(titles: ["ios"], minimumScore: 50), profile: profile)
        #expect(output.rankedJobs.map(\.id) == ["80"])
        #expect(output.noneMetMinimum == false)
    }

    @Test func minimumScoreThatMatchesNothingFlagsNoneMetMinimum() async throws {
        let jobs = ["10", "20"].map { listing($0) }
        let useCase = SearchAndRankUseCase(jobSource: StubJobSource(jobs: jobs),
                                           ranker: JobRanker(provider: CountingRankProvider(), shortlistLimit: 10))
        let output = try await useCase(request: JobSearchRequest(titles: ["ios"], minimumScore: 90), profile: profile)
        #expect(output.rankedJobs.isEmpty)
        #expect(output.noneMetMinimum)              // distinct from "no results found at all"
    }

    @Test func nilMinimumScoreDoesNotFilter() async throws {
        let jobs = ["10", "90"].map { listing($0) }
        let useCase = SearchAndRankUseCase(jobSource: StubJobSource(jobs: jobs),
                                           ranker: JobRanker(provider: CountingRankProvider(), shortlistLimit: 10))
        let output = try await useCase(request: JobSearchRequest(titles: ["ios"]), profile: profile)
        #expect(output.rankedJobs.count == 2)
        #expect(output.noneMetMinimum == false)
    }

    @Test func fetchPostingRanksTheSingleListing() async throws {
        let source = StubPostingSource(listing: listing("55"))
        let useCase = FetchPostingUseCase(postingSource: source, ranker: JobRanker(provider: CountingRankProvider()))
        let ranked = try await useCase(url: URL(string: "https://x.com/j")!, profile: profile)
        #expect(ranked.id == "55")
        #expect(ranked.score == 55)          // CountingRankProvider scores by id digits
    }

    @Test func fetchPostingFallsBackToNeutralWhenUnranked() async throws {
        // A provider that returns no matches → the listing still comes back, unscored.
        let source = StubPostingSource(listing: listing("7"))
        let useCase = FetchPostingUseCase(postingSource: source, ranker: JobRanker(provider: TaggingProvider(tag: "x", matches: [])))
        let ranked = try await useCase(pastedText: "some posting text", profile: profile)
        #expect(ranked.id == "7")
        #expect(ranked.score == 0)
        #expect(ranked.match.reason == "Not scored.")
    }

    @Test func fetchPostingPropagatesUnreadable() async {
        let source = StubPostingSource(error: JobPostingSourceError.unreadable)
        let useCase = FetchPostingUseCase(postingSource: source, ranker: JobRanker(provider: CountingRankProvider()))
        await #expect(throws: JobPostingSourceError.unreadable) {
            _ = try await useCase(url: URL(string: "https://x.com/j")!, profile: profile)
        }
    }

    // MARK: EnrichPostingUseCase (v0.6.0 Milestone A-C)

    private func enrichListing(url: URL? = nil, description: String) -> JobListing {
        JobListing(id: "e1", title: "iOS", company: "Acme", location: "Remote", description: description, url: url)
    }
    private let enrichURL = URL(string: "https://example.com/jobs/1")!

    @Test func enrichPrefersFullPageOverSnippet() async throws {
        let provider = EnrichRecordingProvider(details: PostingDetails(workTypeRaw: "remote", aboutCompany: "Fintech."))
        let page = String(repeating: "Full posting page text. ", count: 20)
        let useCase = EnrichPostingUseCase(provider: provider, postingSource: ReadableStubSource(pageText: page))

        let enriched = try await useCase(enrichListing(url: enrichURL, description: "short snippet"))
        #expect(provider.lastText == page)                 // used the full page, not the snippet
        #expect(enriched.details?.workType == .remote)
        #expect(enriched.details?.aboutCompany == "Fintech.")
    }

    @Test func enrichFallsBackToSnippetWhenPageUnfetchable() async throws {
        let provider = EnrichRecordingProvider(details: PostingDetails(aboutRole: "A role."))
        // readableText throws unreadable → fall back to the description snippet.
        let useCase = EnrichPostingUseCase(provider: provider, postingSource: ReadableStubSource(pageText: nil))

        let enriched = try await useCase(enrichListing(url: enrichURL, description: "the snippet"))
        #expect(provider.lastText == "the snippet")
        #expect(enriched.details?.aboutRole == "A role.")
    }

    @Test func enrichUsesSnippetWhenNoSourceWired() async throws {
        let provider = EnrichRecordingProvider(details: PostingDetails(benefits: ["Health"]))
        let useCase = EnrichPostingUseCase(provider: provider, postingSource: nil)   // snippet-only
        let enriched = try await useCase(enrichListing(url: nil, description: "just the snippet"))
        #expect(provider.lastText == "just the snippet")
        #expect(enriched.details?.benefits == ["Health"])
    }

    @Test func enrichLeavesListingUnchangedWhenNothingFound() async throws {
        let provider = EnrichRecordingProvider(details: PostingDetails())   // empty → hasContent == false
        let useCase = EnrichPostingUseCase(provider: provider, postingSource: nil)
        let original = enrichListing(description: "snippet")
        let result = try await useCase(original)
        #expect(result == original)          // unchanged, not overwritten with an empty structure
        #expect(result.details == nil)
    }

    @Test func enrichSkipsWhenNoUsableText() async throws {
        let provider = EnrichRecordingProvider(details: PostingDetails(aboutRole: "x"))
        let useCase = EnrichPostingUseCase(provider: provider, postingSource: nil)
        let blank = enrichListing(description: "   ")
        let result = try await useCase(blank)
        #expect(result == blank)
        #expect(provider.lastText == nil)    // enrichment never called — nothing to read
    }
}

/// A `JobPostingSource` that returns a canned listing or throws.
private struct StubPostingSource: JobPostingSource {
    var listing: JobListing?
    var error: Error?
    func fetchPosting(from url: URL) async throws -> JobListing { try result() }
    func extractPosting(fromText text: String, sourceURL: URL?) async throws -> JobListing { try result() }
    private func result() throws -> JobListing {
        if let error { throw error }
        return listing ?? JobListing(id: "x", title: "t", company: "c", location: "l", description: "d")
    }
}

/// A `JobPostingSource` whose `readableText` returns canned page text (or throws unreadable).
private struct ReadableStubSource: JobPostingSource {
    var pageText: String?
    func fetchPosting(from url: URL) async throws -> JobListing { throw JobPostingSourceError.unreadable }
    func extractPosting(fromText text: String, sourceURL: URL?) async throws -> JobListing { throw JobPostingSourceError.unreadable }
    func readableText(from url: URL) async throws -> String {
        guard let pageText else { throw JobPostingSourceError.unreadable }
        return pageText
    }
}

/// An `LLMProvider` that returns a canned `PostingDetails` and records the text it enriched.
private final class EnrichRecordingProvider: LLMProvider, @unchecked Sendable {
    let details: PostingDetails
    private(set) var lastText: String?
    init(details: PostingDetails) { self.details = details }
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
    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails {
        lastText = postingText
        return details
    }
}
