//
//  GenerationSettings.swift
//  Taylor'd Portfolio
//
//  Data · Models — user controls over how an application is generated (v0.5.0 Milestone D).
//

import Foundation

/// A **résumé section** the user can choose to tailor (Milestone D-C). An empty selection
/// means "tailor all sections" (today's behaviour).
///
/// Only the four tailorable résumé sections are knobs. **Education** stays verbatim (it's
/// factual and never embellished), and the **cover letter** isn't independent — it's written
/// from the tailored résumé — so neither is a case here (D-C revision).
nonisolated enum TailoredAspect: String, Codable, Sendable, CaseIterable, Identifiable {
    case summary
    case experience
    case projects
    case skills

    var id: String { rawValue }

    var label: String {
        switch self {
        case .summary: return "Summary / Headline"
        case .experience: return "Work Experience"
        case .projects: return "Projects"
        case .skills: return "Skills"
        }
    }
}

/// How much latitude generation has, relative to the candidate's real experience.
nonisolated enum FidelityBand: Sendable {
    /// Reorder / rephrase real experience only — never invent (the grounded default).
    case authentic
    /// Curate, emphasize, and infer reasonable adjacent skills — no invented credentials.
    case curated
    /// Permit plausible additions beyond the profile — every one must be disclosed.
    case embellished
}

/// The user's controls for generating a job's tailored application (Milestone D).
///
/// `.default` (fidelity 0, no aspects, no rank target) is the **grounded** path — with it,
/// generation is byte-for-byte the pre-Milestone-D behaviour.
///
/// **Control hierarchy:** when `desiredRankMatch` is set it is the master control and
/// overrides `fidelity` + `aspects` (the outcome-driven loop, Milestone D-F); otherwise
/// `fidelity` (D-B) and `aspects` (D-C) apply.
nonisolated struct GenerationSettings: Codable, Equatable, Sendable {
    /// 0 = authentic (verbatim), ~0.5 = curated, → 1 = embellished (invented, disclosed).
    var fidelity: Double
    /// Which sections to tailor; **empty = tailor all**.
    var aspects: Set<TailoredAspect>
    /// A target fit score 0–100 (Milestone D-F); `nil` = off. When set, overrides the above.
    var desiredRankMatch: Int?

    init(fidelity: Double = 0, aspects: Set<TailoredAspect> = [], desiredRankMatch: Int? = nil) {
        self.fidelity = fidelity
        self.aspects = aspects
        self.desiredRankMatch = desiredRankMatch
    }

    static let `default` = GenerationSettings()

    /// True for the grounded default — generation then matches the pre-Milestone-D prompt.
    var isDefault: Bool { self == .default }

    /// The latitude band `fidelity` falls into (drives prompt latitude + disclosure).
    var band: FidelityBand {
        if fidelity < 0.15 { return .authentic }
        if fidelity < 0.75 { return .curated }
        return .embellished
    }

    /// True when the settings permit content beyond the real profile (embellished band),
    /// so the UI must surface the disclosure warning (Milestone D-E).
    var mayEmbellish: Bool { band == .embellished }
}
