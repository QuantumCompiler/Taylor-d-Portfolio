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
    var createdAt: Date

    init(
        id: String,
        name: String,
        profile: CandidateProfile,
        sourceFileName: String? = nil,
        sourceText: String = "",
        readableText: String = "",
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.profile = profile
        self.sourceFileName = sourceFileName
        self.sourceText = sourceText
        self.readableText = readableText
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, profile, sourceFileName, sourceText, readableText, createdAt
    }

    /// Custom decode so the document fields default when absent — a profile saved before
    /// they existed still loads instead of being silently dropped.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        profile = try container.decode(CandidateProfile.self, forKey: .profile)
        sourceFileName = try container.decodeIfPresent(String.self, forKey: .sourceFileName)
        sourceText = try container.decodeIfPresent(String.self, forKey: .sourceText) ?? ""
        readableText = try container.decodeIfPresent(String.self, forKey: .readableText) ?? ""
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
