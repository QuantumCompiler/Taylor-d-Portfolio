//
//  AppSettings.swift
//  Taylor'd Portfolio
//
//  Data · Settings — user-configurable app settings.
//

import Foundation

/// The user's configurable settings: which LLM engine to use and which Adzuna
/// country to search. `Codable` so it can be persisted via a `KeyValueStore`.
///
/// Adzuna credentials are **not** here — they're baked in at build time via
/// `AppConfig` (see Milestone K), so a misconfigured build fails fast rather than
/// silently failing a search. `adzunaCountry` stays a user setting because it's a
/// search preference, not a secret.
nonisolated struct AppSettings: Codable, Equatable, Sendable {
    /// Which LLM engine the router should prefer.
    var llmChoice: LLMChoice
    /// Adzuna country code, e.g. "us", "gb".
    var adzunaCountry: String

    init(
        llmChoice: LLMChoice = .auto,
        adzunaCountry: String = "us"
    ) {
        self.llmChoice = llmChoice
        self.adzunaCountry = adzunaCountry
    }

    /// Fresh defaults for a first launch.
    static let `default` = AppSettings()
}
