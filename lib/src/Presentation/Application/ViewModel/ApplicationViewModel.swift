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

    private let generateApplication: GenerateApplicationUseCase
    private let saveApplication: SaveApplicationUseCase?
    private let loadApplication: LoadApplicationUseCase?
    private let exportApplication: ExportApplicationUseCase?

    init(
        generateApplication: GenerateApplicationUseCase,
        saveApplication: SaveApplicationUseCase? = nil,
        loadApplication: LoadApplicationUseCase? = nil,
        exportApplication: ExportApplicationUseCase? = nil
    ) {
        self.generateApplication = generateApplication
        self.saveApplication = saveApplication
        self.loadApplication = loadApplication
        self.exportApplication = exportApplication
    }

    // MARK: Export (Q-A)

    /// Whether there's a generated kit and an exporter wired to save/copy it.
    var canExport: Bool { kit != nil && exportApplication != nil }

    /// The exported bytes for `format`, or `nil` if unavailable / the format is unsupported.
    func exportData(_ format: ExportFormat) -> Data? {
        guard let kit, let exportApplication else { return nil }
        return try? exportApplication(kit, as: format)
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

    /// Opens the application for `job`: shows previously-saved materials if present
    /// (no LLM call), otherwise generates fresh output.
    func open(for job: JobListing, profile: CandidateProfile) async {
        self.job = job
        if let loadApplication, let saved = try? await loadApplication(forJobID: job.id) {
            kit = saved
            isSaved = true
            errorMessage = nil
            isGenerating = false
            return
        }
        await generate(for: job, profile: profile)
    }

    /// Generates fresh materials (also used by "Regenerate") and persists them.
    func generate(for job: JobListing, profile: CandidateProfile) async {
        self.job = job
        isGenerating = true
        errorMessage = nil
        kit = nil
        isSaved = false
        defer { isGenerating = false }
        do {
            let produced = try await generateApplication(job: job, profile: profile)
            kit = produced
            // Best-effort persist — a storage failure shouldn't lose the generated output.
            try? await saveApplication?(produced, forJobID: job.id)
        } catch {
            errorMessage = "Couldn't generate the application. Try again."
        }
    }
}
