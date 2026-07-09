# Taylor'd Portfolio — Project Spec

## One-liner

A native macOS app that searches for jobs, ranks them against your portfolio,
and — on demand — writes a tailored resume and cover letter for a chosen job.
Human-in-the-loop: it never submits applications for you.

## Background

Inspired by the useful half of tools like AIApply (tailored resumes, cover
letters, portfolio-aware matching) while deliberately dropping the part that
gets those tools criticized: mass auto-submission to job boards. Taylor'd Portfolio keeps
the human in control of every application.

## Core user flow

Four stages, run locally on the user's Mac:

1. **Portfolio → profile.** The user pastes their resume, projects, and links.
   The app distills this once into a structured `CandidateProfile` and caches it.
2. **Search → listings.** The user sets parameters — one or more role titles (as
   chips, autocompleted and pre-seeded from the profile) plus a shared location and
   salary floor. The app runs one search per title, merges and de-duplicates the
   listings, and returns a single candidate set.
3. **Rank.** A cheap prefilter trims the set to a shortlist, then the LLM
   re-ranks the shortlist against the profile, producing a fit score, a reason,
   and matched/missing skills per job.
4. **Apply → generate.** When the user taps "Apply" on a job, the app generates
   a tailored resume and cover letter grounded strictly in the real portfolio.

Alongside search, the user can also paste a **specific job-posting URL** (or the
posting text, when a page can't be fetched); the app extracts it into the same
ranked-listing flow. If a page is JS-gated, paywalled, or blocks fetching, the app
says so and asks for the pasted text rather than guessing a role.

The user can **track** where each application stands — mark it applied (the date is
stamped automatically) and flag later stages (interview, offer, outcome). A Tracker
screen lists tracked jobs and a status badge appears on results. This stays
human-in-the-loop: the user applies themselves, then records it — no auto-submission.

## v1 scope (in)

- Portfolio input (paste text, or import a PDF / Word / RTF / text file) → structured profile
- Job search via one job source (Adzuna to start)
- Lexical prefilter + LLM re-rank with scores and reasons
- On-demand resume + cover letter generation per job
- Two interchangeable LLM engines: Apple Foundation Models (primary, on-device)
  and `claude -p` (secondary), selectable in Settings
- Basic SwiftUI UI (Portfolio / Search / Results tabs + Settings)

Adzuna API credentials are **baked in at build time** (from a gitignored
`Secrets.xcconfig`), not entered by the user — so a correctly-built binary always
has them and a misconfigured build fails fast (Search is disabled with a clear
banner) rather than silently returning nothing. Only the Adzuna **country** is a
user setting. (Distribution would instead need a backend proxy — see ROADMAP.)

## Non-goals (v1)

- No auto-submission or form-filling on job sites
- No mobile/iOS target (macOS only)
- No account system or cloud sync
- No job-board browsing beyond the search feature
- Pulled listings + their match results — and the generated resume/cover letter for a
  job — now **persist** across launches (SwiftData; see ROADMAP v2 Milestone O).
  Reopening a job with saved materials shows them without regenerating. Broader
  persistence — profile cache, saved/re-runnable searches — remains a fast follow.

## Principles

- **Grounded generation.** Generated resumes/cover letters reorder and rephrase
  *real* experience only. Never invent employers, titles, dates, or credentials.
  Generation is **two-stage** (ported from Taylor's résumé agent, `AGENT.md`):
  first distil the posting into a structured *target brief* (company, exact role,
  must-have vs. nice-to-have keywords, tech stack, domain, mission/values), then
  tailor against it — mapping each signal to a true profile fact, foregrounding the
  best-fit overlap, flagging gaps (never faking them), and structuring the cover
  letter as *About Me / Why \<company\> / Why Me*.
- **On-device first.** Default to Apple Foundation Models: free, private, offline.
  Escalate to Claude only when chosen or when the on-device model is unavailable.
- **Swappable seams.** The LLM engine and the job source are both behind
  protocols, so either can be replaced without touching the rest of the app.
- **Layered + MVVM.** Four layers — Presentation → Business → Data →
  Infrastructure — with dependencies pointing downward only, and SwiftUI Views
  kept dumb behind `@Observable` ViewModels. See `CLAUDE.md` for the rule and the
  layer map.
- **Privacy.** The portfolio and profile stay on the user's machine.

## Grounding strategy (RAG over the portfolio)

Ranking and generation must stay grounded in the user's *real* portfolio, and
the on-device model has a small context window — so we treat portfolio grounding
as a retrieval problem (RAG), not a "dump everything into the prompt" problem.

- **v1 keeps it simple:** the bounded (truncated) portfolio is injected directly
  into the profile-building and generation prompts.
- **As portfolios grow,** retrieve only the most relevant chunks per job: embed
  the portfolio chunks once, embed the job, take the top-k by similarity, and
  inject those. Better grounding, and it respects the context window.
- **Retrieval is on-device** (embeddings via the Natural Language framework). The
  same embedding index powers the ranking prefilter, so it's built once, reused
  twice — retrieval for matching and retrieval for generation are the same step.
- **Two wiring options, decided later:** inject retrieved chunks into the prompt
  (classic RAG), or expose retrieval as a `Tool` the model calls (agentic RAG).

This is what makes the "never fabricate" principle enforceable — the model only
ever sees real portfolio text, never a blank space it might fill with invention.

## Success criteria for v1

A user can paste a portfolio, run a search, see a ranked list with meaningful
scores and reasons, and generate a usable tailored resume + cover letter for a
job they pick — end to end, on-device, with Claude as an optional upgrade.
