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

1. **Portfolio → profile.** The user provides a **resume/portfolio** (paste or import)
   and, optionally, a **cover letter** — two separate documents. The app distills the
   resume/portfolio once into a structured `CandidateProfile` and caches it; both
   documents are kept and later referenced to ground generation (see ROADMAP v0.3.0
   Milestone T).
2. **Search → listings.** The user sets parameters — one or more role titles (as
   chips, autocompleted and pre-seeded from the profile) plus a shared location and
   salary floor. Optionally, the user can also set a **position type**, **type in** a
   custom location or salary floor (and save either as a reusable preset), request a
   **desired number of results** (a best-effort goal, never a hard requirement), and set
   a **minimum-rank filter** — all optional, so leaving them blank keeps the original
   behaviour (ROADMAP v0.3.0 Milestone U). The app runs one search per title, merges and
   de-duplicates the listings, and returns a single candidate set.
3. **Rank.** A cheap prefilter trims the set to a shortlist, then the LLM
   re-ranks the shortlist against the profile, producing a fit score, a reason,
   and matched/missing skills per job. In the Results view the user can then
   **interactively filter** the ranked list — by rank, keywords, location, and more —
   without re-running the search (ROADMAP v0.3.0 Milestone W).
4. **Save → generate.** From the results, the user **saves** a job to the Tracker (a
   save icon on the row, or swiping the opened result right) rather than generating on
   the spot — or **deletes** a result they don't want (a trash icon; swiping left just
   dismisses). Then, from the **Tracker**, the app generates a tailored resume and cover
   letter for a saved job — grounded in the real portfolio by default, with a **fidelity
   control** to opt into more latitude (any addition beyond the portfolio is disclosed; see
   Principles). The user can then **export** those materials — copy them, or save as Markdown, PDF,
   or DOCX (native, on-device — see ROADMAP v0.3.0 Milestone Q). A **second, high-fidelity PDF
   path** (v0.5.1) renders the résumé and cover letter as their **own** documents through Taylor's
   awesome-cv LaTeX classes, compiled with `lualatex` (an optional external dependency, like the
   `claude` CLI); the raw `.tex` source can also be exported. Export never alters the generated content.

Alongside search, the user can also paste a **specific job-posting URL** (or the
posting text, when a page can't be fetched); the app extracts it into the same
ranked-listing flow. If a page is JS-gated, paywalled, or blocks fetching, the app
says so and asks for the pasted text rather than guessing a role.

The user can **track** where each application stands. A job enters the Tracker when the
user **saves** it from the results (the save icon or a right swipe, which marks it
`saved`); from there they generate its materials and advance its stage — mark it applied
(the date is stamped automatically) and flag later stages (interview, offer, outcome). A
Tracker screen lists tracked jobs and a status badge appears on results. This stays
human-in-the-loop: the user applies themselves, then records it — no auto-submission.

## v0.1.0 scope (in)

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

## Non-goals (v0.1.0)

- No auto-submission or form-filling on job sites
- No mobile/iOS target (macOS only)
- No account system or cloud sync
- No job-board browsing beyond the search feature
- Pulled listings + their match results — and the generated resume/cover letter for a
  job — now **persist** across launches (SwiftData; see ROADMAP v0.2.0 Milestone O).
  Reopening a job with saved materials shows them without regenerating. The built
  profile also persists, as a named `SavedProfile` (with its source document). The
  remaining persistence gap — **saved/re-runnable searches** — is a v0.3.0 target (ROADMAP
  Milestone R).

## Principles

- **Generation may fabricate; the user always sees what's generated.** The generation-fidelity
  control governs how much latitude the model takes — from reordering/rephrasing *real* experience,
  through curation, up to embellished/invented content at the top of the scale — and the LLM job
  source surfaces AI-suggested leads that aren't verified postings. Fabrication is an **accepted
  capability**, not something the app blocks. What stays is **transparency to the user**: content
  beyond the real profile (and unverified leads) is **surfaced, not silent** — listed as an addition
  and flagged in the UI with a "draft — verify before sending" (or "AI-suggested — verify") marker —
  so the user decides what to submit.
  Generation is **two-stage** (ported from Taylor's résumé agent, `AGENT.md`):
  first distil the posting into a structured *target brief* (company, exact role,
  must-have vs. nice-to-have keywords, tech stack, domain, mission/values), then
  tailor against it — mapping signals to profile facts, foregrounding the best-fit
  overlap, and structuring the cover letter as *About Me / Why \<company\> / Why Me*.
  When the user has uploaded a **cover letter** (ROADMAP v0.3.0 Milestone T), it serves
  only as a **voice / tone / structure exemplar** for the generated cover letter — the
  output mirrors the candidate's real style. Factual grounding comes from the
  resume/portfolio and the distilled profile.
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

Ranking, and generation at its grounded default, build on the user's *real* portfolio, and
the on-device model has a small context window — so we treat portfolio grounding
as a retrieval problem (RAG), not a "dump everything into the prompt" problem. (Grounding is
the *default*, not a hard rule — the fidelity control lets the user opt into more latitude; RAG
improves grounding **quality**, it doesn't enforce a never-fabricate rule.)

- **v0.1.0 keeps it simple:** the bounded (truncated) portfolio is injected directly
  into the profile-building and generation prompts.
- **As portfolios grow,** retrieve only the most relevant chunks per job: embed
  the portfolio chunks once, embed the job, take the top-k by similarity, and
  inject those. Better grounding, and it respects the context window.
- **Retrieval is on-device** (embeddings via the Natural Language framework). The
  same embedding index powers the ranking prefilter, so it's built once, reused
  twice — retrieval for matching and retrieval for generation are the same step.
- **Two wiring options, decided later:** inject retrieved chunks into the prompt
  (classic RAG), or expose retrieval as a `Tool` the model calls (agentic RAG).

This keeps generation **well-grounded when the user wants it** — the model builds on real
portfolio text rather than a blank space it fills with invention — while the fidelity control
still lets the user opt into more latitude. (RAG improves grounding *quality*; it isn't
enforcing a never-fabricate rule.)

## Success criteria for v0.1.0

A user can paste a portfolio, run a search, see a ranked list with meaningful
scores and reasons, and generate a usable tailored resume + cover letter for a
job they pick — end to end, on-device, with Claude as an optional upgrade.
