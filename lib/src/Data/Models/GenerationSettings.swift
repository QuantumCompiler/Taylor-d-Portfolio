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
    /// Opt-in keyword emphasis (v0.6.1 Milestone D): weave the posting's **must-have** keywords
    /// into the résumé's **visible** text wherever they are genuinely true for this candidate,
    /// and route the ones that aren't into `gapNote` so the user sees them and decides.
    ///
    /// Deliberately **not** a ``TailoredAspect`` case: those are résumé *sections*, and
    /// `Prompts.generationControls` renders the selection as "tailor ONLY these résumé
    /// sections — …", which a non-section case would corrupt.
    ///
    /// It is an **alignment** control, not a latitude one — the fidelity band still governs how
    /// much the model may add, so at the grounded default this can only surface keywords the
    /// candidate truly matches. Never hidden text: emphasis lands in the document a human reads.
    var emphasizeKeywords: Bool = false
    /// Free-text guidance the user types to steer emphasis/framing on the next
    /// generate/regenerate (Milestone I) — e.g. "lean into the API-gateway angle". It steers
    /// which true experience to foreground, never licenses invention (the grounding + fidelity
    /// rules still apply). **Deliberately excluded from `Codable`** (see `CodingKeys`) so it is
    /// per-job and never captured into a reusable ``GenerationPreset``; it *is* part of
    /// `Equatable`, so non-empty context counts against `isDefault`.
    var additionalContext: String = ""

    init(fidelity: Double = 0, aspects: Set<TailoredAspect> = [], desiredRankMatch: Int? = nil,
         emphasizeKeywords: Bool = false, additionalContext: String = "") {
        self.fidelity = fidelity
        self.aspects = aspects
        self.desiredRankMatch = desiredRankMatch
        self.emphasizeKeywords = emphasizeKeywords
        self.additionalContext = additionalContext
    }

    /// Persisted keys — `additionalContext` is intentionally omitted, so presets store only the
    /// fidelity/aspect/target controls and legacy blobs (which never had it) still decode.
    private enum CodingKeys: String, CodingKey {
        case fidelity, aspects, desiredRankMatch, emphasizeKeywords
    }

    /// Decoded by hand only so `emphasizeKeywords` can be **optional on the wire**: synthesized
    /// decoding requires every non-optional key, which would break every preset saved before
    /// v0.6.1. Absent ⇒ `false`, so a legacy preset still produces the prompt it always did.
    /// Encoding stays synthesized, so new presets do persist the flag.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fidelity = try container.decode(Double.self, forKey: .fidelity)
        aspects = try container.decode(Set<TailoredAspect>.self, forKey: .aspects)
        desiredRankMatch = try container.decodeIfPresent(Int.self, forKey: .desiredRankMatch)
        emphasizeKeywords = try container.decodeIfPresent(Bool.self, forKey: .emphasizeKeywords) ?? false
        additionalContext = ""   // per-job, never persisted (see the property's note)
    }

    static let `default` = GenerationSettings()

    /// True for the grounded default — generation then matches the pre-Milestone-D prompt.
    /// Non-empty `additionalContext` makes this false (the prompt is no longer byte-for-byte
    /// the grounded base).
    var isDefault: Bool { self == .default }

    /// Whether the fidelity/aspect/target/keyword controls are all at their defaults — ignores
    /// the free-text `additionalContext`, so context-only generation keeps the base latitude
    /// prompt and merely appends the user's guidance.
    var hasDefaultControls: Bool {
        fidelity == 0 && aspects.isEmpty && desiredRankMatch == nil && !emphasizeKeywords
    }

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
