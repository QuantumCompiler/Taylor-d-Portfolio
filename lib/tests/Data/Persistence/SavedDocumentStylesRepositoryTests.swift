//
//  SavedDocumentStylesRepositoryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Data · Persistence — persisting the user's LaTeX document styles (v0.7.0 Milestone D).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("SavedDocumentStylesRepository")
struct SavedDocumentStylesRepositoryTests {

    private func saved(_ id: String, _ name: String, at seconds: TimeInterval,
                       style: LaTeXStyle = .default) -> SavedDocumentStyle {
        SavedDocumentStyle(id: id, name: name, style: style,
                           createdAt: Date(timeIntervalSince1970: seconds))
    }

    /// A style with **every** field off its default — the fixture that catches lossy decoding.
    private var customisedStyle: LaTeXStyle {
        var style = LaTeXStyle.default
        style.template = .awesomeCVCompact
        style.fontFamily = .sourceSansPro
        style.fontSizes = LaTeXFontSizes(resumePt: 7, coverLetterPt: 12)
        style.accent = .custom(hex: "123ABC")
        style.pageSize = .usLetter
        style.margins = LaTeXMargins(leftCm: 1.25, topCm: 1, rightCm: 1.25, bottomCm: 2, footskipCm: 0.5)
        style.letterParagraphSkipEm = 0.8
        style.letterLineSpread = 1.2
        style.sectionOrder = [.skills, .experience]
        style.hiddenSections = [.projects]
        style.sectionSpacingEm = [.skills: -0.25]
        style.customPreamble = "\\documentclass[10pt]{Class/Resume}"
        return style
    }

    /// Plants a raw blob under this repository's kind — the only way to simulate a record written
    /// by a different build.
    private func plant(_ json: String, id: String, in store: InMemoryRecordStore) async throws {
        try await store.upsert(kind: SavedDocumentStylesRepository.kind, id: id, data: Data(json.utf8))
    }

    // MARK: The canonical library four

    @Test func saveThenLoadRoundTripsNewestFirst() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "Older", at: 100))
        try await repo.save(saved("b", "Newer", at: 200))

        let all = try await repo.all()
        #expect(all.map(\.id) == ["b", "a"])                 // newest first
        #expect(all.first == saved("b", "Newer", at: 200))   // whole-value round-trip
    }

    @Test func upsertByIDReplacesRatherThanDuplicates() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "First name", at: 100))
        try await repo.save(saved("a", "Renamed", at: 100))   // same id

        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.name == "Renamed")
    }

    @Test func deleteRemovesByID() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "Keep", at: 100))
        try await repo.save(saved("b", "Drop", at: 200))
        try await repo.delete(id: "b")

        #expect(try await repo.all().map(\.id) == ["a"])
    }

    @Test func emptyStoreLoadsNothing() async throws {
        #expect(try await SavedDocumentStylesRepository(store: InMemoryRecordStore()).all().isEmpty)
    }

    // MARK: Style fidelity — D is the first place a *decoded* style exists

    @Test func aFullyCustomisedStyleSurvivesTheStore() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        let original = customisedStyle
        try await repo.save(saved("a", "Custom", at: 100, style: original))

        let loaded = try #require(try await repo.all().first).style
        #expect(loaded == original)
        // Named separately so a failure says *what* was lost, not merely "not equal".
        #expect(loaded.margins.geometryOptions == original.margins.geometryOptions)
        #expect(loaded.sectionVSpace(forSectionTitled: "Core Skills") == "-0.25em")
        #expect(loaded.customPreamble == original.customPreamble)
    }

    @Test(arguments: [LaTeXAccent.templateDefault, .named(.emerald), .custom(hex: "FF6138")])
    func everyAccentCaseSurvivesTheStore(accent: LaTeXAccent) async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        var style = LaTeXStyle.default
        style.accent = accent
        try await repo.save(saved("a", "Accent", at: 100, style: style))

        #expect(try await repo.all().first?.style.accent == accent)
    }

    /// The two collections that encode as flat arrays rather than objects — the shape most likely
    /// to decode lossily.
    @Test func sectionSpacingAndHiddenSectionsSurviveTheStore() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        var style = LaTeXStyle.default
        style.sectionSpacingEm = [.education: -1.25, .skills: 0, .other: -2]
        style.hiddenSections = [.projects, .other]
        try await repo.save(saved("a", "Sections", at: 100, style: style))

        let loaded = try #require(try await repo.all().first).style
        #expect(loaded.sectionSpacingEm == style.sectionSpacingEm)
        #expect(loaded.hiddenSections == style.hiddenSections)
    }

    /// The point of persisting a style at all: the document it produces is the same one.
    @Test func aStyleRoundTrippedThroughTheStoreProducesTheSameTex() async throws {
        let markdown = """
        # Taylor J. Larrechea

        ## Core Skills
        iOS: SwiftUI

        ## Experience
        ### iOS Engineer
        Lehi, UT · 2025 – Present
        - Shipped things.
        """
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        let original = customisedStyle
        try await repo.save(saved("a", "Custom", at: 100, style: original))
        let loaded = try #require(try await repo.all().first).style

        #expect(TexDocumentBuilder.resume(fromMarkdown: markdown, style: loaded)
            == TexDocumentBuilder.resume(fromMarkdown: markdown, style: original))
        #expect(TexDocumentBuilder.coverLetter(fromMarkdown: "## About\nHello.", style: loaded)
            == TexDocumentBuilder.coverLetter(fromMarkdown: "## About\nHello.", style: original))
    }

    // MARK: Tolerance — records written by another build

    /// A record saved before later style fields existed still loads, with those fields defaulted.
    /// This is the test that fails against a synthesized (all-or-nothing) decoder.
    @Test func aLegacyBlobMissingLaterStyleFieldsStillLoads() async throws {
        let store = InMemoryRecordStore()
        try await plant(#"{"id":"a","name":"Old","createdAt":0,"style":{"template":"awesomeCV"}}"#,
                        id: "a", in: store)

        let loaded = try #require(try await SavedDocumentStylesRepository(store: store).all().first)
        #expect(loaded.name == "Old")
        #expect(loaded.style.fontFamily == .templateDefault)
        #expect(loaded.style.fontSizes == .default)
        #expect(loaded.style.margins == .default)
        #expect(loaded.style.sectionOrder == LaTeXResumeSection.canonicalOrder)
        #expect(loaded.style.sectionSpacingEm == LaTeXResumeSection.canonicalSpacingEm)
        #expect(loaded.style.customPreamble == nil)
    }

    /// A style naming things this build doesn't know — a template from a later version, a section
    /// bucket that no longer exists, an unknown palette colour — degrades field by field instead
    /// of vanishing from the library.
    @Test func aStyleFromALaterBuildDegradesFieldByField() async throws {
        let store = InMemoryRecordStore()
        try await plant("""
        {"id":"a","name":"Future","createdAt":0,"style":{
          "template":"awesomeCVUltra",
          "sectionOrder":["education","glossary"],
          "accent":{"named":{"_0":"chartreuse"}},
          "fontFamily":"comicSans"
        }}
        """, id: "a", in: store)

        let loaded = try #require(try await SavedDocumentStylesRepository(store: store).all().first)
        #expect(LaTeXTemplateRegistry.descriptor(for: loaded.style).template == .awesomeCV)
        #expect(loaded.style.sectionOrder == [.education])     // the unknown bucket is dropped
        #expect(loaded.style.accent == .templateDefault)
        #expect(loaded.style.fontFamily == .templateDefault)
    }

    /// The anti-zombie guarantee: an envelope whose `style` is unreadable **as a whole** still
    /// loads as a named row the user can see and delete. Without it the row would be invisible to
    /// `all()` yet still occupy the store, undeletable (deleting needs the id in the blob).
    @Test func anEnvelopeWithAnUnusableStyleStillLoadsAsADeletableRow() async throws {
        let store = InMemoryRecordStore()
        let repo = SavedDocumentStylesRepository(store: store)
        try await plant(#"{"id":"a","name":"Broken","createdAt":0,"style":"nonsense"}"#, id: "a", in: store)

        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all.first?.name == "Broken")
        #expect(all.first?.style == .default)

        try await repo.delete(id: "a")
        #expect(try await repo.all().isEmpty)
    }

    /// One unreadable row must not take the good ones with it.
    @Test func aCorruptBlobIsSkippedWithoutLosingTheGoodOnes() async throws {
        let store = InMemoryRecordStore()
        let repo = SavedDocumentStylesRepository(store: store)
        try await repo.save(saved("a", "Good", at: 100))
        try await store.upsert(kind: SavedDocumentStylesRepository.kind, id: "bad",
                               data: Data("not json".utf8))
        try await repo.save(saved("c", "Also good", at: 200))

        #expect(try await repo.all().map(\.id) == ["c", "a"])
    }

    // MARK: Edges

    @Test func twoStylesMayShareANameAndStayDistinct() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "Same name", at: 100))
        try await repo.save(saved("b", "Same name", at: 200))

        #expect(try await repo.all().count == 2)
    }

    @Test func deletingAnAbsentIDIsANoOp() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "Keep", at: 100))
        try await repo.delete(id: "ghost")

        #expect(try await repo.all().map(\.id) == ["a"])
    }

    /// Equal timestamps: assert **membership**, not order — `sorted(by:)` isn't documented stable.
    @Test func stylesWithTheSameCreatedAtBothSurvive() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "One", at: 100))
        try await repo.save(saved("b", "Two", at: 100))

        #expect(Set(try await repo.all().map(\.id)) == ["a", "b"])
    }

    /// `kind` + `id` is the store's composite key, so a shared id across two kinds must not
    /// collide — this is what a duplicated `kind` string would silently break.
    @Test func savingAStyleDoesNotDisturbAnotherKind() async throws {
        let store = InMemoryRecordStore()
        let styles = SavedDocumentStylesRepository(store: store)
        let profiles = SavedProfilesRepository(store: store)
        try await styles.save(saved("a", "A style", at: 100))
        let profile = CandidateProfile(seniority: "Mid", yearsExperience: 5, coreSkills: ["Swift"],
                                       domains: [], targetTitles: ["iOS Engineer"], summary: "")
        try await profiles.save(SavedProfile(id: "a", name: "A profile", profile: profile,
                                             createdAt: Date(timeIntervalSince1970: 100)))

        let styleNames = try await styles.all().map(\.name)
        let profileNames = try await profiles.all().map(\.name)
        #expect(styleNames == ["A style"])
        #expect(profileNames == ["A profile"])
    }

    /// Nothing guarded this before D added the seventh repository. A duplicate `kind` is a
    /// cross-type overwrite that surfaces nowhere: `records(ofKind:)` filters on kind alone and
    /// `all()` drops foreign blobs silently.
    @Test func everyRepositoryKindIsDistinct() {
        let kinds = [
            SavedDocumentStylesRepository.kind,
            SavedProfilesRepository.kind,
            SavedJobsRepository.kind,
            SavedApplicationsRepository.kind,
            SavedStatusRepository.kind,
            SavedSearchesRepository.kind,
            GenerationPresetsRepository.kind,
        ]
        #expect(Set(kinds).count == kinds.count)
        #expect(kinds.allSatisfy { !$0.isEmpty })
    }

    // MARK: Use cases

    @Test func saveUseCaseAutoNamesAndAssignsIDAndDate() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        let save = SaveDocumentStyleUseCase(repository: repo,
                                            makeID: { "fixed-id" },
                                            now: { Date(timeIntervalSince1970: 42) })
        var style = LaTeXStyle.default
        style.accent = .named(.emerald)

        let saved = try await save(style)
        #expect(saved.id == "fixed-id")
        #expect(saved.createdAt == Date(timeIntervalSince1970: 42))
        #expect(saved.name == SavedDocumentStyle.defaultName(for: style))
        #expect(try await LoadDocumentStylesUseCase(repository: repo)().count == 1)
    }

    @Test func saveUseCasePreservesIDAndDateWhenUpdatingExisting() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        let save = SaveDocumentStyleUseCase(repository: repo,
                                            makeID: { "new-id" },
                                            now: { Date(timeIntervalSince1970: 999) })
        let existing = saved("original-id", "Mine", at: 42)
        try await repo.save(existing)

        var style = LaTeXStyle.default
        style.pageSize = .usLetter
        let updated = try await save(style, name: "Mine", existing: existing)

        #expect(updated.id == "original-id")
        #expect(updated.createdAt == Date(timeIntervalSince1970: 42))
        #expect(updated.style.pageSize == .usLetter)
        #expect(try await repo.all().count == 1)              // updated in place, not duplicated
    }

    @Test func defaultNameSummarisesTheStyle() {
        let template = LaTeXTemplateRegistry.fallback.displayName
        #expect(SavedDocumentStyle.defaultName(for: .default) == template)

        var named = LaTeXStyle.default
        named.accent = .named(.emerald)
        #expect(SavedDocumentStyle.defaultName(for: named) == "\(template) · Emerald")

        var custom = LaTeXStyle.default
        custom.accent = .custom(hex: "#dc3522")
        #expect(SavedDocumentStyle.defaultName(for: custom) == "\(template) · #DC3522")

        var malformed = LaTeXStyle.default
        malformed.accent = .custom(hex: "nope")
        #expect(SavedDocumentStyle.defaultName(for: malformed) == template)

        var compact = LaTeXStyle.default
        compact.template = .awesomeCVCompact
        #expect(SavedDocumentStyle.defaultName(for: compact)
            == LaTeXTemplateDescriptor.awesomeCVCompact.displayName)
    }

    @Test func deleteUseCaseRemovesByID() async throws {
        let repo = SavedDocumentStylesRepository(store: InMemoryRecordStore())
        try await repo.save(saved("a", "Drop", at: 100))
        try await DeleteDocumentStyleUseCase(repository: repo)(id: "a")

        #expect(try await repo.all().isEmpty)
    }
}
