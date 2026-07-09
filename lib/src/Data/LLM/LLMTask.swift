//
//  LLMTask.swift
//  Taylor'd Portfolio
//
//  Data · LLM — the distinct LLM jobs the user can assign an engine to.
//

import Foundation

/// A user-facing LLM job that can be routed to its own engine.
///
/// Each `LLMProvider` method maps to exactly one task, so the router can consult a
/// per-task engine preference instead of one global choice. Two-stage application
/// generation (`buildTargetBrief` + `generateApplication`) shares a single task —
/// the user thinks of it as "writing the resume & cover letter", not two steps.
nonisolated enum LLMTask: String, Codable, Equatable, Hashable, Sendable, CaseIterable, Identifiable {
    /// Distilling a raw portfolio into a ``CandidateProfile``.
    case profile
    /// Scoring search results against the profile.
    case ranking
    /// Reading a pasted job link/text into a structured posting.
    case extraction
    /// Writing tailored application materials (brief + resume + cover letter).
    case application

    var id: String { rawValue }

    /// Short label shown in Settings.
    var displayName: String {
        switch self {
        case .profile:     return "Profile"
        case .ranking:     return "Job ranking"
        case .extraction:  return "Posting extraction"
        case .application: return "Resume & cover letter"
        }
    }

    /// One-line explanation of what the task does.
    var detail: String {
        switch self {
        case .profile:     return "Distilling your portfolio into a candidate profile."
        case .ranking:     return "Scoring search results against your profile."
        case .extraction:  return "Reading a pasted job link into a structured posting."
        case .application: return "Writing your tailored resume and cover letter."
        }
    }
}
