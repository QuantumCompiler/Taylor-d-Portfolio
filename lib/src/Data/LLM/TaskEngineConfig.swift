//
//  TaskEngineConfig.swift
//  Taylor'd Portfolio
//
//  Data · LLM — the engine (+ Claude model) chosen for one LLMTask.
//

import Foundation

/// Which engine an ``LLMTask`` should use, plus the Claude model to run when that
/// engine is Claude (or when `.auto` falls back to Claude).
///
/// The default is **Claude / Opus 4.8**: the on-device model is no longer the
/// automatic engine, though it stays selectable per task via `.onDevice` / `.auto`.
nonisolated struct TaskEngineConfig: Codable, Equatable, Hashable, Sendable {
    /// Which engine to prefer for this task.
    var choice: LLMChoice
    /// The Claude model id used when this task runs on Claude.
    var claudeModel: String

    init(choice: LLMChoice = .claude, claudeModel: String = ClaudeModel.defaultID) {
        self.choice = choice
        self.claudeModel = claudeModel
    }

    /// The default per-task config: Claude, on the default model.
    static let `default` = TaskEngineConfig()

    /// The `claude -p` `--model` arguments for this task's model, or `[]` when unset
    /// (let the CLI use its own default).
    var claudeModelArguments: [String] {
        claudeModel.isEmpty ? [] : ["--model", claudeModel]
    }
}
