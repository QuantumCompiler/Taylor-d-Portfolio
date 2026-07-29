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

    func tidyDocument(rawText: String) async throws -> String {
        if fails { throw Boom() }
        return tag
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

    func scoreApplication(for job: JobListing, brief: TargetBrief, kit: ApplicationKit) async throws -> JobMatch {
        if fails { throw Boom() }
        return JobMatch(jobId: tag, score: 42, reason: "", matchedSkills: [], missingSkills: [])
    }

    func enrichPosting(fromPostingText postingText: String) async throws -> PostingDetails {
        if fails { throw Boom() }
        return PostingDetails(aboutCompany: tag)
    }

    func cleanPostingText(fromPageText pageText: String) async throws -> String {
        if fails { throw Boom() }
        return tag
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

        // The settings + score methods (Milestone D) must also route to the engine — a
        // forwarding adapter that misses them silently drops settings / throws on scoring.
        let tailored = try await router.generateApplication(
            for: job, profile: profile, brief: brief, grounding: nil, settings: GenerationSettings(fidelity: 0.8)
        )
        #expect(tailored.resumeMarkdown == "claude")
        let score = try await router.scoreApplication(for: job, brief: brief, kit: kit)
        #expect(score.jobId == "claude")

        // Enrichment (v0.6.0 A-B) must route too — a forwarding adapter that misses it throws.
        let details = try await router.enrichPosting(fromPostingText: "posting")
        #expect(details.aboutCompany == "claude")

        // Posting-text cleaning (v0.6.0 E) must route too.
        let cleaned = try await router.cleanPostingText(fromPageText: "raw page")
        #expect(cleaned == "claude")

        // Single-job re-rank (v0.6.0 C) routes through `.ranking` — the stub uses the default,
        // which forwards to its batch `rank` (tagged with the engine).
        let single = try await router.rank(job: job, against: profile, instruction: "steer")
        #expect(single.jobId == "claude")
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

    @Test func tidyDocumentUsesTheProfileTaskEngine() async throws {
        // Profile → on-device; everything else → Claude. Tidy must follow profile.
        let router = LLMRouter(
            configFor: { task in
                task == .profile ? TaskEngineConfig(choice: .onDevice) : TaskEngineConfig(choice: .claude)
            },
            onDevice: StubLLMProvider(tag: "onDevice", fails: false),
            makeClaude: { _ in StubLLMProvider(tag: "claude", fails: false) },
            isOnDeviceAvailable: { true }
        )
        let tidied = try await router.tidyDocument(rawText: "x")
        #expect(tidied == "onDevice")   // routed to the profile engine, not the default
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
