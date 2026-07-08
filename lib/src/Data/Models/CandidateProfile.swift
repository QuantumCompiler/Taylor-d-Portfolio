//
//  CandidateProfile.swift
//  Taylor'd Portfolio
//
//  Data · Models — the user's portfolio distilled into a structured profile.
//

import Foundation
import FoundationModels

/// The user's portfolio distilled into a structured profile.
///
/// Produced once by the LLM (hence `@Generable`) and cached; also `Codable` so it
/// can be persisted between launches.
@Generable
nonisolated struct CandidateProfile: Codable, Equatable, Sendable {
    @Guide(description: "Overall seniority, e.g. \"Junior\", \"Mid\", \"Senior\", \"Staff\".")
    var seniority: String

    @Guide(description: "Total years of professional experience.")
    var yearsExperience: Int

    @Guide(description: "The candidate's strongest, most relevant skills.")
    var coreSkills: [String]

    @Guide(description: "Industries or problem domains the candidate has worked in.")
    var domains: [String]

    @Guide(description: "Job titles the candidate is targeting.")
    var targetTitles: [String]

    @Guide(description: "A concise two-to-three sentence professional summary.")
    var summary: String

    init(
        seniority: String,
        yearsExperience: Int,
        coreSkills: [String],
        domains: [String],
        targetTitles: [String],
        summary: String
    ) {
        self.seniority = seniority
        self.yearsExperience = yearsExperience
        self.coreSkills = coreSkills
        self.domains = domains
        self.targetTitles = targetTitles
        self.summary = summary
    }
}
