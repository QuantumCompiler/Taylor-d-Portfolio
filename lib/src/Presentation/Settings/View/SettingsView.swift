//
//  SettingsView.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · View
//

import SwiftUI

/// Settings: choose the LLM engine and the Adzuna country. Adzuna credentials are
/// baked in at build time, so they're shown here only as a read-only status.
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
                TextField("Country code", text: $viewModel.adzunaCountry)
                LabeledContent("Credentials") {
                    if viewModel.adzunaConfigured {
                        Label("Configured", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Not configured in this build", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
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
    SettingsView(viewModel: SettingsViewModel(store: Preview.settingsStore, adzunaConfigured: true))
}
#endif
