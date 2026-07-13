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
                        ForEach(ApplicationDocument.allCases) { document in
                            if viewModel.canExport(document) {
                                Menu(document.displayName) {
                                    Button("PDF (.pdf)") { startExport(document, .pdf) }
                                    Button("Word (.docx)") { startExport(document, .docx) }
                                    Button("Markdown (.md)") { startExport(document, .markdown) }
                                    Button("Plain Text (.txt)") { startExport(document, .plainText) }
                                    Divider()
                                    // The awesome-cv route (Milestone D): PDF needs a TeX install;
                                    // the .tex source is deterministic and always offered.
                                    if viewModel.canExportLaTeX(document) {
                                        Button("PDF — Portfolio (LaTeX)") { startLaTeXExport(document) }
                                    }
                                    Button("LaTeX source (.tex)") { startTexExport(document) }
                                }
                            }
                        }
                        if !viewModel.canExportLaTeX {
                            Divider()
                            Text("Portfolio PDF needs a TeX install (lualatex)")
                        }
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

                    if viewModel.isCompilingLaTeX {
                        ProgressView().controlSize(.small)
                            .help("Compiling the awesome-cv PDF with lualatex…")
                    }
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
            latexNotices
            generationControlsPanel
            embellishWarning
            rankOutcomeBanner
            Divider()
            content
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 440)
        // Load saved materials if present — but never auto-generate. Generation is started
        // explicitly with the Generate button so the user can set options first (v0.5.0).
        .task {
            await viewModel.loadSaved(for: job)
            await viewModel.loadPresets()
        }
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
                rankTargetControl
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Fidelity").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(fidelityLabel).font(.caption.bold())
                    }
                    Slider(value: $viewModel.generationSettings.fidelity, in: 0...1, step: 0.05)
                        .clickableCursor()
                        .disabled(rankTargetOn)
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
                .disabled(rankTargetOn)
                .opacity(rankTargetOn ? 0.5 : 1)
                // Free-text steering (Milestone I). Stays enabled under a rank target — the
                // guidance is honoured on both the single-pass and outcome-driven paths.
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional context (optional)").font(.caption).foregroundStyle(.secondary)
                    TextField("e.g. lean into the API-gateway angle for this role",
                              text: $viewModel.generationSettings.additionalContext, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                        .clickableCursor()
                }
                if viewModel.canManagePresets {
                    Divider()
                    presetsRow
                }
                Text("Changes apply when you Generate / Regenerate.").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clickableCursor()
    }

    /// Apply a saved preset, delete one, or save the current settings as a new preset (D-D).
    private var presetsRow: some View {
        HStack {
            Menu {
                if viewModel.presets.isEmpty {
                    Text("No saved presets")
                } else {
                    ForEach(viewModel.presets) { preset in
                        Button(preset.name) { viewModel.applyPreset(preset) }
                    }
                    Divider()
                    Menu("Delete…") {
                        ForEach(viewModel.presets) { preset in
                            Button(preset.name, role: .destructive) {
                                Task { await viewModel.deletePreset(preset) }
                            }
                        }
                    }
                }
            } label: {
                Label("Presets", systemImage: "slider.horizontal.3")
            }
            .fixedSize()
            .clickableCursor()
            Spacer()
            Button("Save as preset") { Task { await viewModel.saveCurrentAsPreset() } }
                .clickableCursor()
        }
    }

    private var fidelityLabel: String {
        switch viewModel.generationSettings.band {
        case .authentic: return "Authentic"
        case .curated: return "Curated"
        case .embellished: return "Embellished"
        }
    }

    /// Whether a rank target is engaged (D-F) — it overrides fidelity + aspects.
    private var rankTargetOn: Bool { viewModel.generationSettings.desiredRankMatch != nil }

    /// The rank-target master control (D-F): when on, generation fabricates as needed to hit
    /// a target score and overrides fidelity + aspects.
    private var rankTargetControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Target a match score", isOn: rankTargetBinding)
                .toggleStyle(.switch)
                .clickableCursor()
            if let target = viewModel.generationSettings.desiredRankMatch {
                HStack {
                    Slider(value: rankTargetSliderBinding, in: 0...100, step: 5).clickableCursor()
                    Text("\(target)").font(.caption.bold()).monospacedDigit().frame(width: 34, alignment: .trailing)
                }
                Label("Fabricates as needed to hit this score — overrides fidelity & sections. Verify before sending.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2).foregroundStyle(.orange)
            }
        }
    }

    private var rankTargetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.generationSettings.desiredRankMatch != nil },
            set: { on in viewModel.generationSettings.desiredRankMatch = on ? 80 : nil }
        )
    }

    private var rankTargetSliderBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.generationSettings.desiredRankMatch ?? 80) },
            set: { viewModel.generationSettings.desiredRankMatch = Int($0) }
        )
    }

    /// The achieved-score note after a rank-target generation (D-F).
    @ViewBuilder private var rankOutcomeBanner: some View {
        if let note = viewModel.rankOutcomeNote {
            let reached = viewModel.rankOutcome?.reachedTarget == true
            Label(note, systemImage: reached ? "target" : "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(reached ? .green : .orange)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((reached ? Color.green : Color.orange).opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
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

    /// Renders one document (résumé / cover letter) to `format` and presents the save panel.
    private func startExport(_ document: ApplicationDocument, _ format: ExportFormat) {
        guard let data = viewModel.exportData(document, format) else { return }
        exportDocument = ExportFileDocument(data: data, contentType: format.contentType)
        exportContentType = format.contentType
        exportFilename = viewModel.exportFilename(for: document, format)
        isExporting = true
    }

    /// Compiles the awesome-cv PDF (async, via `lualatex`) then presents the save panel. On
    /// failure the ViewModel sets `exportError`, surfaced by `latexNotices`.
    private func startLaTeXExport(_ document: ApplicationDocument) {
        Task {
            guard let data = await viewModel.exportLaTeXPDF(document) else { return }
            exportDocument = ExportFileDocument(data: data, contentType: .pdf)
            exportContentType = .pdf
            exportFilename = viewModel.exportFilename(for: document, .pdf)
            isExporting = true
        }
    }

    /// Exports the awesome-cv `.tex` **source** (no compile) for the PortfolioBuddy handoff.
    private func startTexExport(_ document: ApplicationDocument) {
        guard let data = viewModel.exportTexSource(document) else { return }
        let texType = UTType(filenameExtension: "tex") ?? .plainText
        exportDocument = ExportFileDocument(data: data, contentType: texType)
        exportContentType = texType
        exportFilename = viewModel.texFilename(for: document)
        isExporting = true
    }

    /// Export-side advisories: a `lualatex` failure (with the log) and the compiled résumé's
    /// real page count when it overflows — both distinct from the Core Text length gate.
    @ViewBuilder private var latexNotices: some View {
        if let error = viewModel.exportError {
            noticeBanner(error, systemImage: "exclamationmark.triangle.fill")
        }
        if viewModel.latexResumeExceedsOnePage {
            noticeBanner(
                "The awesome-cv résumé compiled to \(viewModel.latexResumePages) pages — tighten the content to fit one page.",
                systemImage: "doc.on.doc"
            )
        }
    }

    private func noticeBanner(_ text: String, systemImage: String) -> some View {
        Label { Text(text).font(.caption).textSelection(.enabled) } icon: { Image(systemName: systemImage) }
            .foregroundStyle(.orange)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
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
            let parts = GapNoteParts.parse(kit.gapNote)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    documentSection("Résumé", kit.resumeMarkdown)
                    documentSection("Cover letter", kit.coverLetter)
                    if parts.hasEmbellishments {
                        disclosuresSection(parts.embellishments)
                    }
                    if !parts.gaps.isEmpty {
                        gapsSection(parts.gaps)
                    }
                }
            }
        } else if let error = viewModel.errorMessage {
            ContentUnavailableView("Couldn't generate", systemImage: "exclamationmark.triangle", description: Text(error))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    /// The disclosed embellishments (D-E): content NOT supported by the real profile. A hard
    /// integrity surface — the user must verify these before sending.
    private func disclosuresSection(_ items: [String]) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Label(item, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            Label("Disclosures — unverified, embellished content. Verify before sending.",
                  systemImage: "exclamationmark.shield.fill")
                .foregroundStyle(.orange)
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
