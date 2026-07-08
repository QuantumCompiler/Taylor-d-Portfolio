//
//  LLMRouterTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · LLM — LLMRouter engine selection and auto-fallback.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// A stub `LLMProvider` that either returns results tagged with `tag`, or throws.
private struct StubLLMProvider: LLMProvider {
    let tag: String
    let fails: Bool

    struct Boom: Error {}

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        if fails { throw Boom() }
        return CandidateProfile(
            seniority: tag, yearsExperience: 0, coreSkills: [],
            domains: [], targetTitles: [], summary: ""
        )
    }

    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] {
        if fails { throw Boom() }
        return [JobMatch(jobId: tag, score: 0, reason: "", matchedSkills: [], missingSkills: [])]
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile) async throws -> ApplicationKit {
        if fails { throw Boom() }
        return ApplicationKit(resumeMarkdown: tag, coverLetter: "", gapNote: "")
    }
}

@Suite("LLMRouter")
struct LLMRouterTests {

    private func makeRouter(
        _ choice: LLMChoice,
        onDeviceFails: Bool = false,
        claudeFails: Bool = false,
        available: Bool = true
    ) -> LLMRouter {
        LLMRouter(
            choice: choice,
            onDevice: StubLLMProvider(tag: "onDevice", fails: onDeviceFails),
            claude: StubLLMProvider(tag: "claude", fails: claudeFails),
            isOnDeviceAvailable: { available }
        )
    }

    @Test func onDeviceChoiceUsesOnDevice() async throws {
        let profile = try await makeRouter(.onDevice).buildProfile(fromPortfolio: "x")
        #expect(profile.seniority == "onDevice")
    }

    @Test func claudeChoiceUsesClaude() async throws {
        let profile = try await makeRouter(.claude).buildProfile(fromPortfolio: "x")
        #expect(profile.seniority == "claude")
    }

    @Test func autoPrefersOnDeviceWhenAvailable() async throws {
        let profile = try await makeRouter(.auto, available: true).buildProfile(fromPortfolio: "x")
        #expect(profile.seniority == "onDevice")
    }

    @Test func autoFallsBackToClaudeWhenOnDeviceThrows() async throws {
        let profile = try await makeRouter(.auto, onDeviceFails: true, available: true)
            .buildProfile(fromPortfolio: "x")
        #expect(profile.seniority == "claude")
    }

    @Test func autoSkipsOnDeviceWhenUnavailable() async throws {
        // onDevice would throw if used — proving it wasn't tried when unavailable.
        let profile = try await makeRouter(.auto, onDeviceFails: true, available: false)
            .buildProfile(fromPortfolio: "x")
        #expect(profile.seniority == "claude")
    }

    @Test func throwsWhenEveryEngineFails() async {
        let router = makeRouter(.auto, onDeviceFails: true, claudeFails: true, available: true)
        await #expect(throws: StubLLMProvider.Boom.self) {
            _ = try await router.buildProfile(fromPortfolio: "x")
        }
    }

    @Test func routesRankAndGenerateToo() async throws {
        let router = makeRouter(.claude)
        let profile = CandidateProfile(
            seniority: "s", yearsExperience: 0, coreSkills: [],
            domains: [], targetTitles: [], summary: ""
        )
        let job = JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")

        let matches = try await router.rank(jobs: [job], against: profile)
        #expect(matches.first?.jobId == "claude")

        let kit = try await router.generateApplication(for: job, profile: profile)
        #expect(kit.resumeMarkdown == "claude")
    }
}
