//
//  ApplicationViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Application · ViewModel
//

import Foundation
import Observation
import PDFKit

/// Drives the Application sheet: generates a tailored resume + cover letter for a job,
/// persisting the result and reloading it on reopen (Milestone O-C) so the user isn't
/// charged a redundant generation.
@MainActor
@Observable
final class ApplicationViewModel {
    private(set) var kit: ApplicationKit?
    /// The ``TargetBrief`` the shown ``kit`` was generated against (v0.6.1 Milestone B) — the
    /// only place the posting's keywords exist, so keyword coverage reads them from here. Held
    /// in lockstep with `kit`; `nil` when nothing is generated, or when a reopened saved kit
    /// predates the brief being persisted alongside it.
    private(set) var brief: TargetBrief?
    private(set) var isGenerating = false
    private(set) var errorMessage: String?
    /// Whether the shown kit was loaded from storage (vs freshly generated).
    private(set) var isSaved = false
    /// The job the current materials are for — used to name exported files.
    private(set) var job: JobListing?
    /// The résumé template used for PDF export + the one-page gate (Milestone X).
    var exportTemplate: ExportTemplate = .classic
    /// The generation controls (fidelity + tailored aspects) applied on the next generate /
    /// regenerate (Milestone D). `.default` = the grounded, pre-D behaviour.
    var generationSettings: GenerationSettings = .default
    /// How many pages the résumé occupies in `exportTemplate`'s layout — 0 when there's no
    /// kit/exporter. Recomputed by `refreshLengthGate()` when the kit or template changes.
    private(set) var resumePageCount = 0
    /// True while a `lualatex` compile is running (drives a spinner on the LaTeX export item).
    private(set) var isCompilingLaTeX = false
    /// A user-facing message when a LaTeX/export step fails — surfaced as a banner, not the
    /// content view (an export failure isn't a generation failure).
    private(set) var exportError: String?
    /// Pages in the last compiled awesome-cv résumé PDF (0 = none yet) — the real `lualatex`
    /// count, distinct from the Core Text `resumePageCount` gate (Milestone D).
    private(set) var latexResumePages = 0

    /// The user's saved generation presets (Milestone D-D), newest first.
    private(set) var presets: [GenerationPreset] = []

    /// The saved profiles the user can generate against (v0.6.0 Milestone B), newest first.
    private(set) var savedProfiles: [SavedProfile] = []
    /// The picked profile's id, or `nil` for **Current profile** (the ambient/loaded one) — the
    /// default, so generation is unchanged until the user picks another. Session-only.
    var selectedProfileID: String?

    /// The user's saved document styles (v0.7.0 Milestone D), newest first — empty when the
    /// library isn't wired in this build.
    private(set) var savedStyles: [SavedDocumentStyle] = []
    /// The built-in templates whose class files actually shipped, resolved in the composition
    /// root (checking that is file I/O, which Presentation doesn't do).
    let availableTemplates: [LaTeXTemplateDescriptor]
    /// Which document style the LaTeX exports use. `nil` = **follow the user's default** (and the
    /// built-in look when no default resolves), kept as a live state rather than seeded once, so
    /// changing the default in Settings immediately changes what an unpicked export produces.
    /// Session-only and sticky across jobs, like ``exportTemplate``.
    var selectedStyleChoice: StyleChoice? {
        didSet {
            // The "compiled to N pages" advisory was measured under the old style.
            latexResumePages = 0
            exportError = nil
        }
    }

    /// The outcome of the last rank-target generation (Milestone D-F), if that path was used.
    private(set) var rankOutcome: GenerateToTargetUseCase.Outcome?

    private let generateApplication: GenerateApplicationUseCase
    private let generateToTarget: GenerateToTargetUseCase?
    private let saveApplication: SaveApplicationUseCase?
    private let loadApplication: LoadApplicationUseCase?
    private let exportApplication: ExportApplicationUseCase?
    private let saveGenerationPreset: SaveGenerationPresetUseCase?
    private let loadGenerationPresets: LoadGenerationPresetsUseCase?
    private let deleteGenerationPreset: DeleteGenerationPresetUseCase?
    private let loadProfiles: LoadProfilesUseCase?
    private let loadDocumentStyles: LoadDocumentStylesUseCase?
    private let defaultDocumentStyleStore: DefaultDocumentStyleStore?

    init(
        generateApplication: GenerateApplicationUseCase,
        generateToTarget: GenerateToTargetUseCase? = nil,
        saveApplication: SaveApplicationUseCase? = nil,
        loadApplication: LoadApplicationUseCase? = nil,
        exportApplication: ExportApplicationUseCase? = nil,
        saveGenerationPreset: SaveGenerationPresetUseCase? = nil,
        loadGenerationPresets: LoadGenerationPresetsUseCase? = nil,
        deleteGenerationPreset: DeleteGenerationPresetUseCase? = nil,
        loadProfiles: LoadProfilesUseCase? = nil,
        loadDocumentStyles: LoadDocumentStylesUseCase? = nil,
        defaultDocumentStyleStore: DefaultDocumentStyleStore? = nil,
        availableTemplates: [LaTeXTemplateDescriptor] = LaTeXTemplateRegistry.all
    ) {
        self.generateApplication = generateApplication
        self.generateToTarget = generateToTarget
        self.saveApplication = saveApplication
        self.loadApplication = loadApplication
        self.exportApplication = exportApplication
        self.saveGenerationPreset = saveGenerationPreset
        self.loadGenerationPresets = loadGenerationPresets
        self.deleteGenerationPreset = deleteGenerationPreset
        self.loadProfiles = loadProfiles
        self.loadDocumentStyles = loadDocumentStyles
        self.defaultDocumentStyleStore = defaultDocumentStyleStore
        self.availableTemplates = availableTemplates
    }

    // MARK: Profile selection (v0.6.0 Milestone B)

    /// Whether the generation screen can offer a saved-profile picker (any saved profiles exist).
    var canPickProfile: Bool { !savedProfiles.isEmpty }

    /// Loads the saved profiles the picker offers (newest first, as the repository returns them).
    func loadSavedProfiles() async {
        savedProfiles = (try? await loadProfiles?()) ?? []
    }

    /// Resolves which profile + grounding to generate against: the **picked** saved profile
    /// (grounding on *its* real source documents), or the ambient fallback — the loaded profile
    /// passed in by the window — when "Current profile" is selected or the pick no longer exists.
    /// Pure given the loaded `savedProfiles`, so it's unit-testable without the view.
    func resolvedTarget(
        fallbackProfile: CandidateProfile,
        fallbackGrounding: PortfolioGrounding?
    ) -> (profile: CandidateProfile, grounding: PortfolioGrounding?) {
        guard let id = selectedProfileID, let picked = savedProfiles.first(where: { $0.id == id }) else {
            return (fallbackProfile, fallbackGrounding)
        }
        return (picked.profile, picked.grounding)
    }

    // MARK: Keyword coverage (v0.6.1 Milestone C)

    /// How well the shown résumé covers the posting's keywords, measured on its **visible**
    /// text (v0.6.1 Milestone C). Derived from `kit` + `brief`, both `@Observable`, so it
    /// recomputes after every generate / regenerate without an explicit refresh.
    ///
    /// `nil` means there is nothing honest to report, and the panel hides rather than showing a
    /// meaningless "0/0": no generated kit, no `brief` (a saved record written before Milestone
    /// B paired the two), or a posting that yielded no keywords at all.
    var coverage: KeywordCoverage? {
        guard let kit, let brief else { return nil }
        let coverage = KeywordCoverage(brief: brief, resumeMarkdown: kit.resumeMarkdown)
        return coverage.isEmpty ? nil : coverage
    }

    /// A user-facing note about the rank-target outcome, if used.
    var rankOutcomeNote: String? {
        guard let outcome = rankOutcome else { return nil }
        return outcome.reachedTarget
            ? "Reached a \(outcome.achievedScore) match (your target was \(outcome.target))."
            : "Reached \(outcome.achievedScore) of your \(outcome.target) target after \(outcome.rounds) attempts."
    }

    // MARK: Presets (Milestone D-D)

    /// Whether preset save/load is wired in this build.
    var canManagePresets: Bool { saveGenerationPreset != nil && loadGenerationPresets != nil }

    /// Loads the saved presets (newest first).
    func loadPresets() async {
        guard let loadGenerationPresets else { return }
        presets = (try? await loadGenerationPresets()) ?? []
    }

    /// Saves the current `generationSettings` as a named preset (auto-named when `name` is nil).
    func saveCurrentAsPreset(named name: String? = nil) async {
        guard let saveGenerationPreset else { return }
        _ = try? await saveGenerationPreset(generationSettings, name: name)
        await loadPresets()
    }

    /// Applies a saved preset's settings to the next generation.
    func applyPreset(_ preset: GenerationPreset) {
        generationSettings = preset.settings
    }

    /// Deletes a saved preset.
    func deletePreset(_ preset: GenerationPreset) async {
        guard let deleteGenerationPreset else { return }
        try? await deleteGenerationPreset(id: preset.id)
        await loadPresets()
    }

    // MARK: Export (Q-A; per-document since Milestone G)

    /// Whether there's a generated kit and an exporter wired to save/copy it.
    var canExport: Bool { kit != nil && exportApplication != nil }

    /// Whether a specific document (résumé / cover letter) can be exported — it exists, is
    /// non-empty, and an exporter is wired. The Application sheet offers only present documents.
    func canExport(_ document: ApplicationDocument) -> Bool {
        guard let kit, exportApplication != nil else { return false }
        return ExportApplicationUseCase.isPresent(document, in: kit)
    }

    /// The exported bytes for one `document` in `format` (styled with the chosen template for
    /// PDF), or `nil` if the document is absent/empty, unavailable, or the format is
    /// unsupported. Guards on presence so an empty section never exports an empty file.
    func exportData(_ document: ApplicationDocument, _ format: ExportFormat) -> Data? {
        guard let kit, let exportApplication,
              ExportApplicationUseCase.isPresent(document, in: kit) else { return nil }
        return try? exportApplication(kit, document, as: format, template: exportTemplate)
    }

    /// The suggested save filename for one `document` + `format`, e.g. `Acme - iOS Engineer - Résumé.pdf`.
    func exportFilename(for document: ApplicationDocument, _ format: ExportFormat) -> String {
        "\(exportFilenameBase) - \(document.filenameSuffix).\(format.fileExtension)"
    }

    // MARK: LaTeX (awesome-cv) export — Milestone D

    /// Whether the awesome-cv LaTeX route is available at all (a kit exists and a `lualatex`
    /// install was found) — drives whether the Export menu shows the LaTeX items.
    var canExportLaTeX: Bool { kit != nil && (exportApplication?.isLaTeXAvailable ?? false) }

    // MARK: Document styles (v0.7.0 Milestone E)

    /// Which style the LaTeX route uses — a built-in template or one of the user's saved styles.
    /// The two have separate id spaces, so the picker's selection is this tagged choice rather
    /// than a bare id.
    nonisolated enum StyleChoice: Hashable, Sendable {
        case builtIn(LaTeXTemplateID)
        case saved(String)
    }

    /// Loads the user's saved styles (newest first). A no-op when the library isn't wired.
    func loadDocumentStyles() async {
        guard let loadDocumentStyles else { return }
        savedStyles = (try? await loadDocumentStyles()) ?? []
    }

    /// The style the LaTeX exports actually use. Pure given `savedStyles`, so it's testable
    /// without the view.
    ///
    /// A **dangling** default (its style was deleted) falls back to the built-in look, never to
    /// "some other saved style" — see ``DefaultDocumentStyleStore/resolved(in:)``. Silently
    /// applying a style the user never chose would change the document they're about to send.
    var resolvedStyle: LaTeXStyle {
        switch selectedStyleChoice {
        case let .saved(id)?:
            return savedStyles.first { $0.id == id }?.style ?? LaTeXTemplateRegistry.fallback.defaultStyle
        case let .builtIn(template)?:
            return (LaTeXTemplateRegistry.descriptor(for: template) ?? LaTeXTemplateRegistry.fallback).defaultStyle
        case nil:
            return defaultDocumentStyleStore?.resolved(in: savedStyles)?.style
                ?? LaTeXTemplateRegistry.fallback.defaultStyle
        }
    }

    /// The label on the picker's "follow my default" row — it names what that currently means.
    var defaultStyleRowLabel: String {
        if let resolved = defaultDocumentStyleStore?.resolved(in: savedStyles) {
            return "Default — \(resolved.name)"
        }
        return "Default — \(LaTeXTemplateRegistry.fallback.displayName)"
    }

    /// Whether the style this export would use carries a raw-LaTeX override — the most likely
    /// cause of a compile failure, and what the failure banner names.
    var exportUsedCustomPreamble: Bool { resolvedStyle.effectiveCustomPreamble != nil }

    /// Session-only escape from a style whose custom preamble won't compile: export against the
    /// built-in look, without editing or deleting the style the user spent time on. The durable
    /// fix lives in the manager; this unblocks the send now.
    func useBuiltInStyleForExport() {
        selectedStyleChoice = .builtIn(LaTeXTemplateRegistry.fallback.template)
    }

    /// Whether a document can be exported as an awesome-cv PDF (present **and** `lualatex` found).
    func canExportLaTeX(_ document: ApplicationDocument) -> Bool {
        guard let kit, let exportApplication, exportApplication.isLaTeXAvailable else { return false }
        return ExportApplicationUseCase.isPresent(document, in: kit)
    }

    /// Compiles one document to an awesome-cv PDF via `lualatex` (async). Returns `nil` and sets
    /// ``exportError`` on failure; records the real compiled page count for the résumé.
    func exportLaTeXPDF(_ document: ApplicationDocument) async -> Data? {
        guard let kit, let exportApplication, canExportLaTeX(document) else { return nil }
        isCompilingLaTeX = true
        exportError = nil
        defer { isCompilingLaTeX = false }
        do {
            let pdf = try await exportApplication.latexPDF(kit, document, style: resolvedStyle)
            if document == .resume { latexResumePages = Self.pdfPageCount(pdf) }
            return pdf
        } catch {
            exportError = Self.describeExport(error, customPreamble: exportUsedCustomPreamble)
            return nil
        }
    }

    /// The awesome-cv `.tex` **source** for one document (no compile, needs no TeX install), as
    /// bytes for the save panel — a handoff into the manual PortfolioBuddy pipeline.
    func exportTexSource(_ document: ApplicationDocument) -> Data? {
        guard let kit, let exportApplication,
              ExportApplicationUseCase.isPresent(document, in: kit) else { return nil }
        return Data(exportApplication.texSource(kit, document, style: resolvedStyle).utf8)
    }

    /// The suggested `.tex` filename for one document.
    func texFilename(for document: ApplicationDocument) -> String {
        "\(exportFilenameBase) - \(document.filenameSuffix).tex"
    }

    /// True when the last compiled awesome-cv résumé overflowed one page — the real `lualatex`
    /// count, surfaced as an advisory after a résumé PDF export.
    var latexResumeExceedsOnePage: Bool { latexResumePages > 1 }

    /// Pages in a compiled PDF via PDFKit (0 if it can't be read).
    static func pdfPageCount(_ data: Data) -> Int { PDFDocument(data: data)?.pageCount ?? 0 }

    /// A user-facing message for an export failure — surfaces the real `lualatex` log so a
    /// compile error is diagnosable, not hidden behind a generic "try again".
    ///
    /// Not private: the style manager's Preview (v0.7.0 Milestone E) compiles through the same
    /// port and needs the same five-case mapping. One copy, so the two can't drift.
    /// The same mapping, plus one sentence naming a custom preamble when the style has one — an
    /// overload rather than a fork, so the style manager gets the same copy from the same place.
    static func describeExport(_ error: Error, customPreamble: Bool) -> String {
        let base = describeExport(error)
        guard customPreamble, case .nonZeroExit = error as? LaTeXProcessError else { return base }
        return base + "\n\nThis style uses a custom LaTeX preamble, which is the most likely cause."
    }

    static func describeExport(_ error: Error) -> String {
        guard let latexError = error as? LaTeXProcessError else {
            return "Couldn't export.\n\n(\(String(describing: error)))"
        }
        switch latexError {
        case .notInstalled:
            return "No TeX install found. Install MacTeX (which provides `lualatex`) to export the awesome-cv PDF."
        case .assetsUnavailable:
            return "The bundled LaTeX assets are missing from this build."
        case .launchFailed(let message):
            return "Couldn't launch lualatex: \(message)"
        case .nonZeroExit(_, let log):
            return "lualatex couldn't compile the document:\n\n\(log)"
        case .noOutput:
            return "lualatex produced no PDF."
        }
    }

    // MARK: One-page gate (Milestone X)

    /// True when the current résumé overflows one page in the chosen template — a surfaced
    /// warning, never a reason to truncate content. Requires a kit, so a stale page count
    /// from a prior generation doesn't linger after a failed/cleared generation (v0.5.0 fix).
    var resumeExceedsOnePage: Bool { kit != nil && resumePageCount > 1 }

    /// Recomputes `resumePageCount` for the current kit + template. Cheap (short résumés);
    /// call after the kit loads/generates and whenever the template changes.
    func refreshLengthGate() {
        guard let kit, let exportApplication else { resumePageCount = 0; return }
        resumePageCount = (try? exportApplication.resumePageCount(kit, template: exportTemplate)) ?? 0
    }

    /// The **combined** résumé + cover letter as text (for the "copy everything" affordance).
    /// Defaults to Markdown.
    func exportedText(_ format: ExportFormat = .markdown) -> String? {
        guard let kit, let exportApplication else { return nil }
        return (try? exportApplication(kit, as: format, template: exportTemplate))
            .map { String(decoding: $0, as: UTF8.self) }
    }

    /// A filesystem-safe base name for exports, derived from the job (company · role).
    var exportFilenameBase: String {
        let raw = [job?.company, job?.title].compactMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
        let base = raw.isEmpty ? "Application" : raw
        let illegal = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        return base.components(separatedBy: illegal).joined(separator: "-")
    }

    /// Loads previously-saved materials for `job` if present (no LLM call); otherwise leaves
    /// `kit` nil so the view offers an explicit **Generate** button. Opening the Application
    /// view never auto-generates — generation is user-initiated so options can be set first
    /// (v0.5.0).
    func loadSaved(for job: JobListing) async {
        latexResumePages = 0        // the advisory belongs to the kit it was measured on
        self.job = job
        errorMessage = nil
        exportError = nil
        isGenerating = false
        if let loadApplication, let saved = try? await loadApplication(forJobID: job.id) {
            kit = saved
            // Absent for records written before the brief was paired with the kit — coverage
            // is then simply unavailable for that saved result, not wrong.
            brief = (try? await loadApplication.brief(forJobID: job.id)) ?? nil
            isSaved = true
            refreshLengthGate()
        } else {
            kit = nil
            brief = nil
            isSaved = false
            resumePageCount = 0
        }
    }

    /// Generates fresh materials (also used by "Regenerate") and persists them. When a rank
    /// target is set (Milestone D-F), runs the outcome-driven loop instead of a single pass.
    func generate(for job: JobListing, profile: CandidateProfile, grounding: PortfolioGrounding? = nil) async {
        self.job = job
        isGenerating = true
        errorMessage = nil
        kit = nil
        brief = nil
        isSaved = false
        rankOutcome = nil
        defer { isGenerating = false }
        do {
            let produced: ApplicationKit
            let producedBrief: TargetBrief
            if let target = generationSettings.desiredRankMatch, let generateToTarget {
                let outcome = try await generateToTarget(job: job, profile: profile, grounding: grounding,
                                                         target: target,
                                                         additionalContext: generationSettings.additionalContext,
                                                         emphasizeKeywords: generationSettings.emphasizeKeywords)
                produced = outcome.kit
                producedBrief = outcome.brief
                rankOutcome = outcome
            } else {
                let outcome = try await generateApplication(job: job, profile: profile, grounding: grounding, settings: generationSettings)
                produced = outcome.kit
                producedBrief = outcome.brief
            }
            kit = produced
            brief = producedBrief
            refreshLengthGate()
            // Best-effort persist — a storage failure shouldn't lose the generated output. The
            // brief rides along so a reopened result can still report keyword coverage.
            try? await saveApplication?(produced, brief: producedBrief, forJobID: job.id)
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    /// A user-facing message that still surfaces the real cause (a bare "try again" hides
    /// engine/CLI failures that the user needs to see).
    private static func describe(_ error: Error) -> String {
        if case LLMProviderError.noProviderAvailable = error {
            return "No LLM engine is available for this step. Check Settings → Engines — for the Claude "
                + "engine the `claude` CLI must be installed and authenticated."
        }
        return "Couldn't generate the application. Try again.\n\n(\(String(describing: error)))"
    }
}
