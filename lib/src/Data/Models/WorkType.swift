//
//  WorkType.swift
//  Taylor'd Portfolio
//
//  Data · Models — how a role is worked (on-site / remote / hybrid).
//

import Foundation

/// How a role is worked. LLM-extracted from a posting (v0.6.0 Milestone A-B) — Adzuna gives
/// no structured field for it. Optional everywhere, since many postings don't state it.
///
/// A plain domain enum (deliberately *not* `Generable`): the LLM output type
/// ``PostingDetails`` carries the raw string and maps it here via ``init(loose:)``, so the
/// model never has to satisfy an enum schema and lenient wording still resolves.
nonisolated enum WorkType: String, CaseIterable, Codable, Sendable, Identifiable {
    case onSite = "on_site"
    case remote
    case hybrid

    var id: String { rawValue }

    /// A human-readable label for badges / chips.
    var label: String {
        switch self {
        case .onSite: return "On-site"
        case .remote: return "Remote"
        case .hybrid: return "Hybrid"
        }
    }

    /// A lenient parse of a free-form model string ("on-site", "onsite", "in office",
    /// "Remote", "hybrid"). Returns nil when the text names no recognizable work type, so an
    /// unstated / unclear value stays absent rather than guessed.
    init?(loose text: String) {
        let normalized = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        switch normalized {
        case "onsite", "inoffice", "office", "onpremises", "onprem": self = .onSite
        case "remote", "fullyremote", "remotefirst": self = .remote
        case "hybrid", "flexible": self = .hybrid
        default: return nil
        }
    }
}
