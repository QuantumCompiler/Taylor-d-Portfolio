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
    /// The id of the profile marked as default (auto-loaded on launch), or `nil`.
    private(set) var defaultProfileID: String?

    /// The imported document's file name the current profile was built on (nil if pasted).
    private(set) var sourceFileName: String?
    /// The raw portfolio text the current profile was built on.
    private(set) var sourceText: String = ""
    /// The LLM-tidied, readable form of the source document, shown with the profile.
    private(set) var readableText: String = ""

    /// The **optional** cover letter's editable text (import/paste). A voice/tone exemplar
    /// for generation only — the profile is never distilled from it (ROADMAP Milestone T).
    var coverLetterText: String = ""
    /// The imported cover letter's file name (nil if pasted or absent).
    private(set) var coverLetterFileName: String?
    /// The raw cover-letter text the current profile was built alongside.
    private(set) var coverLetterSourceText: String = ""
    /// The LLM-tidied, readable form of the cover letter, shown with the profile.
    private(set) var coverLetterReadableText: String = ""

    /// Whether the default profile has been auto-applied yet (so it's applied once, on
    /// first load, and never clobbers a later manual selection).
    private var hasAppliedDefault = false

    private let buildProfile: BuildProfileUseCase
    private let importPortfolio: ImportPortfolioUseCase
    private let tidyDocument: TidyDocumentUseCase?
    private let saveProfile: SaveProfileUseCase?
    private let loadProfiles: LoadProfilesUseCase?
    private let deleteProfile: DeleteProfileUseCase?
    private let defaultProfileStore: DefaultProfileStore?

    init(
        buildProfile: BuildProfileUseCase,
        importPortfolio: ImportPortfolioUseCase,
        tidyDocument: TidyDocumentUseCase? = nil,
        saveProfile: SaveProfileUseCase? = nil,
        loadProfiles: LoadProfilesUseCase? = nil,
        deleteProfile: DeleteProfileUseCase? = nil,
        defaultProfileStore: DefaultProfileStore? = nil
    ) {
        self.buildProfile = buildProfile
        self.importPortfolio = importPortfolio
        self.tidyDocument = tidyDocument
        self.saveProfile = saveProfile
        self.loadProfiles = loadProfiles
        self.deleteProfile = deleteProfile
        self.defaultProfileStore = defaultProfileStore
        self.defaultProfileID = defaultProfileStore?.load()
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

    /// Reads a picked document into the **optional** cover-letter slot. Never gates Build.
    func importCoverLetter(from url: URL) async {
        isImporting = true
        errorMessage = nil
        defer { isImporting = false }
        do {
            coverLetterText = try await importPortfolio(fileURL: url)
            coverLetterFileName = url.lastPathComponent
        } catch let error as DocumentExtractionError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = "Couldn't read that cover letter. Try a PDF, Word, RTF, or text file."
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
            // Cover letter (optional): captured + tidied the same way, but NEVER distilled
            // into the profile — it's a voice/tone exemplar for generation only (Milestone T).
            let letter = coverLetterText.trimmingCharacters(in: .whitespacesAndNewlines)
            if letter.isEmpty {
                coverLetterSourceText = ""
                coverLetterReadableText = ""
                coverLetterFileName = nil
            } else {
                coverLetterSourceText = letter
                if let tidyDocument {
                    coverLetterReadableText = (try? await tidyDocument(rawText: letter)) ?? letter
                } else {
                    coverLetterReadableText = letter
                }
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
        applyDefaultIfNeeded()
    }

    /// On the first load, auto-select the default profile — unless the user already has
    /// a profile in hand (freshly built or selected), which we never override.
    private func applyDefaultIfNeeded() {
        guard !hasAppliedDefault else { return }
        hasAppliedDefault = true
        guard profile == nil, selectedProfileID == nil,
              let defaultProfileID,
              let match = savedProfiles.first(where: { $0.id == defaultProfileID })
        else { return }
        select(match)
    }

    /// Whether `saved` is the default profile.
    func isDefault(_ saved: SavedProfile) -> Bool { defaultProfileID == saved.id }

    /// Whether the currently-loaded profile is the default (drives the summary's ⭐).
    var isSelectedProfileDefault: Bool {
        selectedProfileID != nil && selectedProfileID == defaultProfileID
    }

    /// Toggles a profile as the default (long-press): sets it, or clears the default if
    /// it was already the default. Persisted so it auto-loads next launch.
    func setDefault(_ saved: SavedProfile) {
        defaultProfileID = (defaultProfileID == saved.id) ? nil : saved.id
        defaultProfileStore?.save(defaultProfileID)
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
                coverLetterFileName: coverLetterFileName,
                coverLetterText: coverLetterSourceText,
                coverLetterReadableText: coverLetterReadableText,
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
        coverLetterFileName = saved.coverLetterFileName
        coverLetterSourceText = saved.coverLetterText
        coverLetterReadableText = saved.coverLetterReadableText
        errorMessage = nil
    }

    /// Toggles a saved profile's selection: loads it, or clears it if already loaded.
    func toggleSelection(_ saved: SavedProfile) {
        if selectedProfileID == saved.id {
            deselect()
        } else {
            select(saved)
        }
    }

    /// Clears the current selection so no saved profile is loaded (the radio is unset),
    /// removing the active profile and its paired document.
    func deselect() {
        profile = nil
        profileName = ""
        selectedProfileID = nil
        sourceFileName = nil
        sourceText = ""
        readableText = ""
        coverLetterText = ""
        coverLetterFileName = nil
        coverLetterSourceText = ""
        coverLetterReadableText = ""
        errorMessage = nil
    }

    /// Deletes a saved profile from the library; clears the selection if it was loaded.
    func delete(_ saved: SavedProfile) async {
        guard let deleteProfile else { return }
        try? await deleteProfile(id: saved.id)
        if selectedProfileID == saved.id { selectedProfileID = nil }
        if defaultProfileID == saved.id {
            defaultProfileID = nil
            defaultProfileStore?.save(nil)
        }
        await reloadProfiles()
    }

    /// A friendly default name for a freshly-built profile.
    private static func defaultName(for profile: CandidateProfile) -> String {
        let role = profile.targetTitles.first ?? "Profile"
        let seniority = profile.seniority.trimmingCharacters(in: .whitespaces)
        return seniority.isEmpty ? role : "\(seniority) \(role)"
    }
}
