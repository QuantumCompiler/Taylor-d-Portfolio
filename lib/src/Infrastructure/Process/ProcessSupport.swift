//
//  ProcessSupport.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Process — shared helpers for the app's external-process clients.
//

import Foundation

/// Small shared helpers for the clients that shell out to external binaries — the `claude` CLI
/// (`ClaudeProcessClient`) and `lualatex` (`LaTeXProcessClient`). GUI apps inherit only a minimal
/// `PATH` (`/usr/bin:/bin:/usr/sbin:/sbin`), so both need it widened to the common tool locations.
nonisolated enum ProcessSupport {
    /// Builds a `PATH` that includes the common CLI install locations a Finder/Xcode-launched
    /// app's minimal environment omits. `extraDirectories` are prepended **first** (a client's
    /// tool-specific dirs, e.g. TeX bins), then the common dirs, then any existing `base` entries —
    /// all de-duped, order preserved.
    static func searchPATH(base: String?, home: String, extraDirectories: [String] = []) -> String {
        let common = [
            "\(home)/.local/bin",
            "\(home)/.npm-global/bin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/bin", "/bin", "/usr/sbin", "/sbin",
        ]
        let existing = base?.split(separator: ":").map(String.init) ?? []
        var seen = Set<String>()
        var ordered = [String]()
        for dir in extraDirectories + common + existing where !dir.isEmpty && seen.insert(dir).inserted {
            ordered.append(dir)
        }
        return ordered.joined(separator: ":")
    }

    /// Reads a child's stdout and stderr pipes to EOF **concurrently**, returning both.
    ///
    /// Draining them one after the other deadlocked (v0.7.1 Milestone E): a pipe buffer is
    /// ~64 KB, so a child that filled **stderr** while we were still reading stdout blocked on
    /// its write — and stdout then never reached EOF, hanging both sides forever with no
    /// timeout. Blocking call — invoke off the main thread; the `DispatchGroup` wait provides
    /// the memory ordering for the box written on the second queue.
    static func drainToEnd(stdout: Pipe, stderr: Pipe) -> (stdout: Data, stderr: Data) {
        final class Box: @unchecked Sendable { var data = Data() }   // synchronized by group.wait()
        let errBox = Box()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            errBox.data = stderr.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        group.wait()
        return (outData, errBox.data)
    }

    /// The first directory in `path` (colon-separated) that holds an executable named `name`,
    /// or `nil` if none does. Used to probe whether a tool (e.g. `lualatex`) is installed.
    static func locateExecutable(named name: String, inPATH path: String) -> URL? {
        let fileManager = FileManager.default
        for dir in path.split(separator: ":") where !dir.isEmpty {
            let candidate = URL(fileURLWithPath: String(dir)).appendingPathComponent(name)
            if fileManager.isExecutableFile(atPath: candidate.path) { return candidate }
        }
        return nil
    }
}
