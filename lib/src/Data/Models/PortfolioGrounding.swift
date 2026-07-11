//
//  PortfolioGrounding.swift
//  Taylor'd Portfolio
//
//  Data · Models — the real document text injected into generation as grounding.
//

import Foundation

/// The candidate's real document text passed into generation alongside the distilled
/// ``CandidateProfile`` (ROADMAP Milestone T). `resumeText` is **factual grounding** —
/// the model may reorder and rephrase it but never add facts absent from it or the profile.
/// `coverLetterText`, when present, is a **voice / tone / structure exemplar** for the
/// generated cover letter only: its style is mirrored, but no facts, metrics, employers,
/// or dates are imported from it.
///
/// Both are the LLM-tidied readable forms (bounded in `Prompts`). Absent/empty grounding
/// falls back to profile-only generation, unchanged.
nonisolated struct PortfolioGrounding: Equatable, Sendable {
    var resumeText: String
    var coverLetterText: String?

    init(resumeText: String, coverLetterText: String? = nil) {
        self.resumeText = resumeText
        self.coverLetterText = coverLetterText
    }
}
