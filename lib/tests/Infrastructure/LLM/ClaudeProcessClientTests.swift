//
//  ClaudeProcessClientTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · LLM — pure parsing logic, plus real scripted child processes
//  for the pipe-drain and cancellation regressions (v0.7.1 Milestone E).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("ClaudeProcessClient parsing")
struct ClaudeProcessClientTests {

    // MARK: claudeArguments

    @Test func claudeArgumentsIncludeJSONAndExtraModelFlag() {
        let args = ClaudeProcessClient.claudeArguments(fullPrompt: "hi", extra: ["--model", "claude-opus-4-8"])
        #expect(args == ["-p", "hi", "--output-format", "json", "--model", "claude-opus-4-8"])
    }

    @Test func claudeArgumentsWithoutExtraOmitModel() {
        let args = ClaudeProcessClient.claudeArguments(fullPrompt: "hi", extra: [])
        #expect(args == ["-p", "hi", "--output-format", "json"])
        #expect(!args.contains("--model"))
    }

    // MARK: searchPATH

    @Test func searchPATHIncludesCommonToolLocations() {
        let path = ClaudeProcessClient.searchPATH(base: "/usr/bin:/bin", home: "/Users/x")
        let dirs = path.split(separator: ":").map(String.init)
        #expect(dirs.contains("/Users/x/.local/bin"))   // where `claude` often lives
        #expect(dirs.contains("/opt/homebrew/bin"))
        #expect(dirs.contains("/usr/bin"))               // base entries preserved
    }

    @Test func searchPATHDedupesAndKeepsCommonDirsFirst() {
        let path = ClaudeProcessClient.searchPATH(base: "/opt/homebrew/bin:/custom/bin", home: "/Users/x")
        let dirs = path.split(separator: ":").map(String.init)
        #expect(dirs.filter { $0 == "/opt/homebrew/bin" }.count == 1)   // no duplicate
        #expect(dirs.first == "/Users/x/.local/bin")                    // common dirs prepended
        #expect(dirs.contains("/custom/bin"))                           // extra base entry retained
    }

    @Test func searchPATHHandlesMissingBase() {
        let path = ClaudeProcessClient.searchPATH(base: nil, home: "/Users/x")
        #expect(path.contains("/Users/x/.local/bin"))
        #expect(path.contains("/usr/bin"))
    }

    // MARK: composePrompt

    @Test func composePromptWithoutInstructionsReturnsPrompt() {
        #expect(ClaudeProcessClient.composePrompt(prompt: "hi", instructions: nil) == "hi")
        #expect(ClaudeProcessClient.composePrompt(prompt: "hi", instructions: "") == "hi")
    }

    @Test func composePromptPrependsInstructions() {
        let combined = ClaudeProcessClient.composePrompt(prompt: "Rank this.", instructions: "You are a recruiter.")
        #expect(combined == "You are a recruiter.\n\nRank this.")
    }

    // MARK: stripCodeFences

    @Test func stripLeavesPlainTextUntouched() {
        #expect(ClaudeProcessClient.stripCodeFences("just text") == "just text")
    }

    @Test func stripRemovesJSONFence() {
        let fenced = "```json\n{\"a\":1}\n```"
        #expect(ClaudeProcessClient.stripCodeFences(fenced) == "{\"a\":1}")
    }

    @Test func stripRemovesBareFence() {
        let fenced = "```\nline one\nline two\n```"
        #expect(ClaudeProcessClient.stripCodeFences(fenced) == "line one\nline two")
    }

    @Test func stripHandlesMissingClosingFence() {
        let fenced = "```json\n{\"a\":1}"
        #expect(ClaudeProcessClient.stripCodeFences(fenced) == "{\"a\":1}")
    }

    // MARK: parseResult

    @Test func parseReturnsStrippedResult() throws {
        let json = #"{"type":"result","subtype":"success","is_error":false,"result":"```json\n{\"score\":42}\n```"}"#
        let text = try ClaudeProcessClient.parseResult(from: Data(json.utf8))
        #expect(text == "{\"score\":42}")
    }

    @Test func parseReturnsPlainResult() throws {
        let json = #"{"is_error":false,"result":"Hello world"}"#
        let text = try ClaudeProcessClient.parseResult(from: Data(json.utf8))
        #expect(text == "Hello world")
    }

    @Test func parseEmptyDataThrows() {
        #expect(throws: ClaudeProcessError.emptyOutput) {
            try ClaudeProcessClient.parseResult(from: Data())
        }
    }

    @Test func parseReportedErrorThrows() {
        let json = #"{"is_error":true,"subtype":"error_max_turns","result":null}"#
        #expect(throws: ClaudeProcessError.claudeReportedError("error_max_turns")) {
            try ClaudeProcessClient.parseResult(from: Data(json.utf8))
        }
    }

    @Test func parseMissingResultThrowsEmptyOutput() {
        let json = #"{"is_error":false,"subtype":"success"}"#
        #expect(throws: ClaudeProcessError.emptyOutput) {
            try ClaudeProcessClient.parseResult(from: Data(json.utf8))
        }
    }

    @Test func parseMalformedJSONThrowsDecodingFailed() {
        #expect(throws: ClaudeProcessError.self) {
            try ClaudeProcessClient.parseResult(from: Data("not json".utf8))
        }
    }

    // MARK: v0.7.1 Milestone E — real child processes: pipe drain + cancellation

    /// Writes `body` as an executable `/bin/sh` script in a temp dir and returns its path.
    private func makeScript(_ body: String) throws -> String {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("claude-stub-\(UUID().uuidString).sh")
        try ("#!/bin/sh\n" + body).write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url.path
    }

    /// The E-1 regression: a child that floods **stderr** far past the ~64 KB pipe buffer while
    /// stdout stays open. Sequential draining deadlocked here forever; concurrent draining
    /// completes. The time limit turns a regression into a failure instead of a hung suite.
    @Test(.timeLimit(.minutes(1))) func childFloodingStderrCompletesInsteadOfDeadlocking() async throws {
        // ~130 lines × 1 KB ≈ 130 KB of stderr, then a valid envelope on stdout.
        let script = try makeScript("""
        i=0
        line=$(printf 'e%.0s' $(seq 1 1024))
        while [ $i -lt 130 ]; do
          echo "$line" 1>&2
          i=$((i+1))
        done
        printf '{"result":"OK","is_error":false}'
        """)
        let client = ClaudeProcessClient(launcher: .path(script))
        let result = try await client.generate(prompt: "ignored", instructions: nil)
        #expect(result == "OK")
    }

    /// Cancelling the awaiting task terminates the child and throws `CancellationError` —
    /// before, a cancelled call kept awaiting a child that ran to completion anyway.
    @Test(.timeLimit(.minutes(1))) func cancellationTerminatesTheChildPromptly() async throws {
        let script = try makeScript("""
        sleep 30
        printf '{"result":"TOO LATE","is_error":false}'
        """)
        let client = ClaudeProcessClient(launcher: .path(script))
        let started = Date()
        let call = Task { try await client.generate(prompt: "ignored", instructions: nil) }
        try await Task.sleep(for: .milliseconds(300))   // let the child launch
        call.cancel()

        await #expect(throws: (any Error).self) { try await call.value }
        #expect(Date().timeIntervalSince(started) < 10)   // did not wait out the 30 s sleep
    }
}
