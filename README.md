# Taylor'd Portfolio

A native **macOS** app that searches for jobs, ranks them against your portfolio, and — on
demand — writes a tailored **résumé and cover letter** for a chosen role. It is
**human-in-the-loop by design: it never submits applications for you.**

Inspired by the useful half of tools like AIApply (tailored resumes, portfolio-aware
matching) while deliberately dropping the part that gets them criticized — mass
auto-submission to job boards. You stay in control of every application.

## What it does

Four stages, run locally on your Mac:

1. **Portfolio → profile.** Paste or import a résumé/portfolio (and, optionally, a cover
   letter). The app distills the résumé once into a structured `CandidateProfile` and keeps
   both documents to ground later generation.
2. **Search → listings.** Set role titles, location, salary, and other optional parameters;
   the app pulls listings (Adzuna) and **ranks them against your profile** with a fit score
   and reasoning. Searches are saveable and re-runnable.
3. **Review → track.** Browse and filter ranked results, open a job's detail, save the ones
   worth pursuing, and advance their status in a **Tracker** (Saved → Applied → Interviewing → …).
4. **Generate → export.** For a chosen job, generate a tailored résumé + cover letter —
   grounded strictly in your real documents, never fabricating employers, titles, or dates —
   then export to **PDF / DOCX / Markdown / plain text** with a selectable template and a
   one-page length check.

## Stack

- **UI:** SwiftUI, macOS 26 (Tahoe), Xcode 26.
- **LLMs:** Apple **Foundation Models** (on-device) as primary, **Claude Code** headless
  (`claude -p`) as secondary — the engine and Claude model are chosen **per task** in Settings.
- **Jobs:** Adzuna REST API (credentials are build-time secrets).
- **Persistence:** SwiftData (saved jobs / applications / statuses / profiles / searches) +
  `UserDefaults` for settings and small preferences.
- **Architecture:** four-layer clean architecture (Presentation → Business → Data →
  Infrastructure) with an MVVM presentation layer; dependencies point down only.

Source lives under `lib/src/`, tests under `lib/tests/`. Not distributed via the Mac App Store
(the App Sandbox is off so the `claude -p` provider can launch an external binary).

## Version history

Feature releases are numbered `v0.x.0`, each a coherent theme; `v0.x.y` numbers a patch release — a batch of
fixes and refinements on top of a shipped feature release. The granular per-milestone record is in
[`lib/documentation/MILESTONES.md`](lib/documentation/MILESTONES.md).

### v0.1.0 — foundation
The end-to-end vertical slice, built layer by layer: project scaffold, domain models, the dual
**LLM seam** (Foundation Models + Claude Code behind one `LLMProvider`), the Adzuna **job
seam**, per-task engine **settings**, the **ranking** funnel, all screens wired through a
**composition root**, a working portfolio → search → rank → generate flow, and portfolio
**document import**. *(Milestones A–J.)*

### v0.2.0 — reliability
Hardened the pipeline into something usable day-to-day: Adzuna credentials moved to
**build-time config**; generate from a pasted **job-posting URL** with two-stage,
AGENT.md-grade generation; **multi-title search** with field autocomplete; **persistence** of
pulled listings plus a job-**detail view**; and an application-**status Tracker**.
*(Milestones K, M, N, O, P.)*

### v0.3.0 — output & polish
Made the output first-class and the app feel finished:
- **Export** résumé + cover letter to PDF / DOCX / Markdown / plain text (Q), with selectable
  **templates** and a **one-page résumé gate** (X).
- **Saved / re-runnable searches** (R) and **expanded, optional search parameters** (U).
- A **Results ↔ Tracker** interaction overhaul — save / delete / swipe, generation in context
  (V) — plus non-destructive **results filtering** (W).
- **Two-document portfolio grounding** (résumé + cover-letter voice) for generation (T).
- A broad **polish pass** (S): in-app markdown rendering, empty/loading/error states,
  Results/saved-jobs/Tracker cohesion, scrollable screens, saved-profile tile gestures.
- Quality-of-life touches (pointer cursors, custom tab bar, trackpad-swipe result card) and
  project housekeeping (tests under `lib/tests/`, config under `lib/`, corrected
  `com.veritum` bundle identifier). *(Hotfix + Milestones Q–X.)*

### v0.4.0 — navigation & shell
Reworked the app's navigation so it can grow past a single tab strip — a **Presentation-only** change
(every screen's content, view models, and use cases preserved, only re-homed):
- A left **sidebar** (`NavigationSplitView`) for the five top-level areas, with accent-fill selection
  and Results/Tracker count badges, plus a **segmented inner nav** per area (A).
- Each area split into its sub-views (B): Portfolio → Profile / Saved Profiles / Source Documents;
  Search → New Search / Saved Searches / From a Link; Results → Ranked; Tracker → All / Applied /
  Interviewing / Offers (stage filters); Settings → Engines / Adzuna / About.
- Polish (C): keyboard navigation (⌘1–⌘5, ⌘⇧[ / ⌘⇧]), sidebar collapse/restore, and an **About**
  pane — plus a version-string fix so the app reports `0.4.0`. *(Milestones A–C.)*

### v0.4.1 — fixes & refinements
The project's first **patch release** — bug fixes and small refinements on the navigation shell, mostly
Presentation:
- Portfolio **Profile** tab is now inputs-only; the built profile's preview, description regeneration,
  and Save/Update controls moved to **Saved Profiles** (A). **Source Documents** became browsable **by
  profile**, with whole-row-clickable disclosures (a new `ExpandableRow` component) (F).
- Removed the `Area / Sub-view` header text everywhere — the segmented tabs and sidebar carry it, and
  **Results** is a plain section with no tabs (B).
- **Results ↔ Tracker**: saving a result now moves it out of Results into the Tracker (C); the Tracker
  gained a tab for **every** application status (All + Saved / Applied / Interviewing / Offer / Accepted
  / Declined / Rejected / Withdrawn) (D); empty states are centered (E).
- The Settings **Save** button lost its background band (G), and all concurrency / unused-result build
  warnings were cleared (H). *(Milestones A–H.)*

### v0.5.0 — document generation fixes
Rounds out the tailored résumé + cover letter experience and the control the user has over it:
- **View generated materials** back from the Tracker (A), and job detail + the Application view are now
  real detached **windows** instead of modal sheets, driven by a shared `AppSession` (B).
- Removed the redundant "Mark as applied" button — the status menu covers it (C).
- **Generation controls (D):** a **fidelity** scale (Authentic → Curated → Embellished), **tailored-section**
  checkboxes (Summary / Experience / Projects / Skills, each aimed at the job post's keywords), reusable
  **presets**, disclosed embellishment, and a **desired rank-match target** — an outcome-driven loop that
  fabricates as needed to hit a score. **Grounded stays the default; anything invented is opt-in and
  disclosed** ("verify before sending"), and the default path is byte-for-byte the old prompt.
- Generation is now **user-initiated** (an explicit Generate button, so options can be set first); swipe
  save/delete restored on Results; remove-from-Tracker (return to Results or delete); and the Claude
  subprocess runs in a neutral directory so it no longer triggers spurious Photos/Music privacy prompts.
  *(Milestones A–D + fixes.)*

### v0.5.1 — LaTeX résumé & cover letter output
Adds a **second, high-fidelity PDF export path** plus a batch of export/Tracker refinements:
- **awesome-cv LaTeX output (A–E):** the app renders a generated application into `.tex` against Taylor's own
  awesome-cv classes (bundled in `lib/tex/`) and compiles it with **`lualatex`** — shelled as an external
  process, like the `claude` CLI — producing résumé + cover-letter PDFs that match the ones he builds by hand
  (matching section order, spacing, and entry macros). The raw **`.tex` source** exports too (a handoff into
  his manual pipeline). `lualatex` is **optional**: present → the awesome-cv PDF is offered (Settings → About
  shows availability), absent → only the native exports appear.
- **Export/Tracker refinements:** Markdown `---` renders as a real rule instead of literal dashes (F); the
  résumé and cover letter export as **separate** documents (G); a live **sort control** in the Tracker (H);
  and an **additional-context** box that steers generation without changing the grounded default (I).
  *(Milestones A–I.)*

### v0.6.0 — richer grounding, job detail & sources
Gave ranking and tailored generation **more real signal to work from** — and **more sources** to get it from:
- **Richer job postings (A):** decode Adzuna's job/work type, posted date, and category; **LLM-enrich** a saved
  posting into a structured `PostingDetails` (qualifications, responsibilities, about-the-role/company,
  benefits) and feed it into the two-stage generation. Surfaced as badges + a structured posting description
  (standardized across sources in Milestone K).
- **Profile at generation time (B):** a per-generation **profile picker** so the user chooses which saved
  profile to generate against, grounded on *that* profile's real source documents (defaults to the loaded one).
- **Regenerate result (C):** a **re-rank** action on a saved job — re-assess fit (and backfill posting detail)
  against a chosen profile with an optional steering note, persisted latest-wins — to refresh stale / legacy entries.
- **User-editable API credentials (D):** enter provider keys in **Settings → Sources** (stored locally, hidden &
  locked after saving), with the build-time secrets kept as a fallback.
- **Full job-posting text (E):** recover the **whole posting** behind the redirect URL, LLM-cleaned of site
  chrome, rendered as markdown and used as grounding — not Adzuna's ~500-char snippet.
- **Multi-source search (F):** aggregate providers behind a `CompositeJobSource` with cross-source de-dup —
  **Adzuna** plus an optional **JSearch (RapidAPI)** aggregator whose rich response arrives already-enriched.
- **Provider setup help & selector (G, H):** a data-driven **provider registry** powers per-provider
  "How to get a key" help in Settings and a **"Search sources" selector** in the Search view — pick which
  API(s) to query; a provider with no key is disabled.
- **Supporting profile documents (I):** a profile can attach **additional documents** — e.g. a full career
  portfolio — baked in as **factual** grounding, enriching both ranking and generation.
- **LLM job source (J):** find job **leads straight from your résumé** with no API key — the AI source is a
  first-class search provider (engine-based availability, its own task in the engines menu). Results are clearly
  labelled **AI-suggested** and link to a web search, never presented as verified live postings.
- **Standardized result descriptions (K):** every result is LLM-digested into one **canonical `PostingDetails`
  format** and rendered the same way — done **progressively** (rows appear first, descriptions standardize in the
  background) — so results read consistently whatever the source and generation grounds on a uniform structure. *(Milestones A–K.)*

### v0.6.1 — keyword match & ATS coverage
A patch release on v0.6.0. ATS and AI résumé screeners filter on a posting's keywords, and good candidates get
auto-rejected for missing a few. The answer here is **visible text only** — never hidden white-text keyword
stuffing, which backfires (screeners parse to plain text, and recruiters see it):
- **Coverage, measured on what a human reads (A–C):** a generated application now reports **how many of the
  posting's must-have keywords the résumé actually contains**, with the covered and missing lists per keyword
  tier. Matching is case- and accent-insensitive and respects word boundaries — so "Go" never matches "Google",
  while "C++", "C#", and "Node.js" match properly. The posting's keyword brief is stored **with** the generated
  documents, so coverage is still there when a saved result is reopened.
- **Truthful keyword matching, opt-in (D):** a **"Match the posting's must-have keywords"** control tells
  generation to use the posting's own wording for experience you **genuinely have**, and to list anything you
  can't claim in the **Gaps** note instead of writing it into the résumé. Off by default; it changes emphasis,
  never latitude, so the grounded default still can't invent. *(Milestones A–D.)*

### v0.6.2 — list actions, sorting & document previews
A patch release on v0.6.0/v0.6.1, tidying up how the two list tabs and the Portfolio document previews behave:
- **Removals you can find (A):** the Tracker could always send a job back to Results or delete it, but only by
  swiping — an iOS gesture with no visible affordance on macOS. Both are now on the row as **visible icons** and a
  **right-click menu**, and in the open job's own view; deleting confirms from every path.
- **Multi-select and bulk actions (B):** ⌘/shift-click to select several results, then **save them all to the
  Tracker** or **delete them** at once (the Tracker gets the same, for bulk **Return to Results**). Opening a job
  is now a **double-click**, since a single click selects. Bulk saving fetches the postings a few at a time rather
  than all at once.
- **Sort and filter on both tabs (C):** Results had a filter but no sort, the Tracker a sort but no filter. Now
  both do both — Results sorts by match score, company, role title, salary or date posted; the Tracker filters by
  rank, keywords, location, company or salary, within the open stage tab.
- **Source documents you can actually read (D–E):** importing a résumé or cover letter no longer shows a raw
  extraction preview — just the file, with **Clear** to go back to typing — and the tidied copy under Source
  Documents is no longer cut off, either by the box it sat in **or** by a length limit that quietly dropped the
  end of a long document. *(Milestones A–E.)*

### v0.7.0 — customizable LaTeX document styles
The awesome-cv PDF route had exactly one look, hardcoded down to the font size and margins. It's now yours:
- **Named styles you create and pick at export time (A–D):** font, accent colour, margins, page size (US Letter /
  A4), and which résumé sections appear and in what order. Two built-in templates to start from, and your styles
  are saved, reusable, and one can be starred as the default.
- **A Document Styles pane in Settings (E)** with a **Preview** that compiles a sample so you can see a style
  before you use it, and controls bounded to ranges that were measured rather than guessed — LaTeX will happily
  produce an unreadable page without ever reporting an error.
- **A raw-LaTeX escape hatch (F)** for anyone who wants to write the preamble themselves — including replacing
  the résumé header's built-in name and contact details. If it doesn't compile you get the real log, the `.tex`
  source still exports so you can debug it, and one click puts you back on a style that works.
- Also fixed: a stray LaTeX setting from the skills grid had been quietly compressing every section printed after
  it. *(Milestones A–F.)*

### v0.7.1 — bug fixes
A patch release fixing **18 verified defects** found by a structured codebase audit (every finding re-verified
against the source by a pass instructed to refute it), grouped into eight milestones by shared root cause:
- **State that stays put (A–B):** an in-flight generation can no longer write one job's résumé under another
  job's header (or export a file named for the wrong job) — re-targeting cancels the old run, and a run token
  guards every write. The background description digest no longer yanks navigation back to Results once per
  posting, resurrects deleted rows, or re-persists them; the Results badge counts what the list actually shows.
- **Identity and search correctness (C–D):** a pasted posting's id is now deterministic across launches (it was
  seeded per process, orphaning saved materials and duplicating rows every launch). A desired-result-count goal
  really ranks past the old silent 20 cap (bounded by an explicit cost ceiling, with an honest shortfall note),
  short provider pages keep paging, and the same posting from two sources collapses to one row.
- **LLM layer (E):** a subprocess pipe deadlock that could hang an LLM call forever is gone (both pipes drain
  concurrently), task cancellation now terminates the child `claude` process and is never treated as an engine
  failure, the AI job-search prompt names the JSON shape its decoder requires, and the rank-target loop scores
  the **whole** résumé instead of an under-scored truncation that escalated fidelity on its own.
- **Wiring and guards (F–H):** the Document Styles pane loads its saved library on open (no more "No saved
  styles yet" over a full library, no duplicate rows on save), the AI source's Configured status follows the
  engine choice live, a cleared cover letter is cleared everywhere (it silently kept steering generation), a
  selected profile can be rebuilt without re-importing its document, and two `Double`→`Int` overflow crashes
  (salary fields) are clamped at every layer. *(Milestones A–H; suite 904 → 930 cases.)*

**Next:** not named yet — likely candidates come from the backlog (the native `LanguageModel` provider seam,
on-device embedding RAG, an optional MCP tool layer) or the unspecced ideas noted in `TODO.md` (an ATS-friendly
export mode, a chunked full tidy for long documents).

## Build & run

Requires Xcode 26 on macOS 26, an Apple-Intelligence-capable Mac (for the on-device model), and
the `claude` CLI installed/authenticated (for the Claude engine). To enable job search, copy
`lib/secrets/Secrets.example.xcconfig` → `lib/secrets/Secrets.xcconfig` and fill in your Adzuna
`ADZUNA_APP_ID` / `ADZUNA_APP_KEY` (gitignored). A build without them still runs, with Search
disabled behind a clear banner.

```sh
# Test from the CLI
xcodebuild test -project "Taylor'd Portfolio.xcodeproj" -scheme "Taylor'd Portfolio" -destination 'platform=macOS'
```

## Documentation

- [`lib/documentation/SPEC.md`](lib/documentation/SPEC.md) — what we're building and why (the north star).
- [`lib/documentation/ROADMAP.md`](lib/documentation/ROADMAP.md) — the high-level plan and backlog.
- [`lib/documentation/TODO.md`](lib/documentation/TODO.md) — the granular checklist of remaining work.
- [`lib/documentation/MILESTONES.md`](lib/documentation/MILESTONES.md) — the detailed record of completed milestones.
- [`lib/documentation/CLAUDE.md`](lib/documentation/CLAUDE.md) — architecture, conventions, and working process for contributors.

## License

**Proprietary — all rights reserved.** Copyright © 2026 Veritum LLC. This is *not* open-source
software: no right to use, copy, modify, or distribute it is granted without prior written permission.
See [`LICENSE`](LICENSE) for the full terms.
