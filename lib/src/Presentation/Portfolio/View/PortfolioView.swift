//
//  PortfolioView.swift
//  Taylor'd Portfolio
//
//  Presentation · Portfolio · View
//

import SwiftUI
import UniformTypeIdentifiers

/// Import-or-paste-your-portfolio screen: text in, a structured profile out.
struct PortfolioView: View {
    @Bindable var viewModel: PortfolioViewModel
    @State private var showResumeImporter = false
    @State private var showCoverLetterImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio").font(.largeTitle.bold())
            Text("Import or paste your résumé / portfolio (required) — we distil a structured profile from it. You can also add an optional cover letter, used only as a voice and tone example when generating.")
                .foregroundStyle(.secondary)

            documentSlot(
                title: "Résumé / portfolio",
                fileName: viewModel.sourceFileName,
                text: $viewModel.portfolioText,
                minHeight: 180
            ) { showResumeImporter = true }
            .fileImporter(
                isPresented: $showResumeImporter,
                allowedContentTypes: Self.allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    Task { await viewModel.importDocument(from: url) }
                }
            }

            documentSlot(
                title: "Cover letter (optional)",
                fileName: viewModel.coverLetterFileName,
                text: $viewModel.coverLetterText,
                minHeight: 120
            ) { showCoverLetterImporter = true }
            .fileImporter(
                isPresented: $showCoverLetterImporter,
                allowedContentTypes: Self.allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    Task { await viewModel.importCoverLetter(from: url) }
                }
            }

            HStack(spacing: 12) {
                Button("Build Profile") {
                    Task { await viewModel.build() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canBuild)

                if viewModel.isBusy {
                    ProgressView().controlSize(.small)
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(.callout).foregroundStyle(.red)
                }
            }

            if let profile = viewModel.profile {
                ProfileSummary(profile: profile, isDefault: viewModel.isSelectedProfileDefault)
                if hasSourceDocuments {
                    sourceDocumentsSection
                }
                if viewModel.supportsSavedProfiles {
                    saveRow
                }
            }

            if viewModel.supportsSavedProfiles && !viewModel.savedProfiles.isEmpty {
                savedProfilesSection
            }
        }
        .padding(24)
        .scrollableScreen()
        .task { await viewModel.reloadProfiles() }
    }

    /// A labelled import-or-paste slot for one document (résumé or cover letter).
    private func documentSlot(
        title: String,
        fileName: String?,
        text: Binding<String>,
        minHeight: CGFloat,
        onImport: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(title).font(.headline)
                if let fileName {
                    Text("· \(fileName)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onImport) {
                    Label("Import…", systemImage: "doc.badge.plus")
                }
                .disabled(viewModel.isBusy)
            }
            TextEditor(text: text)
                .font(.body.monospaced())
                .frame(minHeight: minHeight)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        }
    }

    /// Whether either document has readable text to show under the profile.
    private var hasSourceDocuments: Bool {
        !viewModel.readableText.isEmpty || !viewModel.coverLetterReadableText.isEmpty
    }

    /// Shows the documents this profile was built on, in their LLM-tidied readable form —
    /// each collapsed by default since they can be long.
    private var sourceDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.readableText.isEmpty {
                documentDisclosure(
                    label: viewModel.sourceFileName.map { "Résumé — \($0)" } ?? "Résumé / portfolio",
                    text: viewModel.readableText
                )
            }
            if !viewModel.coverLetterReadableText.isEmpty {
                documentDisclosure(
                    label: viewModel.coverLetterFileName.map { "Cover letter — \($0)" } ?? "Cover letter",
                    text: viewModel.coverLetterReadableText
                )
            }
        }
    }

    /// One collapsed, scrollable readable-document disclosure.
    private func documentDisclosure(label: String, text: String) -> some View {
        DisclosureGroup {
            ScrollView {
                Text(text)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
            .frame(maxHeight: 220)
        } label: {
            Label(label, systemImage: "doc.text").font(.headline)
        }
    }

    /// Name-and-save controls for the currently-built (or loaded) profile.
    private var saveRow: some View {
        HStack(spacing: 12) {
            TextField("Profile name", text: $viewModel.profileName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)
            Button(viewModel.selectedProfileID == nil ? "Save Profile" : "Update Profile") {
                Task { await viewModel.saveProfile() }
            }
            .disabled(!viewModel.canSaveProfile)
        }
    }

    /// The saved-profile library: tap to load one, long-press to set it as the default
    /// (auto-loaded on launch), or delete it.
    private var savedProfilesSection: some View {
        GroupBox("Saved profiles") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(viewModel.savedProfiles) { saved in
                    savedProfileRow(saved)
                }
                Text("Tap to load a profile · long-press to set it as your default (loads on launch).")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }

    /// One saved-profile row. Tap **anywhere on the tile** toggles selection; long-press
    /// **anywhere** toggles default. The dial is only an indicator, and the trash button
    /// still intercepts its own taps.
    private func savedProfileRow(_ saved: SavedProfile) -> some View {
        let isSelected = viewModel.selectedProfileID == saved.id
        let isDefault = viewModel.isDefault(saved)
        return HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(saved.name).font(.callout)
                        if isDefault {
                            Image(systemName: "star.fill")
                                .font(.caption2).foregroundStyle(.yellow)
                                .help("Default profile")
                        }
                    }
                    Text("\(saved.profile.seniority) · \(saved.profile.yearsExperience) yrs")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive) {
                Task { await viewModel.delete(saved) }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        // Make the whole tile (including the Spacer and padding) the hit target.
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleSelection(saved) }
        // A simultaneous long-press so it coexists with the tap-to-select instead of
        // the two gestures cancelling each other out. The trash Button, being a control,
        // still handles its own taps and isn't triggered by this row gesture.
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in viewModel.setDefault(saved) }
        )
        .help(isDefault ? "Default — long-press to unset · tap to load"
                        : "Tap to load · long-press to set as default")
    }

    /// Document types accepted by the importer.
    private static var allowedTypes: [UTType] {
        var types: [UTType] = [.pdf, .plainText, .rtf]
        let identifiers = [
            "org.openxmlformats.wordprocessingml.document", // .docx
            "com.microsoft.word.doc",                       // .doc
            "com.apple.rtfd",                               // .rtfd
            "net.daringfireball.markdown",                  // .md
        ]
        types.append(contentsOf: identifiers.compactMap { UTType($0) })
        return types
    }
}

/// A compact read-only summary of a built profile.
private struct ProfileSummary: View {
    let profile: CandidateProfile
    /// Whether this loaded profile is the user's default (shows the same ⭐ as Search).
    var isDefault = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(profile.seniority) · \(profile.yearsExperience) yrs experience").font(.headline)
                Text(profile.summary).font(.callout).foregroundStyle(.secondary)
                if !profile.coreSkills.isEmpty {
                    Text("Skills: " + profile.coreSkills.joined(separator: ", "))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            HStack(spacing: 4) {
                Text("Your profile")
                if isDefault {
                    Image(systemName: "star.fill")
                        .font(.caption2).foregroundStyle(.yellow)
                        .help("Default profile")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    PortfolioView(viewModel: PortfolioViewModel(buildProfile: Preview.buildProfile, importPortfolio: Preview.importPortfolio))
}
#endif
