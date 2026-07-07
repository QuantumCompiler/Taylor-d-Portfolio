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
        store.save(AppSettings(llmChoice: .claude, adzunaAppID: "id", adzunaAppKey: "key", adzunaCountry: "gb"))

        let vm = SettingsViewModel(store: store)
        #expect(vm.llmChoice == .claude)
        #expect(vm.adzunaAppID == "id")
        #expect(vm.adzunaCountry == "gb")
    }

    @Test func saveThenReloadPersists() {
        let backing = PresentationMemoryStore()
        let vm = SettingsViewModel(store: SettingsStore(store: backing))
        vm.llmChoice = .onDevice
        vm.adzunaAppID = "newid"
        vm.save()

        let reloaded = SettingsViewModel(store: SettingsStore(store: backing))
        #expect(reloaded.llmChoice == .onDevice)
        #expect(reloaded.adzunaAppID == "newid")
    }

    @Test func defaultsWhenNothingStored() {
        let vm = SettingsViewModel(store: SettingsStore(store: PresentationMemoryStore()))
        #expect(vm.llmChoice == .auto)
        #expect(vm.adzunaCountry == "us")
    }
}
