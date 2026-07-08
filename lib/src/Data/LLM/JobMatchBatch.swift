//
//  JobMatchBatch.swift
//  Taylor'd Portfolio
//
//  Data · LLM — the structured wire shape for a batched ranking call.
//

import Foundation
import FoundationModels

/// The structured output of a batched ranking call: one ``JobMatch`` per job.
///
/// A wrapper is needed because both engines emit a single top-level structured
/// value — `FoundationModelsProvider` decodes it against this `@Generable` type, and
/// `ClaudeCodeProvider` decodes JSON of the same shape (`{ "matches": [ … ] }`).
@Generable
nonisolated struct JobMatchBatch: Codable, Equatable, Sendable {
    @Guide(description: "One match per input job, in the same order as the jobs were given.")
    var matches: [JobMatch]

    init(matches: [JobMatch]) {
        self.matches = matches
    }
}
