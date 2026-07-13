# Taylor'd Portfolio — Roadmap

How we work: features get discussed in chat, written up here (and in `SPEC.md`),
then handed to the Claude Code session to build. This file is the high-level
running list; `TODO.md` holds the granular checklist of **remaining** work, and
`MILESTONES.md` records the **completed** milestones in detail. As items land, tick
them here too so this stays an accurate progress board. (See `CLAUDE.md` → "Working
process" for how these four docs fit together.)

## v0.1.0 — foundation (complete)

- [x] Project scaffold: SwiftUI macOS app, folder layout per `CLAUDE.md`
      (four-layer `lib/src`, feature-based Presentation, landing screen, template removed)
- [x] `LLMProvider` seam with `FoundationModelsProvider` (primary) +
      `ClaudeCodeProvider` (secondary) + `LLMRouter`
      (on `TextGenerating` + `FoundationModelsClient` / `ClaudeProcessClient`)
- [x] Structured types: `CandidateProfile`, `JobListing`, `JobMatch`, `ApplicationKit`
      (+ `JobQuery`, `RankedJob`, `SalaryRange`; Codable round-trip tests)
- [x] `JobSource` seam + `AdzunaJobSource` (on `HTTPClient` / `URLSessionHTTPClient`)
- [x] `JobRanker`: lexical prefilter + batched LLM re-rank
- [x] UI: Portfolio, Search, Results tabs + Settings (Landing → TabView; screens wired
      through a composition root)
- [x] Portfolio → profile → search → ranked results → generate resume/cover letter,
      end to end (wiring proven by `EndToEndTests` + launch smoke; live-engine run is a
      manual device step)

## v0.2.0 — reliability (complete)

The theme is turning "misconfigured / weak output" into problems that surface early
and clearly, rather than as silent runtime failures. See `TODO.md` for the granular
breakdown.

- [x] **Adzuna credentials → build-time configuration.** Stop consuming the Adzuna
      `app_id` / `app_key` as runtime user settings; bake them in at build time so a
      correctly-built binary always has them and misconfiguration fails fast. New
      Infrastructure `AppConfig` port + `BundleAppConfig` (Info.plist ← gitignored
      `Secrets.xcconfig`); the composition root assembles `Credentials` from config
      (id/key) + settings (country). `adzunaCountry` stays a user setting — it's a
      search preference, not a secret.
      Seam: `Infrastructure/Config` (new) + `Composition`; deletes credential fields
      from `AppSettings` / Settings UI. On-device: n/a (config only).
      Note: baked keys are extractable from the bundle — fine for a personal free-tier
      key. If the app is ever distributed, prefer a backend proxy (a small Worker/
      service that vends results on one authenticated Adzuna account) over shipping
      keys in the binary or asking each user to obtain their own. Adzuna's commercial
      API pricing starts in the low-thousands per month, so a shared proxy is the
      realistic path at any scale beyond personal use.

- ~~**Prefer AFM 3 Core Advanced on-device.**~~ **Dropped.** A spike found on-device
      tier selection is OS/hardware-driven — the FoundationModels SDK has no API to request
      Core Advanced (20B) vs Core (3B) or to query which tier is served, so there's nothing
      to build. On capable silicon the OS serves the best tier automatically; the existing
      `LLMRouter` already handles on-device→Claude degradation. Revisit only if a future SDK
      adds a tier-selection API.

- [x] **Job-URL input + AGENT.md-grade generation prompts.** Two linked upgrades,
      ported from Taylor's hand-built LaTeX résumé agent (`AGENT.md`). **Both parts done.**
      1. **✅ Generate from a job URL (done).** Accept a posting URL as an input path
         (alongside the existing keyword search): fetch the page, extract the JD
         fields, and feed them into ranking/generation. If the page is JS-gated,
         paywalled, or blocks fetching, **stop and ask the user to paste the posting
         text** — never guess the role. New `JobPostingSource` seam (fetch + extract
         one posting → `JobListing`), reusing `HTTPClient`; extraction likely wants an
         LLM pass to pull company / role / requirements / stack / values from messy
         HTML.
      2. **✅ Two-stage, structured generation prompts (done).** Replaced the current
         single-shot `generateApplication` prompt with the AGENT.md discipline:
         first distil a **target brief** (company, exact role title, top 5–8
         must-have vs. nice-to-have keywords, tech stack, domain, stated
         mission/values), map each signal to a *true* profile fact, note gaps
         (requirements the candidate lacks — surfaced, never faked), then generate:
         a role-specific headline + summary, experience/projects re-angled to
         foreground overlap (feature the best-fit project), and a cover letter in
         three sections — *About Me* / *Why \<company\>* / *Why Me*. Same hard
         guardrail the app already states (SPEC "Grounded generation"): reorder and
         rephrase real experience only; never invent employers, titles, dates,
         metrics, or credentials.
      Seam: `Prompts` (new brief + generation prompts), `LLMProvider` (a
      `buildTargetBrief` step, or fold into `generateApplication`), a new
      `JobPostingSource` in Data/Jobs, and a small Presentation affordance to paste a
      URL. `ApplicationKit` likely grows a `gapNote`-adjacent brief or keeps the brief
      internal — decide during design.
      On-device: brief-building and generation are on-device-friendly; **URL fetch
      needs network** (and, if sandboxed, outgoing-connections entitlement — the same
      one Adzuna already uses). Note: AGENT.md's LaTeX/PDF build pipeline
      (PortfolioBuddy, one-page gate, `.docx` export) is **out of scope** here — that's
      the existing "Export" fast-follow; this item ports the *prompt discipline and URL
      input*, not the LaTeX toolchain.

- [x] **Multi-title search + field autocomplete.** Improve the search step's recall and
      ergonomics once a profile is loaded. Two linked parts:
      1. **Multiple title searches in one run.** Let the user enter several role titles
         (e.g. iOS Developer, iOS Engineer, Software Developer, Software Engineer) as
         chips/tokens; run a search per title, **merge and dedupe by `JobListing.id`**,
         then rank the combined set once against the profile. Location and salary are
         shared across all title searches. `JobQuery` stays the single-search unit (one
         `what` per `JobSource.search`) — the fan-out lives in the use case, so the seam
         contract is unchanged.
      2. **Autocomplete on the input fields.** Titles autocomplete from suggestions
         **seeded by the loaded profile** (`targetTitles`, `coreSkills`) plus a small
         curated vocabulary of common role titles; location autocompletes from a static
         list (+ "Remote"). Salary isn't autocomplete — offer preset brackets instead.
      Seam: a fan-out in `SearchAndRankUseCase` (expand titles → N `JobQuery` → concurrent
      searches → dedupe → single `rank`); a `SuggestionProvider` (Data) fed by the profile
      + static vocab for the suggestion source; `SearchViewModel` holds `titles: [String]`;
      Presentation renders the chip/token input + suggestions dropdown.
      On-device: yes — suggestions come from the profile + a static list, no network.
      Reliability notes: cap the number of concurrent title searches (Adzuna free-tier
      rate limits); decide partial-failure policy (if one title's search fails, prefer to
      continue with the successful ones and surface a soft note rather than fail the whole
      run). Composes with M's URL input — a URL-extracted posting can pre-fill a title chip.

- [x] **Save pulled listings + a job-detail view.** **Done (all three parts).** Persist what a search pulls down —
      each `JobListing` (full description, salary, original URL) and its `JobMatch`
      (score, reason, matched/missing skills) — and give the user a way to read the full
      job description from the UI. Two parts:
      1. **✅ Job-detail view (Presentation) (done).** Tapping a result opens a detail view showing
         the full description, salary, a "View original posting" link (`JobListing.url`),
         and the match score/reason + matched/missing skills. This closes a real gap —
         the pulled `description` currently isn't shown anywhere. Works in-session with no
         persistence, so it can land on its own.
      2. **✅ Persist searched listings (first slice of SwiftData) (done).** Store pulled listings +
         their match results so they survive relaunch and can be revisited — the concrete
         first slice of the "Persistence with SwiftData" fast-follow. New persistence port
         (declared in the layer that owns it) + a SwiftData-backed impl in Infrastructure;
         domain `JobListing` / `RankedJob` stay clean `Codable` structs, mapped to/from an
         `@Model` in Infrastructure (don't leak `@Model` into the domain).
      3. **✅ Persist generated materials with the posting (done).** When the user generates a
         resume + cover letter for a job, save the `ApplicationKit` (resumeMarkdown,
         coverLetter, gapNote) **linked to that `JobListing.id`**, so the posting carries
         its generated materials. The detail view then shows saved materials (and can
         re-open them without regenerating — avoids a redundant LLM call). Latest-wins per
         job to start; keeping a history is a later option.
      Seam: `JobDetailView` (+ optional lightweight VM) in Presentation; a persistence
      port + SwiftData impl in Infrastructure; a Data-layer repository (e.g.
      `SavedJobsRepository`) that maps stored rows ↔ domain types (`JobListing`,
      `JobMatch`, `ApplicationKit`); the save-after-generate step wires through the
      Application flow.
      On-device: yes — local SwiftData store, no network. Notes: Adzuna descriptions can
      contain HTML — decide whether to store raw and strip on display, or strip on ingest.
      This unlocks "already seen," a saved-jobs list, and "already generated" later (rest
      of the SwiftData item).

- [x] **Application status tracker.** Let the user record where each job stands: **mark
      as applied** (the applied date is stamped **automatically** — no manual entry), and
      flag later stages — interview offered, offer received, rejected, accepted/declined,
      withdrawn — each with its own auto date stamp when set. A tracker view lists the
      jobs the user has applied to with their current stage, and results/detail show a
      status badge. Stays consistent with the human-in-the-loop principle — the user
      applies themselves, then records it (no auto-submission).
      Seam: a domain `ApplicationStatus` type (current stage + dated milestones,
      `Codable`/`Sendable` like the other models); it persists via Milestone O's port /
      `SavedJobsRepository`, keyed by `JobListing.id`; a `MarkStatusUseCase` (or a small
      set) sets the stage and stamps `Date()` on transition; a `Tracker` screen
      (View + VM) plus a status control on the detail view; a status badge on `RankedRow`.
      On-device: yes — local, no network. Note: auto-stamp on transition by default;
      manual date edit is an optional later touch. Builds on O (persistence); replaces the
      "applied-to tracker" that was parked in the SwiftData fast-follow.

## v0.3.0 — output & polish (complete)

The theme: get the generated materials cleanly *out* of the app (Export), finish the
persistence fast-follow (saved/re-runnable searches), and polish the app that produces
them. A priority **hotfix** (the job-posting URL fetch is broken) comes first, then
Milestones Q (Export), R (Saved searches), S (Polish), T (two-document portfolio),
U (expanded search parameters), V (results ↔ tracker interaction), W (results filtering);
X (templates + one-page gate) was promoted from stretch into v0.3.0 proper and shipped.
**v0.3.0 scope is closed.** The milestone
letters are a catalogue, **not** the build order — see **"Recommended implementation order
(v0.3.0)"** in `TODO.md` for the phased sequence (fixes → Export → grounding/search → results
experience → cohesive polish → stretch). `TODO.md` has the granular breakdown.

- [x] **🔧 Hotfix — job-posting URL fetch is broken (do first).** ✅ **Done.** The Search screen's
      "Or generate from a specific posting" flow (Milestone M-A) produced no result. Root cause was
      **not** a propagation break (the `fetchFromLink` → `onChange(of: search.results)` → Results
      wiring was correct): the fetch itself failed for real boards because `URLSessionHTTPClient`
      sent no browser-like `User-Agent`/`Accept` headers and decoded only UTF-8 → `.unreadable`;
      and the error was rendered next to the Search button, not the Fetch action, so it looked like
      nothing happened. Fixed by (1) extending the `HTTPClient` port with a backward-compatible
      `get(_:headers:)`, having `LinkJobPostingSource` present as a browser + fall back UTF-8→ISO
      Latin-1 on decode, and (2) a dedicated `linkErrorMessage` surfaced prominently in the link
      section, auto-expanding the paste-text fallback. Regression tests cover both the VM flow and
      the fetch hardening; full suite green. Seam: Search flow (`SearchViewModel` / `SearchView`),
      `FetchPostingUseCase`, `LinkJobPostingSource`, `HTTPClient`, RootView results wiring.

- [x] **Export résumé & cover letter (Markdown / PDF / DOCX).** ✅ **Done (Q-A + Q-B + Q-C).**
      Copy, Markdown/plain-text, **PDF**, and true **DOCX** export all shipped behind one
      domain-agnostic `DocumentExporter` port composed by `RoutingDocumentExporter`
      (`MarkdownDocumentExporter` + `PDFDocumentExporter` + `DocxDocumentExporter`), an
      `ExportApplicationUseCase`, and an Export menu + Copy on the Application sheet. PDF renderer:
      native `NSAttributedString` → Core Text (not WebKit) — sync + `nonisolated`, self-contained;
      coarser layout is the trade-off (see Milestone X). DOCX: a hand-rolled minimal OOXML package +
      a pure-Foundation STORED-method `ZipArchiveWriter` (no compression/external deps), verified by
      a zip round-trip test. Fidelity limits (no tables/images/list numbering) documented in TODO.
      The flagged
      highest-value fast-follow: let the user get a generated `ApplicationKit` (résumé +
      cover letter) out of the app as polished files. New `DocumentExporter` port
      (Infrastructure — CLAUDE.md already reserves "exporters" as protocol-worthy) with
      format-specific impls, an `ExportApplicationUseCase` (Business), and an export
      control on the Application sheet / job-detail view. Three formats: **Markdown /
      plain-text** (trivial — clipboard + save-as, lands first), **PDF** (the core
      deliverable — the concrete renderer, HTML-template→PDF vs AttributedString→PDF, is
      an **open design decision inside the milestone**, with the one-page-gate implication
      noted), and **DOCX** (true Word format via a **hand-rolled minimal OOXML / zipped-XML
      writer** — macOS has no native `.docx` writer, so this is the heaviest single piece).
      Seam: `Infrastructure/Export` (new) + `Business/UseCases` + a Presentation affordance.
      On-device: yes — pure local rendering, no network. Note: AGENT.md's LaTeX/PDF
      toolchain stays out of scope; this is native rendering only.

- [x] **Saved / re-runnable searches.** ✅ **Done.** `SavedSearch` (a named `JobSearchRequest`)
      persists via `SavedSearchesRepository` on Milestone O's `PersistentRecordStore`; save/load/
      delete use cases; a "Saved searches" section on the Search screen with Save + per-item Run
      (repopulates the form and re-runs via `SearchAndRankUseCase`) / Delete. A re-run reports "N new
      since your last search" by deduping against the saved-jobs store. The full grown
      `JobSearchRequest` (U params included) round-trips.
      Finish the persistence fast-follow: persist each
      `JobSearchRequest` (titles + shared location + salary floor), list saved searches,
      and **re-run** one later against the current profile through the existing search→rank
      pipeline, deduping against already-seen listings. New `SavedSearchesRepository`
      (Data/Persistence) on Milestone O's `PersistentRecordStore` (new `kind`); save/load/
      delete use cases; re-run reuses `SearchAndRankUseCase`; a Presentation surface on the
      Search screen. The *other* half of the old fast-follow — caching the built profile
      across launches — already shipped via named `SavedProfile`s, so it's **done**.
      On-device: yes — local SwiftData store; the re-run itself hits Adzuna as any search does.

- [x] **Polish pass.** ✅ **Done (S-A…S-E).** Made the six-tab app feel finished. Five parts: (1) ✅
      **in-app markdown rendering** — a `MarkdownText` view renders the generated résumé/cover
      letter as styled, selectable text (headings/bullets/bold-italic, reusing the exporter
      parsers) with per-document copy buttons, on the Application sheet; (2) ✅ **empty / loading /
      error states** — audited all tabs and added the missing `isLoading` spinner to Results
      + Tracker so their persisted-data load no longer flashes the empty state; other tabs already
      had error/unavailable/loading affordances; (3) ✅ **results / saved-jobs / Tracker cohesion**
      — a pure `JobHistory` type + `LoadJobHistoryUseCase` join "already seen / already generated /
      applied" into one story, rendered as `RankedRow` badges across Results **and** Tracker, with
      loads reconciled so a fresh search is never clobbered; (4) ✅ **scrollable screens /
      small-window layout** — the Portfolio + Search tabs now scroll via a shared
      `View.scrollableScreen()` wrapper (the trailing `Spacer()` dropped), so lower controls (incl.
      Search's Fetch button) stay reachable at any window size; Results/Tracker/Settings/Application
      already scroll natively; (5) ✅ **saved-profile tile gestures** — long-press *anywhere* on a
      saved-profile tile sets it as default and tap *anywhere* loads it (the dial is now just
      an indicator); the trash button stays independent. Seam: mostly Presentation (Views + VMs),
      with small Data/use-case touches for the history joins. On-device: yes.

- [x] **Two-document portfolio (résumé/portfolio + cover letter) as generation grounding.**
      ✅ **Done (T-A + T-B).** The Portfolio tab now takes a required résumé/portfolio + an **optional
      cover letter** (both LLM-tidied, carried on `SavedProfile`, back-compatible with single-document
      saves). Generation injects a `PortfolioGrounding` — résumé real text as factual grounding, cover
      letter as a voice/tone exemplar with a "never import facts from it" guardrail — via a grown
      `generateApplication(…grounding:)` seam (a forwarding default keeps stubs untouched); nil
      grounding falls back to the profile-only prompt unchanged.
      Let the Portfolio tab accept **two** documents — a résumé/portfolio (the existing
      import, now the primary slot) and an **optional cover letter** — and reference both
      when generating a job's tailored materials. The résumé/portfolio stays the *factual*
      grounding: the `CandidateProfile` is still distilled from it, and its real text grounds
      both outputs. The uploaded cover letter is a **voice / tone / structure exemplar** for
      the generated cover letter only — the output mirrors the candidate's real style, but
      facts, metrics, employers, and dates are **never imported from it** (the "never
      fabricate" guardrail holds; facts come from the résumé/profile). Both documents are
      LLM-tidied (`TidyDocumentUseCase`) and carried on `SavedProfile`; generation injects
      their bounded text — the concrete v0.1.0 grounding approach in SPEC ("inject the bounded
      portfolio directly"), later upgradable to embedding retrieval over the same documents.
      Cover letter is **optional** and back-compatible with existing single-document profiles.
      Seam: `SavedProfile` (second-document fields), Portfolio input (second importer/paste
      slot), `TidyDocumentUseCase`, `GenerateApplicationUseCase` + `LLMProvider.generateApplication`
      + `Prompts` (grounding injection), and the plumbing carrying the documents from
      Portfolio → Application. On-device: yes — import + tidy + generation are on-device-friendly;
      bound both inputs for the small context window.

- [x] **Expanded, optional search parameters.** ✅ **Done (U-A…U-F).** Position-type filter
      (`PositionType` → Adzuna contract flag), typeable **and saveable** location + minimum salary
      (`LocationStore` / `SalaryPresetStore` + `SuggestionProvider` merges), a best-effort
      **desired-result-count** goal (`SearchAndRankUseCase` pages toward it, capped, never fails →
      `resultShortfall` note), and a post-rank **minimum-rank** filter (`noneMetMinimum`, distinct
      from no-results). All fields optional — an all-blank form assembles today's exact request.
      Give the search step more control — every
      field **optional**, so a blank field leaves today's behaviour unchanged:
      - **Position type** (full-time, part-time, contract, permanent…) — a new optional filter
        mapped to Adzuna's contract params inside `AdzunaJobSource`.
      - **Typeable + saveable location** — the user can *type* a location (not only pick a
        preset) and **save it as a preset**; saved locations persist (a new `LocationStore`,
        mirroring `RoleTitleStore`) and join the suggestions.
      - **Typeable + saveable minimum salary** — same pattern: type a custom floor and
        optionally save it as a reusable preset.
      - **Desired result count** — a soft **goal**, not a guarantee: the search pages/pulls
        toward it, but if it can't be reached it returns what's available with a note — it
        **never fails** the search.
      - **Minimum-rank (score) filter** — keep only results scoring ≥ N; if none qualify, tell
        the user nothing met their minimum (distinct from "no results found at all").
      Seam: new optional fields on `JobSearchRequest` / `JobQuery`; a `PositionType` domain type;
      `AdzunaJobSource` (position-type param + paging toward the goal); `SearchAndRankUseCase`
      (result-count goal via bounded paging + the post-rank score filter); new persisted
      `LocationStore` / salary-preset store + a `SuggestionProvider` merge; `SearchViewModel` +
      Search UI. On-device: suggestions + persistence are local; the search itself hits Adzuna
      (mind free-tier rate limits when paging toward a large goal — cap the pages).

- [x] **Results ↔ Tracker interaction overhaul.** ✅ **Done (V-A…V-E).** Per-row Save-to-Tracker
      (bookmark, marks `.saved`) + Delete (trash → `DeleteSavedJobUseCase` clears job/status/kit)
      icons; a swipeable result card (right = save, left = dismiss, via a pure unit-tested
      `SwipeOutcome`); and **generation moved to the Tracker** — `JobDetailView.canGenerate` is
      `false` in Results (Save-to-Tracker footer, no Generate) and `true` in the Tracker (unchanged).
      Change how the user acts on a ranked
      result, and move generation out of the Results path:
      - **Per-row actions.** Each result tile gets a **Save to Tracker** icon and, to its
        right, a **Delete** (trash) icon.
      - **Save = mark `saved`.** "Save to Tracker" marks the job at the `saved` stage
        (`MarkStatusUseCase`), so it appears in the Tracker; the row then carries a "Saved"
        badge. (Reuses Milestone P — no new status model.)
      - **Delete = fully forget.** Deleting removes the result from the list and the
        saved-jobs store and — by decision — clears its tracker status (and any saved
        materials) too, so there are no orphaned entries.
      - **Swipeable card.** Opening a result presents a card the user can drag horizontally
        (macOS trackpad/mouse drag): **right = save to Tracker**, **left = dismiss** (no save,
        no delete). Delete stays the explicit trash icon.
      - **Generation moves to the Tracker.** Remove the "Generate résumé & cover letter"
        action from the Results→detail path — from Results the user only reads the posting and
        chooses whether to save. **Generation stays available from the Tracker** (unchanged:
        brief → tailor, persisted `ApplicationKit`) for a saved job.
      Seam: `SavedJobsRepository.delete` + `DeleteSavedJobUseCase` (clears the saved job, its
      status, and its saved `ApplicationKit`); `ResultsViewModel` (save/delete + badge refresh);
      Results row actions + a swipeable detail card (Presentation); `JobDetailView` gains a
      generation-context flag (Results = no generate, shows Save; Tracker = generate); updated
      Tracker empty-state copy. On-device: yes — all local; reuses the Milestone O/P persistence
      + status seams.

- [x] **Results filtering.** ✅ **Done.** A pure, unit-tested `ResultsFilter` (minScore / keywords /
      location / company / salaryMin / tracked-status) applied live over the loaded `[RankedJob]` via
      `ResultsViewModel.filteredResults`; a collapsible filter bar with "Showing X of Y" + Clear and a
      distinct empty-filtered state. View-only — never re-runs the search or mutates persistence, so
      V's row actions act on the filtered rows.
      Let the user **interactively narrow the displayed results** in the
      Results view — by **minimum rank**, **keywords**, **location**, and a few more facets
      (company, salary floor, tracked status) — without re-running the search. Non-destructive: a
      filter only hides rows (delete/save still act on what's shown), and it's live + reversible.
      This is **distinct from Milestone U-E's search-time min-rank filter** (which trims the
      persisted/ranked set): W is a view filter over the already-loaded `[RankedJob]`. Seam: a pure
      `ResultsFilter` value with `apply(to:)` (unit-tested); `ResultsViewModel` filter state +
      `filteredResults`; a filter bar on the Results view (pickers populated from the values present
      in the current results) + an empty-filtered state. On-device: yes — pure, local, no network,
      no persistence (session-only; a saved-filter option is a later idea).

- [x] **Export templates + one-page gate.** ✅ **Done (Milestone X — promoted from stretch).**
      Three selectable résumé templates (Classic / Compact / Modern) as `ExportTemplate` →
      `TemplateStyle` (typography/layout) threaded through the Core Text PDF renderer via a
      `template:` parameter on the `DocumentExporter` port (text formats ignore it — no new port).
      The one-page gate reuses the same pagination: `DocumentExporter.pageCount(...)` →
      `ExportApplicationUseCase.resumePageCount` → an **advisory** banner on the Application sheet
      when the résumé overflows a page (suggests Compact / tightening — **never** truncates).

## v0.4.0 — navigation & shell (complete)

The theme: give the app room to grow. As of v0.3.0 several areas have real internal
depth, and the single top tab strip can't scale. Move primary navigation to a **left
sidebar** (top-level areas only) and demote per-area sub-screens to a **segmented inner
nav** at the top of the content pane. Native-macOS throughout; content, view models, and
use cases are preserved and only re-homed. **Presentation-layer only** — no
Business/Data/Infrastructure changes. `TODO.md` has the granular breakdown.

- [x] **Milestone A — Navigation shell.** ✅ **Done.** Replaced `RootView`'s custom tab bar
      with a sidebar-driven shell (`NavigationSplitView`): sidebar rows = the five areas
      (existing SF Symbols + Results/Tracker count badges, accent-fill selection); a
      per-area segmented inner-nav picks the sub-view; `Area / Sub-view` title header.
      A testable `ShellNavigation` holder owns area/sub-view state (reset-to-first on area
      change). No changes below Presentation. Seam: `RootView` + `ShellNavigation`.
      On-device: n/a (UI only).
- [x] **Milestone B — Sub-view routing per area.** ✅ **Done.** Wired each area's sub-views
      behind the inner nav (Portfolio: Profile / Saved Profiles / Source Documents; Search: New
      Search / Saved Searches / From a Link; Results: Ranked; Tracker: All / Applied /
      Interviewing / Offers; Settings: Engines / Adzuna / About). A type-safe section enum per
      area (labels derive `MainArea.subViews`); each screen takes a `section:` param and renders
      the matching piece with empty states. Tracker stage filters reuse the existing status data
      via a pure `TrackerSection.includes(_:)` policy + `TrackerViewModel.jobs(in:)`.
- [x] **Milestone C — Polish + About.** ✅ **Done.** Keyboard navigation (⌘1–⌘5 to areas,
      ⌘⇧[ / ⌘⇧] to step sub-views), native `NavigationSplitView` sidebar collapse/restore,
      carried-over pointer-cursor + swipe polish, and a polished Settings **About** sub-view
      (app icon + name + version + one-liner). Also corrected the app's `MARKETING_VERSION`
      1.0 → **0.4.0** so About reports the real version.

## v0.4.1 — fixes & refinements  (complete)

This project's first **point release** — a small `v0.x.y` patch on the v0.4.0 shell, gathering bug
fixes and minor refinements rather than a new feature theme. Mostly Presentation (H also touched
Infrastructure/Export); milestones restart at **A** and commit as `v0.4.1 : Milestone X Completed`. See
`MILESTONES.md` for the write-ups.

- [x] **Milestone A — Move the profile preview & its controls to Saved Profiles.** ✅ **Done.** In the
      Portfolio tab, relocated the built-profile **preview**, the **Regenerate description** control, and
      the **Save / Update Profile** row from the **Profile** sub-view into the **Saved Profiles** sub-view.
      Profile now holds only the import/paste slots + **Build Profile**; Saved Profiles shows the current
      built/loaded profile (preview + regenerate + save) above the saved-profiles library, and its
      empty-state gate widened to host a just-built, unsaved profile. Seam: Presentation only
      (`Portfolio/View/PortfolioView.swift`) — the ViewModel and all lower layers untouched. On-device:
      n/a (UI only).

- [x] **Milestone B — Remove the content-pane header text entirely (tabs only).** ✅ **Done.** App-wide:
      dropped the `Area / Sub-view` header text everywhere — both above the segmented tabs and in the
      window title bar. The segmented **tabs** are now the only sub-view indicator and the **sidebar**
      names the area, so no "Portfolio / Profile" appears in any capacity. **Results** (no real sub-views)
      shows no header and no tabs — the selected sidebar row identifies it. The window title is the app
      name ("Taylor'd Portfolio"). `ShellNavigation.breadcrumbTitle` retired. Seam: Presentation only
      (`Presentation/App/RootView.swift` + `ShellNavigation.swift` + `ShellNavigationTests`). On-device:
      n/a (UI only).

- [x] **Milestone C — Saved-to-Tracker jobs leave the Results list.** ✅ **Done.** Once a job has any
      tracker status (starting with `.saved` when saved to the Tracker), it's excluded from the
      **Results** list so Results shows only un-triaged ranked jobs; the job lives in the **Tracker** from
      then on. `ResultsViewModel.untrackedResults` drives the list/counts/filter; saving refreshes history
      so the row drops out live; a distinct "All results are in your Tracker" empty state; the now-dead
      "Tracked" filter facet and the (auto-gone) Results status badge cleaned up. Seam: Presentation + a
      status read (`Results/ViewModel/ResultsViewModel` + `Results/View`), reusing the Milestone O/P status
      data. On-device: yes.

- [x] **Milestone D — Tracker: one tab per application status.** ✅ **Done.** Expanded the Tracker inner
      nav from All / Applied / Interviewing / Offers to **All + a tab for every `ApplicationStage`** (Saved,
      Applied, Interviewing, Offer, Accepted, Declined, Rejected, Withdrawn), each filtering to exactly its
      stage — un-bundling the old Offers-includes-accepted grouping. The 9-segment fit was resolved by
      wrapping the inner nav in a horizontal scroll (narrow areas look unchanged); per-tab empty states
      come free from the existing section-title template. Seam: Presentation only (`TrackerSection` +
      `includes` in `ShellNavigation.swift`, the inner-nav scroll in `RootView`, tests) — reuses the
      existing status model. On-device: yes.

- [x] **Milestone E — Center the Tracker empty-state icon & text.** ✅ **Done.** Stretched the Tracker's
      empty-state `ContentUnavailableView` branches with `.frame(maxWidth: .infinity, maxHeight: .infinity)`
      (matching the sibling `ProgressView`) so the icon + text center in the pane instead of hugging the
      top under the tabs — applied to all of D's per-status tabs. Consistency sweep centered the Results
      empty states the same way (no results / all-tracked / filtered-empty); the left-aligned
      `InlineEmptyState` (Portfolio/Search) left as-is. Seam: Presentation only (`TrackerView` +
      `ResultsView`). On-device: n/a (UI only).

- [x] **Milestone F — Source Documents browsable by profile.** ✅ **Done.** The Portfolio → Source
      Documents sub-view now lists the **saved profiles**, each a disclosure that expands to that profile's
      résumé + optional cover-letter readable text (a two-level profile → documents disclosure), with a
      per-profile "no source documents" note and a reworded empty state gated on having saved profiles.
      View restructure over existing data — each `SavedProfile` already carries its source + cover-letter
      readable text via `viewModel.savedProfiles`. Open call resolved as recommended: **only saved
      profiles** appear (an unsaved just-built profile shows once saved). Seam: Presentation only
      (`Portfolio/View/PortfolioView.swift`) — no ViewModel/persistence change. On-device: yes.

- [x] **Milestone G — Settings Save button: drop the section background.** ✅ **Done.** Moved the Save
      button into the Engines / Adzuna section **footer** (`saveButton`), so it has no grouped-section
      background band **and still scrolls with the content**, attached to the end of the section. Same
      `viewModel.save()` action/style; About is unaffected. Seam: Presentation only
      (`Settings/View/SettingsView.swift`). On-device: n/a (UI only).

- [x] **Milestone H — Clear the concurrency & unused-result build warnings.** ✅ **Done.** Marked the pure
      Export value types `nonisolated` (`ExportTemplate`, `TemplateStyle`, `RGBColor`, the `RGBColor.nsColor`
      accessor, and the `Data` little-endian `append` helpers), clearing the whole family of "main
      actor-isolated … from a nonisolated context" warnings (`ExportTemplate.style`, `nsColor`, and the
      `ZipArchiveWriter` batch a clean build surfaced), and fixed the `Result of 'try?' is unused` in
      `SearchViewModel.saveCurrentSearch()` with `_ =`. A clean build is now **warning-free**; behaviour
      unchanged. Seam: Infrastructure/Export + `SearchViewModel`. On-device: n/a.

## v0.5.0 — document generation fixes  (complete)

The theme: fix and round out the **document-generation experience** — the tailored résumé + cover
letter the app produces for a saved job, and the paths to view/regenerate them. A feature release
(not a patch) gathering the generation-side gaps Taylor has hit in use. Milestones restart at **A**
and commit as `v0.5.0 : Milestone X Completed`. Presentation-first (Milestone A reuses the existing
`LoadApplicationUseCase` — no new seam). `TODO.md` has the granular breakdown.

Also shipped in v0.5.0 as ad-hoc fixes (see `MILESTONES.md`): **generation is user-initiated** (explicit
Generate button, no auto-generate), swipe-to-save/delete restored on Results, remove-from-Tracker (return
to Results / delete), the runtime provider now forwards the D settings/score methods, and the Claude
subprocess runs in a neutral directory (no more spurious Photos/Music privacy prompts).

- [x] **Milestone A — View generated materials from the Tracker.** ✅ **Done.** After generating a job's résumé +
      cover letter from the Tracker, there's no clear way back to them: the materials persist
      (`SavedApplicationsRepository`, reloaded by `ApplicationViewModel.open(for:)` with **no** LLM
      call), but `JobDetailView`'s footer always shows one **"Generate résumé & cover letter"** button
      (`JobDetailView.swift:219`) with no "already generated" indicator — so the user can't tell that
      tapping it shows the existing docs rather than making new ones. Add a **"View résumé & cover
      letter"** button alongside Generate in the Tracker context (`canGenerate == true`), shown when a
      saved kit exists (detected via the existing `LoadApplicationUseCase`, threaded
      `Composition` → `RootView` → `TrackerView` → `JobDetailView`); View opens the sheet in
      load-only mode, Generate forces a fresh regeneration (open call: label + force-regenerate
      mechanics). Seam: **Presentation only** — `JobDetailView`, `TrackerView`, `RootView`,
      `Composition`, `ApplicationSheet` / `ApplicationViewModel`; reuses Business `LoadApplicationUseCase`.
      On-device: yes (local store read; regeneration uses the current `.application` engine).

- [x] **Milestone B — Present job detail (and its Application view) as real windows, not sheets.** ✅ **Done
      (B-A + B-B + B-C).** Tapping a
      job in the Tracker and Results presents `JobDetailView` as a modal **sheet** (`TrackerView.swift:57`,
      `ResultsView.swift:73`), and generating opens `ApplicationSheet` as a **nested sheet**
      (`JobDetailView.swift:57`). Replace **every** custom sheet with a genuine detached macOS **window**
      (`WindowGroup(id:for:)` + `openWindow`). Not a one-line swap: the app has a single `WindowGroup`
      (`App.swift:20`) and the sheets read `RootView`'s live `profile` / `PortfolioGrounding` — but
      `PortfolioGrounding` isn't `Codable`, so session state must be **hoisted into a shared app-level
      `@Observable`** injected across scenes (B-A), and the detail (B-B) + application (B-C) windows keyed by
      job **id**. Also adds a cross-window **refresh signal** (no sheet-dismiss callback) and reconciles the
      Results **swipe** card (open call). Seam: **Presentation** (`App`, `RootView`, `Composition`,
      `TrackerView`, `ResultsView`, `JobDetailView`, `ApplicationSheet`) — Presentation-only under the
      recommended id-based windows; the pass-by-value alternative would add `Hashable` in Data. On-device:
      yes (local reads + existing engines).

- [x] **Milestone C — Remove the "Mark as applied" button (the status menu covers it).** ✅ **Done.** `JobDetailView`
      shows a prominent **"Mark as applied"** button for untracked jobs (`JobDetailView.swift:125`) beside a
      **"Set status"** menu that already includes Applied (`ApplicationStage.settable` excludes only
      `.saved`) with the same auto-date-stamp — so the button is redundant. Remove it in all views (one file;
      it's presented from both Results and Tracker). Seam: **Presentation only** (`JobDetailView.statusSection`);
      no lower-layer change. On-device: n/a (UI only).

- [x] **Milestone D — Generation controls: fidelity scale, tailored aspects, and presets.** ✅ **Done (D-A…D-F).**
      Add a controls
      panel to the generate flow: (1) rename the button to **"Generate application"** (`JobDetailView.swift:221`;
      a non-colliding label for the `ApplicationKit` output); (2) a **generation-fidelity** slider `0…1`
      (0 = authentic / verbatim, 0.5 = curated, 1.0 = embellished) mapped to **prompt latitude** and threaded
      `GenerateApplicationUseCase` → `LLMProvider.generateApplication(…settings:)` → `Prompts` (new `settings`
      param with a forwarding default, like `grounding`); (3) **tailored-aspect** checkboxes over the
      four résumé sections (Summary / Experience / Projects / Skills — none = all; **Education** stays
      verbatim and the **Cover Letter** is derived from the curated résumé, so neither is a knob), each
      tailored to **match the job post's keywords + description**; (4) named **presets**
      (`GenerationPreset` + `GenerationPresetsRepository`, reusable across jobs, mirroring `SavedSearch`);
      and (5) a **desired rank-match target** (D-F) — the master control: set a target fit score and an
      **outcome-driven loop** (generate → score the tailored output via a new `scoreApplication`/`rank`
      step → escalate → regenerate, to an iteration cap) fabricates as needed to hit it, **overriding both
      the fidelity slider and the aspect checkboxes**.
      **Integrity:** grounded stays the **default**; the upper scale is opt-in and any invented content is
      **disclosed** (gap-note list + UI "draft — verify" warning) — this revises SPEC "Grounded generation"
      and CLAUDE "Hard rules for generated content" to *grounded-by-default + opt-in + disclosed*. Seam:
      **Presentation + Business + Data** (new `GenerationSettings` / `TailoredAspect` / `GenerationPreset`
      models, preset repo + use cases, prompt/provider threading), optional Infrastructure (sampling
      temperature, on-device only). On-device: yes (local presets; prompt-driven fidelity keeps both engines
      in lockstep).

## v0.5.1 — LaTeX résumé & cover letter output  (in progress)

A **patch release** on top of shipped v0.5.0 that adds a **second, high-fidelity PDF output path**: render the
generated `ApplicationKit` into `.tex` against Taylor's own **awesome-cv LaTeX classes** and compile it with
**`lualatex`** — shelled as an external process, exactly like the `claude -p` provider — so the app can produce
résumé + cover-letter PDFs identical to the ones he builds by hand in his `Resume-And-Cover-Letter` repo. The
existing native exports (Core Text PDF / DOCX / Markdown, Milestones Q/X) are untouched; `lualatex` is an
**optional external dependency** (present → the awesome-cv PDF is offered, absent → the route is disabled with
a clear note), like the `claude` CLI. Milestones **restart at A**; commit as `v0.5.1 : Milestone X Completed`.
**DOCX-from-LaTeX** (the repo's `tex2docx.py` → pandoc path) is out of scope. `TODO.md` has the granular
breakdown + open calls.

- [ ] **Milestone A — Bundle the awesome-cv LaTeX assets.** Ship the presentation assets `lualatex` compiles
      against inside the app bundle — the three `Class/*.cls`, `fonts/`, `Images/`, and `fontawesome*.sty` —
      under `lib/src/Infrastructure/Tex/Resources/`, with a `TexAssets` accessor that resolves them at
      runtime. Content sections are **not** bundled (the app supplies content per job). Seam:
      `Infrastructure/Tex` (new) + an Xcode bundling step for non-Swift resources (open call). On-device: n/a
      (packaging).
- [ ] **Milestone B — `LaTeXCompiling` port + `LaTeXProcessClient`.** The compile engine, mirroring
      `ClaudeProcessClient`: stage the bundled assets + generated `.tex` into an app-owned temp dir, run
      `lualatex` twice (`-interaction=nonstopmode -halt-on-error`), return PDF `Data`, clean aux, surface the
      log tail on failure; PATH-widen to TeX bin dirs (`/Library/TeX/texbin`, `texlive`), plus an availability
      probe. Seam: `Infrastructure/Tex` (new), reusing the `ClaudeProcessClient` PATH/temp-dir helpers.
      On-device: n/a; needs a local TeX install (MacTeX / TeX Live).
- [ ] **Milestone C — `TexDocumentBuilder` (`ApplicationKit` → awesome-cv `.tex`).** The inverse of the repo's
      `tex2docx.py`: turn the generated résumé Markdown + cover letter into `.tex` driving the awesome-cv
      macros (`\cvsection`/`\cventry`/`\cvproject`/`\cvitems`/`\cvskills`, `\lettersection`, `\position`),
      reusing `MarkdownBlockParser`, with strict LaTeX escaping and only the safe FontAwesome icons. **Open
      call:** best-effort Markdown parse (C-parse, recommended for the patch) vs. a `@Generable` structured
      résumé that generation emits (C-structured, deferred fast-follow for full fidelity). Seam:
      `Infrastructure/Tex` (new), pure + domain-agnostic. On-device: yes (local string transform).
- [ ] **Milestone D — Wire the awesome-cv PDF route through export + the Application sheet.** Because
      `DocumentExporter` is synchronous and `lualatex` is async, add an **async** route: an
      `ExportApplicationUseCase.latex(_:)` overload → builder → compiler, injected in `Composition`, exposed via
      `ApplicationViewModel` (`canExportLaTeX` + async export) and a **"PDF — Portfolio (LaTeX)"** item in the
      `ApplicationSheet` export menu (disabled with a "requires `lualatex`" note when unavailable). Bonus:
      also export the raw **`.tex` source** (a path-C handoff into `PortfolioBuddy`). Reconcile the one-page
      gate to the compiled PDF's real page count (PDFKit). Seam: Business (`ExportApplicationUseCase`) +
      Presentation (`Composition`, `ApplicationViewModel`, `ApplicationSheet`). On-device: yes (compile needs
      the local TeX install).
- [ ] **Milestone E — Availability surfacing, docs, release hygiene.** Surface whether `lualatex` is detected
      (Settings → About), document the new optional dependency + `Infrastructure/Tex/` seam in `CLAUDE.md`
      (Build & run + layer map), note the LaTeX PDF path in `SPEC.md`, add the v0.5.1 summary to `README.md`
      on ship, and confirm `MARKETING_VERSION` = `0.5.1` (bumped at kickoff). Seam: docs + a local availability
      read. On-device: n/a.
- [ ] **Milestone F — Render Markdown thematic breaks (`---`) instead of printing them literally.** An
      **independent bug fix** to the existing native renderer (not part of the LaTeX path): the generated
      Markdown's `---` section separators print as literal `---` in the PDF/DOCX/preview because
      `MarkdownBlockParser.classify` has no thematic-break case and falls through to a paragraph. Add a
      `.thematicBreak` block (3+ `-`/`*`/`_`, whole-line, detected before the bullet rule) and render it as a
      thin rule in `MarkdownAttributedRenderer` (PDF), `OOXMLDocument` (DOCX), and a `Divider` in `MarkdownText`
      (in-app preview) — the compiler flags all three exhaustive switches. Seam: `Infrastructure/Text` +
      `Infrastructure/Export` + one Presentation component. On-device: yes (pure local rendering).
- [ ] **Milestone G — Export the résumé and cover letter as separate documents.** An **independent export
      refinement**: today `ExportApplicationUseCase.assembleMarkdown` merges both into one file. Split export so
      each is its own named deliverable (`<Company> - <Role> - Résumé.<ext>` / `… - Cover Letter.<ext>`) via an
      `ApplicationDocument` selector on the use case, per-document `exportData`/filenames/Copy in
      `ApplicationViewModel`, and Résumé / Cover Letter groups in the `ApplicationSheet` export menu — which
      also aligns the native path with the LaTeX path (C/D already emit two files). Seam: Business
      (`ExportApplicationUseCase`) + Presentation (`ApplicationViewModel`, `ApplicationSheet`). On-device: yes
      (pure local assembly + export).
- [ ] **Milestone H — Sort control in the Tracker.** Mirror the Results tab's live `ResultsFilter` with an
      interactive **sort** in the Tracker: a pure, unit-tested `TrackerSort` (sort key + direction) the view
      holds and applies live over `TrackerViewModel.jobs(in:)`, composing with the existing per-stage tab
      filter. Folds today's load-time ordering (recent status activity) into the default sort; adds keys like
      date applied, stage, match score, company, and title. Seam: **Presentation only**
      (`Tracker/View/TrackerSort.swift` + `TrackerViewModel` + `TrackerView`), paralleling
      `Results/View/ResultsFilter.swift`. On-device: yes (pure local sort, session-only).

## Fast follow (next up)

- Export and saved/re-runnable searches shipped in **v0.3.0**; the profile-cache half of the old
  "Persistence with SwiftData" fast-follow already shipped via `SavedProfile`. **v0.4.0** (navigation
  & shell), **v0.4.1** (fixes & refinements), and **v0.5.0** (document generation fixes) are complete;
  **v0.5.1** (LaTeX résumé & cover letter output) is **in progress** (above).
- **C-structured résumé (v0.5.1 fast-follow).** If the Milestone C Markdown-parse fidelity proves too coarse,
  add a `@Generable` structured résumé representation (sections → entries with org/location/date, projects,
  skill buckets) that generation emits and `TexDocumentBuilder` renders faithfully — full awesome-cv fidelity.
  Touches `LLMProvider` / `Prompts` / `ApplicationKit`, so it's larger than the patch.

> **Numbering the versions.** Each version letters its own milestones **A, B, C…** from scratch —
> v0.4.0 restarts at Milestone A (it does **not** continue from v0.3.0's X), and a **patch release like
> v0.4.1 restarts at A too**. Patch releases use a `v0.x.y` number (`y > 0`) for bug-fix / refinement
> batches on top of a shipped `v0.x.0`. See `CLAUDE.md` → "Working process" → Versioning.

## Backlog (to be specced from chat)

_Add features here as we discuss them. Each should note: what it does, which
seam it touches, and whether it's on-device-friendly or needs Claude/network._

- [ ] **Adopt the native `LanguageModel` protocol seam (WWDC 2026).** The Foundation
      Models framework opened up at WWDC 2026: the on-device model is now
      `SystemLanguageModel()`, and the same `LanguageModelSession` API can route to
      Private Cloud Compute (`PrivateCloudComputeLanguageModel`) or third-party
      providers (Claude, Gemini) that conform to a public `LanguageModel` protocol —
      one call site, provider chosen at deploy time.
      What: decide whether to adopt Apple's protocol as our raw-generation seam or
      keep our own `TextGenerating` / `LLMRouter`. It overlaps our abstraction almost
      exactly, so this is a "converge or keep parallel" decision, not free adoption.
      A middle path: keep `TextGenerating` as the port and add a `LanguageModel`-backed
      adapter, so the Claude CLI path and the native path live behind the same seam.
      Seam: `Infrastructure/LLM` (`TextGenerating`, `FoundationModelsClient`) + Data's
      `LLMRouter`. Note: Private Cloud Compute could become a *third* engine tier
      between on-device and the Claude CLI — cleaner privacy story than shelling out
      to `claude -p`, and it removes the "App Sandbox off" requirement for that path.

- [ ] **On-device embedding retrieval (RAG layer).**
      What: embed portfolio chunks + jobs with `NLContextualEmbedding`, store the
      vectors, rank by cosine similarity. Powers two things at once — the ranking
      prefilter (replaces the lexical overlap) *and* portfolio grounding (retrieve
      the top-k relevant chunks per job to inject into generation, instead of the
      whole truncated portfolio).
      Seam: `JobRanker` for the prefilter, plus a new `Retriever` used by the
      generation path. Build the index once, reuse it for both.
      On-device: yes, no network. Notes: `NLContextualEmbedding` returns per-token
      vectors — mean-pool per chunk. Before hand-rolling similarity, check whether
      the framework's built-in semantic search (reportedly added WWDC 2026) covers it.

- [ ] **Optional MCP tool layer.**
      What: let the on-device model call external MCP tools (e.g. a jobs or
      research server) via a runtime bridge — `DynamicGenerationSchema` converts
      MCP tool schemas at runtime, then pass them to `LanguageModelSession(tools:)`.
      See SwiftMCP or the official `modelcontextprotocol/swift-sdk`.
      Seam: sits alongside `JobSource` as an alternative data path; tools register
      on the session. Needs network; validate tool-call output server-side; mind
      the macOS sandbox for stdio servers.
      Priority: later. A plain REST `JobSource` is simpler for a single known
      source — MCP earns its place once we want many pluggable tools or agentic
      tool-selection.

## Ideas / candidate features to discuss

_Loose parking lot — not committed._

- Additional job sources (JSearch for fuller descriptions, USAJOBS, remote feeds)
- Portfolio ingestion from files — ✅ **done** for PDF/Word/RTF/text (see TODO
  "Portfolio document import"); portfolio-URL import (fetch + extract) still open
- Anthropic Messages API provider (cleaner than `claude -p` if the app is ever
  distributed)
- Backend proxy for Adzuna (see v0.2.0 note) — required if the app is ever distributed
- Multimodal portfolio input — read a screenshot/image of a resume on-device (needs a
  multimodal on-device model), avoiding a separate OCR step
- Interview prep / mock-interview feature
- Application tracker with statuses and follow-up reminders

## Explicit non-goals

- Auto-submitting applications or filling forms on job sites
- iOS/mobile target
- Accounts / cloud sync
