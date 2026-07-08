//
//  SettingsViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · ViewModel
//

import Observation

/// Drives the Settings screen: edits and persists ``AppSettings``.
@MainActor
@Observable
final class SettingsViewModel {
    var llmChoice: LLMChoice
    var adzunaAppID: String
    var adzunaAppKey: String
    var adzunaCountry: String

    private let store: SettingsStore

    init(store: SettingsStore) {
        self.store = store
        let settings = store.load()
        self.llmChoice = settings.llmChoice
        self.adzunaAppID = settings.adzunaAppID
        self.adzunaAppKey = settings.adzunaAppKey
        self.adzunaCountry = settings.adzunaCountry
    }

    /// The current field values as an ``AppSettings`` value.
    var settings: AppSettings {
        AppSettings(
            llmChoice: llmChoice,
            adzunaAppID: adzunaAppID,
            adzunaAppKey: adzunaAppKey,
            adzunaCountry: adzunaCountry
        )
    }

    func save() {
        store.save(settings)
    }
}
