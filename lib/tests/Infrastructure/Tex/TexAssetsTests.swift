//
//  TexAssetsTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Tex — the bundled awesome-cv asset accessor (Milestone A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Marker so `Bundle(for:)` can address the (asset-free) test bundle.
private final class TexAssetsTestMarker {}

@Suite("TexAssets")
struct TexAssetsTests {

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TexAssetsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Resolves from the running app bundle — this also **verifies the assets were copied into
    /// the built `.app`** (the Milestone A folder-reference integration).
    @Test func bundledAssetsResolveFromTheAppAndAreComplete() throws {
        let assets = try #require(TexAssets(), "the app bundle should ship the tex/ resources")
        #expect(assets.isComplete)
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: assets.classesDirectory.appendingPathComponent("Resume.cls").path))
        #expect(fileManager.fileExists(atPath: assets.classesDirectory.appendingPathComponent("CoverLetter.cls").path))
        #expect(fileManager.fileExists(atPath: assets.fontsDirectory.appendingPathComponent("Roboto-Regular.ttf").path))
        #expect(fileManager.fileExists(atPath: assets.root.appendingPathComponent("fontawesome5.sty").path))
    }

    @Test func missingBundleResourcesResolveToNilGracefully() {
        // The test bundle itself ships no tex/ folder → the failable init returns nil.
        #expect(TexAssets(bundle: Bundle(for: TexAssetsTestMarker.self)) == nil)
    }

    @Test func emptyFixtureIsNotComplete() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let assets = TexAssets(root: dir)
        #expect(assets.isComplete == false)
        #expect(assets.classesDirectory.lastPathComponent == "Class")
        #expect(assets.fontsDirectory.lastPathComponent == "fonts")
        #expect(assets.imagesDirectory.lastPathComponent == "Images")
    }

    @Test func fixtureWithClassesAndFontsIsComplete() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileManager = FileManager.default
        let classes = dir.appendingPathComponent("Class", isDirectory: true)
        try fileManager.createDirectory(at: classes, withIntermediateDirectories: true)
        for name in TexAssets.requiredClassFiles {
            try Data("%".utf8).write(to: classes.appendingPathComponent(name))
        }
        try fileManager.createDirectory(at: dir.appendingPathComponent("fonts", isDirectory: true),
                                        withIntermediateDirectories: true)
        #expect(TexAssets(root: dir).isComplete)
    }

    @Test func missingOneClassFileIsNotComplete() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileManager = FileManager.default
        let classes = dir.appendingPathComponent("Class", isDirectory: true)
        try fileManager.createDirectory(at: classes, withIntermediateDirectories: true)
        // Only two of the three required class files.
        try Data("%".utf8).write(to: classes.appendingPathComponent("Resume.cls"))
        try Data("%".utf8).write(to: classes.appendingPathComponent("CoverLetter.cls"))
        try fileManager.createDirectory(at: dir.appendingPathComponent("fonts", isDirectory: true),
                                        withIntermediateDirectories: true)
        #expect(TexAssets(root: dir).isComplete == false)
    }
}
