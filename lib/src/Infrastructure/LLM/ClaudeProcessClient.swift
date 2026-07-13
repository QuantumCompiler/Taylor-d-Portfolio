//
//  ClaudeProcessClient.swift
//  Taylor'd Portfolio
//
//  Infrastructure · LLM — the `claude -p` CLI behind the TextGenerating port.
//

import Foundation

/// Runs the `claude -p … --output-format json` CLI as an external process and
/// returns its text result.
///
/// Behind the `TextGenerating` port. Note: a sandboxed app cannot launch external
/// binaries — App Sandbox must be **off** to use this client (see CLAUDE.md → Build).
nonisolated struct ClaudeProcessClient: TextGenerating {

    /// How to locate/launch the `claude` executable.
    enum Launcher: Sendable, Equatable {
        /// Resolve `binaryName` from `PATH` via `/usr/bin/env`.
        case env(binaryName: String)
        /// Launch an explicit absolute path.
        case path(String)
    }

    var launcher: Launcher
    /// Extra CLI arguments appended after the built-in ones.
    var extraArguments: [String]

    init(launcher: Launcher = .env(binaryName: "claude"), extraArguments: [String] = []) {
        self.launcher = launcher
        self.extraArguments = extraArguments
    }

    // MARK: TextGenerating

    func generate(prompt: String, instructions: String?) async throws -> String {
        let fullPrompt = Self.composePrompt(prompt: prompt, instructions: instructions)
        let claudeArgs = Self.claudeArguments(fullPrompt: fullPrompt, extra: extraArguments)

        let executableURL: URL
        let arguments: [String]
        switch launcher {
        case .env(let name):
            executableURL = URL(fileURLWithPath: "/usr/bin/env")
            arguments = [name] + claudeArgs
        case .path(let path):
            executableURL = URL(fileURLWithPath: path)
            arguments = claudeArgs
        }

        let output = try await Self.runProcess(executableURL: executableURL, arguments: arguments)
        return try Self.parseResult(from: output)
    }

    // MARK: - Pure helpers (unit-tested without launching a process)

    /// The `claude -p` argument vector: the prompt, JSON output, then any extra flags
    /// (e.g. `--model <id>`). Pure, so the composed command is unit-tested.
    static func claudeArguments(fullPrompt: String, extra: [String]) -> [String] {
        ["-p", fullPrompt, "--output-format", "json"] + extra
    }

    /// Combines optional instructions with the prompt into a single CLI prompt.
    static func composePrompt(prompt: String, instructions: String?) -> String {
        guard let instructions, !instructions.isEmpty else { return prompt }
        return instructions + "\n\n" + prompt
    }

    /// Decodes the `claude -p --output-format json` envelope, surfaces reported
    /// errors, and returns the fence-stripped `result` text.
    static func parseResult(from data: Data) throws -> String {
        guard !data.isEmpty else { throw ClaudeProcessError.emptyOutput }

        let envelope: Envelope
        do {
            envelope = try JSONDecoder().decode(Envelope.self, from: data)
        } catch {
            throw ClaudeProcessError.decodingFailed(String(data: data, encoding: .utf8) ?? "<non-utf8 output>")
        }

        if envelope.isError == true {
            throw ClaudeProcessError.claudeReportedError(envelope.result ?? envelope.subtype ?? "unknown error")
        }
        guard let result = envelope.result else {
            throw ClaudeProcessError.emptyOutput
        }
        return stripCodeFences(result)
    }

    /// Removes a leading ```` ``` ```` / ```` ```json ```` fence and its closing
    /// fence, if present. Leaves un-fenced text untouched.
    static func stripCodeFences(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else { return trimmed }

        var lines = trimmed.components(separatedBy: "\n")
        lines.removeFirst() // opening fence (``` or ```json)
        if let last = lines.last, last.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
            lines.removeLast() // closing fence
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Builds a `PATH` that includes the common CLI install locations a GUI app's
    /// minimal environment omits (`~/.local/bin`, Homebrew, npm global), so
    /// `/usr/bin/env` can find tools like `claude`. Launched-from-Finder/Xcode apps
    /// inherit only `/usr/bin:/bin:/usr/sbin:/sbin`, where `claude` usually isn't.
    /// Delegates to the shared ``ProcessSupport/searchPATH(base:home:extraDirectories:)``.
    static func searchPATH(base: String?, home: String) -> String {
        ProcessSupport.searchPATH(base: base, home: home)
    }

    /// The subset of the CLI's JSON envelope we consume.
    struct Envelope: Decodable {
        var result: String?
        var isError: Bool?
        var subtype: String?

        enum CodingKeys: String, CodingKey {
            case result
            case isError = "is_error"
            case subtype
        }
    }

    // MARK: - Process execution

    /// A neutral, app-owned working directory for the `claude` subprocess — an (empty) Caches
    /// subdirectory, which is not TCC-protected. Keeps the child out of the user's home so its
    /// startup scan can't touch Photos / Music / Documents and trigger privacy prompts. Falls
    /// back to `nil` (inherit the caller's directory) only if Caches is somehow unavailable.
    private static func neutralWorkingDirectory() -> URL? {
        let fileManager = FileManager.default
        guard let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let directory = caches.appendingPathComponent("ClaudeProcess", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func runProcess(executableURL: URL, arguments: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = executableURL
                process.arguments = arguments
                // Run the child in a neutral, app-owned directory. Without this it inherits the
                // app's working directory (the user's home for a Finder-launched app), where the
                // Claude CLI's startup context-scan reaches TCC-protected locations (Photos,
                // Music, Documents…). Because the app is unsandboxed, macOS attributes those
                // accesses to this app and prompts the user for access that makes no sense for a
                // job app. An empty Caches subdirectory has nothing to traverse into.
                process.currentDirectoryURL = neutralWorkingDirectory()
                // GUI apps inherit a minimal PATH; widen it so `env` can find `claude`.
                var environment = ProcessInfo.processInfo.environment
                environment["PATH"] = searchPATH(base: environment["PATH"], home: environment["HOME"] ?? NSHomeDirectory())
                process.environment = environment
                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: ClaudeProcessError.launchFailed(error.localizedDescription))
                    return
                }

                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                if process.terminationStatus != 0 {
                    let message = String(data: errData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    continuation.resume(
                        throwing: ClaudeProcessError.nonZeroExit(code: process.terminationStatus, message: message)
                    )
                    return
                }
                continuation.resume(returning: outData)
            }
        }
    }
}

/// Errors raised while running or parsing the `claude -p` CLI.
enum ClaudeProcessError: Error, Equatable {
    case launchFailed(String)
    case nonZeroExit(code: Int32, message: String)
    case emptyOutput
    case decodingFailed(String)
    case claudeReportedError(String)
}
