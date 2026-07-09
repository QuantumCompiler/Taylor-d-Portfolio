//
//  ApplicationViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Application · ViewModel
//

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

    private let generateApplication: GenerateApplicationUseCase
    private let saveApplication: SaveApplicationUseCase?
    private let loadApplication: LoadApplicationUseCase?

    init(
        generateApplication: GenerateApplicationUseCase,
        saveApplication: SaveApplicationUseCase? = nil,
        loadApplication: LoadApplicationUseCase? = nil
    ) {
        self.generateApplication = generateApplication
        self.saveApplication = saveApplication
        self.loadApplication = loadApplication
    }

    /// Opens the application for `job`: shows previously-saved materials if present
    /// (no LLM call), otherwise generates fresh output.
    func open(for job: JobListing, profile: CandidateProfile) async {
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
