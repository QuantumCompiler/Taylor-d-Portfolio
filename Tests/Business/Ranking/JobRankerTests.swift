//
//  JobRankerTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · Ranking — prefilter, pairing, and sorting.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Returns fixed matches; ignores its input.
private struct StubProvider: LLMProvider {
    var matches: [JobMatch] = []
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        CandidateProfile(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { matches }
    func generateApplication(for job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
        ApplicationKit(resumeMarkdown: "", coverLetter: "", gapNote: "")
    }
}

/// Records the jobs handed to `rank` so tests can assert the shortlist.
private actor RecordingRankProvider: LLMProvider {
    private(set) var received: [JobListing] = []
    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        CandidateProfile(seniority: "", yearsExperience: 0, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        received = jobs
        return []
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
        ApplicationKit(resumeMarkdown: "", coverLetter: "", gapNote: "")
    }
}

@Suite("JobRanker")
struct JobRankerTests {

    private let profile = CandidateProfile(
        seniority: "Senior", yearsExperience: 8, coreSkills: ["Swift", "SwiftUI"],
        domains: ["Fintech"], targetTitles: ["iOS Engineer"], summary: ""
    )

    private func job(_ id: String, title: String = "", desc: String = "") -> JobListing {
        JobListing(id: id, title: title, company: "", location: "", description: desc)
    }

    @Test func prefilterReturnsAllWhenWithinLimit() {
        let ranker = JobRanker(provider: StubProvider())
        let jobs = [job("1"), job("2")]
        #expect(ranker.prefilter(jobs, for: profile, limit: 5).count == 2)
    }

    @Test func prefilterKeepsMostRelevantJob() {
        let ranker = JobRanker(provider: StubProvider())
        let relevant = job("hit", title: "iOS Engineer", desc: "Swift and SwiftUI at a Fintech startup")
        let irrelevant = job("miss", title: "Chef", desc: "cooking pasta all day")
        let shortlist = ranker.prefilter([irrelevant, relevant], for: profile, limit: 1)
        #expect(shortlist.map(\.id) == ["hit"])
    }

    @Test func rankPairsSortsDescendingAndDropsUnmatched() async throws {
        let matches = [
            JobMatch(jobId: "b", score: 90, reason: "", matchedSkills: [], missingSkills: []),
            JobMatch(jobId: "a", score: 50, reason: "", matchedSkills: [], missingSkills: []),
            JobMatch(jobId: "ghost", score: 99, reason: "", matchedSkills: [], missingSkills: []),
        ]
        let ranker = JobRanker(provider: StubProvider(matches: matches), shortlistLimit: 10)
        let ranked = try await ranker.rank([job("a"), job("b")], for: profile)

        #expect(ranked.map(\.id) == ["b", "a"]) // sorted by score desc; "ghost" has no listing
        #expect(ranked.first?.score == 90)
    }

    @Test func rankReturnsEmptyWhenNoJobs() async throws {
        let ranker = JobRanker(provider: StubProvider())
        let ranked = try await ranker.rank([], for: profile)
        #expect(ranked.isEmpty)
    }

    @Test func rankOnlySendsTheShortlistToTheProvider() async throws {
        let provider = RecordingRankProvider()
        let ranker = JobRanker(provider: provider, shortlistLimit: 1)
        let relevant = job("hit", title: "iOS Engineer", desc: "Swift SwiftUI Fintech")
        let irrelevant = job("miss", title: "Chef", desc: "pasta")

        _ = try await ranker.rank([irrelevant, relevant], for: profile)

        let received = await provider.received
        #expect(received.map(\.id) == ["hit"])
    }
}
