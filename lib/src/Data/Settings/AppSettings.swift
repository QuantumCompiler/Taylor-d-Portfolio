//
//  AppSettings.swift
//  Taylor'd Portfolio
//
//  Data · Settings — user-configurable app settings.
//

import Foundation

/// The user's configurable settings: a per-task LLM engine assignment (each
/// ``LLMTask`` picks its own engine and Claude model) plus the Adzuna country to
/// search. `Codable` so it can be persisted via a `KeyValueStore`.
///
/// Adzuna credentials are **not** here — as of Milestone D they're user-entered into the
/// separate `JobSourceCredentialsStore` (with a build-time `AppConfig` fallback), so they
/// stay out of this `Codable` settings blob. `adzunaCountry` stays a user setting because
/// it's a search preference, not a secret.
nonisolated struct AppSettings: Codable, Equatable, Sendable {
    /// The engine (+ Claude model) chosen for each LLM task. Tasks absent from the map
    /// fall back to ``TaskEngineConfig/default`` via ``config(for:)``.
    var engines: [LLMTask: TaskEngineConfig]
    /// Adzuna country code, e.g. "us", "gb".
    var adzunaCountry: String

    init(
        engines: [LLMTask: TaskEngineConfig] = AppSettings.defaultEngines,
        adzunaCountry: String = "us"
    ) {
        self.engines = engines
        self.adzunaCountry = adzunaCountry
    }

    /// Every task seeded with the default engine config.
    static let defaultEngines: [LLMTask: TaskEngineConfig] =
        Dictionary(uniqueKeysWithValues: LLMTask.allCases.map { ($0, .default) })

    /// Fresh defaults for a first launch.
    static let `default` = AppSettings()

    /// The engine config for `task`, falling back to the default when unset — so a
    /// task added in a later version still resolves against older persisted settings.
    func config(for task: LLMTask) -> TaskEngineConfig {
        engines[task] ?? .default
    }
}
