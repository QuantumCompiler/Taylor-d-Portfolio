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

Releases are numbered `v0.x.0`. Each is a coherent theme; the granular per-milestone record
is in [`lib/documentation/MILESTONES.md`](lib/documentation/MILESTONES.md).

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

**Next:** the next version's number and theme are decided when development on it starts. Likely candidates
come from the backlog — the native `LanguageModel` provider seam, on-device embedding RAG, or an optional
MCP tool layer.

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
