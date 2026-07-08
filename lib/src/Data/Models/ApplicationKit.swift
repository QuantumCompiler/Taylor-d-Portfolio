//
//  ApplicationKit.swift
//  Taylor'd Portfolio
//
//  Data · Models — generated application materials for one job.
//

import Foundation
import FoundationModels

/// The generated application materials for a single job.
///
/// `@Generable` + `Codable`. Content must stay grounded strictly in the user's real
/// portfolio — never fabricated (see SPEC "Grounded generation").
@Generable
nonisolated struct ApplicationKit: Codable, Equatable, Sendable {
    @Guide(description: "The tailored resume in Markdown, grounded only in the real portfolio.")
    var resumeMarkdown: String

    @Guide(description: "The tailored cover letter, addressed to the specific role.")
    var coverLetter: String

    @Guide(description: "A short, honest note on gaps between the portfolio and the job.")
    var gapNote: String

    init(resumeMarkdown: String, coverLetter: String, gapNote: String) {
        self.resumeMarkdown = resumeMarkdown
        self.coverLetter = coverLetter
        self.gapNote = gapNote
    }
}
