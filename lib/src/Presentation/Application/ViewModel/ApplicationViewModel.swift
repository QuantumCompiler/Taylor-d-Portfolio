//
//  ApplicationViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Application · ViewModel
//

import Foundation
import Observation

/// Drives the Application sheet: generates a tailored resume + cover letter for a job,
/// persisting the result and reloading it on reopen (Milestone O-C) so the user isn't
/// charged a redundant generation.
@MainActor
@Observable
final class ApplicationViewModel {
    private(set) var kit: ApplicationKit?
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

    /// The user's saved generation presets (Milestone D-D), newest first.
    private(set) var presets: [GenerationPreset] = []

    private let generateApplication: GenerateApplicationUseCase
    private let saveApplication: SaveApplicationUseCase?
    private let loadApplication: LoadApplicationUseCase?
    private let exportApplication: ExportApplicationUseCase?
    private let saveGenerationPreset: SaveGenerationPresetUseCase?
    private let loadGenerationPresets: LoadGenerationPresetsUseCase?
    private let deleteGenerationPreset: DeleteGenerationPresetUseCase?

    init(
        generateApplication: GenerateApplicationUseCase,
        saveApplication: SaveApplicationUseCase? = nil,
        loadApplication: LoadApplicationUseCase? = nil,
        exportApplication: ExportApplicationUseCase? = nil,
        saveGenerationPreset: SaveGenerationPresetUseCase? = nil,
        loadGenerationPresets: LoadGenerationPresetsUseCase? = nil,
        deleteGenerationPreset: DeleteGenerationPresetUseCase? = nil
    ) {
        self.generateApplication = generateApplication
        self.saveApplication = saveApplication
        self.loadApplication = loadApplication
        self.exportApplication = exportApplication
        self.saveGenerationPreset = saveGenerationPreset
        self.loadGenerationPresets = loadGenerationPresets
        self.deleteGenerationPreset = deleteGenerationPreset
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

    // MARK: Export (Q-A)

    /// Whether there's a generated kit and an exporter wired to save/copy it.
    var canExport: Bool { kit != nil && exportApplication != nil }

    /// The exported bytes for `format` (styled with the chosen template for PDF), or `nil`
    /// if unavailable / the format is unsupported.
    func exportData(_ format: ExportFormat) -> Data? {
        guard let kit, let exportApplication else { return nil }
        return try? exportApplication(kit, as: format, template: exportTemplate)
    }

    // MARK: One-page gate (Milestone X)

    /// True when the résumé overflows one page in the chosen template — a surfaced warning,
    /// never a reason to truncate content.
    var resumeExceedsOnePage: Bool { resumePageCount > 1 }

    /// Recomputes `resumePageCount` for the current kit + template. Cheap (short résumés);
    /// call after the kit loads/generates and whenever the template changes.
    func refreshLengthGate() {
        guard let kit, let exportApplication else { resumePageCount = 0; return }
        resumePageCount = (try? exportApplication.resumePageCount(kit, template: exportTemplate)) ?? 0
    }

    /// The exported document as text (for copy-to-clipboard). Defaults to Markdown.
    func exportedText(_ format: ExportFormat = .markdown) -> String? {
        exportData(format).map { String(decoding: $0, as: UTF8.self) }
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
        self.job = job
        errorMessage = nil
        isGenerating = false
        if let loadApplication, let saved = try? await loadApplication(forJobID: job.id) {
            kit = saved
            isSaved = true
            refreshLengthGate()
        } else {
            kit = nil
            isSaved = false
            resumePageCount = 0
        }
    }

    /// Generates fresh materials (also used by "Regenerate") and persists them.
    func generate(for job: JobListing, profile: CandidateProfile, grounding: PortfolioGrounding? = nil) async {
        self.job = job
        isGenerating = true
        errorMessage = nil
        kit = nil
        isSaved = false
        defer { isGenerating = false }
        do {
            let produced = try await generateApplication(job: job, profile: profile, grounding: grounding, settings: generationSettings)
            kit = produced
            refreshLengthGate()
            // Best-effort persist — a storage failure shouldn't lose the generated output.
            try? await saveApplication?(produced, forJobID: job.id)
        } catch {
            errorMessage = "Couldn't generate the application. Try again."
        }
    }
}
