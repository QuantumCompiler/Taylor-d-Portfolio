//
//  SettingsView.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · View
//

import SwiftUI

/// Settings: assign an LLM engine (and Claude model) to each task, and choose the
/// Adzuna country. Adzuna credentials are baked in at build time, so they're shown
/// here only as a read-only status.
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                ForEach(viewModel.tasks) { task in
                    engineRow(for: task)
                }
            } header: {
                Text("Engines")
            } footer: {
                Text("Each task runs on its own engine. Claude uses the selected model; "
                    + "On-device uses Apple's Foundation model; Auto tries on-device first, "
                    + "then Claude.")
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
                    .clickableCursor()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }

    /// One task's engine + (conditional) Claude-model controls.
    @ViewBuilder
    private func engineRow(for task: LLMTask) -> some View {
        let config = viewModel.config(for: task)

        VStack(alignment: .leading, spacing: 6) {
            Text(task.displayName).font(.headline)
            Text(task.detail).font(.caption).foregroundStyle(.secondary)

            Picker("Engine", selection: choiceBinding(for: task)) {
                ForEach(LLMChoice.allCases, id: \.self) { choice in
                    Text(choice.displayName).tag(choice)
                }
            }
            .clickableCursor()

            // Only relevant when Claude can be used (Claude, or Auto's fallback).
            if config.choice != .onDevice {
                Picker("Claude model", selection: modelBinding(for: task)) {
                    ForEach(viewModel.claudeModels) { model in
                        Text(model.displayName).tag(model.id)
                    }
                }
                .clickableCursor()
            }
        }
        .padding(.vertical, 4)
    }

    private func choiceBinding(for task: LLMTask) -> Binding<LLMChoice> {
        Binding(
            get: { viewModel.config(for: task).choice },
            set: { viewModel.setChoice($0, for: task) }
        )
    }

    private func modelBinding(for task: LLMTask) -> Binding<String> {
        Binding(
            get: { viewModel.config(for: task).claudeModel },
            set: { viewModel.setModel($0, for: task) }
        )
    }
}

#if DEBUG
#Preview {
    SettingsView(viewModel: SettingsViewModel(store: Preview.settingsStore, adzunaConfigured: true))
}
#endif
