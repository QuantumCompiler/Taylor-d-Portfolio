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

    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        if fails { throw Boom() }
        return TargetBrief(company: tag, roleTitle: tag, mustHaveKeywords: [],
                           niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }

    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
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
        // Every task shares one config here, so these tests exercise choice/fallback.
        LLMRouter(
            configFor: { _ in TaskEngineConfig(choice: choice) },
            onDevice: StubLLMProvider(tag: "onDevice", fails: onDeviceFails),
            makeClaude: { _ in StubLLMProvider(tag: "claude", fails: claudeFails) },
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

        let brief = try await router.buildTargetBrief(for: job)
        #expect(brief.roleTitle == "claude")

        let kit = try await router.generateApplication(for: job, profile: profile, brief: brief)
        #expect(kit.resumeMarkdown == "claude")
    }

    // MARK: Per-task routing

    @Test func routesEachTaskToItsConfiguredEngine() async throws {
        // Profile → on-device; ranking → Claude.
        let router = LLMRouter(
            configFor: { task in
                task == .profile ? TaskEngineConfig(choice: .onDevice) : TaskEngineConfig(choice: .claude)
            },
            onDevice: StubLLMProvider(tag: "onDevice", fails: false),
            makeClaude: { _ in StubLLMProvider(tag: "claude", fails: false) },
            isOnDeviceAvailable: { true }
        )

        let profile = try await router.buildProfile(fromPortfolio: "x")
        #expect(profile.seniority == "onDevice")

        let job = JobListing(id: "a", title: "t", company: "c", location: "l", description: "d")
        let ranked = try await router.rank(jobs: [job], against: profile)
        #expect(ranked.first?.jobId == "claude")
    }

    @Test func passesConfiguredModelToClaudeFactory() async throws {
        // makeClaude tags its stub with the requested model id, proving the model flows through.
        let router = LLMRouter(
            configFor: { _ in TaskEngineConfig(choice: .claude, claudeModel: "claude-fable-5") },
            onDevice: StubLLMProvider(tag: "onDevice", fails: false),
            makeClaude: { model in StubLLMProvider(tag: model, fails: false) },
            isOnDeviceAvailable: { true }
        )

        let profile = try await router.buildProfile(fromPortfolio: "x")
        #expect(profile.seniority == "claude-fable-5")
    }
}
