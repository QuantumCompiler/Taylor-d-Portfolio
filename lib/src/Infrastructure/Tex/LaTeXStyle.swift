//
//  LaTeXStyle.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Tex — the user-owned presentation style for the awesome-cv route (v0.7.0 Milestone A).
//

import Foundation

/// Every **presentation** choice the awesome-cv LaTeX route makes, as one pure value: typography,
/// colour, page geometry, and résumé section order / visibility — plus an optional raw-LaTeX
/// preamble override (v0.7.0 Milestone F).
///
/// Today those choices are string literals inside ``TexDocumentBuilder``'s two preamble builders;
/// Milestones B and C move them here, so a style is what the builder reads instead. It is a **pure**
/// value type — no I/O, no model calls — so styles are trivially testable, `Codable` for the styles
/// library (Milestone D), and `Sendable` for use off the main actor.
///
/// **One style covers both documents** (résumé + cover letter). Only genuinely document-inherent
/// values are split per document — see ``LaTeXFontSizes``, where the two awesome-cv classes take
/// very different base sizes for the *same* apparent text size.
///
/// **Presentation only.** A style themes layout; it never contributes content. The document body
/// stays app-generated and LaTeX-escaped, including under a `customPreamble` override.
///
/// ⚠️ Not to be confused with `ExportTemplate` / `TemplateStyle` (Infrastructure · Export), which
/// theme the **native Core Text** PDF/DOCX exports. That system is untouched by this one.
nonisolated struct LaTeXStyle: Sendable, Equatable, Codable {

    /// Which built-in template (bundled class set + its defaults) this style is based on.
    var template: LaTeXTemplateID

    /// The body/header font family, or the template's own default (no `\newfontfamily` override).
    var fontFamily: LaTeXFontFamily

    /// The `\documentclass` base sizes — per document, because the classes differ (see the type).
    var fontSizes: LaTeXFontSizes

    /// The accent colour awesome-cv paints section titles / locations with (`\colorlet{awesome}`).
    var accent: LaTeXAccent

    /// The page size passed as a `\documentclass` paper option.
    var pageSize: LaTeXPageSize

    /// The `\geometry{…}` page margins, shared by both documents.
    var margins: LaTeXMargins

    /// The cover letter's body paragraph skip, in `em` (`\setlength{\parskip}{…em}`).
    var letterParagraphSkipEm: Double

    /// The cover letter's body line spread (`\linespread{…}`).
    var letterLineSpread: Double

    /// The résumé's section order, top to bottom. Sections are matched to these buckets by title
    /// (``LaTeXResumeSection/classify(_:)``); anything unrecognised lands in ``LaTeXResumeSection/other``.
    var sectionOrder: [LaTeXResumeSection]

    /// Sections omitted from the résumé entirely.
    var hiddenSections: Set<LaTeXResumeSection>

    /// The `\vspace` before each `\cvsection`, in `em` (negative tightens, matching awesome-cv).
    var sectionSpacingEm: [LaTeXResumeSection: Double]

    /// A raw-LaTeX preamble that **replaces** the generated one verbatim (Milestone F). The body is
    /// still app-generated and escaped — an override themes presentation, it can't inject content.
    /// `nil` (the normal case) means "build the preamble from the fields above".
    var customPreamble: String?

    init(
        template: LaTeXTemplateID = .awesomeCV,
        fontFamily: LaTeXFontFamily = .templateDefault,
        fontSizes: LaTeXFontSizes = .default,
        accent: LaTeXAccent = .templateDefault,
        pageSize: LaTeXPageSize = .templateDefault,
        margins: LaTeXMargins = .default,
        letterParagraphSkipEm: Double = 1.0,
        letterLineSpread: Double = 1.08,
        sectionOrder: [LaTeXResumeSection] = LaTeXResumeSection.canonicalOrder,
        hiddenSections: Set<LaTeXResumeSection> = [],
        sectionSpacingEm: [LaTeXResumeSection: Double] = LaTeXResumeSection.canonicalSpacingEm,
        customPreamble: String? = nil
    ) {
        self.template = template
        self.fontFamily = fontFamily
        self.fontSizes = fontSizes
        self.accent = accent
        self.pageSize = pageSize
        self.margins = margins
        self.letterParagraphSkipEm = letterParagraphSkipEm
        self.letterLineSpread = letterLineSpread
        self.sectionOrder = sectionOrder
        self.hiddenSections = hiddenSections
        self.sectionSpacingEm = sectionSpacingEm
        self.customPreamble = customPreamble
    }

    /// The style that reproduces **today's** output exactly — the hand-authored awesome-cv look
    /// `TexDocumentBuilder` currently hardcodes. Every `.templateDefault` case above exists for
    /// this: the current builder emits no font-family, colour, or paper option, so the default
    /// style must emit none either, and Milestones B/C can land behind a byte-for-byte regression.
    static let `default` = LaTeXStyle()

    // MARK: Section helpers (consumed by Milestone C)

    /// Whether a section with this title is rendered at all.
    func isVisible(sectionTitled title: String) -> Bool {
        !hiddenSections.contains(LaTeXResumeSection.classify(title))
    }

    /// The sort index for a section title — its bucket's position in ``sectionOrder``. Buckets the
    /// order doesn't mention sort **after** the ones it does (stable within themselves), so a
    /// section can never be silently dropped by omission — only by ``hiddenSections``.
    func orderIndex(ofSectionTitled title: String) -> Int {
        let section = LaTeXResumeSection.classify(title)
        return sectionOrder.firstIndex(of: section) ?? sectionOrder.count
    }

    /// The `\vspace` argument before a section's `\cvsection` (e.g. `-1.5em`).
    func sectionVSpace(forSectionTitled title: String) -> String {
        let section = LaTeXResumeSection.classify(title)
        let value = sectionSpacingEm[section] ?? LaTeXResumeSection.canonicalSpacingEm[section] ?? -1
        return "\(LaTeXStyle.number(value))em"
    }

    // MARK: Cover-letter body spacing (consumed by Milestone B)

    /// The `\setlength{\parskip}{…}` argument — one decimal, as the current builder writes `1.0em`.
    var letterParagraphSkipArgument: String { "\(LaTeXStyle.fixed(letterParagraphSkipEm, decimals: 1))em" }

    /// The `\linespread{…}` argument (`1.08`).
    var letterLineSpreadArgument: String { LaTeXStyle.number(letterLineSpread) }

    // MARK: Number formatting

    /// Formats a measurement the way the hand-authored `.tex` writes it — up to `decimals` places
    /// with trailing zeros trimmed (`-1.0` → `-1`, `-1.50` → `-1.5`, `1.08` → `1.08`).
    static func number(_ value: Double, decimals: Int = 2) -> String {
        var text = String(format: "%.\(decimals)f", value)
        if text.contains(".") {
            while text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix(".") { text.removeLast() }
        }
        return text == "-0" ? "0" : text
    }

    /// Formats a fixed-precision measurement (no trimming) — `\geometry` writes `0.50cm`, not `0.5cm`.
    static func fixed(_ value: Double, decimals: Int = 2) -> String {
        String(format: "%.\(decimals)f", value)
    }
}

// MARK: - Page size

/// The paper the documents are laid out on, as a `\documentclass` option.
nonisolated enum LaTeXPageSize: String, Sendable, Codable, CaseIterable, Identifiable {
    /// Whatever the template's classes already do — the résumé passes no paper option and the
    /// cover letter passes `a4paper`. Keeping this as its own case (rather than picking one for
    /// the user) is what lets ``LaTeXStyle/default`` reproduce today's output byte-for-byte.
    case templateDefault
    case usLetter
    case a4

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .templateDefault: return "Template default"
        case .usLetter: return "US Letter"
        case .a4: return "A4"
        }
    }

    /// The `\documentclass` option, or `nil` to leave the template's own choice alone.
    var classOption: String? {
        switch self {
        case .templateDefault: return nil
        case .usLetter: return "letterpaper"
        case .a4: return "a4paper"
        }
    }
}

// MARK: - Fonts

/// The bundled font families under `lib/tex/fonts/`. **Bundled only** — a family the app doesn't
/// ship can't be selected, because the compile stages these faces into its scratch directory and
/// `lualatex` resolves them by file name via `\fontdir`. Adding a family means bundling its faces
/// (licensing + bundle size), so the set stays deliberately small.
nonisolated enum LaTeXFontFamily: String, Sendable, Codable, CaseIterable, Identifiable {
    /// The classes' own choice — Roboto for headers, Source Sans Pro for body text. No override
    /// is emitted, which is what today's output does.
    case templateDefault
    case roboto
    case sourceSansPro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .templateDefault: return "Template default"
        case .roboto: return "Roboto"
        case .sourceSansPro: return "Source Sans Pro"
        }
    }

    /// The face-file prefix under `lib/tex/fonts/` (`Roboto-Regular.ttf`, `SourceSansPro-Regular.otf`),
    /// which is also the family name `\newfontfamily` is given. `nil` for the template default.
    var faceNamePrefix: String? {
        switch self {
        case .templateDefault: return nil
        case .roboto: return "Roboto"
        case .sourceSansPro: return "SourceSansPro"
        }
    }

    /// The file extension the bundled faces use — Roboto ships as TrueType, Source Sans as OpenType.
    /// Passed to `fontspec` explicitly so it resolves the exact bundled file rather than guessing.
    var fileExtension: String? {
        switch self {
        case .templateDefault: return nil
        case .roboto: return ".ttf"
        case .sourceSansPro: return ".otf"
        }
    }

    /// The four face suffixes of one weight group, as `fontspec`'s `*-…` patterns.
    struct Faces: Sendable, Equatable {
        var upright: String
        var italic: String
        var bold: String
        var boldItalic: String
    }

    /// The regular weight group (drives `\bodyfont`). `nil` for the template default.
    var regularFaces: Faces? {
        switch self {
        case .templateDefault: return nil
        case .roboto: return Faces(upright: "*-Regular", italic: "*-Italic",
                                   bold: "*-Bold", boldItalic: "*-BoldItalic")
        case .sourceSansPro: return Faces(upright: "*-Regular", italic: "*-It",
                                          bold: "*-Bold", boldItalic: "*-BoldIt")
        }
    }

    /// The light weight group (drives `\bodyfontlight`, which awesome-cv uses for body copy and
    /// entry descriptions). `nil` for the template default.
    var lightFaces: Faces? {
        switch self {
        case .templateDefault: return nil
        case .roboto: return Faces(upright: "*-Light", italic: "*-LightItalic",
                                   bold: "*-Medium", boldItalic: "*-MediumItalic")
        case .sourceSansPro: return Faces(upright: "*-Light", italic: "*-LightIt",
                                          bold: "*-Semibold", boldItalic: "*-SemiboldIt")
        }
    }
}

/// The `\documentclass` base font sizes, **per document**.
///
/// This is the one deliberately un-unified control. The two awesome-cv classes scale everything off
/// their base size very differently — the résumé class is authored around `6pt` (its own styles then
/// set 24pt/10pt/8pt/7pt explicitly) while the letter class is authored around `11pt` — so a single
/// shared number would mean "6pt" rendering as two unrelated text sizes across the two documents.
/// The user still edits one style; it just carries the two bases.
nonisolated struct LaTeXFontSizes: Sendable, Equatable, Codable {
    var resumePt: Double
    var coverLetterPt: Double

    init(resumePt: Double = 6, coverLetterPt: Double = 11) {
        self.resumePt = resumePt
        self.coverLetterPt = coverLetterPt
    }

    /// Today's bases: `\documentclass[6pt]{Class/Resume}` / `\documentclass[11pt, a4paper]{Class/CoverLetter}`.
    static let `default` = LaTeXFontSizes()

    /// The `\documentclass` size option for one document (`6pt`).
    func classOption(for document: LaTeXDocumentKind) -> String {
        switch document {
        case .resume: return "\(LaTeXStyle.number(resumePt))pt"
        case .coverLetter: return "\(LaTeXStyle.number(coverLetterPt))pt"
        }
    }
}

/// Which of the two deliverables a preamble is being built for. (Infrastructure-local — the domain's
/// `ApplicationDocument` lives in Data and must not be imported downward.)
nonisolated enum LaTeXDocumentKind: String, Sendable, Codable, CaseIterable, Identifiable {
    case resume
    case coverLetter

    var id: String { rawValue }
}

// MARK: - Accent colour

/// The accent colour awesome-cv paints section titles, entry locations, and the header position
/// with — the class's `\colorlet{awesome}{…}`.
nonisolated enum LaTeXAccent: Sendable, Equatable, Codable {
    /// Leave the class's own choice (`awesome-cyan`) alone — emits nothing, as today does.
    case templateDefault
    /// One of the palette colours the bundled classes already define.
    case named(LaTeXAwesomeColor)
    /// An arbitrary colour as a six-digit RGB hex string (no `#`), e.g. `"DC3522"`.
    case custom(hex: String)

    /// The six-digit uppercase hex this accent resolves to, or `nil` for the template default.
    var hex: String? {
        switch self {
        case .templateDefault: return nil
        case let .named(colour): return colour.hex
        case let .custom(hex): return LaTeXAccent.normalizedHex(hex)
        }
    }

    /// Uppercases and strips a leading `#`, returning `nil` unless it's six hex digits — so a
    /// malformed value degrades to "no override" rather than emitting broken LaTeX.
    static func normalizedHex(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, value.allSatisfy(\.isHexDigit) else { return nil }
        return value
    }
}

/// The `awesome-*` palette the bundled classes define (`lib/tex/Class/Resume.cls`). Named rather
/// than hex-only so the picker can offer the template's own palette, and so the emitted LaTeX can
/// read `\colorlet{awesome}{awesome-red}`.
nonisolated enum LaTeXAwesomeColor: String, Sendable, Codable, CaseIterable, Identifiable {
    case emerald, skyblue, red, pink, orange, nephritis, concrete, darknight, cyan

    var id: String { rawValue }

    /// The colour name defined by the classes (`awesome-red`).
    var latexName: String { "awesome-\(rawValue)" }

    /// The hex the classes define it as — kept in sync with `Resume.cls` / `CoverLetter.cls`.
    var hex: String {
        switch self {
        case .emerald: return "00A388"
        case .skyblue: return "0395DE"
        case .red: return "DC3522"
        case .pink: return "EF4089"
        case .orange: return "FF6138"
        case .nephritis: return "27AE60"
        case .concrete: return "95A5A6"
        case .darknight: return "131A28"
        case .cyan: return "01DDF0"
        }
    }

    var displayName: String {
        switch self {
        case .emerald: return "Emerald"
        case .skyblue: return "Sky Blue"
        case .red: return "Red"
        case .pink: return "Pink"
        case .orange: return "Orange"
        case .nephritis: return "Nephritis"
        case .concrete: return "Concrete"
        case .darknight: return "Dark Night"
        case .cyan: return "Cyan"
        }
    }

    /// The class default (`\colorlet{awesome}{awesome-cyan}`).
    static let templateDefault = LaTeXAwesomeColor.cyan
}

// MARK: - Margins

/// The `\geometry{…}` page margins, in centimetres (the unit the hand-authored résumé uses).
nonisolated struct LaTeXMargins: Sendable, Equatable, Codable {
    var leftCm: Double
    var topCm: Double
    var rightCm: Double
    var bottomCm: Double
    var footskipCm: Double

    init(leftCm: Double = 0.50, topCm: Double = 0.50, rightCm: Double = 0.50,
         bottomCm: Double = 0.75, footskipCm: Double = 0.25) {
        self.leftCm = leftCm
        self.topCm = topCm
        self.rightCm = rightCm
        self.bottomCm = bottomCm
        self.footskipCm = footskipCm
    }

    /// Today's margins, as both preambles hardcode them.
    static let `default` = LaTeXMargins()

    /// The `\geometry` argument, formatted exactly as the current builder writes it —
    /// `left=0.50cm, top=0.50cm, right=0.50cm, bottom=0.75cm, footskip=0.25cm`.
    var geometryOptions: String {
        "left=\(LaTeXStyle.fixed(leftCm))cm, top=\(LaTeXStyle.fixed(topCm))cm, "
            + "right=\(LaTeXStyle.fixed(rightCm))cm, bottom=\(LaTeXStyle.fixed(bottomCm))cm, "
            + "footskip=\(LaTeXStyle.fixed(footskipCm))cm"
    }
}

// MARK: - Sections

/// The résumé's section buckets — the vocabulary a style orders, hides, and spaces. Generated
/// section titles are free text, so they're matched to a bucket by the same heuristics the builder
/// has always used; anything unrecognised is ``other``, which keeps unknown sections **visible and
/// stably last** rather than dropped.
nonisolated enum LaTeXResumeSection: String, Sendable, Codable, CaseIterable, Identifiable {
    case education, experience, projects, skills, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .education: return "Education"
        case .experience: return "Experience"
        case .projects: return "Projects"
        case .skills: return "Skills & Qualifications"
        case .other: return "Other sections"
        }
    }

    /// Buckets a free-text section title. Mirrors `TexDocumentBuilder.canonicalOrder(_:)` /
    /// `.isSkillsSection(_:)` so a style classifies sections exactly as the builder always has.
    static func classify(_ title: String) -> LaTeXResumeSection {
        let lower = title.lowercased()
        if lower.contains("education") { return .education }
        if lower.contains("experience") || lower.contains("employment") || lower.contains("work history") {
            return .experience
        }
        if lower.contains("project") { return .projects }
        if lower.contains("skill") || lower.contains("qualification") || lower.contains("competenc") {
            return .skills
        }
        return .other
    }

    /// The hand-authored résumé's order: Education → Experience → Projects → Skills → everything else.
    static let canonicalOrder: [LaTeXResumeSection] = [.education, .experience, .projects, .skills, .other]

    /// The hand-authored résumé's per-section `\vspace`, in `em` (what `sectionVSpace(_:)` hardcodes).
    static let canonicalSpacingEm: [LaTeXResumeSection: Double] = [
        .education: -1,
        .experience: -1.5,
        .projects: -1.5,
        .skills: -0.5,
        .other: -1,
    ]
}
