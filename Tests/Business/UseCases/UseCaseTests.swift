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
}
