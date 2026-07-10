# Taylor'd Portfolio — Roadmap

How we work: features get discussed in chat, written up here (and in `SPEC.md`),
then handed to the Claude Code session to build. This file is the high-level
running list; `TODO.md` breaks the current target into granular, checkable tasks.
As TODO items land, tick them here too so this stays an accurate progress board.

## v1 — foundation (complete)

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

## v2 — reliability (complete)

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

## v3 — output & polish (current target)

The theme: get the generated materials cleanly *out* of the app (Export), finish the
persistence fast-follow (saved/re-runnable searches), and polish the app that produces
them. A priority **hotfix** (the job-posting URL fetch is broken) comes first, then
Milestones Q (Export), R (Saved searches), S (Polish), T (two-document portfolio),
U (expanded search parameters), V (results ↔ tracker interaction), W (results filtering);
X (templates + one-page gate) is a stretch. **v0.3.0 scope is closed.** The milestone
letters are a catalogue, **not** the build order — see **"Recommended implementation order
(v3)"** in `TODO.md` for the phased sequence (fixes → Export → grounding/search → results
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

- [ ] **Export résumé & cover letter (Markdown / PDF / DOCX).** _Q-A ✅ + Q-B ✅ done — copy,
      Markdown/plain-text, and **PDF** export shipped (domain-agnostic `DocumentExporter` port +
      `RoutingDocumentExporter`, `ExportApplicationUseCase`, an Export menu + Copy on the Application
      sheet). PDF renderer decision: native `NSAttributedString` → Core Text (not WebKit) — sync +
      `nonisolated`, self-contained; coarser layout is the trade-off (see Milestone X). **Q-C (DOCX)
      remains.**_ The flagged
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

- [ ] **Saved / re-runnable searches.** Finish the persistence fast-follow: persist each
      `JobSearchRequest` (titles + shared location + salary floor), list saved searches,
      and **re-run** one later against the current profile through the existing search→rank
      pipeline, deduping against already-seen listings. New `SavedSearchesRepository`
      (Data/Persistence) on Milestone O's `PersistentRecordStore` (new `kind`); save/load/
      delete use cases; re-run reuses `SearchAndRankUseCase`; a Presentation surface on the
      Search screen. The *other* half of the old fast-follow — caching the built profile
      across launches — already shipped via named `SavedProfile`s, so it's **done**.
      On-device: yes — local SwiftData store; the re-run itself hits Adzuna as any search does.

- [ ] **Polish pass.** Make the six-tab app feel finished. Five parts: (1) in-app
      **markdown rendering** of the generated résumé/cover letter (styled text + copy
      buttons) instead of raw markdown; (2) consistent **empty / loading / error states**
      across all tabs (no profile, no results, fetch/generation failure); (3) **results /
      saved-jobs / Tracker cohesion** so "already seen / already generated / applied" reads
      as one history; (4) ✅ **scrollable screens / small-window layout (done)** — the
      Portfolio + Search tabs now scroll via a shared `View.scrollableScreen()` wrapper (the
      trailing `Spacer()` dropped), so lower controls (incl. Search's Fetch button) stay
      reachable at any window size; Results/Tracker/Settings/Application already scroll
      natively; (5) ✅ **saved-profile tile gestures (done)** — long-press *anywhere* on a
      saved-profile tile sets it as default and tap *anywhere* loads it (the dial is now just
      an indicator); the trash button stays independent. Parts 1–3 remain (Phase 5). Seam: mostly
      Presentation (Views + VMs), with small Data/use-case touches for the history joins.
      On-device: yes.

- [ ] **Two-document portfolio (résumé/portfolio + cover letter) as generation grounding.**
      Let the Portfolio tab accept **two** documents — a résumé/portfolio (the existing
      import, now the primary slot) and an **optional cover letter** — and reference both
      when generating a job's tailored materials. The résumé/portfolio stays the *factual*
      grounding: the `CandidateProfile` is still distilled from it, and its real text grounds
      both outputs. The uploaded cover letter is a **voice / tone / structure exemplar** for
      the generated cover letter only — the output mirrors the candidate's real style, but
      facts, metrics, employers, and dates are **never imported from it** (the "never
      fabricate" guardrail holds; facts come from the résumé/profile). Both documents are
      LLM-tidied (`TidyDocumentUseCase`) and carried on `SavedProfile`; generation injects
      their bounded text — the concrete v1 grounding approach in SPEC ("inject the bounded
      portfolio directly"), later upgradable to embedding retrieval over the same documents.
      Cover letter is **optional** and back-compatible with existing single-document profiles.
      Seam: `SavedProfile` (second-document fields), Portfolio input (second importer/paste
      slot), `TidyDocumentUseCase`, `GenerateApplicationUseCase` + `LLMProvider.generateApplication`
      + `Prompts` (grounding injection), and the plumbing carrying the documents from
      Portfolio → Application. On-device: yes — import + tidy + generation are on-device-friendly;
      bound both inputs for the small context window.

- [ ] **Expanded, optional search parameters.** Give the search step more control — every
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

- [ ] **Results ↔ Tracker interaction overhaul.** Change how the user acts on a ranked
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

- [ ] **Results filtering.** Let the user **interactively narrow the displayed results** in the
      Results view — by **minimum rank**, **keywords**, **location**, and a few more facets
      (company, salary floor, tracked status) — without re-running the search. Non-destructive: a
      filter only hides rows (delete/save still act on what's shown), and it's live + reversible.
      This is **distinct from Milestone U-E's search-time min-rank filter** (which trims the
      persisted/ranked set): W is a view filter over the already-loaded `[RankedJob]`. Seam: a pure
      `ResultsFilter` value with `apply(to:)` (unit-tested); `ResultsViewModel` filter state +
      `filteredResults`; a filter bar on the Results view (pickers populated from the values present
      in the current results) + an empty-filtered state. On-device: yes — pure, local, no network,
      no persistence (session-only; a saved-filter option is a later idea).

- [ ] *(stretch)* **Export templates + one-page gate.** Once PDF export lands: 1–2
      selectable résumé templates and AGENT.md's one-page length gate (warn / offer a
      tightened variant when the résumé overflows a page — surfaced, never silently
      truncating). Depends on the Q PDF-renderer choice (the HTML-template path makes both
      realistic). Promote into v3 proper only if Q completes early; otherwise it seeds v4.

## Fast follow (next up)

- Export and saved/re-runnable searches moved **up into v3** (see above); the profile-cache
  half of the old "Persistence with SwiftData" fast-follow already shipped via `SavedProfile`.
  When v3 completes, pull the next item up from Backlog.

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
- Backend proxy for Adzuna (see v2 note) — required if the app is ever distributed
- Multimodal portfolio input — read a screenshot/image of a resume on-device (needs a
  multimodal on-device model), avoiding a separate OCR step
- Interview prep / mock-interview feature
- Application tracker with statuses and follow-up reminders

## Explicit non-goals

- Auto-submitting applications or filling forms on job sites
- iOS/mobile target
- Accounts / cloud sync
