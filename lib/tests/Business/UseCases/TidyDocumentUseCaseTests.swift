//
//  TidyDocumentUseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — the tidy path's completeness guarantee (v0.6.2 Milestone E).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("TidyDocumentUseCase")
struct TidyDocumentUseCaseTests {

    /// The shared stub echoes what it was asked to tidy as `"TIDY:\n" + rawText`, so a test can
    /// assert exactly how much of the document the model actually saw.
    private var provider: PresentationStubProvider { PresentationStubProvider() }

    private func document(_ characters: Int, filler: Character = "a") -> String {
        String(repeating: String(filler), count: characters)
    }

    // MARK: Within the bound — unchanged behaviour

    @Test func aShortDocumentIsTidiedWholeWithNoNotice() async throws {
        let text = "A short résumé."
        let tidied = try await TidyDocumentUseCase(provider: provider)(rawText: text)

        #expect(tidied == "TIDY:\n" + text)
        #expect(!tidied.contains(TidyDocumentUseCase.remainderNotice))
    }

    /// A document that fits exactly is still one clean pass — the fallback is strictly for
    /// what exceeds the bound.
    @Test func aDocumentExactlyAtTheBoundIsTidiedWhole() async throws {
        let text = document(Prompts.maxTidyDocumentCharacters)
        let tidied = try await TidyDocumentUseCase(provider: provider)(rawText: text)

        #expect(tidied == "TIDY:\n" + text)
        #expect(!tidied.contains(TidyDocumentUseCase.remainderNotice))
    }

    /// A document longer than the *old* 6 000 cap now tidies in full — the point of raising it.
    @Test func aDocumentPastTheOldCapNowTidiesWhole() async throws {
        let text = document(Prompts.maxPortfolioCharacters + 500)
        let tidied = try await TidyDocumentUseCase(provider: provider)(rawText: text)

        #expect(tidied == "TIDY:\n" + text)
        #expect(!tidied.contains(TidyDocumentUseCase.remainderNotice))
    }

    // MARK: Past the bound — tidied where possible, complete regardless

    @Test func aLongDocumentKeepsItsRemainderAsExtracted() async throws {
        let bound = Prompts.maxTidyDocumentCharacters
        let head = document(bound, filler: "h")
        let tail = document(2_000, filler: "t")
        let tidied = try await TidyDocumentUseCase(provider: provider)(rawText: head + tail)

        // The model saw exactly the head…
        #expect(tidied.hasPrefix("TIDY:\n" + head))
        // …the user is told where the clean-up stopped…
        #expect(tidied.contains(TidyDocumentUseCase.remainderNotice))
        // …and the tail is there verbatim, so nothing is lost.
        #expect(tidied.hasSuffix(tail))
    }

    /// The regression this milestone exists for: the stored readable text must contain **every**
    /// character of the original, however long it is.
    @Test func nothingIsDroppedHoweverLongTheDocument() async throws {
        let bound = Prompts.maxTidyDocumentCharacters
        let marker = "UNIQUE_TAIL_MARKER"
        let text = document(bound + 5_000) + marker
        let tidied = try await TidyDocumentUseCase(provider: provider)(rawText: text)

        #expect(tidied.contains(marker))
        // Everything past the bound survives as-is.
        #expect(tidied.contains(String(text.dropFirst(bound))))
    }

    /// The remainder is appended raw — not re-tidied and not summarised — so the notice is an
    /// honest description of what follows it.
    @Test func theRemainderIsNotSentToTheModel() async throws {
        let bound = Prompts.maxTidyDocumentCharacters
        let tail = "TAIL_THAT_MUST_NOT_BE_TIDIED"
        let tidied = try await TidyDocumentUseCase(provider: provider)(rawText: document(bound) + tail)

        // The stub prefixes anything it tidies with "TIDY:\n" — exactly one pass happened.
        #expect(tidied.components(separatedBy: "TIDY:\n").count - 1 == 1)
        #expect(tidied.hasSuffix(tail))
    }

    // MARK: Failure

    /// A failing engine still throws, so the caller (`PortfolioViewModel.build`) can fall back
    /// to the raw text rather than storing a half-document.
    @Test func aFailingProviderPropagates() async {
        var stub = PresentationStubProvider()
        stub.shouldThrow = true
        let useCase = TidyDocumentUseCase(provider: stub)

        await #expect(throws: (any Error).self) {
            try await useCase(rawText: "anything")
        }
    }

    @Test func anEmptyDocumentIsHandled() async throws {
        let tidied = try await TidyDocumentUseCase(provider: provider)(rawText: "")
        #expect(tidied == "TIDY:\n")
    }
}
