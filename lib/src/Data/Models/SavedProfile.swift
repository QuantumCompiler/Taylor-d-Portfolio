//
//  SavedProfile.swift
//  Taylor'd Portfolio
//
//  Data · Models — a named, persisted CandidateProfile + the document it was built on.
//

import Foundation

/// A ``CandidateProfile`` the user has saved under a name, paired with the imported
/// document it was built from — so a portfolio only has to be distilled once and can be
/// re-selected at search or build time, and so the user can see *what* it was built on.
///
/// `id` is a stable identifier (a UUID string) assigned at first save; `createdAt`
/// orders the library (newest first). `sourceText` is the raw portfolio text the profile
/// was built on (the imported document's extracted text, or pasted text); `readableText`
/// is the LLM-tidied, human-readable form of it; `sourceFileName` names the imported file
/// when one was used. `Codable` so it persists via the record store.
nonisolated struct SavedProfile: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var profile: CandidateProfile
    /// The imported document's file name (nil when the portfolio was pasted, not imported).
    var sourceFileName: String?
    /// The raw portfolio text the profile was built on.
    var sourceText: String
    /// The LLM-tidied, readable form of `sourceText`.
    var readableText: String

    /// The imported cover letter's file name (nil when pasted or absent). The cover letter
    /// is **optional** and a **voice / tone exemplar** for generation only — the profile is
    /// never distilled from it (see ROADMAP Milestone T).
    var coverLetterFileName: String?
    /// The raw cover-letter text, if the user supplied one (empty when absent).
    var coverLetterText: String
    /// The LLM-tidied, readable form of `coverLetterText`.
    var coverLetterReadableText: String

    /// **Additional supporting documents** baked into this profile as **factual** grounding
    /// (v0.6.0 Milestone I) — e.g. a full career portfolio. Empty for profiles saved before
    /// the feature existed. Their content may be used (like the résumé), unlike the cover letter.
    var supportingDocuments: [SupportingDocument]

    var createdAt: Date

    init(
        id: String,
        name: String,
        profile: CandidateProfile,
        sourceFileName: String? = nil,
        sourceText: String = "",
        readableText: String = "",
        coverLetterFileName: String? = nil,
        coverLetterText: String = "",
        coverLetterReadableText: String = "",
        supportingDocuments: [SupportingDocument] = [],
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.profile = profile
        self.sourceFileName = sourceFileName
        self.sourceText = sourceText
        self.readableText = readableText
        self.coverLetterFileName = coverLetterFileName
        self.coverLetterText = coverLetterText
        self.coverLetterReadableText = coverLetterReadableText
        self.supportingDocuments = supportingDocuments
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, profile, sourceFileName, sourceText, readableText
        case coverLetterFileName, coverLetterText, coverLetterReadableText
        case supportingDocuments
        case createdAt
    }

    /// Custom decode so the document fields default when absent — a profile saved before
    /// they existed (single-document, pre-cover-letter, or pre-supporting-documents) still
    /// loads instead of being silently dropped.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        profile = try container.decode(CandidateProfile.self, forKey: .profile)
        sourceFileName = try container.decodeIfPresent(String.self, forKey: .sourceFileName)
        sourceText = try container.decodeIfPresent(String.self, forKey: .sourceText) ?? ""
        readableText = try container.decodeIfPresent(String.self, forKey: .readableText) ?? ""
        coverLetterFileName = try container.decodeIfPresent(String.self, forKey: .coverLetterFileName)
        coverLetterText = try container.decodeIfPresent(String.self, forKey: .coverLetterText) ?? ""
        coverLetterReadableText = try container.decodeIfPresent(String.self, forKey: .coverLetterReadableText) ?? ""
        supportingDocuments = try container.decodeIfPresent([SupportingDocument].self, forKey: .supportingDocuments) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

extension SavedProfile {
    /// The real document text for grounded generation against **this** profile (v0.6.0
    /// Milestone B): its résumé's tidied `readableText` (falling back to the raw `sourceText`)
    /// as factual grounding, plus the optional cover letter as a voice/tone exemplar. `nil`
    /// when there's no usable résumé text — a legacy profile saved without its source document —
    /// so generation falls back to profile-only, unchanged.
    ///
    /// Mirrors `PortfolioViewModel.grounding`, but keyed to any saved profile so the user can
    /// pick which one to generate against and have generation ground on **its** source
    /// documents (not just the ambient/loaded one).
    nonisolated var grounding: PortfolioGrounding? {
        let resume = readableText.isEmpty ? sourceText : readableText
        guard !resume.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let rawLetter = coverLetterReadableText.isEmpty ? coverLetterText : coverLetterReadableText
        let letter = rawLetter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : rawLetter
        return PortfolioGrounding(
            resumeText: resume,
            coverLetterText: letter,
            supportingText: Self.joinedSupportingText(supportingDocuments)
        )
    }

    /// The concatenated readable text of a profile's supporting documents (Milestone I),
    /// as one factual-grounding block — or `nil` when there are none with usable text.
    /// Shared by `SavedProfile.grounding` and `PortfolioViewModel.grounding`.
    nonisolated static func joinedSupportingText(_ documents: [SupportingDocument]) -> String? {
        let joined = documents
            .map(\.effectiveText)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        return joined.isEmpty ? nil : joined
    }
}
