//
//  Prompts.swift
//  Taylor'd Portfolio
//
//  Data · LLM — shared prompt text, so the two engines never drift.
//

import Foundation

/// Shared prompt text for the LLM tasks.
///
/// Both providers build their prompts from here so the on-device and Claude engines
/// stay in lockstep. Structural output is enforced per-engine (constrained decoding
/// on-device; ``jsonOnlySuffix`` for Claude), so these prompts describe the *task*
/// and desired fields, not the transport.
nonisolated enum Prompts {

    /// Character caps to respect the on-device model's limited context window.
    static let maxPortfolioCharacters = 6_000
    static let maxDescriptionCharacters = 2_000

    // MARK: Build profile

    static let profileInstructions =
        "You extract a structured professional profile from a candidate's portfolio. " +
        "Use only information present in the text. Never invent employers, titles, dates, or skills."

    static func buildProfile(portfolio: String) -> String {
        """
        From the portfolio below, produce a structured candidate profile with these fields:
        - seniority: overall level (e.g. Junior, Mid, Senior, Staff)
        - yearsExperience: total years of professional experience, as an integer
        - coreSkills: the strongest, most relevant skills
        - domains: industries or problem domains the candidate has worked in
        - targetTitles: job titles this candidate is a fit for
        - summary: a two-to-three sentence professional summary

        Portfolio:
        \(truncate(portfolio, to: maxPortfolioCharacters))
        """
    }

    // MARK: Rank

    static let rankInstructions =
        "You are a technical recruiter scoring how well jobs fit a candidate. " +
        "Judge only on the evidence given; never credit the candidate with skills they don't list."

    static func rank(jobs: [JobListing], profile: CandidateProfile) -> String {
        let jobsBlock = jobs.map { job in
            """
            - jobId: \(job.id)
              title: \(job.title)
              company: \(job.company)
              location: \(job.location)
              description: \(truncate(job.description, to: maxDescriptionCharacters))
            """
        }.joined(separator: "\n")

        return """
        Candidate profile:
        - seniority: \(profile.seniority)
        - yearsExperience: \(profile.yearsExperience)
        - coreSkills: \(profile.coreSkills.joined(separator: ", "))
        - domains: \(profile.domains.joined(separator: ", "))
        - targetTitles: \(profile.targetTitles.joined(separator: ", "))

        Produce a "matches" array — one element per job below, in the same order —
        where each element has:
        - jobId: the job's id
        - score: fit from 0 (no fit) to 100 (perfect fit)
        - reason: one or two sentences explaining the score
        - matchedSkills: candidate skills the job asks for
        - missingSkills: job requirements the candidate appears to lack

        Jobs:
        \(jobsBlock)
        """
    }

    // MARK: Generate application

    static let generateInstructions =
        "You write tailored job application materials grounded strictly in the candidate's real " +
        "portfolio. Reorder and rephrase real experience; never fabricate employers, titles, dates, or credentials."

    static func generateApplication(job: JobListing, profile: CandidateProfile) -> String {
        """
        Write application materials for this job, grounded only in the candidate profile below.

        Job:
        - title: \(job.title)
        - company: \(job.company)
        - location: \(job.location)
        - description: \(truncate(job.description, to: maxDescriptionCharacters))

        Candidate profile:
        - seniority: \(profile.seniority)
        - yearsExperience: \(profile.yearsExperience)
        - coreSkills: \(profile.coreSkills.joined(separator: ", "))
        - domains: \(profile.domains.joined(separator: ", "))
        - summary: \(profile.summary)

        Produce these fields:
        - resumeMarkdown: a tailored resume in Markdown
        - coverLetter: a tailored cover letter addressed to the role
        - gapNote: an honest, short note on gaps between the profile and the job
        """
    }

    // MARK: Shared helpers

    /// Appended by the Claude provider to force clean JSON. The on-device engine
    /// enforces structure via constrained decoding and doesn't need this.
    static let jsonOnlySuffix =
        "Respond with ONLY a single JSON object matching the requested fields — " +
        "no prose, no explanation, no code fences."

    /// Bounds a piece of user/job text to `maxCharacters`, appending an ellipsis
    /// when it had to be cut.
    static func truncate(_ text: String, to maxCharacters: Int) -> String {
        guard text.count > maxCharacters else { return text }
        return String(text.prefix(maxCharacters)) + "…"
    }
}
