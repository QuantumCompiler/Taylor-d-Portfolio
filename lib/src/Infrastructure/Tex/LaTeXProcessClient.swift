//
//  LaTeXProcessClient.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Tex — the `lualatex` compiler behind the LaTeXCompiling port (Milestone B).
//

import Foundation

/// Compiles a `.tex` document to PDF by running `lualatex` as an external process — the second
/// external binary the (unsandboxed) app shells out to, mirroring ``ClaudeProcessClient``.
///
/// A compile stages the bundled awesome-cv assets (``TexAssets``, Milestone A) into a fresh,
/// app-owned build directory, writes the `.tex`, runs `lualatex` **twice** (so footers/refs
/// settle — the two-pass rule the manual `PortfolioBuddy` uses), reads the produced PDF, and
/// tears the directory down. Requires a local TeX install; a sandboxed app cannot launch it.
nonisolated struct LaTeXProcessClient: LaTeXCompiling {

    /// How to locate/launch the `lualatex` executable.
    enum Launcher: Sendable, Equatable {
        /// Resolve `binaryName` from the widened search path.
        case env(binaryName: String)
        /// Launch an explicit absolute path.
        case path(String)
    }

    var launcher: Launcher
    /// The bundled presentation assets to stage; `nil`/incomplete makes a compile throw
    /// ``LaTeXProcessError/assetsUnavailable``.
    var assets: TexAssets?

    init(launcher: Launcher = .env(binaryName: "lualatex"), assets: TexAssets? = TexAssets()) {
        self.launcher = launcher
        self.assets = assets
    }

    /// TeX bin directories prepended to `PATH` so `lualatex` resolves even from a GUI app's
    /// minimal environment: MacTeX's stable symlink dir plus common TeX Live / Homebrew locations.
    static let texDirectories = [
        "/Library/TeX/texbin",
        "/usr/local/texlive/2025/bin/universal-darwin",
        "/usr/local/texlive/2024/bin/universal-darwin",
        "/opt/homebrew/bin",
        "/usr/local/bin",
    ]

    // MARK: LaTeXCompiling

    var isAvailable: Bool { locate() != nil }

    /// The resolved `lualatex` executable, or `nil` when no TeX install is found.
    func locate() -> URL? {
        switch launcher {
        case .path(let path):
            return FileManager.default.isExecutableFile(atPath: path) ? URL(fileURLWithPath: path) : nil
        case .env(let name):
            return ProcessSupport.locateExecutable(named: name, inPATH: widenedPATH())
        }
    }

    func compile(tex: String, jobName: String) async throws -> Data {
        guard let assets, assets.isComplete else { throw LaTeXProcessError.assetsUnavailable }
        guard let executable = locate() else { throw LaTeXProcessError.notInstalled }

        let base = Self.safeBaseName(jobName)
        let buildDir = try Self.makeBuildDirectory()
        defer { try? FileManager.default.removeItem(at: buildDir) }

        try Self.stage(assets: assets, into: buildDir)
        try Data(tex.utf8).write(to: buildDir.appendingPathComponent("\(base).tex"))

        let arguments = Self.arguments(texFileName: "\(base).tex")
        // Two passes so page footers / references settle (PortfolioBuddy discipline).
        for _ in 0..<2 {
            try await runProcess(executable: executable, arguments: arguments, workingDirectory: buildDir)
        }

        let pdfURL = buildDir.appendingPathComponent("\(base).pdf")
        guard let data = try? Data(contentsOf: pdfURL), !data.isEmpty else { throw LaTeXProcessError.noOutput }
        return data
    }

    // MARK: - Pure helpers (unit-tested without launching a process)

    /// The `lualatex` argument vector — non-interactive, halting on the first error, then the
    /// `.tex` filename. Pure, so the composed command is unit-tested.
    static func arguments(texFileName: String) -> [String] {
        ["-interaction=nonstopmode", "-halt-on-error", texFileName]
    }

    /// A LaTeX-safe scratch basename: non-alphanumerics collapse to single dashes; empty falls
    /// back to `document`. (The user-facing export filename is chosen separately in Milestone D.)
    static func safeBaseName(_ name: String) -> String {
        var out = ""
        var lastWasDash = false
        for scalar in name.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                out.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash {
                out.append("-")
                lastWasDash = true
            }
        }
        let trimmed = out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "document" : trimmed
    }

    /// The last `maxLines` lines of a `lualatex` log — enough to surface the real error.
    static func logTail(_ log: String, maxLines: Int = 30) -> String {
        let lines = log.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count > maxLines else { return log.trimmingCharacters(in: .whitespacesAndNewlines) }
        return lines.suffix(maxLines).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Staging / process execution

    private func widenedPATH() -> String {
        let environment = ProcessInfo.processInfo.environment
        return ProcessSupport.searchPATH(
            base: environment["PATH"],
            home: environment["HOME"] ?? NSHomeDirectory(),
            extraDirectories: Self.texDirectories
        )
    }

    /// Creates a fresh, app-owned build directory under Caches (unique per compile).
    static func makeBuildDirectory() throws -> URL {
        let fileManager = FileManager.default
        let root = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let dir = root.appendingPathComponent("TexBuild-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Symlinks each bundled asset (`Class/`, `fonts/`, `Images/`, `*.sty`) into `directory`, so
    /// relative `\documentclass{Class/…}` / `\fontdir[fonts/]` resolve. Symlinks (not copies) —
    /// fast and duplication-free; `lualatex` reads through them and writes outputs to `directory`.
    static func stage(assets: TexAssets, into directory: URL) throws {
        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(
            at: assets.root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )
        for item in items {
            let destination = directory.appendingPathComponent(item.lastPathComponent)
            try fileManager.createSymbolicLink(at: destination, withDestinationURL: item)
        }
    }

    private func runProcess(executable: URL, arguments: [String], workingDirectory: URL) async throws {
        let path = widenedPATH()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = executable
                process.arguments = arguments
                process.currentDirectoryURL = workingDirectory
                var environment = ProcessInfo.processInfo.environment
                environment["PATH"] = path
                process.environment = environment
                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: LaTeXProcessError.launchFailed(error.localizedDescription))
                    return
                }

                // lualatex writes diagnostics to stdout; read it fully (well under the pipe buffer)
                // before waiting so a full pipe can't deadlock the child.
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                _ = stderr.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                if process.terminationStatus != 0 {
                    let log = String(data: outData, encoding: .utf8) ?? ""
                    continuation.resume(throwing: LaTeXProcessError.nonZeroExit(
                        code: process.terminationStatus, log: Self.logTail(log)
                    ))
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }
}
