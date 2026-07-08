//
//  ApplicationSheet.swift
//  Taylor'd Portfolio
//
//  Presentation · Application · View
//

import SwiftUI

/// A sheet that generates and shows a tailored resume + cover letter for one job.
struct ApplicationSheet: View {
    @Bindable var viewModel: ApplicationViewModel
    let job: JobListing
    let profile: CandidateProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("Application").font(.title2.bold())
                    Text("\(job.title) · \(job.company)").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            Divider()
            content
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 440)
        .task { await viewModel.generate(for: job, profile: profile) }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isGenerating {
            ProgressView("Generating…").frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let kit = viewModel.kit {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section("Resume", kit.resumeMarkdown)
                    section("Cover letter", kit.coverLetter)
                    if !kit.gapNote.isEmpty {
                        section("Gaps", kit.gapNote, secondary: true)
                    }
                }
            }
        } else if let error = viewModel.errorMessage {
            ContentUnavailableView("Couldn't generate", systemImage: "exclamationmark.triangle", description: Text(error))
        } else {
            Spacer()
        }
    }

    private func section(_ title: String, _ text: String, secondary: Bool = false) -> some View {
        GroupBox(title) {
            Text(text)
                .font(.callout)
                .foregroundStyle(secondary ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
        }
    }
}

#if DEBUG
#Preview {
    ApplicationSheet(
        viewModel: ApplicationViewModel(generateApplication: Preview.generateApplication),
        job: Preview.sampleListings[0],
        profile: Preview.sampleProfile
    )
}
#endif
