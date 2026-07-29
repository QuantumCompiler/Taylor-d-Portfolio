//
//  KeywordCoverage.swift
//  Taylor'd Portfolio
//
//  Data · Models — how much of a posting's keyword set the generated résumé actually covers
//  (v0.6.1 Milestone A).
//

import Foundation

/// How well a generated résumé covers the keywords a posting emphasises — computed on the
/// **visible** text only.
///
/// ATS / AI résumé screeners filter on a posting's keywords, so the app surfaces which of them
/// the generated résumé genuinely contains and which it misses, letting the user align
/// truthfully. This is the deliberate opposite of hidden "invisible-ink" keyword stuffing:
/// coverage is measured against the résumé a human reads, after Markdown is reduced to plain
/// text, so anything counted here is text the recruiter sees too.
///
/// Pure and `Sendable` — no store, no view, no model call — so the matching rules are
/// unit-tested directly. Derived on demand, never persisted.
///
/// Distinct from `JobMatch.matchedSkills` / `missingSkills`, which score the **candidate
/// profile** during ranking; coverage is specifically *posting keyword vs. the actual generated
/// résumé text*.
nonisolated struct KeywordCoverage: Equatable, Sendable {

    /// Which part of the posting a keyword came from — the three ``TargetBrief`` keyword
    /// fields, in the order the UI shows them (most important first).
    enum Tier: String, CaseIterable, Hashable, Sendable {
        /// `TargetBrief.mustHaveKeywords` — what the posting insists on.
        case mustHave
        /// `TargetBrief.niceToHaveKeywords` — valued but not essential.
        case niceToHave
        /// `TargetBrief.techStack` — the technologies, languages, and frameworks named.
        case techStack

        var label: String {
            switch self {
            case .mustHave: return "Must-have"
            case .niceToHave: return "Nice to have"
            case .techStack: return "Tech stack"
            }
        }
    }

    /// One tier's covered-vs-missing split. Keywords are reported **as the posting wrote
    /// them** (whitespace-trimmed only), so the UI shows "C++", not a normalized form.
    struct TierCoverage: Equatable, Identifiable, Sendable {
        let tier: Tier
        /// Keywords found in the visible résumé, in the order the brief listed them.
        let covered: [String]
        /// Keywords absent from the visible résumé, in the order the brief listed them.
        let missing: [String]

        var id: Tier { tier }
        var total: Int { covered.count + missing.count }
    }

    /// Each tier that contributed at least one usable keyword, in ``Tier/allCases`` order.
    /// A tier whose keywords were all empty or already claimed by a higher tier is omitted
    /// entirely rather than rendered as an empty group.
    let tiers: [TierCoverage]

    /// Splits each tier's keywords into covered vs. missing against `resumeText` (already
    /// plain text — see ``init(brief:resumeMarkdown:)`` for the Markdown entry point).
    ///
    /// A keyword listed in more than one tier is counted **once, in its highest tier**
    /// (must-have > nice-to-have > tech stack), so the headline can't double-count a term the
    /// posting merely repeats. Empty and whitespace-only keywords are dropped, never counted
    /// as missing.
    init(mustHave: [String], niceToHave: [String], techStack: [String], resumeText: String) {
        let haystack = Self.normalized(resumeText)
        var claimed: Set<String> = []
        var tiers: [TierCoverage] = []

        for (tier, keywords) in [(Tier.mustHave, mustHave), (.niceToHave, niceToHave), (.techStack, techStack)] {
            var covered: [String] = []
            var missing: [String] = []
            for keyword in keywords {
                let needle = Self.normalized(keyword)
                // Skip blanks, and any keyword a higher tier already accounted for.
                guard !needle.isEmpty, claimed.insert(needle).inserted else { continue }
                let display = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if Self.contains(needle, in: haystack) {
                    covered.append(display)
                } else {
                    missing.append(display)
                }
            }
            if !covered.isEmpty || !missing.isEmpty {
                tiers.append(TierCoverage(tier: tier, covered: covered, missing: missing))
            }
        }
        self.tiers = tiers
    }

    /// Coverage of a generated résumé against the posting distilled by generation stage 1.
    ///
    /// Reduces the résumé Markdown to plain text first (``MarkdownPlainText``), so a keyword
    /// wrapped in emphasis or sitting behind a bullet marker still counts — it is visible text
    /// either way.
    init(brief: TargetBrief, resumeMarkdown: String) {
        self.init(
            mustHave: brief.mustHaveKeywords,
            niceToHave: brief.niceToHaveKeywords,
            techStack: brief.techStack,
            resumeText: MarkdownPlainText.plainText(from: resumeMarkdown)
        )
    }

    // MARK: Roll-ups

    /// The must-have tier, if the posting named any.
    var mustHave: TierCoverage? { tiers.first { $0.tier == .mustHave } }

    /// Covered **must-have** keywords — the numerator of the headline "X/Y covered". The
    /// headline weights must-haves because those are what a screener filters on; the other
    /// tiers are still reported in ``tiers`` for the breakdown.
    var coveredCount: Int { mustHave?.covered.count ?? 0 }

    /// Must-have keywords in total — the denominator of the headline "X/Y covered".
    var totalCount: Int { mustHave?.total ?? 0 }

    /// Covered keywords across every tier.
    var allCoveredCount: Int { tiers.reduce(0) { $0 + $1.covered.count } }

    /// Keywords across every tier.
    var allTotalCount: Int { tiers.reduce(0) { $0 + $1.total } }

    /// True when the posting yielded no usable keywords at all — the panel hides rather than
    /// reporting a meaningless "0/0 covered".
    var isEmpty: Bool { tiers.isEmpty }

    // MARK: Matching

    /// Punctuation trimmed from a keyword's ends before matching: sentence and quoting marks
    /// only. Deliberately **excludes** `+`, `#`, and `/`, and only ever trims at the ends, so
    /// "C++", "C#", and "Node.js" survive intact.
    nonisolated static let trimmablePunctuation = CharacterSet(charactersIn: ".,;:!?\"'“”‘’()[]{}")

    /// Case- and diacritic-insensitive form with runs of whitespace (including newlines)
    /// collapsed to single spaces and end punctuation trimmed.
    ///
    /// Both sides of a comparison go through this, which is what lets a multi-word keyword
    /// match across a line break in the résumé. Intentionally light: **no stemming and no
    /// synonyms**, so "manage" does not match "management" — that's a later refinement, and
    /// over-matching would report coverage the user doesn't actually have.
    nonisolated static func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: trimmablePunctuation)
    }

    /// Whether `needle` occurs in `haystack` on **word boundaries**. Both must already be
    /// ``normalized(_:)``.
    ///
    /// A boundary here means the character immediately either side of a hit is not
    /// alphanumeric — which is precisely what a regex `\b` *cannot* express for keywords that
    /// end in punctuation: `\bC\+\+\b` never matches "C++", because "+" is followed by no word
    /// character. Scanning the boundaries directly keeps "Go" from matching "Google" while
    /// still matching "C++", ".NET", and "Node.js".
    nonisolated static func contains(_ needle: String, in haystack: String) -> Bool {
        guard !needle.isEmpty else { return false }
        var searchStart = haystack.startIndex
        while let hit = haystack.range(of: needle, range: searchStart..<haystack.endIndex) {
            let openBoundary = hit.lowerBound == haystack.startIndex
                || !isWordCharacter(haystack[haystack.index(before: hit.lowerBound)])
            let closeBoundary = hit.upperBound == haystack.endIndex
                || !isWordCharacter(haystack[hit.upperBound])
            if openBoundary && closeBoundary { return true }
            // Step past this hit's first character — an interior occurrence may still be on a
            // boundary (e.g. "go" in "logo go").
            searchStart = haystack.index(after: hit.lowerBound)
            if searchStart >= haystack.endIndex { break }
        }
        return false
    }

    nonisolated private static func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }
}
