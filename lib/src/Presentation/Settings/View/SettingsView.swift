//
//  SettingsView.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · View
//

import SwiftUI

/// Settings: choose the LLM engine and enter Adzuna credentials.
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Engine") {
                Picker("LLM engine", selection: $viewModel.llmChoice) {
                    Text("Auto (on-device first)").tag(LLMChoice.auto)
                    Text("On-device only").tag(LLMChoice.onDevice)
                    Text("Claude").tag(LLMChoice.claude)
                }
            }

            Section("Adzuna") {
                TextField("App ID", text: $viewModel.adzunaAppID)
                TextField("App Key", text: $viewModel.adzunaAppKey)
                TextField("Country code", text: $viewModel.adzunaCountry)
            }

            Section {
                Button("Save") { viewModel.save() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}

#if DEBUG
#Preview {
    SettingsView(viewModel: SettingsViewModel(store: Preview.settingsStore))
}
#endif
