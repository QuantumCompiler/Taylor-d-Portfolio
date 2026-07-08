# Taylor'd Portfolio — Roadmap

How we work: features get discussed in chat, written up here (and in `SPEC.md`),
then handed to the Claude Code session to build. This file is the high-level
running list; `TODO.md` breaks the current target into granular, checkable tasks.
As TODO items land, tick them here too so this stays an accurate progress board.

## v1 — foundation (current target)

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

## v2 — reliability (current target)

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

- [ ] **Prefer the highest-capability on-device Foundation Model (AFM 3 Core
      Advanced where available).** Target the AFM 3 generation and prefer the 20B
      sparse Core Advanced model on Macs whose silicon supports it; degrade to AFM 3
      Core (3B dense) on older Apple-Intelligence Macs, and to Claude when on-device
      is unavailable entirely. A quality upgrade to the *primary* engine, not a new
      engine — stronger profile extraction, ranking judgment, and grounded generation,
      and fewer escalations to Claude.
      Seam: `FoundationModelsClient` (Infrastructure), behind the existing
      `availability` / `isAvailable` surface.
      **Blocking spike (do first):** confirm against the macOS 27 / AFM 3 SDK whether
      an app can (a) request Core Advanced explicitly, (b) query which on-device tier
      will be served, or (c) neither — tier selection is purely device-driven. The
      framework exposes `SystemLanguageModel.default` (+ use-case initializers), not a
      by-name model picker, and Core-vs-Core-Advanced is currently understood to be an
      OS/hardware-tier decision. The shape of this whole item depends on that answer:
      if the OS decides, "make Core Advanced the default" becomes "bump the target OS
      + guarantee graceful degradation," not an app-controlled model selection.
      On-device: yes. macOS-only means more users clear the silicon bar than on
      iPhone, but not all — the degrade path is required, not optional.

- [ ] **Job-URL input + AGENT.md-grade generation prompts.** Two linked upgrades,
      ported from Taylor's hand-built LaTeX résumé agent (`AGENT.md`).
      **Status: part 2 (structured generation) is done; part 1 (URL input) is still open.**
      1. **Generate from a job URL.** Accept a posting URL as an input path
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

- [ ] **Save pulled listings + a job-detail view.** Persist what a search pulls down —
      each `JobListing` (full description, salary, original URL) and its `JobMatch`
      (score, reason, matched/missing skills) — and give the user a way to read the full
      job description from the UI. Two parts:
      1. **Job-detail view (Presentation).** Tapping a result opens a detail view showing
         the full description, salary, a "View original posting" link (`JobListing.url`),
         and the match score/reason + matched/missing skills. This closes a real gap —
         the pulled `description` currently isn't shown anywhere. Works in-session with no
         persistence, so it can land on its own.
      2. **Persist searched listings (first slice of SwiftData).** Store pulled listings +
         their match results so they survive relaunch and can be revisited — the concrete
         first slice of the "Persistence with SwiftData" fast-follow. New persistence port
         (declared in the layer that owns it) + a SwiftData-backed impl in Infrastructure;
         domain `JobListing` / `RankedJob` stay clean `Codable` structs, mapped to/from an
         `@Model` in Infrastructure (don't leak `@Model` into the domain).
      3. **Persist generated materials with the posting.** When the user generates a
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

- [ ] **Application status tracker.** Let the user record where each job stands: **mark
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

## Fast follow (next up)

- [ ] **Persistence with SwiftData** — store profile cache and saved/re-runnable
      searches. (Pulled listings + generated materials are persisted in v2 Milestone O;
      the applied-to tracker is v2 Milestone P; this fast-follow covers the *rest*:
      caching the built profile across launches, and saved searches you can re-run.)
      Unlocks "already seen."
- [ ] **Export** — resume/cover letter to PDF and/or DOCX.

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
      Priority: after the v2 model work, since the spike above informs it.

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
- Multimodal portfolio input — AFM 3 Core Advanced is natively multimodal, so a
  screenshot/image of a resume could be read on-device without a separate OCR step
- Interview prep / mock-interview feature
- Application tracker with statuses and follow-up reminders

## Explicit non-goals

- Auto-submitting applications or filling forms on job sites
- iOS/mobile target
- Accounts / cloud sync
