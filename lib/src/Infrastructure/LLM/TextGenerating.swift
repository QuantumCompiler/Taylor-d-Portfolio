//
//  TextGenerating.swift
//  Taylor'd Portfolio
//
//  Infrastructure · LLM — the raw text-generation port.
//

import Foundation

/// The raw, domain-agnostic text-generation capability.
///
/// Declared in Infrastructure (the layer that *owns* the capability); the Data-layer
/// providers depend on it, never the other way round. Implemented by
/// `FoundationModelsClient` (on-device) and `ClaudeProcessClient` (the `claude -p` CLI).
protocol TextGenerating: Sendable {
    /// Produces a plain-text completion for `prompt`, optionally steered by `instructions`.
    func generate(prompt: String, instructions: String?) async throws -> String
}

extension TextGenerating {
    /// Convenience: generate without separate instructions.
    func generate(prompt: String) async throws -> String {
        try await generate(prompt: prompt, instructions: nil)
    }
}
