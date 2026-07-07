//
//  JobMatch.swift
//  Taylor'd Portfolio
//
//  Data · Models — the LLM's fit assessment for one job.
//

import Foundation
import FoundationModels

/// The language model's assessment of how well one job fits the candidate.
///
/// `@Generable` so the model can emit it via constrained decoding; `Codable` for
/// persistence and transport.
@Generable
nonisolated struct JobMatch: Codable, Equatable, Sendable {
    @Guide(description: "The id of the JobListing this match refers to.")
    var jobId: String

    @Guide(description: "Fit score from 0 (no fit) to 100 (perfect fit).")
    var score: Int

    @Guide(description: "One or two sentences explaining the score.")
    var reason: String

    @Guide(description: "Skills the candidate has that the job asks for.")
    var matchedSkills: [String]

    @Guide(description: "Skills the job asks for that the candidate appears to lack.")
    var missingSkills: [String]

    init(
        jobId: String,
        score: Int,
        reason: String,
        matchedSkills: [String],
        missingSkills: [String]
    ) {
        self.jobId = jobId
        self.score = score
        self.reason = reason
        self.matchedSkills = matchedSkills
        self.missingSkills = missingSkills
    }
}
