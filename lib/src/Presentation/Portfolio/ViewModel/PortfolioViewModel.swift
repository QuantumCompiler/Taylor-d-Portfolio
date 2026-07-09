//
//  PortfolioViewModel.swift
//  Taylor'd Portfolio
//
//  Presentation · Portfolio · ViewModel
//

import Foundation
import Observation

/// Drives the Portfolio screen: the user pastes/imports their portfolio; we distil a
/// profile. A built profile can be **saved** to a named library and re-selected later,
/// so a portfolio only has to be distilled once.
@MainActor
@Observable
final class PortfolioViewModel {
    var portfolioText: String = ""
    private(set) var profile: CandidateProfile?
    private(set) var isBuilding = false
    private(set) var isImporting = false
    private(set) var errorMessage: String?

    /// The name the current profile will be saved under (prefilled after a build).
    var profileName: String = ""
    /// The user's saved-profile library, newest first.
    private(set) var savedProfiles: [SavedProfile] = []
    /// The id of the saved profile currently loaded, or `nil` for a freshly-built,
    /// not-yet-saved profile. Drives whether "Save" creates a new entry or updates one.
    private(set) var selectedProfileID: String?

    /// The imported document's file name the current profile was built on (nil if pasted).
    private(set) var sourceFileName: String?
    /// The raw portfolio text the current profile was built on.
    private(set) var sourceText: String = ""
    /// The LLM-tidied, readable form of the source document, shown with the profile.
    private(set) var readableText: String = ""

    private let buildProfile: BuildProfileUseCase
    private let importPortfolio: ImportPortfolioUseCase
    private let tidyDocument: TidyDocumentUseCase?
    private let saveProfile: SaveProfileUseCase?
    private let loadProfiles: LoadProfilesUseCase?
    private let deleteProfile: DeleteProfileUseCase?

    init(
        buildProfile: BuildProfileUseCase,
        importPortfolio: ImportPortfolioUseCase,
        tidyDocument: TidyDocumentUseCase? = nil,
        saveProfile: SaveProfileUseCase? = nil,
        loadProfiles: LoadProfilesUseCase? = nil,
        deleteProfile: DeleteProfileUseCase? = nil
    ) {
        self.buildProfile = buildProfile
        self.importPortfolio = importPortfolio
        self.tidyDocument = tidyDocument
        self.saveProfile = saveProfile
        self.loadProfiles = loadProfiles
        self.deleteProfile = deleteProfile
    }

    var isBusy: Bool { isBuilding || isImporting }

    var canBuild: Bool {
        !portfolioText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isBusy
    }

    /// Whether saving is wired and there's a profile with a non-empty name to save.
    var canSaveProfile: Bool {
        saveProfile != nil && profile != nil && !isBusy
            && !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether the saved-profile library is available in this build.
    var supportsSavedProfiles: Bool { loadProfiles != nil }

    /// Reads a picked document (PDF, Word, RTF, text…) into `portfolioText`.
    func importDocument(from url: URL) async {
        isImporting = true
        errorMessage = nil
        defer { isImporting = false }
        do {
            portfolioText = try await importPortfolio(fileURL: url)
            sourceFileName = url.lastPathComponent
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
            let text = portfolioText
            let built = try await buildProfile(portfolio: text)
            profile = built
            // A freshly-built profile isn't yet saved; prefill a sensible name.
            selectedProfileID = nil
            profileName = Self.defaultName(for: built)
            // Pair the source document with the profile, and reflow it to readable text
            // via the same engine (best-effort — fall back to the raw text if it fails).
            sourceText = text
            if let tidyDocument {
                readableText = (try? await tidyDocument(rawText: text)) ?? text
            } else {
                readableText = text
            }
        } catch {
            errorMessage = "Couldn't build your profile. Check that an engine is available in Settings, then try again."
        }
    }

    // MARK: Saved-profile library

    /// Loads the saved-profile library (call on appear). No-op when unavailable.
    func reloadProfiles() async {
        guard let loadProfiles else { return }
        savedProfiles = (try? await loadProfiles()) ?? savedProfiles
    }

    /// Saves the current profile under `profileName`. If a saved profile is loaded
    /// (`selectedProfileID`), that entry is updated (rename/refresh); otherwise a new
    /// one is created. Best-effort refresh of the library afterward.
    func saveProfile() async {
        guard let saveProfile, let profile, canSaveProfile else { return }
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = selectedProfileID.flatMap { id in savedProfiles.first { $0.id == id } }
        do {
            let saved = try await saveProfile(
                profile, name: name,
                sourceFileName: sourceFileName, sourceText: sourceText, readableText: readableText,
                existing: existing
            )
            selectedProfileID = saved.id
            await reloadProfiles()
        } catch {
            errorMessage = "Couldn't save this profile. Try again."
        }
    }

    /// Loads a saved profile as the current profile (so it flows to Search/Results), along
    /// with the document it was built on.
    func select(_ saved: SavedProfile) {
        profile = saved.profile
        profileName = saved.name
        selectedProfileID = saved.id
        sourceFileName = saved.sourceFileName
        sourceText = saved.sourceText
        readableText = saved.readableText
        errorMessage = nil
    }

    /// Deletes a saved profile from the library; clears the selection if it was loaded.
    func delete(_ saved: SavedProfile) async {
        guard let deleteProfile else { return }
        try? await deleteProfile(id: saved.id)
        if selectedProfileID == saved.id { selectedProfileID = nil }
        await reloadProfiles()
    }

    /// A friendly default name for a freshly-built profile.
    private static func defaultName(for profile: CandidateProfile) -> String {
        let role = profile.targetTitles.first ?? "Profile"
        let seniority = profile.seniority.trimmingCharacters(in: .whitespaces)
        return seniority.isEmpty ? role : "\(seniority) \(role)"
    }
}
