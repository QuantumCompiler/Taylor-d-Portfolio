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
    /// Bumped by the hosting window on every open request, so the single-instance
    /// Application window reloads the saved materials when re-opened for a different job.
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
    @State private var showOptions = true

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
                if viewModel.kit == nil {
                    Button("Generate application") { runGeneration() }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isGenerating)
                        .clickableCursor()
                } else {
                    Button("Regenerate") { runGeneration() }
                        .disabled(viewModel.isGenerating)
                        .clickableCursor()
                }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .clickableCursor()
            }
            lengthGateBanner
            generationControlsPanel
            embellishWarning
            Divider()
            content
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 440)
        // Load saved materials if present — but never auto-generate. Generation is started
        // explicitly with the Generate button so the user can set options first (v0.5.0).
        .task { await viewModel.loadSaved(for: job) }
        .onChange(of: requestID) { _, _ in Task { await viewModel.loadSaved(for: job) } }
        // The one-page gate is template-dependent — remeasure when the user switches template.
        .onChange(of: viewModel.exportTemplate) { _, _ in viewModel.refreshLengthGate() }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { _ in }
    }

    // MARK: Generation controls (Milestone D)

    /// The fidelity slider + tailored-aspect checkboxes. Changes apply when the user presses
    /// Generate / Regenerate (the controls drive `viewModel.generationSettings`).
    private var generationControlsPanel: some View {
        DisclosureGroup("Generation options", isExpanded: $showOptions) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Fidelity").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(fidelityLabel).font(.caption.bold())
                    }
                    Slider(value: $viewModel.generationSettings.fidelity, in: 0...1, step: 0.05)
                        .clickableCursor()
                    HStack {
                        Text("Authentic")
                        Spacer()
                        Text("Curated")
                        Spacer()
                        Text("Embellished")
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tailor (none checked = all sections)").font(.caption).foregroundStyle(.secondary)
                    ForEach(TailoredAspect.allCases) { aspect in
                        Toggle(aspect.label, isOn: aspectBinding(aspect))
                            .toggleStyle(.checkbox)
                            .clickableCursor()
                    }
                }
                Text("Changes apply when you Regenerate.").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clickableCursor()
    }

    private var fidelityLabel: String {
        switch viewModel.generationSettings.band {
        case .authentic: return "Authentic"
        case .curated: return "Curated"
        case .embellished: return "Embellished"
        }
    }

    private func aspectBinding(_ aspect: TailoredAspect) -> Binding<Bool> {
        Binding(
            get: { viewModel.generationSettings.aspects.contains(aspect) },
            set: { isOn in
                if isOn { viewModel.generationSettings.aspects.insert(aspect) }
                else { viewModel.generationSettings.aspects.remove(aspect) }
            }
        )
    }

    /// The disclosure warning shown whenever the fidelity is in the embellished band
    /// (Milestone D-E): generated content may include unverified additions.
    @ViewBuilder private var embellishWarning: some View {
        if viewModel.generationSettings.mayEmbellish {
            Label(
                "Embellished mode may add unverified content. Review the Gaps note (lines marked "
                + "\"EMBELLISHED:\") and verify everything before sending — this is a draft.",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        }
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

    /// Explicitly generates (or regenerates) the application with the current options, then
    /// signals `onGenerated` so the lists + detail refresh (v0.5.0).
    private func runGeneration() {
        Task {
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
            ContentUnavailableView(
                "Ready to generate",
                systemImage: "sparkles",
                description: Text("Set your fidelity and which sections to tailor above, then press **Generate application**.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
