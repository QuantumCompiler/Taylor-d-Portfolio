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
    @State private var showImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio").font(.largeTitle.bold())
            Text("Import a document (PDF, Word, RTF, or text) or paste your resume, projects, and links below. We'll distil a structured profile.")
                .foregroundStyle(.secondary)

            TextEditor(text: $viewModel.portfolioText)
                .font(.body.monospaced())
                .frame(minHeight: 200)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            HStack(spacing: 12) {
                Button {
                    showImporter = true
                } label: {
                    Label("Import Document…", systemImage: "doc.badge.plus")
                }
                .disabled(viewModel.isBusy)

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
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: Self.allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    Task { await viewModel.importDocument(from: url) }
                }
            }

            if let profile = viewModel.profile {
                ProfileSummary(profile: profile)
            }

            Spacer()
        }
        .padding(24)
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

    var body: some View {
        GroupBox("Your profile") {
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
        }
    }
}

#if DEBUG
#Preview {
    PortfolioView(viewModel: PortfolioViewModel(buildProfile: Preview.buildProfile, importPortfolio: Preview.importPortfolio))
}
#endif
