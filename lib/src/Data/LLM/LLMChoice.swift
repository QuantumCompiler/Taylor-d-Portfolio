//
//  LLMChoice.swift
//  Taylor'd Portfolio
//
//  Data · LLM — which engine the router should use.
//

import Foundation

/// Which LLM engine to use, as chosen by the user in Settings.
///
/// `auto` prefers the on-device model and falls back to Claude when it's
/// unavailable or a call fails.
nonisolated enum LLMChoice: String, Codable, Equatable, Sendable, CaseIterable {
    case auto
    case onDevice
    case claude
}
