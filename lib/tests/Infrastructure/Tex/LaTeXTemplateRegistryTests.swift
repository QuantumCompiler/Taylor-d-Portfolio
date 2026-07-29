//
//  LaTeXTemplateRegistryTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Tex — the built-in LaTeX template registry (v0.7.0 Milestone A).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("LaTeXTemplateRegistry")
struct LaTeXTemplateRegistryTests {

    /// Writes a fixture asset tree containing `classFiles` under `Class/`, plus a `fonts/` dir.
    private func makeAssets(classFiles: [String]) throws -> TexAssets {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaTeXTemplateRegistryTests-\(UUID().uuidString)", isDirectory: true)
        let classes = root.appendingPathComponent("Class", isDirectory: true)
        try FileManager.default.createDirectory(at: classes, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("fonts", isDirectory: true), withIntermediateDirectories: true)
        for file in classFiles {
            try Data().write(to: classes.appendingPathComponent(file))
        }
        return TexAssets(root: root)
    }

    /// Every registered case has exactly one descriptor — the registry is the source of truth, so
    /// a new `LaTeXTemplateID` without a descriptor (or a duplicate) is a bug, not a runtime `nil`.
    @Test func everyTemplateIDHasExactlyOneDescriptor() {
        #expect(LaTeXTemplateRegistry.all.count == LaTeXTemplateID.allCases.count)
        for template in LaTeXTemplateID.allCases {
            let matches = LaTeXTemplateRegistry.all.filter { $0.template == template }
            #expect(matches.count == 1, "expected one descriptor for \(template.rawValue)")
            #expect(LaTeXTemplateRegistry.descriptor(for: template)?.template == template)
        }
    }

    /// A descriptor's default style must name its own template, or picking a template would hand
    /// back a style pointing at a different one.
    @Test func eachDescriptorsDefaultStyleNamesItsOwnTemplate() {
        for descriptor in LaTeXTemplateRegistry.all {
            #expect(descriptor.defaultStyle.template == descriptor.template)
            #expect(!descriptor.displayName.isEmpty)
            #expect(!descriptor.summary.isEmpty)
            #expect(!descriptor.requiredClassFiles.isEmpty)
        }
    }

    /// The shipped template is the one whose default reproduces today's output.
    @Test func theShippedTemplateDefaultsToTheCurrentLook() {
        let shipped = LaTeXTemplateRegistry.fallback
        #expect(shipped.template == .awesomeCV)
        #expect(shipped.defaultStyle == .default)
        #expect(shipped.documentClass(for: .resume) == "Class/Resume")
        #expect(shipped.documentClass(for: .coverLetter) == "Class/CoverLetter")
    }

    /// The compact variant reuses the bundled classes (no new assets) but differs in presentation
    /// — otherwise it would be a second entry that changes nothing.
    @Test func theCompactTemplateReusesTheBundledClassesButDiffersInStyle() throws {
        let compact = try #require(LaTeXTemplateRegistry.descriptor(for: .awesomeCVCompact))
        #expect(compact.requiredClassFiles == LaTeXTemplateRegistry.fallback.requiredClassFiles)
        #expect(compact.defaultStyle.margins != LaTeXStyle.default.margins)
        #expect(compact.defaultStyle.sectionVSpace(forSectionTitled: "Experience") == "-2em")
    }

    /// Resolving a *style* to its descriptor is total — it hands back the style's own template,
    /// and the shipped one when a case has somehow lost its descriptor (never `nil`, so no call
    /// site has to invent a fallback of its own).
    @Test func aStyleAlwaysResolvesToADescriptor() {
        for template in LaTeXTemplateID.allCases {
            var style = LaTeXStyle.default
            style.template = template
            #expect(LaTeXTemplateRegistry.descriptor(for: style).template == template)
        }
        #expect(LaTeXTemplateRegistry.fallback.template == .awesomeCV)
    }

    // MARK: Availability against a real asset tree

    @Test func templatesResolveAgainstAFixtureAssetTree() throws {
        let assets = try makeAssets(classFiles: ["Resume.cls", "CoverLetter.cls", "Portfolio.cls"])
        #expect(LaTeXTemplateRegistry.available(in: assets).count == LaTeXTemplateRegistry.all.count)
        for descriptor in LaTeXTemplateRegistry.all {
            #expect(descriptor.isAvailable(in: assets))
        }
    }

    /// A template whose classes didn't ship is omitted, so the picker can't offer a compile that
    /// would fail — the same fail-soft posture `TexAssets.isComplete` takes.
    @Test func aTemplateWithMissingClassesIsUnavailable() throws {
        let assets = try makeAssets(classFiles: ["Resume.cls"])
        #expect(LaTeXTemplateRegistry.available(in: assets).isEmpty)
        #expect(!LaTeXTemplateRegistry.fallback.isAvailable(in: assets))
    }

    /// The registry's classes are the ones actually bundled in the built app.
    @Test func theShippedTemplateResolvesAgainstTheAppBundle() throws {
        let assets = try #require(TexAssets(), "the app bundle should ship the tex/ resources")
        #expect(LaTeXTemplateRegistry.fallback.isAvailable(in: assets))
    }
}
