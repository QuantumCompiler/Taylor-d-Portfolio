//
//  FoundationModelsClient.swift
//  Taylor'd Portfolio
//
//  Infrastructure · LLM — Apple on-device model behind the TextGenerating port.
//

import Foundation
import FoundationModels

/// Wraps Apple's on-device Foundation model (`LanguageModelSession`) behind the
/// `TextGenerating` port, and adds constrained decoding for `@Generable` types.
///
/// A fresh `LanguageModelSession` is created per call, so the client holds no
/// conversation state and stays `Sendable`.
nonisolated struct FoundationModelsClient: TextGenerating {

    /// Instructions applied when a call doesn't provide its own.
    var defaultInstructions: String?

    init(defaultInstructions: String? = nil) {
        self.defaultInstructions = defaultInstructions
    }

    /// The current availability of the system language model.
    var availability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    /// Whether the on-device model can be used right now.
    var isAvailable: Bool {
        if case .available = availability { return true }
        return false
    }

    // MARK: TextGenerating

    func generate(prompt: String, instructions: String?) async throws -> String {
        try ensureAvailable()
        let session = makeSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    // MARK: Constrained decoding

    /// Generates a value of a `@Generable` type via constrained decoding — the
    /// on-device engine's distinguishing capability, used by the Data-layer provider.
    func respond<Content: Generable>(
        to prompt: String,
        generating type: Content.Type,
        instructions: String? = nil
    ) async throws -> Content {
        try ensureAvailable()
        let session = makeSession(instructions: instructions)
        let response = try await session.respond(to: prompt, generating: type)
        return response.content
    }

    // MARK: Helpers

    private func makeSession(instructions: String?) -> LanguageModelSession {
        if let text = instructions ?? defaultInstructions {
            return LanguageModelSession(instructions: text)
        }
        return LanguageModelSession()
    }

    private func ensureAvailable() throws {
        switch availability {
        case .available:
            return
        case .unavailable(let reason):
            throw FoundationModelsError.unavailable(reason)
        @unknown default:
            throw FoundationModelsError.unavailable(nil)
        }
    }
}

/// Thrown when the on-device model can't be used.
enum FoundationModelsError: Error {
    /// The model is unavailable; `reason` explains why when the SDK provides one.
    case unavailable(SystemLanguageModel.Availability.UnavailableReason?)
}
