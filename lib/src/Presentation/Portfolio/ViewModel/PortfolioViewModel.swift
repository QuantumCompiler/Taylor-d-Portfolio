//
//  PortfolioViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Portfolio · ViewModel
//

import Foundation
import Observation

/// Drives the Portfolio screen: the user pastes their portfolio; we distil a profile.
@MainActor
@Observable
final class PortfolioViewModel {
    var portfolioText: String = ""
    private(set) var profile: CandidateProfile?
    private(set) var isBuilding = false
    private(set) var isImporting = false
    private(set) var errorMessage: String?

    private let buildProfile: BuildProfileUseCase
    private let importPortfolio: ImportPortfolioUseCase

    init(buildProfile: BuildProfileUseCase, importPortfolio: ImportPortfolioUseCase) {
        self.buildProfile = buildProfile
        self.importPortfolio = importPortfolio
    }

    var isBusy: Bool { isBuilding || isImporting }

    var canBuild: Bool {
        !portfolioText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isBusy
    }

    /// Reads a picked document (PDF, Word, RTF, text…) into `portfolioText`.
    func importDocument(from url: URL) async {
        isImporting = true
        errorMessage = nil
        defer { isImporting = false }
        do {
            portfolioText = try await importPortfolio(fileURL: url)
        } catch let error as DocumentExtractionError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = "Couldn't read that document. Try a PDF, Word, RTF, or text file."
        }
    }

    private static func message(for error: DocumentExtractionError) -> String {
        switch error {
        case .unsupportedType(let ext):
            "Unsupported file type “\(ext)”. Try a PDF, Word, RTF, or text file."
        case .emptyDocument:
            "That document didn't contain any readable text."
        case .readFailed:
            "Couldn't read that document. Try a different file."
        }
    }

    func build() async {
        guard canBuild else { return }
        isBuilding = true
        errorMessage = nil
        defer { isBuilding = false }
        do {
            profile = try await buildProfile(portfolio: portfolioText)
        } catch {
            errorMessage = "Couldn't build your profile. Check that an engine is available in Settings, then try again."
        }
    }
}
