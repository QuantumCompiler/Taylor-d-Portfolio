//
//  ImportPortfolioUseCase.swift
//  Taylor'd Portfolio
//
//  Business · UseCases — import portfolio text from a document file.
//

import Foundation

/// Reads a document file (PDF, Word, RTF, text…) into portfolio text, ready to feed
/// into ``BuildProfileUseCase``.
nonisolated struct ImportPortfolioUseCase: Sendable {
    let extractor: any DocumentTextExtractor

    init(extractor: any DocumentTextExtractor) {
        self.extractor = extractor
    }

    func callAsFunction(fileURL: URL) async throws -> String {
        try extractor.extractText(from: fileURL)
    }
}
