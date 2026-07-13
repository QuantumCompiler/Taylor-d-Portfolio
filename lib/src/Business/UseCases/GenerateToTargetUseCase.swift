//
//  GenerateToTargetUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — the outcome-driven "generate to a target rank" loop (Milestone D-F).
//

import Foundation

/// Generates a tailored application, repeatedly escalating latitude, until its résumé scores
/// at or above a **target match score** — the master control (Milestone D-F). It overrides
/// fidelity and aspects: each round climbs from curated toward full fabrication and re-scores,
/// stopping as soon as the target is met, or returning the **best** attempt (with the achieved
/// score) once a hard iteration cap is hit.
///
/// This is the app's most aggressive mode; the winning kit carries its own embellishment
/// disclosures in `gapNote` (from the embellished-band prompt), which the UI surfaces (D-E).
nonisolated struct GenerateToTargetUseCase: Sendable {
    /// The result of the loop.
    struct Outcome: Sendable, Equatable {
        let kit: ApplicationKit
        let achievedScore: Int
        let target: Int
        let reachedTarget: Bool
        let rounds: Int
    }

    let provider: any LLMProvider
    /// Hard cap on generate→score rounds — bounds cost/latency even though fidelity is
    /// overridden (the loop would otherwise climb forever chasing an unreachable target).
    let maxRounds: Int

    init(provider: any LLMProvider, maxRounds: Int = 4) {
        self.provider = provider
        self.maxRounds = max(1, maxRounds)
    }

    func callAsFunction(
        job: JobListing,
        profile: CandidateProfile,
        grounding: PortfolioGrounding? = nil,
        target: Int,
        additionalContext: String = ""
    ) async throws -> Outcome {
        let brief = try await provider.buildTargetBrief(for: job)
        var bestKit: ApplicationKit?
        var bestScore = -1
        var rounds = 0
        var lastError: Error?

        for round in 0..<maxRounds {
            rounds = round + 1
            // Target overrides fidelity + aspects: climb latitude, tailor all sections. The
            // user's free-text guidance (Milestone I) still rides along each round.
            let settings = GenerationSettings(fidelity: escalatedFidelity(round: round),
                                              additionalContext: additionalContext)
            do {
                let kit = try await provider.generateApplication(
                    for: job, profile: profile, brief: brief, grounding: grounding, settings: settings
                )
                let match = try await provider.scoreApplication(for: job, brief: brief, kit: kit)

                if match.score > bestScore {
                    bestScore = match.score
                    bestKit = kit
                }
                if match.score >= target {
                    return Outcome(kit: kit, achievedScore: match.score, target: target, reachedTarget: true, rounds: rounds)
                }
            } catch {
                // A single round failing (a transient engine/decoding error) shouldn't lose the
                // whole run — remember it and keep trying; only surface it if every round fails.
                lastError = error
            }
        }

        // No round produced a scored kit — surface the real cause instead of a silent empty result.
        guard let bestKit else { throw lastError ?? LLMProviderError.noProviderAvailable }

        // Target not reached within the cap — return the best-scoring attempt.
        return Outcome(
            kit: bestKit,
            achievedScore: max(0, bestScore),
            target: target,
            reachedTarget: false,
            rounds: rounds
        )
    }

    /// Climbs latitude each round: curated (0.5) → embellished (0.75) → full fabrication (1.0).
    func escalatedFidelity(round: Int) -> Double {
        min(1.0, 0.5 + Double(round) * 0.25)
    }
}
