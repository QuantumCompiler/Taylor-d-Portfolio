//
//  SettingsViewModelTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Presentation · Settings
//

import Testing
@testable import Taylor_d_Portfolio

@MainActor
@Suite("SettingsViewModel")
struct SettingsViewModelTests {

    @Test func loadsExistingSettings() {
        let store = SettingsStore(store: PresentationMemoryStore())
        var settings = AppSettings.default
        settings.engines[.profile] = TaskEngineConfig(choice: .claude, claudeModel: "claude-fable-5")
        settings.engines[.ranking] = TaskEngineConfig(choice: .onDevice)
        settings.adzunaCountry = "gb"
        store.save(settings)

        let vm = SettingsViewModel(store: store)
        #expect(vm.config(for: .profile).choice == .claude)
        #expect(vm.config(for: .profile).claudeModel == "claude-fable-5")
        #expect(vm.config(for: .ranking).choice == .onDevice)
        #expect(vm.adzunaCountry == "gb")
    }

    @Test func saveThenReloadPersists() {
        let backing = PresentationMemoryStore()
        let vm = SettingsViewModel(store: SettingsStore(store: backing))
        vm.setChoice(.onDevice, for: .profile)
        vm.setChoice(.claude, for: .application)
        vm.setModel("claude-haiku-4-5", for: .application)
        vm.adzunaCountry = "ca"
        vm.save()

        let reloaded = SettingsViewModel(store: SettingsStore(store: backing))
        #expect(reloaded.config(for: .profile).choice == .onDevice)
        #expect(reloaded.config(for: .application).choice == .claude)
        #expect(reloaded.config(for: .application).claudeModel == "claude-haiku-4-5")
        #expect(reloaded.adzunaCountry == "ca")
    }

    @Test func defaultsWhenNothingStored() {
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()))
        #expect(vm.adzunaCountry == "us")
        #expect(vm.config(for: .profile).choice == .claude)
        #expect(vm.config(for: .profile).claudeModel == "claude-opus-4-8")
        #expect(vm.claudeModels.count == ClaudeModel.all.count)
        #expect(vm.tasks.count == LLMTask.allCases.count)
    }

    @Test func exposesConfiguredStatus() {
        let store = SettingsStore(store: PresentationMemoryStore())
        #expect(SettingsViewModel(store: store, adzunaConfigured: true).adzunaConfigured)
        #expect(SettingsViewModel(store: store, adzunaConfigured: false).adzunaConfigured == false)
        // Defaults to not-configured when the flag isn't supplied.
        #expect(SettingsViewModel(store: store).adzunaConfigured == false)
    }
}
