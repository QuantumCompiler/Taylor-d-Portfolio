//
//  SaveProfileUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — save (or rename/update) a named CandidateProfile.
//

import Foundation

/// Persists a ``CandidateProfile`` under a user-given name so it survives relaunch and
/// can be re-selected without regenerating.
///
/// `makeID`/`now` are injected so tests are deterministic. Pass `existing` to update a
/// profile already in the library (a rename, or re-saving the same slot) — its id and
/// original `createdAt` are preserved; omit it to create a new entry.
nonisolated struct SaveProfileUseCase: Sendable {
    let repository: SavedProfilesRepository
    let makeID: @Sendable () -> String
    let now: @Sendable () -> Date

    init(
        repository: SavedProfilesRepository,
        makeID: @escaping @Sendable () -> String = { UUID().uuidString },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.makeID = makeID
        self.now = now
    }

    @discardableResult
    func callAsFunction(
        _ profile: CandidateProfile,
        name: String,
        sourceFileName: String? = nil,
        sourceText: String = "",
        readableText: String = "",
        coverLetterFileName: String? = nil,
        coverLetterText: String = "",
        coverLetterReadableText: String = "",
        supportingDocuments: [SupportingDocument] = [],
        existing: SavedProfile? = nil
    ) async throws -> SavedProfile {
        let saved = SavedProfile(
            id: existing?.id ?? makeID(),
            name: name,
            profile: profile,
            sourceFileName: sourceFileName,
            sourceText: sourceText,
            readableText: readableText,
            coverLetterFileName: coverLetterFileName,
            coverLetterText: coverLetterText,
            coverLetterReadableText: coverLetterReadableText,
            supportingDocuments: supportingDocuments,
            createdAt: existing?.createdAt ?? now()
        )
        try await repository.save(saved)
        return saved
    }
}
