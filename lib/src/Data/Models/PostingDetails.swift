//
//  PostingDetails.swift
//  Taylor'd Portfolio
//
//  Data · Models — the richer, LLM-extracted structure of a single job posting.
//

import Foundation
import FoundationModels

/// The richer structure of a single job posting that Adzuna gives no structured field for
/// (v0.6.0 Milestone A-B): work type plus the qualifications / responsibilities /
/// about-role / about-company / benefits sections buried in the free-text description.
///
/// `@Generable` + `Codable` like the other structured LLM outputs, so both engines can
/// produce it (constrained decoding on-device; JSON via Claude). Attached to a domain
/// ``JobListing`` as its `details`.
///
/// Enrichment **organizes** what the posting states — it must never invent requirements,
/// responsibilities, or company facts. When it finds nothing, every field comes back empty
/// (``hasContent`` is `false`) and callers keep the original snippet rather than overwrite
/// it with emptiness.
@Generable
nonisolated struct PostingDetails: Codable, Equatable, Sendable {
    @Guide(description: "How the role is worked — exactly one of \"on_site\", \"remote\", or \"hybrid\"; empty if the posting doesn't say.")
    var workTypeRaw: String

    @Guide(description: "Required qualifications / must-haves, one per entry; empty if none stated.")
    var qualifications: [String]

    @Guide(description: "Day-to-day responsibilities, one per entry; empty if none stated.")
    var responsibilities: [String]

    @Guide(description: "Preferred / nice-to-have qualifications, one per entry; empty if none stated.")
    var niceToHaves: [String]

    @Guide(description: "A clean summary of the 'about the role' section; empty if none stated.")
    var aboutRole: String

    @Guide(description: "A clean summary of the 'about the company' section; empty if none stated.")
    var aboutCompany: String

    @Guide(description: "Listed benefits or perks, one per entry; empty if none stated.")
    var benefits: [String]

    init(
        workTypeRaw: String = "",
        qualifications: [String] = [],
        responsibilities: [String] = [],
        niceToHaves: [String] = [],
        aboutRole: String = "",
        aboutCompany: String = "",
        benefits: [String] = []
    ) {
        self.workTypeRaw = workTypeRaw
        self.qualifications = qualifications
        self.responsibilities = responsibilities
        self.niceToHaves = niceToHaves
        self.aboutRole = aboutRole
        self.aboutCompany = aboutCompany
        self.benefits = benefits
    }

    /// The parsed work type, or nil when the posting didn't state a recognizable one.
    var workType: WorkType? { WorkType(loose: workTypeRaw) }

    /// Whether enrichment found anything worth attaching. Guards callers against replacing a
    /// real description snippet with an empty extraction.
    var hasContent: Bool {
        workType != nil
            || !aboutRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !aboutCompany.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !qualifications.isEmpty
            || !responsibilities.isEmpty
            || !niceToHaves.isEmpty
            || !benefits.isEmpty
    }

    /// A **standardized** rendering of the posting into one fixed markdown template (v0.6.0
    /// Milestone K), so every result reads the same regardless of source: About the role →
    /// Responsibilities → Qualifications → Nice to have → About the company → Benefits → Work
    /// type. Empty sections are omitted; empty overall (`!hasContent`) returns `""` so callers
    /// fall back to the raw description. Pure and deterministic.
    var standardDescription: String {
        var sections: [String] = []
        func paragraph(_ heading: String, _ body: String) {
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { sections.append("## \(heading)\n\(trimmed)") }
        }
        func bulleted(_ heading: String, _ items: [String]) {
            let cleaned = items
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !cleaned.isEmpty { sections.append("## \(heading)\n" + cleaned.map { "- \($0)" }.joined(separator: "\n")) }
        }
        paragraph("About the role", aboutRole)
        bulleted("Responsibilities", responsibilities)
        bulleted("Qualifications", qualifications)
        bulleted("Nice to have", niceToHaves)
        paragraph("About the company", aboutCompany)
        bulleted("Benefits", benefits)
        if let workType { sections.append("## Work type\n\(workType.label)") }
        return sections.joined(separator: "\n\n")
    }
}
