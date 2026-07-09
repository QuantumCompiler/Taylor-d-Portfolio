//
//  ClaudeModel.swift
//  Taylor'd Portfolio
//
//  Data · LLM — the selectable Claude models for the `claude -p` engine.
//

import Foundation

/// A Claude model the user can pick for the `claude -p` engine. `id` is the exact
/// model string passed to the CLI's `--model` flag; `displayName` is shown in Settings.
///
/// The list is the current Claude generation. IDs are the canonical model strings —
/// don't append date suffixes (the CLI resolves these as-is).
nonisolated struct ClaudeModel: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let displayName: String

    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }

    /// All selectable models, most-capable first.
    static let all: [ClaudeModel] = [
        .init(id: "claude-fable-5", displayName: "Fable 5"),
        .init(id: "claude-opus-4-8", displayName: "Opus 4.8"),
        .init(id: "claude-opus-4-7", displayName: "Opus 4.7"),
        .init(id: "claude-sonnet-5", displayName: "Sonnet 5"),
        .init(id: "claude-sonnet-4-6", displayName: "Sonnet 4.6"),
        .init(id: "claude-haiku-4-5", displayName: "Haiku 4.5"),
    ]

    /// The default selection (Opus 4.8 — the recommended general-purpose model).
    static let defaultID = "claude-opus-4-8"

    /// Whether `id` is one of the known models.
    static func isKnown(_ id: String) -> Bool {
        all.contains { $0.id == id }
    }
}
