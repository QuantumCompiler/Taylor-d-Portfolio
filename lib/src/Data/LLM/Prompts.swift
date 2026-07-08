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
    /// Cap on the (stripped) web-page text fed to posting extraction.
    static let maxPageCharacters = 12_000

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

    // MARK: Extract posting (from a URL / pasted text)

    static let extractInstructions =
        "You extract the key facts of a SINGLE job posting from the raw text of a web page, ignoring " +
        "navigation, ads, cookie notices, and other boilerplate. Use only what the text states — never " +
        "invent a role. If the text isn't a real job posting, return empty strings."

    /// Distils the (stripped) text of a job-posting page into an ``ExtractedPosting``.
    static func extractPosting(pageText: String) -> String {
        """
        From the web-page text below, extract this one job posting:
        - title: the exact job title
        - company: the hiring company's name
        - location: the location (or "Remote")
        - description: a clean, readable summary — responsibilities, requirements, and tech stack

        If the text does not contain a real job posting (e.g. it's a login wall, an error page,
        or a list of many jobs), return empty strings for every field.

        Page text:
        \(truncate(pageText, to: maxPageCharacters))
        """
    }

    // MARK: Target brief (stage 1 of generation)

    static let briefInstructions =
        "You distil a job posting into a structured target brief that a writer will use to tailor an " +
        "application. Extract only what the posting states; do not infer requirements it doesn't mention."

    /// Stage 1: distil a posting into a ``TargetBrief`` (AGENT.md §5, Step 1).
    static func buildTargetBrief(job: JobListing) -> String {
        """
        Read the job posting below and distil a structured target brief with these fields:
        - company: the hiring company's name
        - roleTitle: the exact role title
        - mustHaveKeywords: the 5–8 most important must-have requirements or keywords
        - niceToHaveKeywords: preferred / nice-to-have requirements
        - techStack: technologies, languages, and frameworks the role uses
        - domain: the industry or problem domain (e.g. fintech, mobile, API management)
        - missionValues: the company's stated mission or values (empty if none is stated)

        Job posting:
        - title: \(job.title)
        - company: \(job.company)
        - location: \(job.location)
        - description: \(truncate(job.description, to: maxDescriptionCharacters))
        """
    }

    // MARK: Generate application (stage 2 of generation)

    static let generateInstructions =
        "You are an expert application writer. You tailor a candidate's REAL experience to a specific role " +
        "by re-ordering, re-weighting, and re-phrasing true facts only — never by inventing employers, titles, " +
        "dates, metrics, degrees, or skills. If the role wants something the candidate lacks, you omit it and " +
        "note the gap; you never fake it."

    /// Stage 2: tailor the application against the profile and the stage-1 ``TargetBrief``.
    /// Ports the résumé-agent discipline (AGENT.md §5): map each brief signal to a true
    /// profile fact, foreground the best-fit overlap, flag gaps, and structure the cover
    /// letter as *About Me / Why <company> / Why Me*.
    static func generateApplication(job: JobListing, profile: CandidateProfile, brief: TargetBrief) -> String {
        """
        Tailor application materials for this role, grounded ONLY in the candidate profile below.

        Target brief (what the role wants):
        - company: \(brief.company)
        - roleTitle: \(brief.roleTitle)
        - mustHaveKeywords: \(brief.mustHaveKeywords.joined(separator: ", "))
        - niceToHaveKeywords: \(brief.niceToHaveKeywords.joined(separator: ", "))
        - techStack: \(brief.techStack.joined(separator: ", "))
        - domain: \(brief.domain)
        - missionValues: \(brief.missionValues)

        Candidate profile (the only true facts you may use):
        - seniority: \(profile.seniority)
        - yearsExperience: \(profile.yearsExperience)
        - coreSkills: \(profile.coreSkills.joined(separator: ", "))
        - domains: \(profile.domains.joined(separator: ", "))
        - targetTitles: \(profile.targetTitles.joined(separator: ", "))
        - summary: \(profile.summary)

        Method:
        1. Map each brief signal to the closest TRUE fact in the profile. Where the profile has
           no matching fact, treat it as a GAP — never fabricate one.
        2. Foreground the overlap: lead with the single best-fit strength (the skill, domain, or
           experience that most closely matches the must-have keywords), and surface the exact
           keywords from the brief that are genuinely true for this candidate.

        Produce these fields:
        - resumeMarkdown: a tailored resume in Markdown. Open with a role-specific headline for
          "\(brief.roleTitle)" and a 1–2 sentence summary positioning the candidate for THIS role,
          then sections that re-angle the real experience to foreground the best-fit overlap first.
        - coverLetter: a cover letter in exactly three sections, each with a Markdown heading:
            "## About Me" — who the candidate is, framed toward this role.
            "## Why \(brief.company)" — connect the candidate's real strengths to this company's
              product, domain, and stated mission/values. This is the company-specific section.
            "## Why Me" — the concrete value proposition and a memorable closing.
          Confident, specific, and technically literal; no clichés and no invented metrics.
        - gapNote: an honest, short note listing the notable must-have requirements the candidate
          does NOT clearly meet (the gaps from step 1). Never disguise a gap as a strength.
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
