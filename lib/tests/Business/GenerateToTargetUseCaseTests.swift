//
//  GenerateToTargetUseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business — the rank-target generation loop (Milestone D-F).
//

import Testing
@testable import Taylor_d_Portfolio

/// A stub provider whose `scoreApplication` returns a scripted score per call (rising, so
/// the loop converges), and that labels each generated kit by its round.
private actor ScoringStubProvider: LLMProvider {
    struct Boom: Error {}
    /// A negative scripted score means "this round's scoring throws" (tests failure tolerance).
    let scores: [Int]
    private(set) var generateCalls = 0
    private(set) var scoreCalls = 0
    /// The `additionalContext` seen on the most recent settings-carrying generate call.
    private(set) var lastAdditionalContext = ""

    init(scores: [Int]) { self.scores = scores }

    func buildProfile(fromPortfolio portfolio: String) async throws -> CandidateProfile {
        CandidateProfile(seniority: "S", yearsExperience: 1, coreSkills: [], domains: [], targetTitles: [], summary: "")
    }
    func rank(jobs: [JobListing], against profile: CandidateProfile) async throws -> [JobMatch] { [] }
    func buildTargetBrief(for job: JobListing) async throws -> TargetBrief {
        TargetBrief(company: "C", roleTitle: "R", mustHaveKeywords: [], niceToHaveKeywords: [], techStack: [], domain: "", missionValues: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief) async throws -> ApplicationKit {
        generateCalls += 1
        return ApplicationKit(resumeMarkdown: "round \(generateCalls)", coverLetter: "c", gapNote: "")
    }
    func generateApplication(for job: JobListing, profile: CandidateProfile, brief: TargetBrief, grounding: PortfolioGrounding?, settings: GenerationSettings) async throws -> ApplicationKit {
        lastAdditionalContext = settings.additionalContext
        return try await generateApplication(for: job, profile: profile, brief: brief)
    }
    func scoreApplication(for job: JobListing, brief: TargetBrief, kit: ApplicationKit) async throws -> JobMatch {
        let index = min(scoreCalls, scores.count - 1)
        let score = scores[index]
        scoreCalls += 1
        if score < 0 { throw Boom() }
        return JobMatch(jobId: job.id, score: score, reason: "", matchedSkills: [], missingSkills: [])
    }
}

@Suite("GenerateToTargetUseCase")
struct GenerateToTargetUseCaseTests {
    private let job = JobListing(id: "a", title: "iOS Engineer", company: "Acme", location: "Remote", description: "d")
    private let profile = CandidateProfile(seniority: "Senior", yearsExperience: 8, coreSkills: ["Swift"],
                                           domains: [], targetTitles: [], summary: "")

    @Test func stopsOnceTargetIsReached() async throws {
        let provider = ScoringStubProvider(scores: [50, 70, 90])   // reaches 90 on round 3
        let outcome = try await GenerateToTargetUseCase(provider: provider, maxRounds: 4)(
            job: job, profile: profile, target: 85
        )
        #expect(outcome.reachedTarget)
        #expect(outcome.achievedScore == 90)
        #expect(outcome.rounds == 3)
        #expect(await provider.generateCalls == 3)              // stopped as soon as it hit the target
        #expect(outcome.kit.resumeMarkdown == "round 3")
    }

    @Test func stopsAtTheCapAndReturnsTheBestAttempt() async throws {
        let provider = ScoringStubProvider(scores: [50, 60, 55, 40])   // best is 60 (round 2), never 95
        let outcome = try await GenerateToTargetUseCase(provider: provider, maxRounds: 4)(
            job: job, profile: profile, target: 95
        )
        #expect(outcome.reachedTarget == false)
        #expect(outcome.achievedScore == 60)                   // the best across the rounds
        #expect(outcome.target == 95)
        #expect(outcome.rounds == 4)                           // hit the cap
        #expect(outcome.kit.resumeMarkdown == "round 2")       // returns the best-scoring kit
    }

    @Test func reachesTargetOnFirstRoundWithoutExtraWork() async throws {
        let provider = ScoringStubProvider(scores: [90])
        let outcome = try await GenerateToTargetUseCase(provider: provider)(job: job, profile: profile, target: 80)
        #expect(outcome.reachedTarget)
        #expect(outcome.rounds == 1)
        #expect(await provider.generateCalls == 1)
    }

    @Test func toleratesAFailingRoundAndUsesASuccessfulOne() async throws {
        let provider = ScoringStubProvider(scores: [-1, 88])   // round 1 throws, round 2 succeeds
        let outcome = try await GenerateToTargetUseCase(provider: provider, maxRounds: 4)(
            job: job, profile: profile, target: 80
        )
        #expect(outcome.reachedTarget)
        #expect(outcome.achievedScore == 88)
    }

    @Test func throwsWhenEveryRoundFails() async {
        let provider = ScoringStubProvider(scores: [-1])   // every round's scoring throws
        await #expect(throws: (any Error).self) {
            _ = try await GenerateToTargetUseCase(provider: provider, maxRounds: 3)(
                job: job, profile: profile, target: 80
            )
        }
    }

    @Test func forwardsAdditionalContextIntoEachRound() async throws {
        let provider = ScoringStubProvider(scores: [90])
        _ = try await GenerateToTargetUseCase(provider: provider)(
            job: job, profile: profile, target: 80, additionalContext: "emphasize EV Charging"
        )
        #expect(await provider.lastAdditionalContext == "emphasize EV Charging")
    }

    @Test func fidelityEscalatesEachRound() {
        let useCase = GenerateToTargetUseCase(provider: ScoringStubProvider(scores: [0]))
        #expect(useCase.escalatedFidelity(round: 0) == 0.5)    // curated
        #expect(useCase.escalatedFidelity(round: 1) == 0.75)   // embellished
        #expect(useCase.escalatedFidelity(round: 2) == 1.0)    // full fabrication
        #expect(useCase.escalatedFidelity(round: 3) == 1.0)    // clamped
    }

    @MainActor
    @Test func viewModelUsesTheLoopWhenARankTargetIsSet() async {
        let provider = ScoringStubProvider(scores: [88])
        let vm = ApplicationViewModel(
            generateApplication: GenerateApplicationUseCase(provider: provider),
            generateToTarget: GenerateToTargetUseCase(provider: provider)
        )
        vm.generationSettings.desiredRankMatch = 80
        await vm.generate(for: job, profile: profile)
        #expect(vm.rankOutcome?.reachedTarget == true)
        #expect(vm.rankOutcome?.achievedScore == 88)
        #expect(vm.rankOutcomeNote?.contains("Reached a 88") == true)
        #expect(vm.kit != nil)
    }
}
