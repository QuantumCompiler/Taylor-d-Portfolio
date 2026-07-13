//
//  LaTeXCompiling.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Tex — the port that compiles a .tex document to PDF bytes (Milestone B).
//

import Foundation

/// Compiles a LaTeX document into PDF bytes by shelling out to `lualatex` (Milestone B). The
/// concrete ``LaTeXProcessClient`` stages the bundled awesome-cv assets (Milestone A) alongside
/// the given `.tex` and runs two passes. `isAvailable` reflects whether a `lualatex` install was
/// found — the export UI (Milestone D) disables the LaTeX route when it isn't.
nonisolated protocol LaTeXCompiling: Sendable {
    /// Compiles `tex` (a complete LaTeX document) into PDF `Data`. `jobName` names the scratch
    /// `.tex`/`.pdf` (sanitised internally). Throws ``LaTeXProcessError`` on any failure.
    func compile(tex: String, jobName: String) async throws -> Data

    /// Whether a `lualatex` executable is resolvable on the widened search path.
    var isAvailable: Bool { get }
}

/// Errors raised while compiling with `lualatex`.
nonisolated enum LaTeXProcessError: Error, Equatable, Sendable {
    /// No `lualatex` executable was found (no TeX install).
    case notInstalled
    /// The bundled awesome-cv presentation assets are missing from the app bundle.
    case assetsUnavailable
    /// The process couldn't be launched at all.
    case launchFailed(String)
    /// `lualatex` exited non-zero; carries the tail of its log for diagnosis.
    case nonZeroExit(code: Int32, log: String)
    /// The compile finished but produced no (or empty) PDF.
    case noOutput
}
