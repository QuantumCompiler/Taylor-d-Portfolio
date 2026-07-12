//
//  SettingsView.swift
//  Taylor'd Portfolio
//
//  Presentation · Settings · View
//

import SwiftUI
import AppKit

/// Settings: assign an LLM engine (and Claude model) to each task, and choose the
/// Adzuna country. Adzuna credentials are baked in at build time, so they're shown
/// here only as a read-only status.
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    /// Which settings sub-view to show (v0.4.0 Milestone B). Defaults to the engines
    /// pane, so `#Preview`s and any direct callers keep their prior behaviour.
    var section: SettingsSection = .engines

    var body: some View {
        Form {
            switch section {
            case .engines: enginesSection
            case .adzuna: adzunaSection
            case .about: aboutSection
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Engines — per-task engine + Claude model

    private var enginesSection: some View {
        Section {
            ForEach(viewModel.tasks) { task in
                engineRow(for: task)
            }
        } header: {
            Text("Engines")
        } footer: {
            // The Save control lives in the section footer: attached to the end of the section
            // and scrolling with it, but with no grouped-section background band (v0.4.1 G).
            VStack(alignment: .leading, spacing: 12) {
                Text("Each task runs on its own engine. Claude uses the selected model; "
                    + "On-device uses Apple's Foundation model; Auto tries on-device first, "
                    + "then Claude.")
                saveButton
            }
        }
    }

    // MARK: Adzuna — country code + baked-in credentials status

    private var adzunaSection: some View {
        Section {
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
        } header: {
            Text("Adzuna")
        } footer: {
            saveButton
        }
    }

    /// The shared Save control for the settings-editing panes. Placed in the section **footer**,
    /// so it's attached to the end of the section and scrolls with the content, but carries no
    /// grouped-section background band (footers render outside the section's rounded fill).
    private var saveButton: some View {
        Button("Save") { viewModel.save() }
            .buttonStyle(.borderedProminent)
            .clickableCursor()
            .padding(.top, 2)
    }

    // MARK: About — app identity (Milestone C)

    private var aboutSection: some View {
        Section("About") {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Taylor'd Portfolio").font(.headline)
                    Text("Version \(appVersion)").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            Text("Searches jobs, ranks them against your portfolio, and generates a tailored "
                + "résumé & cover letter for a job you pick — human-in-the-loop, never auto-submitting.")
                .font(.callout).foregroundStyle(.secondary)
        }
    }

    /// The app's marketing version (`CFBundleShortVersionString`), read from the bundle.
    /// This project versions by `v0.x.0` milestones, so the build number isn't shown.
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
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
