//
//  SettingsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · ViewModel
//

import Observation

/// Drives the Settings screen: edits and persists ``AppSettings``.
///
/// Adzuna credentials are baked in at build time (Milestone K), so this screen no
/// longer edits them — it only shows whether the build is configured, alongside the
/// LLM engine choice and the Adzuna country preference.
@MainActor
@Observable
final class SettingsViewModel {
    var llmChoice: LLMChoice
    var adzunaCountry: String

    /// Whether this build has baked Adzuna credentials (read-only status display).
    let adzunaConfigured: Bool

    private let store: SettingsStore

    init(store: SettingsStore, adzunaConfigured: Bool = false) {
        self.store = store
        self.adzunaConfigured = adzunaConfigured
        let settings = store.load()
        self.llmChoice = settings.llmChoice
        self.adzunaCountry = settings.adzunaCountry
    }

    /// The current field values as an ``AppSettings`` value.
    var settings: AppSettings {
        AppSettings(
            llmChoice: llmChoice,
            adzunaCountry: adzunaCountry
        )
    }

    func save() {
        store.save(settings)
    }
}
