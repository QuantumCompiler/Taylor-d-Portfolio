//
//  GenerationPreset.swift
//  Taylor'd Portfolio
//
//  Data · Models — a named, persisted GenerationSettings the user can reuse (Milestone D-D).
//

import Foundation

/// A ``GenerationSettings`` the user has saved under a name so they can reuse it on any job
/// (Milestone D-D). `id` is a stable identifier assigned at first save; `createdAt` orders
/// the library (newest first). Presets are **global** — not tied to a job.
nonisolated struct GenerationPreset: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var settings: GenerationSettings
    var createdAt: Date

    init(id: String, name: String, settings: GenerationSettings, createdAt: Date) {
        self.id = id
        self.name = name
        self.settings = settings
        self.createdAt = createdAt
    }

    /// A friendly default name derived from the settings — a rank target, or the fidelity
    /// band plus any selected sections.
    static func defaultName(for settings: GenerationSettings) -> String {
        if let target = settings.desiredRankMatch {
            return "Rank ≥ \(target)"
        }
        let band: String
        switch settings.band {
        case .authentic: band = "Authentic"
        case .curated: band = "Curated"
        case .embellished: band = "Embellished"
        }
        guard !settings.aspects.isEmpty else { return band }
        let names = settings.aspects
            .sorted { $0.rawValue < $1.rawValue }
            .map(\.label)
            .joined(separator: ", ")
        return "\(band) · \(names)"
    }
}
