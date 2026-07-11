//
//  DocumentTextExtractorTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Documents — extraction + routing/error handling.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("PlatformDocumentTextExtractor")
struct DocumentTextExtractorTests {

    private let extractor = PlatformDocumentTextExtractor()

    private func tempFile(ext: String, contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("doc-test-\(UUID().uuidString)")
            .appendingPathExtension(ext)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func extractsPlainText() throws {
        let url = try tempFile(ext: "txt", contents: "Hello portfolio.\nSecond line.")
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(try extractor.extractText(from: url) == "Hello portfolio.\nSecond line.")
    }

    @Test func extractsMarkdown() throws {
        let url = try tempFile(ext: "md", contents: "# Resume\n\n- Swift")
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(try extractor.extractText(from: url) == "# Resume\n\n- Swift")
    }

    @Test func unsupportedExtensionThrows() {
        #expect(throws: DocumentExtractionError.unsupportedType("xyz")) {
            try extractor.extractText(from: URL(fileURLWithPath: "/tmp/whatever.xyz"))
        }
    }

    @Test func emptyDocumentThrows() throws {
        let url = try tempFile(ext: "txt", contents: "   \n  ")
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(throws: DocumentExtractionError.emptyDocument) {
            try extractor.extractText(from: url)
        }
    }
}
