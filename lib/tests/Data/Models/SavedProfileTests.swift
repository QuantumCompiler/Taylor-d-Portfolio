//
//  SavedProfileTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Models — SavedProfile round-trip + legacy/back-compat decode (T-A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("SavedProfile")
struct SavedProfileTests {
    private func profile() -> CandidateProfile {
        CandidateProfile(seniority: "Senior", yearsExperience: 6, coreSkills: ["Swift"],
                         domains: ["iOS"], targetTitles: ["iOS Engineer"], summary: "s")
    }

    @Test func roundTripsIncludingCoverLetterFields() throws {
        let original = SavedProfile(
            id: "id-1", name: "Primary", profile: profile(),
            sourceFileName: "cv.pdf", sourceText: "raw", readableText: "tidy",
            coverLetterFileName: "letter.docx", coverLetterText: "raw letter",
            coverLetterReadableText: "tidy letter",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SavedProfile.self, from: data)
        #expect(decoded == original)
        #expect(decoded.coverLetterFileName == "letter.docx")
        #expect(decoded.coverLetterText == "raw letter")
        #expect(decoded.coverLetterReadableText == "tidy letter")
    }

    /// A profile saved before the cover-letter fields existed (or even before the source
    /// document fields) must still decode — with the new fields defaulting to empty — rather
    /// than being silently dropped by the repository's `try?` decode.
    @Test func legacyBlobWithoutNewFieldsStillDecodes() throws {
        let profileObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(profile()))
        // Oldest shape: only id / name / profile / createdAt.
        let legacy: [String: Any] = [
            "id": "old-1", "name": "Legacy", "profile": profileObject, "createdAt": 0,
        ]
        let data = try JSONSerialization.data(withJSONObject: legacy)

        let decoded = try JSONDecoder().decode(SavedProfile.self, from: data)
        #expect(decoded.id == "old-1")
        #expect(decoded.name == "Legacy")
        #expect(decoded.sourceText.isEmpty)            // pre-source-document default
        #expect(decoded.coverLetterFileName == nil)    // pre-cover-letter defaults
        #expect(decoded.coverLetterText.isEmpty)
        #expect(decoded.coverLetterReadableText.isEmpty)
    }

    /// A single-document profile (source fields present, cover-letter fields absent) decodes
    /// with only the cover-letter fields defaulting.
    @Test func singleDocumentBlobDecodesWithEmptyCoverLetter() throws {
        let profileObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(profile()))
        let single: [String: Any] = [
            "id": "s-1", "name": "Single", "profile": profileObject, "createdAt": 0,
            "sourceFileName": "cv.pdf", "sourceText": "raw", "readableText": "tidy",
        ]
        let data = try JSONSerialization.data(withJSONObject: single)

        let decoded = try JSONDecoder().decode(SavedProfile.self, from: data)
        #expect(decoded.sourceFileName == "cv.pdf")
        #expect(decoded.readableText == "tidy")
        #expect(decoded.coverLetterText.isEmpty)
        #expect(decoded.coverLetterReadableText.isEmpty)
    }

    // MARK: Grounding mapper (v0.6.0 Milestone B)

    private func saved(sourceText: String = "", readableText: String = "",
                       coverLetterText: String = "", coverLetterReadableText: String = "") -> SavedProfile {
        SavedProfile(
            id: "id", name: "P", profile: profile(),
            sourceText: sourceText, readableText: readableText,
            coverLetterText: coverLetterText, coverLetterReadableText: coverLetterReadableText,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func groundingPrefersReadableTextAndCarriesCoverLetter() {
        let grounding = saved(sourceText: "raw résumé", readableText: "tidy résumé",
                              coverLetterText: "raw letter", coverLetterReadableText: "tidy letter").grounding
        #expect(grounding?.resumeText == "tidy résumé")       // tidied form preferred
        #expect(grounding?.coverLetterText == "tidy letter")   // exemplar carried
    }

    @Test func groundingFallsBackToRawSourceAndOmitsAbsentCoverLetter() {
        let grounding = saved(sourceText: "raw résumé").grounding   // no tidy, no cover letter
        #expect(grounding?.resumeText == "raw résumé")
        #expect(grounding?.coverLetterText == nil)
    }

    @Test func groundingIsNilWhenNoResumeText() {
        // A legacy profile saved without its source document → no grounding (profile-only).
        #expect(saved().grounding == nil)
        #expect(saved(sourceText: "   ").grounding == nil)   // whitespace-only doesn't count
    }

    // MARK: Supporting documents (v0.6.0 Milestone I)

    @Test func roundTripsIncludingSupportingDocuments() throws {
        let original = SavedProfile(
            id: "id-1", name: "Primary", profile: profile(),
            sourceText: "raw", readableText: "tidy",
            supportingDocuments: [
                SupportingDocument(id: "d1", fileName: "portfolio.pdf", rawText: "raw a", readableText: "tidy a"),
                SupportingDocument(id: "d2", fileName: nil, rawText: "raw b", readableText: "tidy b"),
            ],
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SavedProfile.self, from: data)
        #expect(decoded == original)
        #expect(decoded.supportingDocuments.count == 2)
        #expect(decoded.supportingDocuments[0].fileName == "portfolio.pdf")
        #expect(decoded.supportingDocuments[1].readableText == "tidy b")
    }

    /// A profile saved before supporting documents existed must decode with an empty array.
    @Test func legacyBlobWithoutSupportingDocumentsDecodesEmpty() throws {
        let profileObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(profile()))
        let legacy: [String: Any] = [
            "id": "s-1", "name": "Single", "profile": profileObject, "createdAt": 0,
            "sourceFileName": "cv.pdf", "sourceText": "raw", "readableText": "tidy",
        ]
        let data = try JSONSerialization.data(withJSONObject: legacy)
        let decoded = try JSONDecoder().decode(SavedProfile.self, from: data)
        #expect(decoded.supportingDocuments.isEmpty)
    }

    private func savedWithSupporting(_ documents: [SupportingDocument]) -> SavedProfile {
        SavedProfile(
            id: "id", name: "P", profile: profile(),
            sourceText: "raw résumé", readableText: "tidy résumé",
            supportingDocuments: documents, createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func groundingConcatenatesSupportingDocumentText() {
        let grounding = savedWithSupporting([
            SupportingDocument(id: "a", rawText: "raw a", readableText: "tidy a"),
            SupportingDocument(id: "b", rawText: "raw b"),   // no tidy → falls back to raw
        ]).grounding
        #expect(grounding?.supportingText == "tidy a\n\nraw b")   // readable preferred, joined
    }

    @Test func groundingSupportingTextIsNilWhenNoneUsable() {
        #expect(savedWithSupporting([]).grounding?.supportingText == nil)
        // Whitespace-only documents don't count.
        #expect(savedWithSupporting([SupportingDocument(id: "a", rawText: "   ")]).grounding?.supportingText == nil)
    }
}
