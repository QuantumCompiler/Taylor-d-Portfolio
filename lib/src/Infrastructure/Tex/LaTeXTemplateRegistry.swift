//
//  LaTeXTemplateRegistry.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Tex — the enumerable source of truth for built-in LaTeX templates (v0.7.0 Milestone A).
//

import Foundation

/// A built-in LaTeX template's identity. Persisted inside a ``LaTeXStyle``, so raw values are
/// stable — rename the `displayName` in the descriptor, never the case's raw value.
nonisolated enum LaTeXTemplateID: String, Sendable, Codable, CaseIterable, Identifiable {
    /// The awesome-cv classes exactly as v0.5.1 ships them — the look the app has always produced.
    case awesomeCV = "awesomeCV"
    /// The same classes, tuned tighter: smaller margins and section gaps, for fitting more on a page.
    case awesomeCVCompact = "awesomeCVCompact"

    var id: String { rawValue }
}

/// Everything the app needs to know about one built-in template: its identity, how to describe it,
/// the bundled classes it compiles against, and the ``LaTeXStyle`` it starts from.
///
/// This mirrors `JobProviderRegistry`'s descriptor pattern (v0.6.0 Milestone H-A): the style
/// manager (Milestone E) and the builder (B/C) read the registry rather than hand-enumerating
/// templates, so **adding a template is one appended descriptor** (plus its `.cls` assets under
/// `lib/tex/Class/` when it brings its own) — never a view edit.
nonisolated struct LaTeXTemplateDescriptor: Sendable, Identifiable {
    let template: LaTeXTemplateID
    let displayName: String
    /// A one-line description for the picker.
    let summary: String
    /// The résumé document class, as `\documentclass{…}` names it (a path inside the staged `tex/`).
    let resumeClass: String
    /// The cover-letter document class.
    let coverLetterClass: String
    /// The class files this template needs present under `TexAssets.classesDirectory`.
    let requiredClassFiles: [String]
    /// The paper option each document passes when the style says ``LaTeXPageSize/templateDefault`` —
    /// the template's *own* choice. The awesome-cv résumé passes none (the class's `article` default)
    /// while its cover letter passes `a4paper`; that asymmetry is the template's, not the user's, so
    /// it lives here rather than in the style.
    let templateDefaultPaperOptions: [LaTeXDocumentKind: String]
    /// The style a new document of this template starts from.
    let defaultStyle: LaTeXStyle

    var id: String { template.rawValue }

    /// The document class for one deliverable.
    func documentClass(for document: LaTeXDocumentKind) -> String {
        switch document {
        case .resume: return resumeClass
        case .coverLetter: return coverLetterClass
        }
    }

    /// The paper option to emit for one document under `style` — the user's choice when they made
    /// one, else this template's own default (possibly none).
    func paperOption(for document: LaTeXDocumentKind, style: LaTeXStyle) -> String? {
        style.pageSize.classOption ?? templateDefaultPaperOptions[document]
    }

    /// Whether this template's classes are actually present in a bundled asset tree — so a
    /// template whose assets didn't ship can be omitted from the picker rather than failing at
    /// compile time.
    func isAvailable(in assets: TexAssets) -> Bool {
        let fileManager = FileManager.default
        return requiredClassFiles.allSatisfy {
            fileManager.fileExists(atPath: assets.classesDirectory.appendingPathComponent($0).path)
        }
    }
}

/// The registered built-in templates, in display order. Add one by appending a descriptor below.
nonisolated enum LaTeXTemplateRegistry {
    static let all: [LaTeXTemplateDescriptor] = [.awesomeCV, .awesomeCVCompact]

    /// The template the app falls back to — the shipped awesome-cv look.
    static let fallback = LaTeXTemplateDescriptor.awesomeCV

    /// The descriptor for `template`, if registered.
    static func descriptor(for template: LaTeXTemplateID) -> LaTeXTemplateDescriptor? {
        all.first { $0.template == template }
    }

    /// The descriptor a style is based on, falling back to the shipped template when its stored
    /// id is unknown (a style saved by a later build, or a template that was removed).
    static func descriptor(for style: LaTeXStyle) -> LaTeXTemplateDescriptor {
        descriptor(for: style.template) ?? fallback
    }

    /// The templates whose class files are present in `assets` — what the picker should offer.
    static func available(in assets: TexAssets) -> [LaTeXTemplateDescriptor] {
        all.filter { $0.isAvailable(in: assets) }
    }
}

extension LaTeXTemplateDescriptor {
    /// The shipped awesome-cv look. Its default style is ``LaTeXStyle/default`` — the one that
    /// reproduces today's `.tex` byte-for-byte.
    nonisolated static let awesomeCV = LaTeXTemplateDescriptor(
        template: .awesomeCV,
        displayName: "Portfolio (awesome-cv)",
        summary: "The bundled awesome-cv look — the app's original résumé and cover letter.",
        resumeClass: "Class/Resume",
        coverLetterClass: "Class/CoverLetter",
        requiredClassFiles: ["Resume.cls", "CoverLetter.cls"],
        templateDefaultPaperOptions: [.coverLetter: "a4paper"],
        defaultStyle: .default
    )

    /// The same bundled classes with a tighter default style — no extra assets, so it costs
    /// nothing to ship and gives the registry (and Milestone E's picker) a real second option.
    nonisolated static let awesomeCVCompact = LaTeXTemplateDescriptor(
        template: .awesomeCVCompact,
        displayName: "Portfolio — Compact",
        summary: "The same classes with narrower margins and tighter sections, to fit more on a page.",
        resumeClass: "Class/Resume",
        coverLetterClass: "Class/CoverLetter",
        requiredClassFiles: ["Resume.cls", "CoverLetter.cls"],
        templateDefaultPaperOptions: [.coverLetter: "a4paper"],
        defaultStyle: LaTeXStyle(
            template: .awesomeCVCompact,
            margins: LaTeXMargins(leftCm: 0.35, topCm: 0.35, rightCm: 0.35, bottomCm: 0.55, footskipCm: 0.20),
            letterParagraphSkipEm: 0.8,
            letterLineSpread: 1.0,
            sectionSpacingEm: [
                .education: -1.5,
                .experience: -2.0,
                .projects: -2.0,
                .skills: -1.0,
                .other: -1.5,
            ]
        )
    )
}
