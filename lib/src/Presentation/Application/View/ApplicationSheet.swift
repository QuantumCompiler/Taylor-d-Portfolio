//
//  ApplicationSheet.swift
//  Taylor'd Portfolio
//
//  Presentation · Application · View
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A sheet that generates and shows a tailored resume + cover letter for one job.
struct ApplicationSheet: View {
    @Bindable var viewModel: ApplicationViewModel
    let job: JobListing
    let profile: CandidateProfile
    @Environment(\.dismiss) private var dismiss

    // Export state for the save panel.
    @State private var exportDocument: ExportFileDocument?
    @State private var exportContentType: UTType = .plainText
    @State private var exportFilename = "Application"
    @State private var isExporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Text("Application").font(.title2.bold())
                        if viewModel.isSaved {
                            Label("Saved", systemImage: "clock.arrow.circlepath")
                                .font(.caption).foregroundStyle(.secondary)
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    Text("\(job.title) · \(job.company)").foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.canExport {
                    Button { copyToClipboard() } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .help("Copy the résumé + cover letter (Markdown) to the clipboard")

                    Menu {
                        Button("PDF (.pdf)") { startExport(.pdf) }
                        Button("Word (.docx)") { startExport(.docx) }
                        Button("Markdown (.md)") { startExport(.markdown) }
                        Button("Plain Text (.txt)") { startExport(.plainText) }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                if viewModel.kit != nil {
                    Button("Regenerate") { Task { await viewModel.generate(for: job, profile: profile) } }
                        .disabled(viewModel.isGenerating)
                }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            Divider()
            content
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 440)
        .task { await viewModel.open(for: job, profile: profile) }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { _ in }
    }

    /// Renders the kit to `format` and presents the save panel.
    private func startExport(_ format: ExportFormat) {
        guard let data = viewModel.exportData(format) else { return }
        exportDocument = ExportFileDocument(data: data, contentType: format.contentType)
        exportContentType = format.contentType
        exportFilename = "\(viewModel.exportFilenameBase).\(format.fileExtension)"
        isExporting = true
    }

    /// Copies the assembled Markdown document to the clipboard.
    private func copyToClipboard() {
        guard let text = viewModel.exportedText(.markdown) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
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
