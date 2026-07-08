//
//  AppSettings.swift
//  Taylor'd Portfolio
//
//  Data · Settings — user-configurable app settings.
//

import Foundation

/// The user's configurable settings: which LLM engine to use and the Adzuna
/// credentials. `Codable` so it can be persisted via a `KeyValueStore`.
nonisolated struct AppSettings: Codable, Equatable, Sendable {
    /// Which LLM engine the router should prefer.
    var llmChoice: LLMChoice
    var adzunaAppID: String
    var adzunaAppKey: String
    /// Adzuna country code, e.g. "us", "gb".
    var adzunaCountry: String

    init(
        llmChoice: LLMChoice = .auto,
        adzunaAppID: String = "",
        adzunaAppKey: String = "",
        adzunaCountry: String = "us"
    ) {
        self.llmChoice = llmChoice
        self.adzunaAppID = adzunaAppID
        self.adzunaAppKey = adzunaAppKey
        self.adzunaCountry = adzunaCountry
    }

    /// Fresh defaults for a first launch.
    static let `default` = AppSettings()

    /// Whether both Adzuna credentials are present (searching is possible).
    var hasAdzunaCredentials: Bool {
        !adzunaAppID.isEmpty && !adzunaAppKey.isEmpty
    }

    /// The Adzuna credentials in the shape `AdzunaJobSource` expects.
    var adzunaCredentials: AdzunaJobSource.Credentials {
        .init(appID: adzunaAppID, appKey: adzunaAppKey, country: adzunaCountry)
    }
}
