//
//  TargetBrief.swift
//  Taylor'd Portfolio
//
//  Data · Models — a job posting distilled into what the role wants.
//

import Foundation
import FoundationModels

/// A single job posting distilled into a structured "target brief": what the role
/// wants, extracted before any tailoring happens.
///
/// This is the first stage of the two-stage generation flow (see `Prompts`): the LLM
/// produces a `TargetBrief` from the posting, then a second call tailors the
/// application against it. Modelled on the internal brief in Taylor's résumé agent
/// (AGENT.md §5, Step 1). `@Generable` + `Codable` like the other structured types.
@Generable
nonisolated struct TargetBrief: Codable, Equatable, Sendable {
    @Guide(description: "The hiring company's name, exactly as written in the posting.")
    var company: String

    @Guide(description: "The exact role title from the posting.")
    var roleTitle: String

    @Guide(description: "The 5–8 most important must-have requirements or keywords the posting emphasises.")
    var mustHaveKeywords: [String]

    @Guide(description: "Preferred or nice-to-have requirements — valued but not essential.")
    var niceToHaveKeywords: [String]

    @Guide(description: "The technologies, languages, and frameworks the role uses.")
    var techStack: [String]

    @Guide(description: "The industry or problem domain, e.g. fintech, mobile, API management.")
    var domain: String

    @Guide(description: "The company's stated mission or values, if the posting expresses any; otherwise empty.")
    var missionValues: String

    init(
        company: String,
        roleTitle: String,
        mustHaveKeywords: [String],
        niceToHaveKeywords: [String],
        techStack: [String],
        domain: String,
        missionValues: String
    ) {
        self.company = company
        self.roleTitle = roleTitle
        self.mustHaveKeywords = mustHaveKeywords
        self.niceToHaveKeywords = niceToHaveKeywords
        self.techStack = techStack
        self.domain = domain
        self.missionValues = missionValues
    }
}
