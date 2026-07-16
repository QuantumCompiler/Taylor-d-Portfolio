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
    /// Cap on the cover-letter voice exemplar injected into generation grounding.
    static let maxCoverLetterCharacters = 3_000
    /// Cap on the concatenated supporting-document text injected into generation grounding
    /// (Milestone I) — larger than the résumé, since a full portfolio is the point, but still
    /// bounded for the on-device context window.
    static let maxSupportingCharacters = 8_000
    /// Cap on the user's free-text steering guidance injected into generation (Milestone I).
    static let maxAdditionalContextCharacters = 1_000

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

    // MARK: Tidy document (make imported text readable)

    static let tidyInstructions =
        "You reformat a document's raw, machine-extracted text into clean, readable plain text. " +
        "You preserve every fact, name, employer, title, date, number, and bullet EXACTLY — never add, " +
        "remove, invent, reorder, or summarize content. You only repair layout."

    /// Reflows the raw extracted text of an imported document (often a PDF, whose text
    /// comes out with broken lines and artifacts) into readable plain text — same
    /// content, better structure. Used to pair a readable source with a saved profile.
    static func tidyDocument(rawText: String) -> String {
        """
        Reformat the raw document text below into clean, readable plain text.

        Rules:
        - Keep ALL original content — every role, employer, date, skill, number, and bullet. Never summarize or drop anything.
        - Repair words split across line breaks (e.g. "engi-\nneer" → "engineer") and join lines that belong to the same sentence or bullet.
        - Remove extraction artifacts: repeated page headers/footers, page numbers, and stray symbols.
        - Restore structure: a blank line between sections, one bullet per line, and clear headings.
        - Output ONLY the cleaned text — no commentary, no preamble, no code fences.

        Raw document text:
        \(truncate(rawText, to: maxPortfolioCharacters))
        """
    }

    // MARK: Refine profile summary

    static let refineSummaryInstructions =
        "You rewrite a candidate's professional summary. You use only true facts from the profile " +
        "and portfolio provided — never invent employers, titles, dates, metrics, or skills. You " +
        "output only the rewritten summary text, with no preamble, labels, or quotes."

    /// Rewrites the profile's `summary` following the user's `instruction`, staying grounded
    /// in the real profile facts (and portfolio text when available). Returns only the new
    /// summary text. An empty `instruction` just asks for a fresh, well-written summary.
    static func refineSummary(profile: CandidateProfile, portfolio: String, instruction: String) -> String {
        let guidance = instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Write a fresh, compelling two-to-three sentence summary."
            : instruction
        let portfolioSection = portfolio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ""
            : """


            Portfolio (the candidate's real experience — use only facts present here or in the profile):
            \(truncate(portfolio, to: maxPortfolioCharacters))
            """
        return """
        Rewrite the candidate's professional summary following this instruction:
        "\(guidance)"

        Current profile:
        - seniority: \(profile.seniority)
        - yearsExperience: \(profile.yearsExperience)
        - coreSkills: \(profile.coreSkills.joined(separator: ", "))
        - domains: \(profile.domains.joined(separator: ", "))
        - targetTitles: \(profile.targetTitles.joined(separator: ", "))
        - current summary: \(profile.summary)
        \(portfolioSection)

        Rules:
        - Ground every claim in the facts above — never invent employers, titles, dates, metrics, or skills.
        - Keep it to a concise two-to-three sentences unless the instruction asks otherwise.
        - Output ONLY the rewritten summary text — no labels, no quotes, no commentary.
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
              description: \(truncate(job.effectiveDescription, to: maxDescriptionCharacters))
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

    /// Re-ranks a SINGLE job (v0.6.0 Milestone C), asking for one `JobMatch`. Carries the
    /// enriched posting detail (A-E) so a re-rank sees the richer signal, and appends the
    /// user's optional steering `instruction` as guidance (emphasis/interpretation, never
    /// fabrication). Empty instruction ⇒ no guidance block.
    static func rankOne(job: JobListing, profile: CandidateProfile, instruction: String) -> String {
        """
        Score how well this ONE job fits the candidate, and return a single JobMatch.

        Candidate profile:
        - seniority: \(profile.seniority)
        - yearsExperience: \(profile.yearsExperience)
        - coreSkills: \(profile.coreSkills.joined(separator: ", "))
        - domains: \(profile.domains.joined(separator: ", "))
        - targetTitles: \(profile.targetTitles.joined(separator: ", "))

        Job:
        - jobId: \(job.id)
          title: \(job.title)
          company: \(job.company)
          location: \(job.location)
          description: \(truncate(job.effectiveDescription, to: maxDescriptionCharacters))\(postingDetailSection(job.details))

        Produce a JobMatch:
        - jobId: the job's id (\(job.id))
        - score: fit from 0 (no fit) to 100 (perfect fit)
        - reason: one or two sentences explaining the score
        - matchedSkills: candidate skills the job asks for
        - missingSkills: job requirements the candidate appears to lack
        \(rankGuidanceSection(instruction))
        """
    }

    /// The user's free-text steering guidance for a re-rank, appended when non-empty. Empty ⇒
    /// "" so the re-rank prompt is the plain single-job assessment. Steers how to *read* the
    /// fit (which experience to weight), never permission to credit skills the candidate lacks.
    static func rankGuidanceSection(_ instruction: String) -> String {
        let trimmed = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return """


        ADDITIONAL USER GUIDANCE (steer how you weigh the fit, NOT the facts):
        The candidate asked you to keep the following in mind when assessing this role. Use it to
        decide which TRUE experience to weight — it does NOT permit crediting skills they don't have.
        "\(truncate(trimmed, to: maxAdditionalContextCharacters))"
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

    // MARK: Clean posting text (de-chrome a fetched page — v0.6.0 Milestone E)

    static let cleanPostingInstructions =
        "You extract the full text of a SINGLE job posting from the raw text of a web page. " +
        "You remove everything that isn't the posting — site navigation, search boxes, " +
        "\"apply\"/\"back\" buttons, \"similar jobs\", salary-comparison widgets, related-search and " +
        "popular-jobs lists, cookie notices, and the site footer / country lists. You keep the " +
        "posting's own content verbatim and in its original order — never summarize, rephrase, " +
        "reorder, add, or invent. You output only the posting, as clean markdown."

    /// Extracts just the job posting from a fetched page's noisy readable text (Milestone E),
    /// preserving the full posting verbatim and dropping site chrome. Returns clean markdown, or
    /// an empty string when the page has no real posting (so the caller keeps the snippet).
    static func cleanPosting(pageText: String) -> String {
        """
        The text below is the readable text of a web page that contains ONE job posting mixed
        with site chrome. Return ONLY the job posting itself.

        Rules:
        - Keep the ENTIRE posting verbatim — position overview, responsibilities, "what you'll
          do", qualifications / requirements, pay range, benefits, and equal-opportunity notice.
          Never summarize, shorten, rephrase, reorder, or invent any of it.
        - Remove everything that is NOT the posting: site header / navigation, the "What? Where?
          Search" bar, Apply / Easy-Apply / back buttons, salary-comparison and "stats" widgets,
          "Similar jobs", "Popular searches / jobs / companies / locations", "Receive similar jobs
          by email", cookie/consent text, and the footer + country-selection lists.
        - Format the result as clean, readable markdown: a heading for the role, section headings,
          and one bullet per listed item. Keep the company, location, employment type, and pay
          when the posting states them.
        - Output ONLY the posting markdown — no commentary, no preamble, no code fences. If the
          page contains no real job posting, output nothing.

        Page text:
        \(truncate(pageText, to: maxPageCharacters))
        """
    }

    // MARK: Enrich posting (structured detail — v0.6.0 Milestone A-B)

    static let enrichInstructions =
        "You organize the details of a SINGLE job posting from its text, ignoring navigation, ads, and " +
        "boilerplate. You extract only what the posting actually states — never invent requirements, " +
        "responsibilities, benefits, or company facts. If a section isn't present, you leave it empty."

    /// Extracts the richer structured detail of a posting into a ``PostingDetails``. Organizes
    /// what the posting says; never embellishes (the same discipline as ``extractPosting``).
    static func enrichPosting(postingText: String) -> String {
        """
        From the job-posting text below, extract this structured detail:
        - workTypeRaw: how the role is worked — exactly one of "on_site", "remote", or "hybrid"; empty if the posting doesn't say
        - qualifications: required qualifications / must-haves, one per entry
        - responsibilities: the day-to-day responsibilities, one per entry
        - niceToHaves: preferred / nice-to-have qualifications, one per entry
        - aboutRole: a clean, readable summary of what the role is
        - aboutCompany: a clean, readable summary of the hiring company
        - benefits: listed benefits or perks, one per entry

        Extract ONLY what the posting states. If a field isn't present, leave it empty (an empty
        string, or an empty list) — never guess, infer, or invent.

        Job-posting text:
        \(truncate(postingText, to: maxPageCharacters))
        """
    }

    // MARK: Target brief (stage 1 of generation)

    static let briefInstructions =
        "You distil a job posting into a structured target brief that a writer will use to tailor an " +
        "application. Extract only what the posting states; do not infer requirements it doesn't mention."

    /// Stage 1: distil a posting into a ``TargetBrief`` (AGENT.md §5, Step 1). When the posting
    /// has been enriched (v0.6.0 Milestone A), the structured detail is appended as additional
    /// true signal so the brief captures more must-haves, a real domain, and stated
    /// mission/values than the (often truncated) description snippet alone carries. Enriching
    /// stage 1 keeps the two-stage discipline: stage 2 tailors against the richer brief.
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
        - description: \(truncate(job.effectiveDescription, to: maxDescriptionCharacters))\(postingDetailSection(job.details))
        """
    }

    /// The enriched ``PostingDetails`` rendered as extra brief-building signal (v0.6.0 Milestone
    /// A-E). Only non-empty fields appear, and absent/empty details return "" so an un-enriched
    /// posting produces the exact pre-A-E prompt (byte-for-byte). This is signal about the
    /// **role**, not the candidate — it never loosens the never-fabricate rule on the résumé.
    static func postingDetailSection(_ details: PostingDetails?) -> String {
        guard let details, details.hasContent else { return "" }
        var lines: [String] = []
        if let work = details.workType { lines.append("- workType: \(work.label)") }
        if !details.qualifications.isEmpty {
            lines.append("- qualifications: \(details.qualifications.joined(separator: "; "))")
        }
        if !details.responsibilities.isEmpty {
            lines.append("- responsibilities: \(details.responsibilities.joined(separator: "; "))")
        }
        if !details.niceToHaves.isEmpty {
            lines.append("- niceToHaves: \(details.niceToHaves.joined(separator: "; "))")
        }
        let aboutRole = details.aboutRole.trimmingCharacters(in: .whitespacesAndNewlines)
        if !aboutRole.isEmpty { lines.append("- aboutRole: \(truncate(aboutRole, to: maxDescriptionCharacters))") }
        let aboutCompany = details.aboutCompany.trimmingCharacters(in: .whitespacesAndNewlines)
        if !aboutCompany.isEmpty { lines.append("- aboutCompany: \(truncate(aboutCompany, to: maxDescriptionCharacters))") }
        if !details.benefits.isEmpty {
            lines.append("- benefits: \(details.benefits.joined(separator: "; "))")
        }
        guard !lines.isEmpty else { return "" }
        return "\n\nStructured posting detail (already extracted from this posting — use it as additional "
            + "true signal about the role, company, and requirements):\n" + lines.joined(separator: "\n")
    }

    // MARK: Generate application (stage 2 of generation)

    /// The stage-2 system instruction, **conditioned on the fidelity band** (v0.6.0): authentic
    /// forbids fabrication, curated permits reasonable inference, embellished permits *disclosed*
    /// invention. Higher bands no longer contradict the base prompt's framing or the GENERATION
    /// CONTROLS block — they agree. `.authentic` (the default) is the original grounded instruction.
    static func generateInstructions(_ settings: GenerationSettings = .default) -> String {
        switch settings.band {
        case .authentic:
            return "You are an expert application writer. You tailor a candidate's REAL experience to a specific role " +
                "by re-ordering, re-weighting, and re-phrasing true facts only — never by inventing employers, titles, " +
                "dates, metrics, degrees, or skills. If the role wants something the candidate lacks, you omit it and " +
                "note the gap; you never fake it."
        case .curated:
            return "You are an expert application writer. You tailor a candidate's experience to a specific role — " +
                "emphasizing and reframing real experience and inferring reasonable adjacent skills the candidate " +
                "plausibly has. You avoid inventing hard credentials (employers, titles, dates, degrees) outright, " +
                "and you surface any stretch in the gap note."
        case .embellished:
            return "You are an expert application writer producing a DRAFT the candidate will review before sending. " +
                "You tailor aggressively to maximise fit, and you MAY add plausible detail beyond the candidate's " +
                "stated experience when it strengthens the match. Every addition not supported by the profile must be " +
                "disclosed in the gap note (prefixed \"EMBELLISHED: \") so the candidate can verify it before sending."
        }
    }

    /// Stage 2: tailor the application against the profile and the stage-1 ``TargetBrief``.
    /// Ports the résumé-agent discipline (AGENT.md §5): map each brief signal to a true
    /// profile fact, foreground the best-fit overlap, flag gaps, and structure the cover
    /// letter as *About Me / Why <company> / Why Me*.
    // MARK: Score a generated application (Milestone D-F)

    static let scoreInstructions =
        "You are a technical recruiter scoring how well a tailored résumé matches a role. " +
        "Judge only on the résumé's text against the role's stated requirements."

    /// Scores a generated résumé against the target role, returning a `JobMatch` — the
    /// outcome the rank-target loop chases (Milestone D-F).
    static func scoreApplication(job: JobListing, brief: TargetBrief, kit: ApplicationKit) -> String {
        """
        Score how strongly this tailored résumé matches the target role. Return a single JobMatch.

        Target role:
        - roleTitle: \(brief.roleTitle)
        - company: \(brief.company)
        - mustHaveKeywords: \(brief.mustHaveKeywords.joined(separator: ", "))
        - niceToHaveKeywords: \(brief.niceToHaveKeywords.joined(separator: ", "))
        - techStack: \(brief.techStack.joined(separator: ", "))

        Tailored résumé:
        \(truncate(kit.resumeMarkdown, to: maxDescriptionCharacters))

        Produce a JobMatch:
        - jobId: \(job.id)
        - score: 0 (no fit) to 100 (perfect fit) — how well the résumé matches the must-have and
          nice-to-have keywords and the role's requirements.
        - reason: one or two sentences explaining the score.
        - matchedSkills: role keywords the résumé clearly demonstrates.
        - missingSkills: role keywords the résumé still does not demonstrate.
        """
    }

    static func generateApplication(
        job: JobListing,
        profile: CandidateProfile,
        brief: TargetBrief,
        grounding: PortfolioGrounding? = nil,
        settings: GenerationSettings = .default
    ) -> String {
        let sources = grounding?.resumeText.isEmpty == false ? "candidate profile and résumé" : "candidate profile"

        // The base prompt's framing tracks the fidelity band, so higher latitude no longer fights
        // the GENERATION CONTROLS block appended below — they agree instead of contradicting. At
        // `.authentic` (the default) this reproduces the original grounded wording.
        let opening: String, factsParenthetical: String, methodStep1: String
        let metricsClause: String, gapNoteClause: String
        switch settings.band {
        case .authentic:
            opening = "Tailor application materials for this role, grounded ONLY in the \(sources) below."
            factsParenthetical = "the only true facts you may use"
            methodStep1 = "Map each brief signal to the closest TRUE fact in the profile. Where the profile has no "
                + "matching fact, treat it as a GAP — never fabricate one."
            metricsClause = "no clichés and no invented metrics."
            gapNoteClause = "an honest, short note listing the notable must-have requirements the candidate does NOT "
                + "clearly meet (the gaps from step 1). Never disguise a gap as a strength."
        case .curated:
            opening = "Tailor application materials for this role, grounded primarily in the \(sources) below — you "
                + "may infer reasonable adjacent strengths the candidate plausibly has where it sharpens the fit."
            factsParenthetical = "the candidate's true facts — your primary source"
            methodStep1 = "Map each brief signal to the closest fact in the profile. Where the profile has no matching "
                + "fact, you MAY infer a reasonable adjacent strength the candidate plausibly has; otherwise note it as a gap."
            metricsClause = "no clichés; avoid inventing hard metrics or credentials."
            gapNoteClause = "a short note listing the notable must-have requirements the candidate does NOT clearly meet, "
                + "plus any adjacent strengths you inferred rather than read directly from the profile."
        case .embellished:
            opening = "Tailor application materials for this role, informed by the \(sources) below — you MAY build "
                + "beyond it with plausible, role-strengthening detail to maximise the fit. This is a DRAFT the candidate will verify."
            factsParenthetical = "the candidate's true facts — your starting point, which you may extend"
            methodStep1 = "Map each brief signal to a supporting claim. Where the profile has no matching fact, you MAY "
                + "add a plausible one that strengthens the fit — and record every such addition in gapNote."
            metricsClause = "no clichés; any invented metric must be plausible and disclosed."
            gapNoteClause = "a short note listing (a) the must-have requirements the candidate does NOT clearly meet, and "
                + "(b) every statement you added beyond the profile, so the candidate can verify each one."
        }

        let base = """
        \(opening)

        Target brief (what the role wants):
        - company: \(brief.company)
        - roleTitle: \(brief.roleTitle)
        - mustHaveKeywords: \(brief.mustHaveKeywords.joined(separator: ", "))
        - niceToHaveKeywords: \(brief.niceToHaveKeywords.joined(separator: ", "))
        - techStack: \(brief.techStack.joined(separator: ", "))
        - domain: \(brief.domain)
        - missionValues: \(brief.missionValues)

        Candidate profile (\(factsParenthetical)):
        - seniority: \(profile.seniority)
        - yearsExperience: \(profile.yearsExperience)
        - coreSkills: \(profile.coreSkills.joined(separator: ", "))
        - domains: \(profile.domains.joined(separator: ", "))
        - targetTitles: \(profile.targetTitles.joined(separator: ", "))
        - summary: \(profile.summary)
        \(groundingSection(grounding, band: settings.band))
        Method:
        1. \(methodStep1)
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
          Confident, specific, and technically literal; \(metricsClause)
        - gapNote: \(gapNoteClause)
        """
        return base + generationControls(settings) + additionalContextSection(settings.additionalContext, band: settings.band)
    }

    /// The user's free-text steering guidance (Milestone I), appended when non-empty. Empty
    /// context returns "", so the default path stays byte-for-byte the base prompt. It directs
    /// **emphasis/framing**; the fidelity band above still governs how much latitude the model
    /// takes, so at the grounded default the guidance can't introduce fabricated facts.
    static func additionalContextSection(_ context: String, band: FidelityBand = .authentic) -> String {
        let trimmed = context.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let latitudeNote = band == .authentic
            ? "It does NOT permit inventing anything; the grounding and latitude rules above still apply."
            : "It steers emphasis and framing only; the latitude rules above still govern how much you may add or embellish."
        return """


        ADDITIONAL USER GUIDANCE (steer emphasis and framing):
        The candidate asked you to keep the following in mind — use it to choose which experience to
        foreground and how to frame it. \(latitudeNote)
        "\(truncate(trimmed, to: maxAdditionalContextCharacters))"
        """
    }

    /// The generation-controls addendum (Milestone D). Empty for `.default`, so the grounded
    /// path is byte-for-byte the base prompt; otherwise it appends latitude (D-B), aspect
    /// scope (D-C), and — in the embellished band — a mandatory disclosure clause (D-E) that
    /// **override** the base instructions where they conflict.
    static func generationControls(_ settings: GenerationSettings) -> String {
        // Guard on the fidelity/aspect/target controls only — free-text `additionalContext`
        // is appended separately (see `additionalContextSection`) and must not trigger the
        // latitude/scope block on its own.
        guard !settings.hasDefaultControls else { return "" }
        var lines: [String] = []

        switch settings.band {
        case .authentic:
            lines.append("- Latitude: reorder and rephrase the candidate's REAL experience only. "
                + "Never invent employers, titles, dates, degrees, credentials, or metrics.")
        case .curated:
            lines.append("- Latitude: curate aggressively — emphasize and reframe real experience, and you "
                + "MAY infer reasonable adjacent skills the candidate plausibly has. Still never invent "
                + "employers, titles, dates, degrees, or credentials.")
        case .embellished:
            lines.append("- Latitude: you MAY add plausible embellishments to strengthen the fit, including "
                + "details not present in the profile, to maximise the match. Prefer skills/impact framing "
                + "over fabricated hard credentials.")
        }

        if settings.aspects.isEmpty {
            lines.append("- Scope: tailor all résumé sections.")
        } else {
            let names = settings.aspects
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.label)
                .joined(separator: ", ")
            lines.append("- Scope: tailor ONLY these résumé sections — \(names). Reproduce every other section "
                + "faithfully from the candidate's real experience, unchanged.")
        }
        // The tailoring objective (D-C): every targeted section aims at the JD's language.
        lines.append("- Objective: tailor each targeted section to MATCH THIS JOB POST'S keywords and "
            + "description — foreground the brief's must-have and nice-to-have keywords and the posting's own "
            + "language wherever they are genuinely supported for this candidate.")
        // The cover letter is derived from the tailored résumé, not tailored on its own (D-C).
        lines.append("- Cover letter: write it FROM the tailored résumé above so it inherits the same keyword "
            + "alignment (plus the candidate's voice exemplar) — do not tailor it as a separate section.")

        if settings.band == .embellished {
            lines.append("- Disclosure (REQUIRED): in gapNote, list every statement in the résumé or cover "
                + "letter that is NOT directly supported by the candidate profile — each on its own line, "
                + "prefixed \"EMBELLISHED: \". List the honest gaps as usual after them.")
        }

        return "\n\nGENERATION CONTROLS (override the instructions above where they conflict):\n"
            + lines.joined(separator: "\n")
    }

    // MARK: Grounding (Milestone T)

    /// How the résumé / supporting documents may be used, **conditioned on the fidelity band**.
    /// `subject` names the source ("it" / "these documents"). At `.authentic` this is the original
    /// reorder-and-rephrase-only wording; higher bands permit inference / disclosed extension.
    static func groundingUsageClause(_ band: FidelityBand, subject: String) -> String {
        switch band {
        case .authentic:
            return "Use it as factual grounding: you may reorder and rephrase it, but never add any fact "
                + "absent from \(subject) or the profile above."
        case .curated:
            return "Use it as your primary factual grounding: you may reorder, rephrase, and infer reasonable "
                + "adjacent strengths from \(subject), disclosing any inference in gapNote."
        case .embellished:
            return "Use it as your factual base: you may reorder, rephrase, and extend \(subject) with plausible, "
                + "role-strengthening detail — disclose every addition in gapNote."
        }
    }

    /// The optional two-document grounding block injected into generation. The résumé + supporting
    /// documents are **factual** grounding (usage conditioned on the fidelity `band`); the cover
    /// letter is a **voice/tone exemplar** whose facts are never imported, regardless of band.
    /// Empty when there's nothing to inject, so profile-only generation is unchanged.
    static func groundingSection(_ grounding: PortfolioGrounding?, band: FidelityBand = .authentic) -> String {
        guard let grounding else { return "" }
        var section = ""

        let resume = grounding.resumeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !resume.isEmpty {
            section += """


            Candidate résumé — the candidate's REAL experience, as written. \(groundingUsageClause(band, subject: "it"))
            \(truncate(resume, to: maxPortfolioCharacters))
            """
        }

        if let supporting = grounding.supportingText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !supporting.isEmpty {
            section += """


            Additional supporting documents — more of the candidate's REAL background (e.g. a full career
            portfolio of roles, skills, and projects). \(groundingUsageClause(band, subject: "these documents"))
            \(truncate(supporting, to: maxSupportingCharacters))
            """
        }

        if let letter = grounding.coverLetterText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !letter.isEmpty {
            section += """


            Cover-letter style example (the candidate's own writing — MATCH its voice, tone, and
            structure when you write the cover letter, but do NOT import any facts, claims, metrics,
            employers, or dates from it; every fact comes only from the profile and résumé above):
            \(truncate(letter, to: maxCoverLetterCharacters))
            """
        }
        return section
    }

    // MARK: LLM job search (Milestone J)

    /// Cap on the number of AI-suggested leads requested per search.
    static let maxJobLeads = 8

    static let searchJobsInstructions =
        "You are a career research assistant. You suggest real, plausibly-current job openings that fit a " +
        "candidate. These are LEADS the candidate will verify before applying — so prefer genuine, well-known " +
        "employers and realistic roles, and if you are unsure, return FEWER leads rather than padding the list. " +
        "You never output application URLs (the app builds a search link itself)."

    /// Asks the engine for job leads that fit the candidate, grounded in the profile / résumé and
    /// steered by the user's search keywords + location. Requests up to ``maxJobLeads`` leads, each
    /// with a title, company, location, and a short why-it-fits summary — **no URLs** (the source
    /// attaches a search-query link; a model-produced link is never shown as a live posting).
    static func searchJobs(query: JobQuery, grounding: PortfolioGrounding?) -> String {
        let keywords = query.keywords.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = query.location?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resume = grounding?.resumeText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let supporting = grounding?.supportingText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var sections = [String]()
        sections.append("""
        Suggest up to \(maxJobLeads) job openings that would genuinely fit this candidate. They are leads the
        candidate will verify before applying — favour real, plausibly-current roles at real employers, and return
        fewer than \(maxJobLeads) if you are not confident. Do NOT invent application links.
        """)

        var wanted = [String]()
        if !keywords.isEmpty { wanted.append("Desired roles / keywords: \(keywords)") }
        if let location, !location.isEmpty { wanted.append("Preferred location: \(location)") }
        if !wanted.isEmpty { sections.append(wanted.joined(separator: "\n")) }

        if !resume.isEmpty {
            sections.append("Candidate résumé (their REAL background — match roles to it):\n"
                + truncate(resume, to: maxPortfolioCharacters))
        }
        if !supporting.isEmpty {
            sections.append("Additional candidate background:\n" + truncate(supporting, to: maxSupportingCharacters))
        }

        sections.append("""
        For each lead produce:
        - title: the role's job title.
        - company: the hiring company.
        - location: where it's based, or "Remote".
        - summary: two or three sentences on what the role is and why it fits this candidate.
        """)

        return sections.joined(separator: "\n\n")
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
