//
//  ApplicationViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Application · ViewModel
//

import Observation

/// Drives the Application sheet: generates a tailored resume + cover letter for a job.
@MainActor
@Observable
final class ApplicationViewModel {
    private(set) var kit: ApplicationKit?
    private(set) var isGenerating = false
    private(set) var errorMessage: String?

    private let generateApplication: GenerateApplicationUseCase

    init(generateApplication: GenerateApplicationUseCase) {
        self.generateApplication = generateApplication
    }

    func generate(for job: JobListing, profile: CandidateProfile) async {
        isGenerating = true
        errorMessage = nil
        kit = nil
        defer { isGenerating = false }
        do {
            kit = try await generateApplication(job: job, profile: profile)
        } catch {
            errorMessage = "Couldn't generate the application. Try again."
        }
    }
}
