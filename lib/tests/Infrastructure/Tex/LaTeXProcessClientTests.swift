//
//  LaTeXProcessClientTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Tex — the lualatex compiler client (Milestone B).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("LaTeXProcessClient")
struct LaTeXProcessClientTests {

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaTeXTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// A fixture assets root that reports `isComplete` (the three classes + a fonts dir).
    private func completeAssets() throws -> (TexAssets, URL) {
        let dir = try makeTempDir()
        let classes = dir.appendingPathComponent("Class", isDirectory: true)
        try FileManager.default.createDirectory(at: classes, withIntermediateDirectories: true)
        for name in TexAssets.requiredClassFiles {
            try Data("%".utf8).write(to: classes.appendingPathComponent(name))
        }
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("fonts", isDirectory: true),
                                                withIntermediateDirectories: true)
        return (TexAssets(root: dir), dir)
    }

    // MARK: Pure helpers

    @Test func argumentVectorIsNonInteractiveAndHaltsOnError() {
        #expect(LaTeXProcessClient.arguments(texFileName: "foo.tex")
                == ["-interaction=nonstopmode", "-halt-on-error", "foo.tex"])
    }

    @Test func safeBaseNameSanitisesForLaTeX() {
        #expect(LaTeXProcessClient.safeBaseName("Cover Letter") == "Cover-Letter")
        #expect(LaTeXProcessClient.safeBaseName("a/b*c") == "a-b-c")
        #expect(LaTeXProcessClient.safeBaseName("a   b") == "a-b")     // runs collapse to one dash
        #expect(LaTeXProcessClient.safeBaseName("!hi!") == "hi")       // leading/trailing dashes trimmed
        #expect(LaTeXProcessClient.safeBaseName("Resume") == "Resume")
        #expect(LaTeXProcessClient.safeBaseName("   ") == "document")  // empty → fallback
    }

    @Test func logTailKeepsShortLogsAndTrimsLongOnes() {
        #expect(LaTeXProcessClient.logTail("one\ntwo") == "one\ntwo")
        let long = (1...100).map(String.init).joined(separator: "\n")
        let tail = LaTeXProcessClient.logTail(long, maxLines: 5)
        #expect(tail == "96\n97\n98\n99\n100")
    }

    @Test func searchPATHPrependsTexDirectories() {
        let path = ProcessSupport.searchPATH(base: "/usr/bin", home: "/Users/x",
                                             extraDirectories: LaTeXProcessClient.texDirectories)
        #expect(path.hasPrefix("/Library/TeX/texbin"))   // MacTeX dir first
        #expect(path.contains("/usr/local/bin"))
        // De-duped: /usr/bin (in base + common) appears once.
        #expect(path.components(separatedBy: ":").filter { $0 == "/usr/bin" }.count == 1)
    }

    // MARK: Executable location

    @Test func locatesAnExecutableOnThePATHAndRejectsMissingOnes() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let tool = dir.appendingPathComponent("faketool")
        try Data("#!/bin/sh\n".utf8).write(to: tool)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tool.path)

        #expect(ProcessSupport.locateExecutable(named: "faketool", inPATH: dir.path)?.path == tool.path)
        #expect(ProcessSupport.locateExecutable(named: "faketool", inPATH: "/no/such/dir") == nil)
        #expect(ProcessSupport.locateExecutable(named: "absent", inPATH: dir.path) == nil)
    }

    @Test func explicitPathLauncherReflectsExecutability() {
        // /bin/ls is a real executable → available; a bogus path is not.
        #expect(LaTeXProcessClient(launcher: .path("/bin/ls")).isAvailable)
        #expect(LaTeXProcessClient(launcher: .path("/nonexistent/lualatex")).isAvailable == false)
    }

    // MARK: Compile guards (deterministic — no process launched)

    @Test func compileThrowsWhenAssetsAreUnavailable() async {
        let client = LaTeXProcessClient(launcher: .path("/bin/ls"), assets: nil)
        await #expect(throws: LaTeXProcessError.assetsUnavailable) {
            _ = try await client.compile(tex: "x", jobName: "r")
        }
    }

    @Test func compileThrowsNotInstalledWhenNoLualatex() async throws {
        let (assets, dir) = try completeAssets()
        defer { try? FileManager.default.removeItem(at: dir) }
        let client = LaTeXProcessClient(launcher: .path("/nonexistent/lualatex"), assets: assets)
        await #expect(throws: LaTeXProcessError.notInstalled) {
            _ = try await client.compile(tex: "x", jobName: "r")
        }
    }

    // MARK: Staging

    @Test func stageSymlinksEveryBundledItem() throws {
        let (assets, srcDir) = try completeAssets()
        defer { try? FileManager.default.removeItem(at: srcDir) }
        let buildDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: buildDir) }

        try LaTeXProcessClient.stage(assets: assets, into: buildDir)
        // Class/ is staged and resolves through the symlink to a real class file.
        let staged = buildDir.appendingPathComponent("Class/Resume.cls").path
        #expect(FileManager.default.fileExists(atPath: staged))
    }

    // MARK: Integration — a real compile (skipped when lualatex isn't installed)

    @Test func compilesATrivialDocumentEndToEnd() async throws {
        let client = LaTeXProcessClient()
        guard client.isAvailable, client.assets?.isComplete == true else {
            return   // no TeX install / assets in this environment — don't fail the suite
        }
        let pdf = try await client.compile(
            tex: "\\documentclass{article}\\begin{document}Hello TeX\\end{document}",
            jobName: "smoke test"
        )
        #expect(pdf.prefix(4).elementsEqual(Data("%PDF".utf8)))   // real lualatex output
        #expect(pdf.count > 500)
    }
}
