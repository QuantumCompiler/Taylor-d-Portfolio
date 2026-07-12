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
    /// The candidate's real documents for grounded generation (Milestone T); nil falls
    /// back to profile-only generation.
    var grounding: PortfolioGrounding? = nil
    /// Whether to load saved materials or force a fresh regeneration on appear (v0.5.0
    /// Milestone A). Defaults to view-or-generate — the prior behaviour.
    var startMode: ApplicationStartMode = .viewOrGenerate
    /// Bumped by the hosting window on every open request, so the single-instance
    /// Application window re-runs its start mode even when it's already open (v0.5.0 B-C).
    var requestID: Int = 0
    /// Called after fresh materials are generated, so the hosting window can signal the
    /// lists + detail view to reload (v0.5.0 Milestone B-C).
    var onGenerated: (() -> Void)? = nil
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
                    .clickableCursor()

                    Menu {
                        Button("PDF (.pdf)") { startExport(.pdf) }
                        Button("Word (.docx)") { startExport(.docx) }
                        Button("Markdown (.md)") { startExport(.markdown) }
                        Button("Plain Text (.txt)") { startExport(.plainText) }
                        Divider()
                        Picker("PDF template", selection: $viewModel.exportTemplate) {
                            ForEach(ExportTemplate.allCases) { template in
                                Text(template.displayName).tag(template)
                            }
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .clickableCursor()
                }
                if viewModel.kit != nil {
                    Button("Regenerate") {
                        Task {
                            await viewModel.generate(for: job, profile: profile, grounding: grounding)
                            onGenerated?()
                        }
                    }
                    .disabled(viewModel.isGenerating)
                    .clickableCursor()
                }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .clickableCursor()
            }
            lengthGateBanner
            Divider()
            content
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 440)
        .task { await runStartMode() }
        // Re-run when the hosting window re-opens for a new request (e.g. View → Regenerate
        // on the same job) — the single-instance window keeps this view alive (v0.5.0 B-C).
        .onChange(of: requestID) { _, _ in Task { await runStartMode() } }
        // The one-page gate is template-dependent — remeasure when the user switches template.
        .onChange(of: viewModel.exportTemplate) { _, _ in viewModel.refreshLengthGate() }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { _ in }
    }

    /// A surfaced one-page warning (Milestone X): the résumé runs long in the chosen
    /// template. Advisory only — we never truncate; we suggest tightening or the Compact
    /// template.
    @ViewBuilder private var lengthGateBanner: some View {
        if viewModel.resumeExceedsOnePage {
            let pages = viewModel.resumePageCount
            Label {
                Text("Résumé is \(pages) pages in the \(viewModel.exportTemplate.displayName) template — "
                     + (viewModel.exportTemplate == .compact
                        ? "tighten the content to fit one page."
                        : "try the Compact template or tighten the content to fit one page."))
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    /// Loads saved materials or forces a fresh generation per `startMode`, signalling
    /// `onGenerated` whenever fresh output was produced (v0.5.0 Milestone B-C).
    private func runStartMode() async {
        switch startMode {
        case .viewOrGenerate:
            await viewModel.open(for: job, profile: profile, grounding: grounding)
            // `open` generates when nothing was saved — `isSaved` distinguishes the two.
            if !viewModel.isSaved { onGenerated?() }
        case .forceGenerate:
            await viewModel.generate(for: job, profile: profile, grounding: grounding)
            onGenerated?()
        }
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
                    documentSection("Résumé", kit.resumeMarkdown)
                    documentSection("Cover letter", kit.coverLetter)
                    if !kit.gapNote.isEmpty {
                        gapsSection(kit.gapNote)
                    }
                }
            }
        } else if let error = viewModel.errorMessage {
            ContentUnavailableView("Couldn't generate", systemImage: "exclamationmark.triangle", description: Text(error))
        } else {
            Spacer()
        }
    }

    /// A generated document (résumé / cover letter): styled Markdown + a per-document
    /// **copy** button that puts that document's raw Markdown on the clipboard (S-A).
    private func documentSection(_ title: String, _ markdown: String) -> some View {
        GroupBox {
            MarkdownText(markdown: markdown)
                .padding(4)
        } label: {
            HStack {
                Text(title)
                Spacer()
                Button { copy(markdown) } label: {
                    Label("Copy", systemImage: "doc.on.doc").labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Copy the \(title.lowercased()) (Markdown)")
                .clickableCursor()
            }
        }
    }

    /// The advisory gap note — plain secondary text, not part of the deliverable.
    private func gapsSection(_ text: String) -> some View {
        GroupBox("Gaps") {
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
        }
    }

    /// Copies raw text to the clipboard.
    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
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
