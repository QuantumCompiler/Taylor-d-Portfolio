//
//  ImportPortfolioUseCaseTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Business · UseCases — document import delegation.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

private struct StubExtractor: DocumentTextExtractor {
    var text = "TEXT"
    var shouldThrow = false
    func extractText(from url: URL) throws -> String {
        if shouldThrow { throw DocumentExtractionError.emptyDocument }
        return text
    }
}

@Suite("ImportPortfolioUseCase")
struct ImportPortfolioUseCaseTests {

    @Test func returnsExtractedText() async throws {
        let useCase = ImportPortfolioUseCase(extractor: StubExtractor(text: "EXTRACTED"))
        let text = try await useCase(fileURL: URL(fileURLWithPath: "/tmp/x.pdf"))
        #expect(text == "EXTRACTED")
    }

    @Test func propagatesExtractionErrors() async {
        let useCase = ImportPortfolioUseCase(extractor: StubExtractor(shouldThrow: true))
        await #expect(throws: DocumentExtractionError.emptyDocument) {
            _ = try await useCase(fileURL: URL(fileURLWithPath: "/tmp/x.pdf"))
        }
    }
}
