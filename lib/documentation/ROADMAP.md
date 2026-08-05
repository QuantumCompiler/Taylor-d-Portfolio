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

## v0.5.1 — LaTeX résumé & cover letter output  (complete)

A **patch release** on top of shipped v0.5.0 that adds a **second, high-fidelity PDF output path**: render the
generated `ApplicationKit` into `.tex` against Taylor's own **awesome-cv LaTeX classes** and compile it with
**`lualatex`** — shelled as an external process, exactly like the `claude -p` provider — so the app can produce
résumé + cover-letter PDFs identical to the ones he builds by hand in his `Resume-And-Cover-Letter` repo. The
existing native exports (Core Text PDF / DOCX / Markdown, Milestones Q/X) are untouched; `lualatex` is an
**optional external dependency** (present → the awesome-cv PDF is offered, absent → the route is disabled with
a clear note), like the `claude` CLI. Milestones **restart at A**; commit as `v0.5.1 : Milestone X Completed`.
**DOCX-from-LaTeX** (the repo's `tex2docx.py` → pandoc path) is out of scope. `TODO.md` has the granular
breakdown + open calls.

- [x] **Milestone A — Bundle the awesome-cv LaTeX assets.** ✅ **Done.** Ships the presentation assets `lualatex`
      compiles against inside the app bundle — the three `Class/*.cls`, `fonts/`, `Images/`, and
      `fontawesome*.sty` — as a **blue folder reference** (`lib/tex/` → `…app/Contents/Resources/tex/`, structure
      preserved), with a `nonisolated` `TexAssets` accessor resolving/validating them at runtime. Content
      sections are **not** bundled. Seam: `Infrastructure/Tex` (new) + a `project.pbxproj` folder reference (the
      open call, resolved to a folder reference over a sync-group exception). On-device: n/a (packaging).
- [x] **Milestone B — `LaTeXCompiling` port + `LaTeXProcessClient`.** ✅ **Done.** The compile engine, mirroring
      `ClaudeProcessClient`: stages the bundled assets + generated `.tex` into an app-owned temp dir (symlinks),
      runs `lualatex` twice (`-interaction=nonstopmode -halt-on-error`), returns PDF `Data`, tears the dir down,
      surfaces the log tail on failure; PATH-widens to TeX bin dirs via a shared `ProcessSupport` (also now used
      by `ClaudeProcessClient`), plus an `isAvailable`/`locate()` probe. Verified with a real end-to-end
      `lualatex` compile (guarded on availability). Seam: `Infrastructure/Tex` + `Infrastructure/Process` (new).
      On-device: n/a; needs a local TeX install (MacTeX / TeX Live).
- [x] **Milestone C — `TexDocumentBuilder` (`ApplicationKit` → awesome-cv `.tex`).** ✅ **Done (C-parse).** The
      inverse of the repo's `tex2docx.py`: renders the generated résumé Markdown + cover letter into `.tex`
      driving the awesome-cv macros (`\cvsection`/`\cvitems`/`\cvskills`/`\lettersection`/`\position` + entry
      title/date styles), reusing `MarkdownBlockParser`/`MarkdownInline`, with char-by-char LaTeX escaping and
      only the classes' existing FontAwesome icons. Best-effort structural map (**C-parse**, no generation-seam
      change); C-structured remains the flagged fast-follow. Verified by a real end-to-end compile of the
      emitted `.tex` under the bundled classes. Seam: `Infrastructure/Tex` (new, pure). On-device: yes.
- [x] **Milestone D — Wire the awesome-cv PDF route through export + the Application sheet.** ✅ **Done.** An
      **async** route (the sync `RoutingDocumentExporter` untouched): `ExportApplicationUseCase` gains an
      injected `LaTeXCompiling` compiler + `texSource`/`latexPDF`, wired in `Composition`; `ApplicationViewModel`
      exposes `canExportLaTeX` (available × present), async `exportLaTeXPDF`, `.tex`-source export, and a PDFKit
      page count; the `ApplicationSheet` per-document submenus gain **"PDF — Portfolio (LaTeX)"** + **"LaTeX
      source (.tex)"** (the PortfolioBuddy handoff, works without TeX), a "requires a TeX install" note, a
      compile spinner, and an error/overflow banner. One-page gate reconciled to the compiled PDF's real page
      count. Verified by a guarded real end-to-end compile through the use case. Seam: Business + Presentation.
      On-device: yes (compile needs the local TeX install).
- [x] **Milestone E — Availability surfacing, docs, release hygiene.** ✅ **Done.** `lualatex` availability shows
      in Settings → About (probed in `Composition`, flagged on `SettingsViewModel`); `CLAUDE.md` documents the
      second optional binary + `Infrastructure/Process/` + `Infrastructure/Tex/` + `lib/tex/`; `SPEC.md` notes
      the LaTeX PDF path; `README.md` has the v0.5.1 summary and a forward-pointing Next line;
      `MARKETING_VERSION` = `0.5.1`. Seam: Presentation (read-only display) + docs. On-device: n/a.
- [x] **Milestone F — Render Markdown thematic breaks (`---`) instead of printing them literally.** ✅ **Done.**
      An **independent bug fix** to the existing native renderer (not part of the LaTeX path): the generated
      Markdown's `---` section separators print as literal `---` in the PDF/DOCX/preview because
      `MarkdownBlockParser.classify` has no thematic-break case and falls through to a paragraph. Add a
      `.thematicBreak` block (3+ `-`/`*`/`_`, whole-line, detected before the bullet rule) and render it as a
      thin rule in `MarkdownAttributedRenderer` (PDF), `OOXMLDocument` (DOCX), and a `Divider` in `MarkdownText`
      (in-app preview) — the compiler flags all three exhaustive switches. Seam: `Infrastructure/Text` +
      `Infrastructure/Export` + one Presentation component. On-device: yes (pure local rendering).
- [x] **Milestone G — Export the résumé and cover letter as separate documents.** ✅ **Done.** An **independent
      export refinement**: `ExportApplicationUseCase.assembleMarkdown` merged both into one file. Split export so
      each is its own named deliverable (`<Company> - <Role> - Résumé.<ext>` / `… - Cover Letter.<ext>`) via an
      `ApplicationDocument` selector on the use case, per-document `exportData`/filenames/Copy in
      `ApplicationViewModel`, and Résumé / Cover Letter groups in the `ApplicationSheet` export menu — which
      also aligns the native path with the LaTeX path (C/D already emit two files). Seam: Business
      (`ExportApplicationUseCase`) + Presentation (`ApplicationViewModel`, `ApplicationSheet`). On-device: yes
      (pure local assembly + export).
- [x] **Milestone H — Sort control in the Tracker.** ✅ **Done.** Mirror the Results tab's live `ResultsFilter` with an
      interactive **sort** in the Tracker: a pure, unit-tested `TrackerSort` (sort key + direction) the view
      holds and applies live over `TrackerViewModel.jobs(in:)`, composing with the existing per-stage tab
      filter. Folds today's load-time ordering (recent status activity) into the default sort; adds keys like
      date applied, stage, match score, company, and title. Seam: **Presentation only**
      (`Tracker/View/TrackerSort.swift` + `TrackerViewModel` + `TrackerView`), paralleling
      `Results/View/ResultsFilter.swift`. On-device: yes (pure local sort, session-only).
- [x] **Milestone I — Additional-context text box on the generate / regenerate flow.** ✅ **Done.** A free-text
      box in the Application view's generation-options panel to **steer generation** ("lean into the API-gateway
      angle"), behaving like the Portfolio "Regenerate description" prompt but feeding the application. Rides the
      existing `settings:` thread as `GenerationSettings.additionalContext` (excluded from `Codable`/presets,
      counted in `isDefault`); `Prompts` appends an "additional user guidance" block (empty = byte-for-byte the
      base prompt); threaded through `GenerateToTargetUseCase` + `ApplicationViewModel` + `ApplicationSheet`.
      Steers emphasis/framing only — grounding + fidelity rules still bind. Seam: Data (`GenerationSettings`,
      `Prompts`) + Business (`GenerateToTargetUseCase`) + Presentation. On-device: yes.

## v0.6.0 — richer grounding, job detail & sources  (complete)

The theme: give ranking and — especially — tailored résumé/cover-letter generation **more real signal
to work from**, and **more (and better-fed) sources to get it from**. Eleven milestones. The first three
(**A–C, complete**) improve grounding: capture and surface **much more of a job posting** (Milestone A),
let the user **choose which profile to ground on** and generate against its real source documents
(Milestone B), and **regenerate a saved result** against a chosen profile so stale/legacy entries can be
refreshed (Milestone C). The next three (**D–F, planned**) widen the pipe: make API keys **user-editable
in Settings** (Milestone D — the foundation the rest lean on), capture the **full posting text** instead of
Adzuna's truncated snippet (Milestone E), and **aggregate multiple job providers** behind `JobSource`
(Milestone F). **Build order for D–F: D first** (it stands up the per-provider credential seam E and F
both need), then E, then F. Two follow-on milestones (**G–H, complete**) build on that credential seam:
per-provider **credential-setup help** in Settings (Milestone G), and a **provider selector** in the Search view
so the user picks which API(s) to query — both driven by **one data-driven provider registry** so new providers
appear everywhere automatically (Milestone H). A ninth milestone (**I, complete**) lets a profile carry **additional
supporting documents** — e.g. a full career portfolio — baked in as factual grounding for richer search + generation.
A tenth (**J, complete**) adds an **LLM-backed job source** — find leads from the résumé, labelled *AI-suggested*
(leads, not verified postings) — wired in beside the API providers with its own engine in the task-engine map. An
eleventh (**K, complete**) **standardizes result descriptions** — LLM-digests *every* posting (whatever the source:
Adzuna snippet, JSearch full text, page-fetch, or thin input) into one canonical `PostingDetails` format, rendered
the same way, so results read consistently and generation grounds on a uniform structure.
**Transparency to the user** holds throughout (the app makes clear what's real vs. generated), but there's **no
hard never-fabricate rule** — fabrication is an accepted capability: enrichment *structures* what a posting says,
re-ranking *re-assesses fit honestly*, and generated / LLM-sourced content is **surfaced as such** so the user
knows what's real vs. generated.
Milestones restart at **A** and commit as `v0.6.0 : Milestone X Completed`. `TODO.md` has the granular
breakdown + open calls.

- [x] **Milestone A — Richer job postings (capture & surface full posting detail).** ✅ **Done (A-A…A-F).** A search result keeps
      very little today — `JobListing` is only `id/title/company/location/description/url/salary`, and the
      Adzuna `description` is often a truncated snippet. Capture **job type** (full/part-time, contract,
      permanent) and **posted date** cheaply by decoding Adzuna's `contract_type` / `contract_time` /
      `category` / `created` (`AdzunaJobSource.Job` decodes none today), and the richer **work type**
      (on-site/remote/hybrid) + **structured sections** (qualifications, about-the-role, about-the-company,
      responsibilities, benefits) via an **LLM enrichment pass** (grow `ExtractedPosting` or add an
      `enrichPosting` sibling → new `@Generable` `PostingDetails`), optionally over the **full posting page**
      (reuse `LinkJobPostingSource`, snippet fallback). Persist the new fields (back-compatible,
      decode-with-defaults) and thread them into `buildTargetBrief` / `generateApplication` + `Prompts` — the
      payoff — and surface them in `JobDetailView` (badges + collapsible sections) and `RankedRow` chips.
      Seam: Data (`JobListing` / new `WorkType` + `PostingDetails`) + Jobs (`AdzunaJobSource`) + LLM
      (`ExtractedPosting`/`enrichPosting` + `Prompts`) + Business + persistence + Presentation. On-device:
      Adzuna decode is pure/local; enrichment is `.extraction` LLM work (on-device-friendly; Claude when
      chosen); the optional full-page fetch needs network. Guardrail: extract/organize only, never invent.

- [x] **Milestone B — Select a profile at generation time and ground on its source documents.** ✅ **Done.** Grounding is
      tied to the single currently-loaded/default profile today (`PortfolioViewModel.grounding` →
      `AppSession.grounding` → `ApplicationWindow` → `JobDetailView` → `ApplicationSheet`), with a silent
      fall-back to profile-summary-only when grounding wasn't set up. Add an **explicit per-generation profile
      picker** so the user chooses which saved profile to generate against, and guarantee the chosen profile's
      **real source documents** ground the output. Lift `PortfolioViewModel.grounding` into a reusable
      `SavedProfile.grounding` mapper (any saved profile → its `PortfolioGrounding`); add a picker to the
      generation-options panel (populated via `LoadProfilesUseCase`, defaulting to the `DefaultProfileStore`
      profile); thread the chosen profile + grounding through `ApplicationViewModel.generate(...)`. Seam:
      mostly Presentation (picker + wiring) + a small Data mapper — reuses the existing `PortfolioGrounding`
      seam, no new generation seam. On-device: yes (local profile load + grounding; bound the injected source
      text). Guardrail: résumé source grounds facts; cover-letter source stays a voice/tone exemplar only.

- [x] **Milestone C — Regenerate result (re-rank & re-enrich a saved job against a chosen profile).** ✅ **Done (C-A…C-C).** Mirror
      the regenerate-application flow with a **"Regenerate result"** action on a saved job: re-run the fit
      assessment (`JobMatch`) — and, where A's enrichment exists, re-enrich the `JobListing` — against a
      **chosen profile**, with an **additional-context** field to steer the re-assessment. The motivating
      case is **legacy entries** ranked against an older profile and lacking the richer posting fields.
      Ranking is batch + context-free today (`JobRanker.rank` → `LLMProvider.rank(jobs:against:)`); add a
      **single-job re-rank with an optional instruction** (a forwarding-default `LLMProvider` overload +
      `Prompts` guidance block, exactly how `generateApplication` grew `grounding:`/`settings:`), persist via
      `SavedJobsRepository.save` (latest-wins upsert), and add the action to `JobDetailView` with the shared
      profile picker (from B) + context box (shared with v0.5.1 Milestone I). Seam: Presentation + Business
      (new `RegenerateResultUseCase`) + Data/LLM (single-job re-rank overload + `Prompts`; enrichment optional)
      + persistence. On-device: yes (LLM re-rank on the chosen engine; local persist). Guardrail: re-rank
      re-assesses fit honestly (may raise *or lower* the score); context steers emphasis, not fabrication.

- [x] **Milestone D — User-editable API credentials (build first).** ✅ **Done (D-A…D-D).** Adzuna's `app_id` / `app_key` are baked
      in at build time (`Secrets.xcconfig` → Info.plist → `BundleAppConfig` → `AppConfig`), so only a build with
      the secret file can search and there's no in-app fix. Re-integrate credentials as **user-entered
      settings**: add a `KeychainStore: KeyValueStore` (Infrastructure/Store) so secrets stay out of the
      `UserDefaults` plist; a provider-keyed `JobSourceCredentialsStore` (Data/Settings) so Adzuna and future
      providers share one mechanism; resolve **user value → build-time `AppConfig` fallback → absent** live in
      `SettingsBackedJobSource` (`Composition.swift:303`); and replace the read-only `adzunaConfigured` status
      with editable `SecureField` id/key in `SettingsViewModel`. **This is the foundation** the multi-source
      work (F) needs — each provider gets a key field. Seam: Infrastructure (`KeychainStore`) + Data (credentials
      port) + Presentation (Settings) + composition-root rewire; flips the "credentials are build-time" doc
      comments (`AppSettings.swift:14`, `AppConfig.swift`). On-device: n/a (local storage). Safety: the app
      builds the *field*; the user enters keys — the agent never pastes real keys.

- [x] **Milestone E — Full job-posting text (not Adzuna's snippet).** ✅ **Done (E-A…E-D).** The Adzuna `/search` `description` is
      truncated (~500 chars, ends in `…`); the full body isn't in the API response, so no decode recovers it.
      Recover it via a **full-page fetch behind the redirect URL** — reuse `JobPostingSource.readableText(from:)`
      (`LinkJobPostingSource`) against `JobListing.url`, snippet fallback on `.unreadable` — store it as a
      first-class `JobListing.fullDescription`, persist it (decode-with-defaults), and feed it into
      `buildTargetBrief` / `generateApplication` + `Prompts` so tailoring works from the whole posting.
      **Sharpens Milestone A** (which structures a posting via LLM but under-specifies capturing the full raw
      text). Seam: Data (`JobListing`) + reuse Jobs fetch + persistence + generation `Prompts` + `JobDetailView`.
      On-device: page-fetch needs network; storage/display local. Guardrail: full text is captured verbatim;
      any structuring organizes, never invents.

- [x] **Milestone F — Multi-source job search (aggregate providers behind `JobSource`).** ✅ **Done (F-A…F-D).** Too-few-results
      means we've hit Adzuna's index ceiling for a query, not a paging bug — the fix is **more sources**. Add
      provider conformers in `Data/Jobs/` (each keeping its API types private, per the Adzuna pattern) — **JSearch
      via RapidAPI first** (a Google-for-Jobs aggregator whose rich structured response also feeds A/E), then The
      Muse / remote feeds as drop-ins — behind a new `CompositeJobSource: JobSource` that fans out over providers
      with bounded concurrency and merges, wired at `SettingsBackedJobSource` (`Composition.swift:303`). The one
      real wrinkle: **cross-source de-dup** — `JobListing.id` is source-specific, so add a normalized
      `JobListing.fingerprint` (title+company+location, or redirect host+path) for the merge, keeping the source
      id for persistence. Depends on **D** for per-provider keys. Seam: Data (provider gateways + `CompositeJobSource`
      + fingerprint) + composition-root wiring. On-device: search needs network (mind metered RapidAPI free tier).
      Guardrail: n/a (data plumbing).

- [x] **Milestone G — Per-provider credential-setup help.** ✅ **Done (G-A…G-C, on H-A's registry).** With keys now user-entered (D), each provider's
      `SecureField` needs a **"How to get a key"** link (+ optional inline steps). **D-D already shipped the Adzuna
      link**; generalise it so every provider — including F's JSearch — draws its help from **one source of truth**:
      add `setupURL` (+ optional `setupSteps`) to the per-provider descriptor (H-A's registry) and render a
      descriptor-driven `Link` per provider sub-section in `SettingsView`, dropping the hardcoded Adzuna literal.
      Seam: Data (descriptor metadata) + Presentation (Settings). On-device: n/a — static metadata + a browser
      `Link`. Safety: links to official signup pages only; the app never creates accounts or enters keys.

- [x] **Milestone H — Provider selector in the Search view.** ✅ **Done (H-A…H-E).** F queries *every* configured provider; let the user
      **pick which API(s)** to search, from a picker that lists **all registered providers and grows automatically**
      as new ones are added (no hardcoded list). Core piece: formalise the per-provider descriptor as an
      **enumerable registry** (Data — id/displayName/credential spec/`setupURL`/`JobSource` factory) that
      `CompositeJobSource`, Settings (D/G), **and** the picker all read. Add `JobSearchRequest.sources: [String]?`
      (`Codable`, nil ⇒ all available; keeps old `SavedSearch`es valid), build it in `SearchViewModel.buildRequest()`,
      have `SearchAndRankUseCase` run only the selected providers, add the selector to `SearchView` (unconfigured
      rows disabled + link to Settings), and generalise the `adzunaConfigured` search gate to "≥1 *selected* provider
      configured". Depends on **D** (configured signal); extends **F**. Seam: Data (registry + request field) +
      Business (selection filter) + Presentation (picker). On-device: search needs network; registry/selection local.

- [x] **Milestone I — Supporting profile documents (bake extra career docs into a profile).** ✅ **Done (I-A…I-E).** A `SavedProfile`
      carried only two documents — the résumé source (distilled + factual grounding) and an optional cover
      letter (voice exemplar, never distilled). Now a profile attaches **additional file(s)** — e.g. a complete
      career portfolio — as **factual grounding** for both **ranking/search** and **generation**. Generalises the
      existing doc handling: add `supportingDocuments: [SupportingDocument]` to `SavedProfile` (decode-with-defaults,
      back-compatible), import + tidy each via the existing `ImportPortfolioUseCase` / `TidyDocumentUseCase`, add a
      bounded `PortfolioGrounding.supportingText` that flows through Milestone B's grounding threading, and — for
      ranking — distil the docs into a richer `CandidateProfile` at build time. UI: a multi-file slot on the
      Portfolio tab. Bound all injected text; the large-portfolio case is the natural driver for the Backlog **RAG**
      seam (`Retriever`/`EmbeddingClient`) as a follow-on. Seam: Data (`SavedProfile` + `PortfolioGrounding`) +
      Business (build/tidy) + Presentation (upload). On-device: import/tidy are `.profile` LLM work. Note:
      supporting docs are real, user-supplied grounding — they add signal, not invention. Scheduled from `PLANNED.md` 2026-07-15.

- [x] **Milestone J — LLM job source (find jobs from your résumé, no API required).** ✅ **Done (J-A…J-F).** Search needed an API key
      (Adzuna / JSearch); an LLM can surface roles straight from the résumé/portfolio (the "paste your résumé into a
      fresh Claude session and it finds jobs" workflow). Now an **LLM-backed `JobSource`** is wired in as a first-class
      source — in **Settings → Sources** and the Milestone H **provider selector** — and give it its own **engine**
      via a new `LLMTask.jobSearch` (which auto-appears in the engines menu, since it iterates `LLMTask.allCases`).
      Add `LLMProvider.searchJobs(query:grounding:)` (forwarding default; Claude + on-device impls; `LLMRouter`
      routing), a `JobProvider.llm` case (**no credentials**), and an `LLMJobSource: JobSource` (grounded on the
      selected profile via a closure, since the profile lives above the `JobSource` seam). Register `.llm` in
      `JobProviderRegistry` — extending its descriptor factory, which currently builds only credential+HTTP API
      sources — and gate its availability on **engine-availability**, not credentials. **Transparency:** results are
      **AI-suggested leads**, labelled as such and linking to a *search* rather than presenting an unverified URL as
      a confirmed live posting — so the user knows these are AI suggestions, not confirmed openings (fabrication is
      fine; misleading the user isn't). Open calls: lead-URL presentation; whether the `claude -p` provider has
      web-search tooling (verify at build); count/dedup (reuse F's
      `JobListing.fingerprint`). Seam: Data (LLM task + provider + `LLMJobSource` + registry) + Presentation
      (Sources + selector labelling). On-device: `.jobSearch` runs on-device or Claude — no API key. Scheduled 2026-07-15.

- [x] **Milestone K — Standardized result descriptions (digest every posting into one format).** ✅ **Done (K-A…K-E).** Descriptions were
      **inconsistent** (Adzuna's ~500-char snippet, JSearch full text, varying page-fetches) and enrichment ran only
      **on save-to-Tracker** (`ResultsViewModel.enrichSavedJob`), so the list / detail / grounding never got it.
      Fix: as part of search, **LLM-digest every result into one canonical format** — the existing `PostingDetails`
      sections — and render a **standardized description** from it, so every result reads the same *whatever the
      source* and generation grounds on a uniform structure. Inject `EnrichPostingUseCase` into `SearchAndRankUseCase`
      (bounded concurrency, reuse `searchAll`'s window); make it **always** structure — from the fetched page when it
      works, **else the snippet + Adzuna fields anyway** — dropping the "keep snippet / skip already-full" no-op so
      **even full JSearch text is normalized** (one format everywhere); add a pure `PostingDetails.standardDescription`
      renderer as the displayed description; persist + show progressively. **Decisions:** reuse `PostingDetails`,
      always digest every result. ⚠️ Cost: **one LLM call per result** (the skip-already-full saving is gone) —
      guards are the bounded window, **caching** (never re-digest a job with `details`), and progressive display. Seam:
      Business (`SearchAndRankUseCase` + `EnrichPostingUseCase`) + Data/Text (renderer) + Presentation (progressive
      Results). On-device: `.extraction` LLM + page-fetch; the digest **normalizes** the posting (a normalized digest,
      not verbatim, where the source is thin). Scheduled 2026-07-15.

## v0.6.1 — keyword match & ATS coverage  (complete)

A **patch release** on shipped v0.6.0, scheduled out of `PLANNED.md` (its sole `Target: v0.6.1` entry). The
theme: ATS / AI résumé screeners filter on a posting's keywords, and good candidates get auto-rejected for
missing a few. The answer here is **visible-text-only** — explicitly **not** hidden "invisible-ink" white-text
keyword stuffing, which backfires (ATS parse to plain text, recruiters see it, LLM screeners flag it) — so the
app **shows** how well the generated résumé covers the posting's **real** keywords and lets the user align
truthfully. Most of the data already exists: the posting's keywords are distilled into `TargetBrief` at
generation stage 1, and the résumé is `ApplicationKit.resumeMarkdown`. Four milestones **A–D**, in build order;
milestones restart at **A** and commit as `v0.6.1 : Milestone X Completed`. **No new seam and no `LLMProvider`
change.** An **ATS-friendly export mode** (standard headings, single-column, selectable text) is the natural
companion but is **out of scope** — spec it separately if wanted. `TODO.md` has the granular breakdown +
open calls.

- [x] **Milestone A — `KeywordCoverage`: pure covered-vs-missing computation.** ✅ **Done.** A pure, `Sendable`,
      unit-tested value type (Data · Models) that answers "how much of this posting's keyword set actually
      appears in the generated **visible** résumé?" — given `TargetBrief`'s three tiers (`mustHaveKeywords` /
      `niceToHaveKeywords` / `techStack`) and `ApplicationKit.resumeMarkdown` reduced through
      `MarkdownPlainText.plainText(from:)` (Infrastructure — a legal downward use), it returns per-tier
      covered/missing plus a must-have "X/Y covered" headline and all-tier roll-ups. Matching is
      case-insensitive, diacritic-folded, whitespace-collapsed (so a phrase matches across a line break) and
      **word-boundary** — scanned directly rather than by regex, because `\bC\+\+\b` never matches "C++", while
      the scan keeps "Go" out of "Google". No stemming or synonyms (over-matching would report coverage the user
      lacks); a keyword repeated across tiers counts once, in its highest tier. Distinct from
      `JobMatch.matchedSkills` / `missingSkills`, which score the *profile* rather than the generated text.
      Seam: Data (new model) only. On-device: n/a — pure local string matching, no model call.

- [x] **Milestone B — Surface the `TargetBrief` out of generation.** ✅ **Done.** The posting's keywords existed
      only *inside* generation and were thrown away: `GenerateApplicationUseCase` built the brief and returned just
      the `ApplicationKit`, `GenerateToTargetUseCase.Outcome` carried no brief, and `SavedApplicationsRepository`
      persisted only the kit — so a reopened saved kit had no keywords either, and A's computation had no input.
      Both use cases now return an `Outcome` pairing kit **+** brief, and `ApplicationViewModel.brief` is held in
      lockstep with `kit` (cleared on a failed regeneration, so no stale brief survives its résumé). The open call
      resolved to persisting the brief — but **inside the kit's own record**, as a `{kit, brief}` envelope under the
      existing `applicationKit` kind rather than a sibling repository: coverage compares a résumé against the brief
      that produced it, so one latest-wins record can't let them drift apart, `DeleteSavedJobUseCase` already
      forgets both, and no new composition wiring is needed. Legacy bare-kit records still decode (brief nil →
      coverage unavailable, not wrong). Seam: Business + Data/Persistence + Presentation; **no `LLMProvider`
      change**, so nothing to forward in `SettingsBackedLLMProvider`. On-device: n/a — reuses the existing stage-1
      call, no extra LLM work.

- [x] **Milestone C — Coverage panel in the Application view.** ✅ **Done.** The generated result now shows
      **"Posting keywords: X/Y must-haves covered"** with the covered list (green) and missing list (amber) per
      tier, computed on the **visible** résumé and recomputed after each generate/regenerate. A `coverage`
      computed property on `ApplicationViewModel` (`kit` + `brief`, both `@Observable`, so no refresh plumbing and
      no state to invalidate) plus a `coverageSection` in `ApplicationSheet.content`, styled with the existing
      `documentSection` / `disclosuresSection` / `gapsSection` family and reusing `JobDetailView.skillRow`'s
      capsule language for the keyword lists. Placement resolved as recommended — below the documents, above the
      disclosures/gaps. `coverage` is `nil` (and the section simply isn't rendered) for all three empty cases: no
      kit, no brief, or a posting with no keywords — never a misleading "0/0"; the headline falls back to the
      all-tier count when a brief named no must-haves. Seam: **Presentation only**. On-device: n/a — local
      rendering.

- [x] **Milestone D — Optional keyword-emphasis generation control.** ✅ **Done.** An **opt-in** control telling
      generation to weave the posting's must-have keywords into the **visible** résumé **where they truthfully
      apply**, and route the rest into `gapNote` so the user sees what's missing and decides. Report-only stays the
      default (A–C change nothing about what's generated). A dedicated `GenerationSettings.emphasizeKeywords` flag
      — **not** a `TailoredAspect` case as `PLANNED.md` suggested, because `TailoredAspect` is documented and
      prompted as a *résumé section* ("tailor ONLY these résumé sections — …") and a non-section case would
      corrupt that sentence and the preset semantics — added to `CodingKeys` and to `hasDefaultControls` so the
      default prompt stays byte-for-byte. Presets persist it via a hand-written `init(from:)` that
      `decodeIfPresent`s the key, since synthesized decoding would have broken every pre-v0.6.1 preset.
      `Prompts.generationControls` sharpens its existing keyword Objective line into an explicit
      cover-it-or-declare-it instruction that also forbids hidden/bulk keyword lists; a checkbox joins the
      generation-options panel. Both open calls resolved as recommended: the flag is threaded through the
      rank-target loop (as `additionalContext` already was — the target overrides *latitude*, and this isn't a
      latitude control, so the checkbox also stays enabled there), and only **must-have** keywords are pushed.
      **No hidden text** — the deliberate opposite of the invisible-ink idea this replaces. Seam: Data
      (`GenerationSettings` + `Prompts`) + Business (`GenerateToTargetUseCase`) + Presentation. On-device:
      `.application`-task LLM work on the existing engine — no new engine or seam.

## v0.6.2 — list actions, sorting & document previews  (complete)

A **patch release** on shipped v0.6.0/v0.6.1, scheduled out of `PLANNED.md` (all five of its `Target: v0.6.2`
entries, 2026-07-28). The theme is **the two list tabs and the Portfolio document previews**: the Tracker's
removals already work but are swipe-only and undiscoverable on macOS; Results can only act one row at a time; each
list tab has exactly one of sort/filter and not the other; and the source-document previews are truncated twice
over (a 220pt UI cap *and* a real content truncation at tidy time). Five milestones **A–E**; milestones restart at
**A** and commit as `v0.6.2 : Milestone X Completed`. **Almost entirely Presentation** — the sole exception is E's
content fix (`Prompts` / `TidyDocumentUseCase`). **No new seam and no `LLMProvider` change.** `TODO.md` has the
granular breakdown + open calls.

- [x] **Milestone A — Discoverable remove-from-Tracker.** ✅ **Done.** The Tracker *already* supports both removals —
      leading-swipe "To Results" → `TrackerViewModel.returnToResults` (via `UntrackJobUseCase`) and trailing-swipe
      "Delete" → `.delete` (via `DeleteSavedJobUseCase`) — but they're **swipe-only**, an iOS pattern that's
      undiscoverable on macOS, so in practice there's "no way to remove a result from the Tracker." The gap is the
      **affordance, not the behaviour**: a right-click `contextMenu` (Return to Results / Delete), **always-visible**
      row icons matching the Results tab (mirroring it *is* always-visible — its icons render unconditionally — and
      hover-only would still be semi-hidden, the very problem), a "Remove" menu in the open job's detail footer, and
      the swipes kept as a secondary path. One shared `.confirmationDialog` now backs **every** delete path
      including the swipe, which previously deleted outright; Return to Results stays unconfirmed (nothing is lost).
      Seam: **Presentation only** (`TrackerView` / `JobDetailView` / `JobDetailWindow` over the existing VM + use
      cases; `Composition.untrackJob` / `.deleteSavedJob` un-privated) — no Business/Data change. On-device: n/a.

- [x] **Milestone B — Multi-select results: bulk save-to-Tracker / delete.** ✅ **Done.** Both list tabs acted one
      row at a time, so triaging a 30-result search meant 30 individual saves or deletes. `selectedIDs: Set<String>`
      + `saveSelectedToTracker()` / `deleteSelected()` on `ResultsViewModel` (batching the listings through
      `SaveResultsUseCase`, looping the per-id status/delete use cases, keeping the per-row no-downgrade rule), plus
      a bulk action bar — "N selected · Save to Tracker · Delete · Clear" — with a **counted** confirm on delete.
      Selection acts only on **shown** rows (`selectedJobs` derives from `filteredResults`), so a row the filter has
      hidden can't be silently removed. The primary open call resolved as recommended — **native
      `List(selection:)`** (⌘/shift-click), which moves opening the detail to **double-click** via a
      `simultaneousGesture` so the single click still reaches the List. The Tracker open call also resolved as
      recommended: the same pattern is **mirrored there** (bulk Return to Results / Delete), so both tabs share one
      interaction model. **Bulk-save enrichment is bounded** — `enrichSavedJob` became `enrichSavedJobs([RankedJob])`
      running the batch through the same sliding window as `SearchAndRankUseCase.digestStream` (≤4 in flight), with
      the single-row save now its one-element case. Seam: **Presentation only** over existing use cases. On-device:
      `.extraction` enrichment per saved job, unchanged in cost but capped in concurrency.

- [x] **Milestone C — Results sort + Tracker filter (parity across both tabs).** ✅ **Done.** Each list tab had one
      half of the pair: Results a live `ResultsFilter` but no sort, the Tracker a live `TrackerSort` but no filter.
      A useful asymmetry decided the approach — `ResultsFilter.matches(_:isTracked:)` is already `RankedJob`-generic
      and `TrackedJob` wraps one, so the Tracker **reuses** it (filter alongside the stage predicate in `jobs(in:)`,
      before the sort, with the moot `trackedStatus` facet hidden); `TrackerSort`'s status keys don't exist for
      Results, so Results got a **parallel `ResultsSort`** — same shape, keys match score (default = the ranker's
      own order, so an untouched list is unchanged), company, title, salary, posted date — applied after the filter
      in `filteredResults`. Unknown salary/date sorts **last in both directions**, matching `TrackerSort`'s undated
      rule. `ResultsView.filterBar` was extracted to a shared **`ListFilterBar`** (Presentation · Components) both
      tabs render, so the parity can't drift into two diverging copies; the Tracker's "no rows" state now
      distinguishes a **filtered-empty tab** (bar stays, Clear offered) from an **empty stage**. The two sort bars
      stay separate — sharing them would mean churning `TrackerSort` for ~30 lines. Seam: **Presentation** only —
      both are pure, session-only, non-destructive view state. On-device: n/a.

- [x] **Milestone D — Hide the raw-text preview for imported source documents (keep paste).** ✅ **Done.** Each
      Portfolio résumé/cover-letter slot (`documentSlot`) had a "Show text" toggle revealing a raw `TextEditor` of
      the extracted text — noise for an **imported** file, where the user only wants the tidied Source Documents
      view after Build Profile. The editor is now gated on the `fileName: String?` the slot already knew: imported →
      a one-line summary (name, character count, and where the tidied form appears) with **Clear** and
      **Replace…**; pasted (`fileName == nil`) → the editor unchanged, so pasting still works. Clear was the open
      call, resolved as recommended — without it an import is **un-undoable in-slot**, since importing is what hides
      the editor; `clearDocument()` / `clearCoverLetter()` drop the file name and its text but deliberately leave a
      previous build's `sourceText` / `readableText` alone (those belong to the built profile). No read-only snippet
      of the raw text, per the second open call. Brings these slots in line with the already-editorless
      supporting-documents slot (v0.6.0 I). Seam: **Presentation only** (view conditional + two VM setters) — no
      Business/Data change. On-device: n/a.

- [x] **Milestone E — Full source-document preview (remove both truncations).** ✅ **Done.** The preview truncated
      **twice**: a `.frame(maxHeight: 220)` in `documentDisclosure` that merely *looked* cut off, and the real one —
      `Prompts.tidyDocument(rawText:)` bounded its input to `maxPortfolioCharacters` (6 000), so a long document's
      stored `readableText` was genuinely shorter than the original and dropping the UI cap alone would have
      revealed nothing. Both fixed: the nested `ScrollView` is **removed** (the tab already scrolls, and the
      nesting was what boxed the text in), and tidying gets **its own larger bound** —
      `Prompts.maxTidyDocumentCharacters` (12 000, matching `maxPageCharacters`) rather than a global raise, since
      the 6 000 cap also bounds text injected alongside other content at four other call sites.
      `TidyDocumentUseCase` now splits the document itself, tidying the head and **appending anything beyond the
      bound as-extracted** behind a short notice — so the stored text is tidied where it could be and **complete
      regardless**, never silently short. A chunked full-tidy remains the nicer-but-larger follow-on. Seam:
      Presentation + Data/LLM (`Prompts`) + Business (`TidyDocumentUseCase`). On-device: twice the input for one
      document on the `.profile` task, still bounded; the appended remainder costs no model work.

## v0.7.0 — customizable LaTeX document styles  (complete)

A **feature release**, scheduled out of `PLANNED.md`'s single `Target: v0.7.0` entry (2026-07-28). The theme is
**user-owned document presentation**: the awesome-cv LaTeX route (v0.5.1) is one fixed template with every
presentation choice hardcoded in `TexDocumentBuilder` — class + font size, `\geometry`, `\fontdir`, section order
and spacing, and a separate cover-letter documentclass. This release replaces those literals with **named,
reusable `LaTeXStyle`s** chosen at export time, backed by an enumerable built-in template registry, plus a
**raw-LaTeX preamble escape hatch** for power users. Six milestones **A–F**; milestones restart at **A** and
commit as `v0.7.0 : Milestone X Completed`. **Not Presentation-only** — A–C + F are Infrastructure/Tex, D is
Data/Persistence, E is Presentation. Distinct from the native `ExportTemplate` (Core Text PDF/DOCX), which is
untouched. Styles theme **presentation only** on the generated path — the body is always app-generated and escaped, and the
app never writes user or model data into a preamble. (Milestone F's hand-written override is user-authored LaTeX
and *can* affect typeset content; it can't run shell commands.) `TODO.md` has the granular breakdown + open calls.

- [x] **Milestone A — `LaTeXStyle` model + built-in template registry.** ✅ **Done.** The style had no home —
      every choice was a literal in `TexDocumentBuilder`'s preamble builders. Added a pure
      `nonisolated`/`Sendable`/`Codable` `LaTeXStyle` (template id, font family, per-document base sizes, accent,
      page size, margins, the letter's `parskip`/`linespread`, `sectionOrder` / `hiddenSections` /
      `sectionSpacingEm`, optional `customPreamble`) plus the formatting helpers B/C consume, and a data-driven
      `LaTeXTemplateRegistry` in the `JobProviderRegistry` shape — descriptors pairing the bundled classes (via
      `TexAssets`) with a default style, `descriptor(for:)` total, `available(in:)` fail-soft. Two templates ship:
      the shipped awesome-cv look, whose default **is** `LaTeXStyle.default` (byte-identical to today, which is
      what makes B and C safe), and a **Compact** variant reusing the same classes. Font family / accent / page
      size each carry an explicit `.templateDefault` case so "unchanged" is a real state rather than a forced
      choice. Font size stays **per document** (6pt résumé / 11pt letter): the two classes scale off their base
      differently, so one shared number would render as two unrelated sizes. The tests surfaced one **deliberate
      divergence** — the builder sorts "Employment"/"Work History" as experience but spaces them as "other", and a
      style's single bucket unifies that — pinned by its own test so C's byte-for-byte claim stays honest.
      **No behaviour change yet**; the builder is untouched. Seam: **Infrastructure/Tex**. On-device: n/a.

- [x] **Milestone B — Parameterize `TexDocumentBuilder` typography, geometry, colour & page size.** ✅ **Done.**
      Both preambles now come from a shared `preambleHead(for:style:)` — document class + options from the
      template descriptor and the style's per-document base size and page size, `\geometry` from its margins, then
      optional font-family and accent overrides — with the letter's `\parskip`/`\linespread` style-driven too.
      **One style covers both documents:** the résumé-vs-letter paper asymmetry moved to the *template*
      (`templateDefaultPaperOptions`), consulted only while the style says "template default", so choosing US
      Letter or A4 applies to both. A chosen family emits `\newfontfamily` + `\renewcommand*{\bodyfont}` with
      per-family face suffixes and an explicit `Extension=`; a named accent emits `\colorlet{awesome}{awesome-…}`
      and a custom one `\definecolor`, with a malformed hex emitting nothing rather than an uncompilable line.
      Threaded through `ExportApplicationUseCase.texSource` / `.latexPDF` with a `.default`, so Presentation is
      untouched until E. **No change by default, proven properly:** the pre-change output was captured first and
      is asserted as a **whole-document** golden for both deliverables, and a fully-styled document (custom
      accent, Roboto, US Letter, non-default sizes/margins) is compiled under real `lualatex`. Seam:
      **Infrastructure/Tex** + Business call site. On-device: n/a.

- [x] **Milestone C — Section order & visibility from the style.** ✅ **Done.** `canonicalOrder` and
      `sectionVSpace` were hardcoded to the hand-authored résumé; both are now style-driven (reorder, show/hide,
      per-bucket spacing) and the two statics were **deleted** rather than kept as delegates — their coverage
      ported to `LaTeXStyleTests` expectation for expectation. Ordering is a **partition** over `sectionOrder`
      (`LaTeXStyle.orderedSections`), not a `sorted(by:)`: the comparator's index tiebreak is undetectable by
      test, whereas the partition makes document order structural and handles a duplicated bucket, an empty
      order, and unnamed buckets by construction (mutation-verified — reversing within-bucket order now fails
      four tests). Open call resolved as recommended: unknown/unnamed buckets **append stably**, never dropped;
      only `hiddenSections` removes anything. Hiding leaves **no double gap** by construction (the `\vspace` is a
      per-iteration prefix), pinned as byte equality against Markdown that never had the section. The lead
      summary stays out of the style's reach — hiding `.other` must not delete it. One deliberate default change:
      "Employment"/"Work History" take the experience `-1.5em` (the old builder's classifiers disagreed);
      Milestone B's golden is otherwise byte-identical and was not regenerated. The **Compact** template's
      tighter section spacing — inert until now — was measured under `lualatex` (it ran the first section's rule
      ~7.6pt into the lead paragraph vs the default's ~2.6pt) and **reverted to canonical**; margins stay its
      differentiator, and E must bound user-entered spacing. Non-finite spacing now formats as `0` rather than
      emitting an uncompilable `\vspace{nanem}`. Seam: **Infrastructure/Tex**. On-device: n/a.

- [x] **Milestone D — Persistence: styles library + default pointer.** ✅ **Done.** `SavedDocumentStyle`
      (id / name / style / `createdAt` — the store guarantees no ordering, so the library sorts for itself)
      through `PersistentRecordStore` via `SavedDocumentStylesRepository` (`kind = "documentStyle"`, mirrors
      `SavedProfilesRepository`), plus a single-id `DefaultDocumentStyleStore` on `KeyValueStore` so "exactly one
      default" holds by construction, three use cases carrying the id/timestamp policy, and private `Composition`
      wiring. Built-ins stay in the registry; the repository holds only user styles. The substance was **tolerant
      decoding**: synthesized `Codable` is all-or-nothing, and because `all()` is best-effort a style that throws
      doesn't error — it vanishes from the library while its row stays in the store, undeletable. `LaTeXStyle`
      (and its two nested value types) gained a field-by-field `init(from:)` — `(try? decode) ?? default` rather
      than `decodeIfPresent`, which still throws on an invalid raw value; collections degrade element-wise; a
      present-but-empty collection is honoured rather than treated as missing; and a `style` that isn't an object
      still throws so `SavedDocumentStyle` can load it as a named, deletable row. A dangling default pointer
      resolves to `nil` rather than falling back to some other style — silently applying an unchosen style would
      change the document the user sends. Seam: **Data/Persistence** + Business use cases + `Composition`, plus
      the decoder in **Infrastructure/Tex**. On-device: n/a.

- [x] **Milestone E — Style-manager UI + export-time picker.** ✅ **Done.** A "Document styles" manager (create / name /
      duplicate / edit / delete, the four control groups) and a style picker on the LaTeX route in
      `ApplicationSheet`'s Export menu, defaulting to the default style and flowing view → `ApplicationViewModel`
      → `ExportApplicationUseCase` → `TexDocumentBuilder`. **LaTeX-only** — the native exports keep
      `ExportTemplate`, and the two pickers must not read as the same control. Open calls: the manager lives in a
      new `SettingsSection` (recommended, over a new sidebar area), and styling previews via a **Preview button**
      rather than live (recommended — a live preview pays the `lualatex` latency per keystroke); both resolved as
      recommended, the second with a number behind it (~4.0s warm, ~8.2s cold). **Every numeric control is
      bounded** and that is the whole safety mechanism: measured, `lualatex` exits 0 on absurd geometry —
      1.6cm text width, twelve pages, negative margins — so there is no compile error to catch. Base size became
      a discrete picker because `[6pt]` is an unused option the classes forward to `article`, which honours only
      10/11/12pt. The picker's `nil` stays a live "follow my default" and a dangling default falls back to the
      built-in look, never to another saved style. The carried-over **`\arraystretch` fix** landed here (grouped,
      not reset — measured 6.99pt → 10.860pt against a 10.859pt no-skills reference), the release's second
      sanctioned golden exemption. Seam: **Presentation** + a Business preview method + the Infra fix.
      On-device: n/a.

- [x] **Milestone F — Raw-LaTeX preamble override + graceful compile failure.** ✅ **Done.** `customPreamble`
      replaces the **style block** — the `\geometry` line plus the font and accent overrides — not everything
      before `\begin{document}`. Three verified reasons: `\documentclass` differs per document while one
      override serves both; `\cventrysolo`/`\cvprojectsolo` live only in the generated preamble and the body
      emits them *data-dependently*, so a displaced definition would compile one résumé and hard-fail the next;
      and `\position`/`\pageFooter` are generated content. The escape hatch still does what it exists for —
      `\pageHeader` is a `\newcommand` and the override precedes it, so `\renewcommand{\pageHeader}{\name{…}}`
      replaces the classes' hardcoded contact details (verified by a real compile). Under the default style the
      block collapses to the same `\geometry` line in the same position, so **both goldens stayed
      byte-identical**. Failure is graceful in three layers: a blank override falls back to the generated block;
      the compile can't hang (`-halt-on-error` is the real guard, and stdin is now `nullDevice`); and the message
      names the preamble as the likely cause. Nobody strands — the manager offers "use the generated preamble"
      and "revert to a built-in" (keeping the row's id, **writing through** because exports read the store), and
      the export banner offers a session-only built-in escape plus the `.tex` source, which is never gated on a
      test compile. **A doc claim was corrected rather than left overpromising**: a hand-written preamble *can*
      affect typeset content; the guarantee is that the body is app-generated and escaped and the app never
      writes user data into the preamble. Seam: **Infrastructure/Tex** + Presentation (manager + export banner).
      On-device: n/a.

## v0.7.1 — bug fixes  (in progress)

A **patch release**, scheduled out of `PLANNED.md`'s single `Target: v0.7.1` entry (2026-08-04). Not a feature
theme: a batch of **18 verified defects** on top of the shipped v0.7.0, which is exactly the `v0.x.y` case in
`CLAUDE.md` → Versioning. They came from a structured audit — five subsystems swept (concurrency/isolation,
persistence/`Codable`, the LLM layer, the search pipeline, Presentation), every candidate then **re-verified
against the source by a pass instructed to refute it**; 20 survived, two pairs were the same defect found twice,
leaving **4 high / 9 medium / 5 low**. They're grouped into eight milestones **by shared root cause**, so each is
one coherent change. Milestones restart at **A** and commit as `v0.7.1 : Milestone X Completed`. **Not
Presentation-only** — the fixes span all four layers. **Provenance caveat:** these are audit findings, not
user-reported bugs — each cites a real `file:line` and survived refutation, but **reproduce before fixing**.
`TODO.md` has the granular breakdown, the per-defect failure scenarios, and the open calls.

- [x] **Milestone A — Stale-async writes corrupt visible state.** Two unstructured async flows assign into shared
      view state with **no staleness check**. The headline: `ApplicationWindow` holds **one** `ApplicationViewModel`
      and re-targets via `.onChange(of: requestID)`, while `generate(...)` runs as an unstructured `Task` that
      assigns `kit`/`brief` unconditionally (`ApplicationViewModel.swift:438`) — so generating for job A and then
      opening job B leaves the window showing **B's header with A's résumé**, and Export writes a file **named for B
      containing A's content**. `loadSaved` also clears `isGenerating` mid-flight, re-enabling Generate. Fix with a
      generation token + cancel-and-replace. Also cross-gate `fetchFromLink`/`search`, which race for `results`
      (`SearchViewModel.swift:421`). Seam: Presentation. On-device: n/a.
- [x] **Milestone B — Results/search handoff in `RootView`.** Three defects in the same `onChange` + badge block,
      all from handing the Results list **wholesale ownership** of `search.results` on every mutation — including the
      v0.6.0-K background digest's per-posting updates. The digest **yanks the user back to Results once per digested
      posting** (25–50 times a minute, `RootView.swift:60`), **resurrects rows the user deleted** (and re-persists
      them, `:59`), and the sidebar badge **counts tracked jobs the list deliberately hides** (`:121`). Fix: fire
      auto-navigation off a one-shot search signal, merge digest updates **by id**, badge from `untrackedResults`.
      Seam: Presentation. On-device: n/a.
- [x] **Milestone C — Stable posting identity.** `ExtractedPosting.swift:47` builds a pasted posting's id from
      `String.hashValue`, which Swift seeds **per process** — so the same posting gets a **different id every
      launch**, and that id is the persistence key everywhere (`RankedJob.id`, saved-jobs upsert, status, application
      kit). Relaunch orphans the saved kit and status, `contains(jobID:)` never matches, and the store gains a
      **duplicate row per launch** instead of upserting. Fix: derive the fallback id deterministically (reuse the
      `fingerprint` normalization, or a SHA-256 digest). Seam: Data. **Do it early — it touches every persistence
      key.** On-device: n/a.
- [x] **Milestone D — Search goal & de-duplication.** Three defects in `SearchAndRankUseCase`: the
      **desired-result-count goal is silently capped at 20** by the ranker's shortlist and the U-D shortfall note
      never fires (it's computed pre-rank, `:138`); **paging toward the goal never starts** when a provider returns
      fewer listings than the requested page size (`:105`); and **cross-source duplicates leak in** because the use
      case de-dupes by source-specific `id` while the composite de-dupes by `fingerprint` (`:104`). Seam: Business.
      ⚠️ On-device/cost: raising the shortlist limit means **ranking more jobs per search** — the cap was also a cost
      guard.
- [ ] **Milestone E — LLM layer correctness.** A **subprocess pipe deadlock** — stdout is drained to EOF before
      stderr is read, so a child that fills the stderr buffer **hangs the LLM call forever** with no timeout and no
      cancellation path (`ClaudeProcessClient.swift:169`; the same fix applies to `LaTeXProcessClient`). The
      **`searchJobs` prompt never names the `leads` wrapper key** the decoder requires, so AI job search
      intermittently returns nothing on the default Claude engine — and fail-soft compositing **swallows the decode
      error entirely** (`Prompts.swift:699`). And the **generated résumé is truncated to the job-description cap
      (2 000 chars) before scoring** (`:414`), so the rank-target loop under-scores its own output, burns all four
      rounds, and **escalates fidelity to the embellished band** — inventing content the user never asked for. Seam:
      Infrastructure + Data. ⚠️ A larger résumé budget means more tokens per scoring round.
- [ ] **Milestone F — Settings wiring.** `DocumentStylesView.reloadStyles()` **has no caller** (`:25`), so v0.7.0's
      headline feature shows "No saved styles yet" on **every launch** despite styles being persisted, never opens
      the default, and duplicates the style on Save. And `llmSourceAvailable` is a **launch-time snapshot**
      (`SettingsViewModel.swift:38`), so changing the AI-job-search engine leaves the source's status and Search
      availability wrong until relaunch — including a search that silently returns nothing. Fix: a `.task` reload,
      and a live availability closure. Seam: Presentation. On-device: n/a.
- [ ] **Milestone G — Portfolio document state.** Clearing an imported **cover letter** then saving leaves the text
      in the persisted record, and **every later generation still feeds it as the voice exemplar** — a silent no-op
      for content (`PortfolioViewModel.swift:192`). And `select()` restores a saved profile's file names but **not**
      its slot text (`:364`), so a loaded profile reads "0 characters" with **Build disabled**, unable to rebuild
      from its own document. Seam: Presentation. On-device: n/a.
- [ ] **Milestone H — Crash guards.** Two `Double`→`Int` overflow **traps**: a large typed salary floor crashes
      during Adzuna URL construction (`AdzunaJobSource.swift:61`), and a 19+ digit entry in the shared Min-salary
      **filter** crashes in both Results and Tracker (`ListFilterBar.swift:55`). Trivial to guard, expensive to hit —
      ship together. Seam: Data + Presentation. On-device: n/a.

## Fast follow (next up)

- Export and saved/re-runnable searches shipped in **v0.3.0**; the profile-cache half of the old
  "Persistence with SwiftData" fast-follow already shipped via `SavedProfile`. **v0.4.0** (navigation
  & shell), **v0.4.1** (fixes & refinements), **v0.5.0** (document generation fixes), **v0.5.1** (LaTeX
  résumé & cover letter output), and **v0.6.0 (richer grounding, job detail & sources)** are complete
  — v0.6.0 shipped **A–K** (A richer job postings, B profile-at-generation, C regenerate result, D user-editable
  credentials, E full posting text, F multi-source search, G per-provider credential-setup help, H Search provider
  selector — the last two on H-A's data-driven provider registry, I supporting profile documents, J LLM job source,
  K standardized result descriptions). **v0.6.1 (keyword match & ATS coverage) is complete** — Milestones
  **A–D** above: a pure `KeywordCoverage` computation, the `TargetBrief` carried out of generation and persisted
  with the kit, the coverage panel, and the opt-in keyword-emphasis control. **v0.6.2 (list actions, sorting &
  document previews) is complete** — Milestones **A–E** above (A discoverable remove-from-Tracker, B multi-select
  bulk actions, C sort/filter parity, D no raw preview for imports, E full source-document preview), scheduled out
  of `PLANNED.md`'s five `Target: v0.6.2` entries. **v0.7.0 (customizable LaTeX document styles) is in progress** —
  Milestones **A–F** above, scheduled out of `PLANNED.md`'s last remaining entry, which is now empty. Candidate
  fast-follows / later themes: an
  **ATS-friendly export mode** (the companion noted but deliberately left out of v0.6.1 — standard headings,
  single-column, selectable text, which is what decides whether an ATS can *parse* a résumé at all); full awesome-cv
  fidelity (C-structured, below); a **bulk re-rank** of legacy entries (the per-result "regenerate result"
  shipped in v0.6.0 Milestone C); further providers for the multi-source seam (The Muse / remote feeds); and
  the deeper Backlog themes (native `LanguageModel` provider seam, on-device embedding RAG, optional MCP tools).
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
