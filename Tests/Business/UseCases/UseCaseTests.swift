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
            JobListing(id: "a", title: "t", company: "c", location: "l", description: "d"),
            JobListing(id: "b", title: "t", company: "c", location: "l", description: "d"),
        ]
        let matches = [
            JobMatch(jobId: "a", score: 40, reason: "", matchedSkills: [], missingSkills: []),
            JobMatch(jobId: "b", score: 80, reason: "", matchedSkills: [], missingSkills: []),
        ]
        let ranker = JobRanker(provider: TaggingProvider(tag: "x", matches: matches), shortlistLimit: 10)
        let useCase = SearchAndRankUseCase(jobSource: StubJobSource(jobs: jobs), ranker: ranker)

        let ranked = try await useCase(query: JobQuery(keywords: "anything"), profile: profile)
        // Searched jobs flowed into ranking, and results came back sorted by score.
        #expect(ranked.map(\.id) == ["b", "a"])
    }
}
