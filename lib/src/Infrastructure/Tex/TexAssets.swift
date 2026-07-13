//
//  TexAssets.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Tex — locates the bundled awesome-cv LaTeX presentation assets (Milestone A).
//

import Foundation

/// Resolves the awesome-cv **presentation** assets shipped in the app bundle — the
/// `Class/*.cls`, `fonts/`, `Images/`, and `fontawesome*.sty` copied verbatim into the bundle
/// as the `tex/` resource folder (a blue folder reference, so the directory structure is
/// preserved). The LaTeX compile (Milestone B) stages these into a scratch build directory so an
/// app-generated `.tex` resolves `\documentclass{Class/…}` and `\fontdir[fonts/]`.
///
/// Only presentation assets are bundled — never the candidate's content sections; the app
/// supplies content per job.
nonisolated struct TexAssets: Sendable {
    /// The root of the bundled `tex/` folder (contains `Class/`, `fonts/`, `Images/`, `*.sty`).
    let root: URL

    /// Resolves the bundled `tex/` folder in `bundle` (the running app by default). Returns
    /// `nil` when the resources aren't present (e.g. a build that didn't copy them, or the test
    /// bundle) so callers can degrade gracefully rather than crash.
    init?(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "tex", withExtension: nil) else { return nil }
        self.root = url
    }

    /// A caller-supplied root — lets tests point at a fixture directory without a bundle.
    init(root: URL) { self.root = root }

    /// The `Class/` directory holding `Resume.cls` / `CoverLetter.cls` / `Portfolio.cls`.
    var classesDirectory: URL { root.appendingPathComponent("Class", isDirectory: true) }
    /// The `fonts/` directory (Roboto / Source Sans / FontAwesome faces).
    var fontsDirectory: URL { root.appendingPathComponent("fonts", isDirectory: true) }
    /// The `Images/` directory (signature + logo referenced by the classes).
    var imagesDirectory: URL { root.appendingPathComponent("Images", isDirectory: true) }

    /// The class files a compile requires to be present.
    static let requiredClassFiles = ["Resume.cls", "CoverLetter.cls", "Portfolio.cls"]

    /// Whether the expected presentation assets are all present under `root` — the classes and
    /// the fonts directory. Milestone B checks this before attempting a compile.
    var isComplete: Bool {
        let fileManager = FileManager.default
        let classesPresent = Self.requiredClassFiles.allSatisfy {
            fileManager.fileExists(atPath: classesDirectory.appendingPathComponent($0).path)
        }
        var fontsIsDirectory: ObjCBool = false
        let fontsPresent = fileManager.fileExists(atPath: fontsDirectory.path, isDirectory: &fontsIsDirectory)
            && fontsIsDirectory.boolValue
        return classesPresent && fontsPresent
    }
}
