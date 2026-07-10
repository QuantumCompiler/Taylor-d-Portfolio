# Taylor'd Portfolio — TODO

The **granular, current** working checklist — a segmented breakdown of `ROADMAP.md`.
This is the source of truth for *where we are*. See `CLAUDE.md` → "Working process"
for how this file, `ROADMAP.md`, and `SPEC.md` fit together.

**How to use it:** work top-down through the milestones. When you finish an item,
check it off here **and** tick the matching line in `ROADMAP.md`. Keep the
"Current focus" line below pointing at the next unchecked item so a fresh session
can pick up instantly. Add newly-discovered sub-tasks as checkboxes in the right
milestone.

> **Current focus:** v1 core **complete** (Milestones A–J + document import). **v2 —
> reliability complete** (K, M, N, O, P; former Milestone L — "prefer AFM 3 Core Advanced
> on-device" — was **removed**, on-device tier selection has no developer API; see CLAUDE.md
> → Stack). **Post-v2 enhancements shipped:** per-task LLM engine selection (each `LLMTask`
> has its own `TaskEngineConfig` — `LLMChoice` + Claude model; every task defaults to Claude,
> `.auto` / `.onDevice` still selectable) and named `SavedProfile`s (with source document +
> default-profile pointer).
>
> **v3 — output & polish is the current target.** A priority **hotfix** comes first:
> **the job-posting URL fetch is broken** — pasting a URL + Fetch produces no result. Then
> seven milestones, plus a stretch: **Q — Export** (résumé/cover letter → Markdown, PDF, and
> true DOCX — the flagged highest-value item), **R — Saved / re-runnable searches** (finishes
> the persistence fast-follow; the profile-cache half already shipped via `SavedProfile`),
> **S — Polish pass** (in-app markdown rendering, empty/loading/error states, results/saved/
> Tracker cohesion), **T — two-document portfolio** (résumé/portfolio + optional cover letter,
> referenced as generation grounding), **U — expanded search parameters** (position type,
> typeable/saveable location + salary, a desired-result-count goal, and a minimum-rank filter —
> all optional), **V — results ↔ tracker interaction** (per-row save/delete icons, a swipeable
> result card, generation moved to the Tracker), **W — results filtering** (interactively narrow the
> results by rank/keywords/location, non-destructive). Optional **X — export templates + one-page
> gate** is a stretch. **v0.3.0 scope is now closed.** The milestone letters Q–X are a *catalogue,
> not the build order* — follow **"Recommended implementation order (v3)"** at the top of the v3
> section below. In short: **Hotfix + the two quick fixes (S-D scroll, S-E tile gestures) first**,
> then **Q — Export**, then grounding/search depth (T → U → R), then the results experience (V → W),
> then the cohesive polish pass (S-A/B/C), with **X** as the stretch.
>
> Larger backlog beyond v3 (see ROADMAP): native `LanguageModel` provider seam; on-device
> embedding RAG; optional MCP tools.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure,
imports point down only). Build roughly bottom-up so each layer has what it needs.

---

## Milestone A — Project scaffold & app shell  ✅ done

- [x] Restructure repo: `lib/src` (sources) + `Tests`; drop UI tests
- [x] Four-layer folder scaffold in `lib/src` and `Tests`
- [x] Remove Apple's Core Data template (ContentView / Persistence / .xcdatamodeld)
- [x] App entry `Taylor_d_PortfolioApp` — `lib/src/Presentation/App/App.swift`
- [x] Landing screen — `lib/src/Presentation/Landing/View/LandingView.swift`
- [x] Rebrand product name to "Taylor'd Portfolio"
- [x] Feature-based Presentation convention (`<Screen>/View` + `<Screen>/ViewModel`)

## Milestone B — Domain models  ✅ done  (`lib/src/Data/Models`, tests in `Tests/Data/Models`)

- [x] `CandidateProfile` (`@Generable`, `Codable`): seniority, yearsExperience,
      coreSkills, domains, targetTitles, summary
- [x] `JobListing` (`Codable`): id, title, company, location, description, url, salary
      (salary modelled as an optional `SalaryRange`)
- [x] `JobQuery`: keywords, location, salaryMin, page, resultsPerPage
- [x] `JobMatch` (`@Generable`, `Codable`): jobId, score (0–100), reason,
      matchedSkills, missingSkills
- [x] `RankedJob`: pairs a `JobListing` with its `JobMatch` (Identifiable; derives id + score)
- [x] `ApplicationKit` (`@Generable`, `Codable`): resumeMarkdown, coverLetter, gapNote
- [x] Codable round-trip unit tests for each type (`DomainModelTests`, Swift Testing)

Notes: all data models are `nonisolated` + `Sendable` (the project defaults actor
isolation to `MainActor`, so DTOs must opt out to cross into off-main use cases).

## Milestone C — Infrastructure: LLM plumbing  ✅ done  (`lib/src/Infrastructure/LLM`)

- [x] `TextGenerating` protocol — the raw generation port (declared here), `Sendable`
- [x] `FoundationModelsClient` — wraps `LanguageModelSession`, exposes `availability`,
      plain-text `generate`, and constrained decoding `respond(to:generating:)` for `@Generable`
- [x] `ClaudeProcessClient` — runs `claude -p … --output-format json`, unwraps
      `result`, strips code fences; pure helpers unit-tested (`ClaudeProcessClientTests`)

Notes: both clients are `nonisolated` + `Sendable`. `FoundationModelsError` /
`ClaudeProcessError` carry failure detail. `ClaudeProcessClient` needs App Sandbox
**off** at runtime (it launches an external binary). Provider-level tests come with
Milestone D.

## Milestone D — Data: LLM gateway  ✅ done  (`lib/src/Data/LLM`)

- [x] `LLMProvider` protocol — task-oriented (`buildProfile` / `rank` / `generateApplication`),
      not a generic `generate<T>`; `LLMProviderError` for failures
- [x] `Prompts` enum — shared prompt text so the two engines never drift; bounds inputs
- [x] `FoundationModelsProvider` — constrained decoding against `@Generable` types
      (uses `JobMatchBatch` wrapper for batched ranking)
- [x] `ClaudeCodeProvider` — appends `jsonOnlySuffix`, decodes JSON into the domain type
- [x] `LLMRouter` — picks an engine from `LLMChoice` (`auto` = on-device first, fall
      back to Claude on unavailable/throw); conforms to `LLMProvider` itself
- [x] Provider tests: `ClaudeCodeProviderTests`, `LLMRouterTests`, `PromptsTests`

Notes: `LLMChoice` (auto / onDevice / claude) lives in Data/LLM; Milestone F's
`AppSettings` will hold one. `FoundationModelsProvider` is thin glue over the
on-device client and is covered by integration only (can't be unit-mocked without a
device model); the router and Claude provider are fully unit-tested via stubs.

## Milestone E — Job seam  ✅ done  (`lib/src/Infrastructure/Net`, `lib/src/Data/Jobs`)

- [x] `HTTPClient` port + `URLSessionHTTPClient` (throws `HTTPError` on non-2xx)
- [x] `JobSource` protocol — returns `[JobListing]`, no API types leak past it
- [x] `AdzunaJobSource` — builds the Adzuna URL, decodes the response, maps to `JobListing`
      (Adzuna wire types stay private); credentials injected via `Credentials`
- [x] Tests: `AdzunaJobSourceTests` (stubbed `HTTPClient` + pure `buildURL`),
      `URLSessionHTTPClientTests` (stubbed `URLProtocol` for status handling)

Notes: `AdzunaJobSource.Credentials` (appID / appKey / country) is injected — Milestone F's
`AppSettings` will supply it. `URLSessionHTTPClient` is covered via a `URLProtocol` stub,
so no real network is hit in tests.

## Milestone F — Settings  ✅ done  (`lib/src/Infrastructure/Store`, `lib/src/Data/Settings`)

- [x] `KeyValueStore` port + `UserDefaultsStore` (nonisolated port so its sync methods
      work off the main actor; `UserDefaults` shared via `nonisolated(unsafe)`)
- [x] `AppSettings` — `llmChoice`, Adzuna appID/appKey/country; `.default`,
      `hasAdzunaCredentials`, and an `adzunaCredentials` bridge to `AdzunaJobSource`
- [x] `SettingsStore` — load/save `AppSettings` as JSON; `load()` returns `.default`
      when absent or corrupt
- [x] Tests: `SettingsStoreTests` (in-memory store), `UserDefaultsStoreTests` (isolated suite)

## Milestone G — Business: ranking & use cases  ✅ done  (`lib/src/Business`)

- [x] `JobRanker` (Business/Ranking): pure lexical `prefilter(...)` shortlist +
      batched `rank(...)` → `[RankedJob]` (pairs by jobId, sorts by score desc)
- [x] `BuildProfileUseCase` (Business/UseCases)
- [x] `SearchAndRankUseCase` (search → rank)
- [x] `GenerateApplicationUseCase`
- [x] Tests: `JobRankerTests` (prefilter/pairing/sorting/shortlist), `UseCaseTests`

Notes: use cases are `callAsFunction` structs so ViewModels invoke them like
`try await searchAndRank(query:profile:)`. They keep ViewModels off the providers.

## Milestone H — Presentation screens  ✅ done  (`lib/src/Presentation/<Screen>/{View,ViewModel}`)

- [x] `Portfolio` — paste portfolio → build profile (`PortfolioView` + VM)
- [x] `Search` — keywords/location/salary → run search + rank (`SearchView` + VM)
- [x] `Results` — ranked list; `RankedRow` in `Results/View`; taps open the sheet
- [x] `Application` — generates resume + cover letter on appear (`ApplicationSheet` + VM)
- [x] `Settings` — LLM choice + Adzuna keys, saved via `SettingsStore`
- [x] `LandingViewModel` — `getStarted()` invokes an injected action (route wired in I)
- [x] Tests: one `@MainActor @Suite` per ViewModel (`Tests/Presentation/<Screen>`)

Notes: ViewModels are `@MainActor @Observable`; Views take them via `@Bindable`.
Cross-screen inputs (`profile`, results, selected job) are settable properties that the
composition root will connect in Milestone I. `PreviewSupport.swift` (DEBUG-only)
supplies stub engines + sample data so every screen has a working `#Preview`.

## Milestone I — Composition root wiring  ✅ done  (`lib/src/Presentation/App`)

- [x] `Composition` assembles the graph: Infrastructure clients → Data gateways →
      Business use cases → ViewModel factories
- [x] `RootView` gates Landing → main `TabView` (Portfolio / Search / Results / Settings)
      and owns each ViewModel; "Get Started" flips into the app
- [x] Cross-screen state wired: profile (Portfolio → Search), results (Search → Results,
      auto-jumps to the tab), selected job → Application sheet

Notes: ViewModels are injected by ownership (`RootView` `@State`) + direct passing rather
than `.environment` — cleaner for owned reference types. Gateways are **settings-backed**
(`SettingsBackedLLMProvider` / `SettingsBackedJobSource` read the store on each call), so
engine choice and Adzuna keys apply without a relaunch. Runtime caveats for a working flow:
Apple Intelligence on (on-device engine), Adzuna keys in Settings (search), and **App
Sandbox off** to use the Claude CLI engine (see CLAUDE.md → Build).

## Milestone J — End-to-end vertical slice  ✅ done  ← closes v1

- [x] Portfolio → profile → search → ranked results → generate resume/cover letter,
      wired end to end and proven by an integration test (`EndToEndTests`) driving the
      real ViewModels + use cases + ranker with stub engines
- [x] App boot verified (real `Composition`/`RootView` launch smoke, no crash)

Remaining is a **manual device smoke** only — the real engines/network can't run in CI:
run on a Mac with Apple Intelligence on (on-device), or App Sandbox off + Claude CLI
(fallback), plus Adzuna keys in Settings, and confirm real output. The routing/fallback
logic itself is unit-tested (`LLMRouterTests`).

---

## Feature: Portfolio document import  ✅ done

Added on top of the v1 core (from the ROADMAP ideas list).

- [x] `DocumentTextExtractor` port + `PlatformDocumentTextExtractor` — PDFKit for PDFs,
      `NSAttributedString` for Word/RTF/ODT, direct read for text (Infrastructure/Documents)
- [x] `ImportPortfolioUseCase` (Business/UseCases) — depends on the extractor port
- [x] Portfolio screen: "Import Document…" via `.fileImporter` fills the text box; then
      Build Profile runs as before
- [x] Tests: extractor (temp files + routing/errors), use case, `PortfolioViewModel.importDocument`

Notes: security-scoped file access handled; supported types pdf/txt/md/rtf/rtfd/doc/docx/odt.
Portfolio-**URL** import (fetch + extract) is still open (ROADMAP ideas).

---

# v2 — reliability

Turning "misconfigured / weak output" into problems that fail fast and clearly.
All milestones below (K, M, N, O, P) are complete. (A former Milestone L — "prefer
AFM 3 Core Advanced on-device" — was dropped: on-device tier selection isn't
app-controllable, so there was nothing to build. See CLAUDE.md → Stack.)

## Milestone K — Adzuna credentials → build-time config  ✅ done  (`lib/src/Infrastructure/Config`, `Composition`, Settings)

Goal: the user never enters Adzuna `app_id` / `app_key`. They're baked in at build
time, so a correctly-built binary always has them and a missing/typo'd key fails at
build/startup rather than as a silently-failed search. `adzunaCountry` stays a user
setting (it's a search preference, not a secret).

- [x] **Config port + bundle impl.** New `Infrastructure/Config`: `AppConfig` port
      (`var adzunaAppID: String?` / `var adzunaAppKey: String?` + a `hasAdzunaCredentials`
      default) + `BundleAppConfig` reading Info.plist keys (`AdzunaAppID`, `AdzunaAppKey`).
      The lookup is injectable via `BundleAppConfig(values:)` (a `[String: String]` dict)
      so tests need no real bundle — mirrors `UserDefaultsStore(defaults:)`. Empty/
      whitespace values normalize to `nil` (an unfilled `$(…)` reads as "not configured").
- [x] **Secrets wiring (build).** Gitignored `Secrets.xcconfig` (repo root) defining
      `ADZUNA_APP_ID` / `ADZUNA_APP_KEY`, set as the app target's `baseConfigurationReference`
      (Debug + Release); committed `Secrets.example.xcconfig` template; added to `.gitignore`.
      **Implementation note:** `INFOPLIST_KEY_<custom>` build settings only support Xcode's
      known-key allowlist — arbitrary custom keys are silently dropped. So a partial
      `Info.plist` (repo root, `INFOPLIST_FILE = Info.plist`) carries `AdzunaAppID` /
      `AdzunaAppKey = $(ADZUNA_APP_ID)` / `$(ADZUNA_APP_KEY)`; `GENERATE_INFOPLIST_FILE`
      stays `YES` so Xcode merges its auto-generated keys on top. Verified the substituted
      values land in the built app's Info.plist. (xcconfig caveat: `//` starts a comment;
      Adzuna keys are hex so fine.)
- [x] **Trim `AppSettings`.** Removed `adzunaAppID`, `adzunaAppKey`,
      `hasAdzunaCredentials`, and the `adzunaCredentials` bridge. Keeps `llmChoice` +
      `adzunaCountry`. Updated `AppSettings.default` and its tests.
- [x] **Rewire the composition root.** `SettingsBackedJobSource` builds
      `AdzunaJobSource.Credentials` from `AppConfig` (id/key) + settings (country).
      `AppConfig` injected into `Composition.init` (defaults to `BundleAppConfig()`);
      `Composition.isAdzunaConfigured` feeds the Search/Settings ViewModels.
- [x] **Settings UI.** Removed the App ID / App Key fields from `SettingsView` /
      `SettingsViewModel`. Added a read-only "Configured / Not configured in this build"
      status derived from the injected flag (no secret values shown).
- [x] **Fail fast.** `SearchViewModel.adzunaConfigured` gates search; a DEBUG-only
      console warning in `Composition.init` is the developer-facing signal when the build
      lacks credentials, and the user sees the "unavailable in this build" banner instead
      of a confusing failed search.
- [x] **Search messaging.** Replaced the "check your Adzuna keys in Settings" copy; when
      unconfigured, `canSearch` is false (button disabled) and `unavailableMessage` shows
      the banner; the run-failure copy is now a generic connection message.
- [x] **Tests.** `BundleAppConfigTests` (present / missing / partial / empty / trim);
      updated `SettingsStoreTests` + `SettingsViewModelTests` (credential fields gone,
      configured-status added); `SearchViewModelTests` unconfigured-build cases. Full
      suite green on macOS.
- [x] **Docs in the same change.** SPEC (build-time creds note in v1 scope), CLAUDE.md
      (Build setup + Settings/Data map + layer map now lists `Infrastructure/Config`), and
      the gitignore + `Secrets.example.xcconfig`.

Note: baked keys are extractable from the bundle — acceptable for a personal free-tier
key. Distribution would need a backend proxy instead (see ROADMAP backlog / ideas).

## Milestone M — Job-URL input + AGENT.md-grade generation  ✅ done  (`Prompts`, `Data/Jobs`, `LLMProvider`, Presentation)

Goal: port the discipline of Taylor's hand-built LaTeX résumé agent (`AGENT.md`) into
the app — (M-A) generate an application from a **job posting URL**, and (M-B) upgrade
the generation prompts from a single shot to a **structured target-brief → tailored
output** flow. **Both parts done.** Same "never fabricate" guardrail the SPEC already states. Out of scope:
AGENT.md's LaTeX/PDF/`.docx` build toolchain (that's the "Export" fast-follow).

### M-A — Generate from a job URL  ✅ done

- [x] **`JobPostingSource` seam (Data/Jobs).** New port with `fetchPosting(from:)` +
      `extractPosting(fromText:sourceURL:)` → `JobListing`, distinct from `JobSource`.
      `LinkJobPostingSource` impl reuses `HTTPClient`; page parsing stays private.
- [x] **Fetch + extract impl.** Fetches HTML → `HTMLStripper.plainText` (moved to
      `Infrastructure/Text` so Data may use it) → LLM extraction. New `ExtractedPosting`
      `@Generable` model + `Prompts.extractPosting` + `LLMProvider.extractPosting`
      (a protocol requirement with a throwing default, so only the real engines + router
      implement it — stubs are untouched). Bounded by `maxPageCharacters`.
- [x] **Fail loudly, don't guess.** Fetch failure (non-2xx/paywall/network), too-little
      text (JS-gated shell), an extractor error, or an empty extraction all throw
      `JobPostingSourceError.unreadable`; the UI then asks the user to paste the text.
      Never invents a role.
- [x] **Presentation affordance.** Search screen "Or generate from a specific posting":
      a URL field + Fetch, and a DisclosureGroup with a paste-the-text fallback. Results
      flow through the existing pipeline (→ Results tab → detail → generate). Link fetch
      is independent of Adzuna credentials (HTTP + LLM only).
- [x] **Composition + sandbox.** `LinkJobPostingSource` + `FetchPostingUseCase` wired in
      `Composition`. Outgoing-network works for arbitrary hosts (the app is now
      unsandboxed; it worked via the entitlement while sandboxed too).
- [x] **Tests.** `LinkJobPostingSourceTests` (good HTML → fields; 403 / too-little-text /
      extractor-throw / empty-extraction → `.unreadable`; pasted-text path);
      `PromptsTests` extraction shape + bounding + no-invention; `FetchPostingUseCase`
      tests (ranks the single listing, neutral fallback, propagates `.unreadable`);
      `ExtractedPosting` round-trip + mapping. `HTMLStripper` tests moved to Infrastructure.

### M-B — Two-stage, structured generation prompts (from AGENT.md §1, §5)  ✅ done

- [x] **Target brief step.** Added `Prompts.buildTargetBrief(job:)` + `briefInstructions`
      and a new `TargetBrief` `@Generable`/`Codable` model (company, roleTitle, must-have vs.
      nice-to-have keywords, techStack, domain, missionValues). Exposed as an `LLMProvider`
      method; `GenerateApplicationUseCase` orchestrates brief → generate (two-stage in the
      Business layer, providers stay atomic).
- [x] **Map to truth + gaps.** The generation prompt's "Method" step instructs the model to
      map each brief signal to the closest TRUE profile fact and to treat unmatched signals
      as GAPs — feeding a `gapNote` that lists the notable unmet must-haves.
- [x] **Tailored résumé prompt.** Asks for a role-specific headline for the brief's
      `roleTitle` + a 1–2 sentence summary, then sections re-angled to foreground the single
      best-fit overlap first. Reorder/rephrase real experience only.
- [x] **Three-section cover letter.** `generateApplication` now requires the cover letter in
      three Markdown-headed sections: `## About Me` / `## Why <company>` / `## Why Me` (the
      middle is the company-specific payoff of the brief). Grounded, specific, no invented
      metrics.
- [x] **Keep engines in lockstep.** All new text lives in the shared `Prompts` enum, so
      `FoundationModelsProvider` (constrained decoding of `TargetBrief`/`ApplicationKit`) and
      `ClaudeCodeProvider` (JSON) stay identical. `TargetBrief` is both `Generable` + `Codable`.
- [x] **Bound inputs.** The brief step truncates the posting via `maxDescriptionCharacters`
      (covered by a new bounding test); brief fields are short by construction.
- [x] **Tests.** `PromptsTests` (brief fields + bounding + the three cover-letter sections +
      map-to-truth/gap/best-fit discipline); `ClaudeCodeProviderTests.buildTargetBriefDecodes`
      + updated `generateApplicationDecodes` (asserts the brief reaches the prompt);
      `TargetBrief` Codable round-trip; router + use-case two-stage delegation. Suite green.
- [x] **Docs.** SPEC (two-stage approach under "Grounded generation"); CLAUDE.md (two-stage
      note in the LLM-seam description, `TargetBrief` in Key types + the Data/Models layer map).
      (The `JobPostingSource` / URL-input parts are M-A, not M-B.)

Note: M-A and M-B compose but are separable — M-B (better prompts) helps every generation
regardless of input source, so it can land first; M-A (URL input) is the new entry path.
The AGENT.md file itself is Taylor's ground-truth reference for tone and the tailoring
"levers" (which project to feature for which role type) — worth keeping alongside SPEC.

## Milestone N — Multi-title search + field autocomplete  ✅ done  (`SearchAndRankUseCase`, `Data/Search`, `SearchViewModel`, Search UI)

Goal: once a profile is loaded, let the user run **several role titles in one search**
(iOS Developer, iOS Engineer, Software Developer, Software Engineer, …) and **autocomplete**
the input fields, seeded from the loaded profile. More relevant recall, less typing.
This is a search-quality/UX item — could sit in fast-follow instead of v2 if you'd rather;
kept here since it directly touches the reliability of getting good results.

### N-A — Multiple title searches, merged and ranked once  ✅ done

- [x] **Fan-out in the use case.** New `JobSearchRequest { titles, location, salaryMin }`;
      `SearchAndRankUseCase` expands it → one `JobQuery` per title (via
      `request.query(forTitle:)`) → runs the searches with a bounded task group.
- [x] **Dedupe.** Merges in title order and dedupes by `JobListing.id` (first occurrence
      wins), so a posting returned by two titles isn't ranked/shown twice.
- [x] **Rank once.** Feeds the merged, deduped set into `ranker.rank(_:for:)` a single time
      (proven by `CountingRankProvider` asserting one rank call over the merged count).
- [x] **`JobQuery` stays single.** `JobQuery` is unchanged; the fan-out is orchestration
      above the seam, so `JobSource` / `AdzunaJobSource` are untouched.
- [x] **Concurrency + rate-limit guard.** `maxConcurrentSearches = 4` (sliding-window task
      group) + a `maxTitles = 6` hard cap. Both are documented init params on the use case.
- [x] **Partial-failure policy.** A title's search failing is caught per-title; the run
      continues with the successes and reports `Output.failedTitles`. Only throws if *all*
      titles fail. The VM turns `failedTitles` into `SearchViewModel.warningMessage`.
- [x] **ViewModel.** `SearchViewModel` gained `titles: [String]` chips + a `titleInput`
      field (the in-progress input is searched too); `canSearch` requires a profile + at
      least one effective title. Location + salary stay single, shared.
- [x] **Tests.** `UseCaseTests`: two titles merged+deduped ranked once; duplicate id
      collapses; one failing title returns the rest with a note; all-fail throws; empty
      titles handled.

### N-B — Field autocomplete (seeded by the loaded profile)  ✅ done

- [x] **Suggestion source (Data).** `SuggestionProvider` (Data/Search): profile-seeded
      starting titles + static locations (incl. "Remote") + salary presets. Pure, on-device.
- [x] **Pre-fill from profile.** `SearchViewModel.profile.didSet` seeds the title chips
      from `profile.targetTitles` (first 3) the first time a profile loads.
- [x] **Title input UI.** Chip input on the Search screen: removable chips + a text field
      (Add / on-submit); free text allowed.
- [x] **Common role titles are user-curated + persisted (revised design).** The static
      curated vocabulary was **removed**. Instead the user **long-presses a chip** to save
      that title into their own library (a ⭐ marks saved chips), persisted across launches
      via `RoleTitleStore` (on `KeyValueStore`). Saved titles render as multi-select tiles:
      tapping a tile toggles it into the search (tinted); the tile's "x" removes it from the
      library permanently (`saveAsCommonRoleTitle` / `toggleCommonTitle` / `removeCommonRoleTitle`;
      selected titles flow into `effectiveTitles`).
- [x] **Location autocomplete + salary presets.** Location is a picker over the static
      list (+ "Anywhere"); salary is a preset-bracket picker (+ "Any"), not free text.
- [x] **Tests.** `SuggestionProviderTests` (seeded titles, locations, presets);
      `RoleTitleStoreTests` (round-trip, shared-backing persistence, corrupt → empty);
      `SearchViewModelTests` (chip add/remove + dedupe, profile-seeded defaults, `canSearch`,
      warning, long-press-saves-and-persists, toggle-common-title, remove-from-library).
- [x] **Docs.** SPEC ("Search → listings": multiple titles + autocomplete); CLAUDE.md
      (`SuggestionProvider` seam + the multi-title fan-out; `JobQuery` stays single).

Note: N-A and N-B are separable — N-A (multi-search) delivers value even with a plain
text field; N-B (autocomplete) helps single or multi search. Composes with Milestone M:
a URL-extracted posting (M-A) can pre-fill a title chip here.

## Milestone O — Save pulled listings + job-detail view  ✅ done (O-A, O-B, O-C)  (Presentation detail view; Infrastructure persistence + `Data` repository)

Goal: persist what a search pulls down (each `JobListing` + its `JobMatch`) and let the
user **read the full job description from the UI**. Closes a real gap — the pulled
`description` isn't shown anywhere today (`RankedRow` shows only title/company/location +
the match reason). O-A is the viewing part (in-session, no persistence); O-B is the
persistence part (the first concrete slice of the SwiftData fast-follow).

### O-A — Job-detail view (Presentation; no persistence needed)  ✅ done

- [x] **`JobDetailView`.** A read-only, value-driven detail sheet for one `RankedJob`:
      full `JobListing.description`, `salary` (via `SalaryFormatter`/`SalaryRange`), a
      "View original posting" `Link` when `JobListing.url` is present, and the match
      score/reason + matched/missing skills (skill capsules). Reuses `ScoreBadge`.
- [x] **Wire into Results.** `ResultsView`'s row tap now opens `JobDetailView` (the
      `selectedJob` sheet). The "generate application" action stays reachable — a
      "Generate résumé & cover letter" button in the detail presents `ApplicationSheet`
      (disabled until a profile exists). (Saved-materials "view vs regenerate" is O-C.)
- [x] **HTML handling.** Decided: **strip on display.** `HTMLStripper.plainText` (pure,
      unit-tested) turns Adzuna markup into readable text (`<br>`/block tags → newlines,
      tags removed, common entities decoded, blank lines collapsed); the domain
      `JobListing.description` stays raw. Empty descriptions show a placeholder.
- [x] **Tests / previews.** `JobDetailView` `#Preview` with `Preview.sampleRankedJobs`;
      `JobDetailFormattingTests` cover `HTMLStripper` + `SalaryFormatter` (no VM added, so
      no VM suite). Full suite green.

### O-B — Persist searched listings (first SwiftData slice)  ✅ done

- [x] **Persistence port.** `PersistentRecordStore` (Infrastructure/Store), a
      list-oriented blob port keyed by `(kind, id)` — mirrors `KeyValueStore`. Domain
      `JobListing`/`RankedJob` stay clean `Codable` structs.
- [x] **SwiftData impl (Infrastructure).** `SwiftDataRecordStore` (`@ModelActor`, so it
      runs off the main actor + is `Sendable`) backed by a `StoredRecord` `@Model` with a
      unique composite key. The `@Model` is `internal` to Infrastructure — it **never
      leaks upward**; the port speaks only `Data` blobs. (Design note: rather than
      per-type `@Model`s that would force Infrastructure↔domain coupling, one generic
      blob row keeps `@Model` fully contained and serves O-C/P too via `kind`.)
- [x] **Data-layer repository.** `SavedJobsRepository` (Data/Persistence) maps
      `RankedJob` ↔ blob (`kind` "rankedJob"), with `save` / `savedJobs` (sorted by
      score) / `contains(jobID:)` for "already seen". Saved after each search/link fetch.
- [x] **Composition + lifecycle.** `Composition` builds the `ModelContainer` (degrades to
      no-op persistence if it can't be created), exposes `SaveResultsUseCase` /
      `LoadSavedJobsUseCase`; `SearchViewModel` persists after search + link fetch,
      `ResultsViewModel` loads saved jobs on launch (`ResultsView.task`) when empty.
- [x] **Dedupe / upsert.** Keyed by `JobListing.id` (upsert, so re-pulling
      the same posting updates rather than duplicates) — reuses the N-A dedupe identity.
- [x] **Tests.** `SwiftDataRecordStoreTests` (real in-memory container: upsert/fetch,
      replace-by-id, kind isolation, delete); `SavedJobsRepositoryTests` (round-trip
      sorted, upsert collapses dupes, `contains`); `SearchViewModel` persists-after-search;
      `ResultsViewModel` loads-saved (and doesn't clobber a fresh search).
- [x] **Docs.** SPEC (revised the no-persistence line); CLAUDE.md (persistence port +
      SwiftData impl in Infrastructure, `SavedJobsRepository` in Data, layer map, and the
      `@Model`-stays-in-Infrastructure rule).

### O-C — Persist generated materials with the posting  ✅ done

- [x] **Store `ApplicationKit` by job id.** `SavedApplicationsRepository` (Data/Persistence)
      reuses the `PersistentRecordStore` under `kind` "applicationKit", keyed by
      `JobListing.id`, mapping to/from the domain `ApplicationKit` (no `@Model` in the
      domain — same rule as O-B; the generic blob store meant no schema change).
- [x] **Save after generate.** `SaveApplicationUseCase`; `ApplicationViewModel.generate`
      persists the produced kit (best-effort, latest-wins upsert by job id). History of
      regenerations remains a possible later extension.
- [x] **Load saved on open.** `ApplicationViewModel.open(for:profile:)` loads a saved kit
      via `LoadApplicationUseCase` and shows it (marked "Saved") **without** calling the
      provider; only generates when none exists. `ApplicationSheet.task` calls `open`, and
      a **Regenerate** button forces fresh output. Avoids a redundant LLM call.
- [x] **Tests.** `SavedApplicationsRepositoryTests` (round-trip by job id, latest-wins,
      per-job isolation); `ApplicationViewModel` tests: open generates+persists when empty,
      open loads a saved kit with **zero** provider calls (a recording provider asserts it),
      regenerate forces fresh + re-persists.
- [x] **Docs.** SPEC (generated materials persist + reopen-without-regenerating); CLAUDE.md
      (`SavedApplicationsRepository` in Data + the two use cases).

Note: O-A and O-B are independent — O-A (viewing) needs no persistence and can ship first;
O-B is the first real slice of the broader SwiftData fast-follow (which then adds profile
cache, applied-to tracker, and saved/re-runnable searches). O-C builds on O-B's port/
repository. Keep domain types free of `@Model`; map at the Infrastructure boundary.

## Milestone P — Application status tracker  ✅ done  (`Data/Models`, `Business/UseCases`, Infrastructure persistence, Tracker screen)

Goal: record where each job stands. **Mark as applied** with an **automatic** date stamp,
and flag later stages — interview offered, offer received, rejected, accepted/declined,
withdrawn — each auto-stamped when set. A tracker view lists applied jobs by stage; a
status badge appears on results/detail. Builds on Milestone O's persistence. Consistent
with the human-in-the-loop principle (the user applies themselves, then records it).

### P-A — Status model + auto date stamps  ✅ done

- [x] **`ApplicationStatus` domain type (`Data/Models`).** `nonisolated` `Codable`/
      `Equatable`/`Sendable`: an `ApplicationStage` enum (saved/applied/interviewing/offer/
      accepted/declined/rejected/withdrawn, with `label` + `settable` + `isClosed`) plus
      dated milestones (`appliedDate`/`interviewDate`/`offerDate`/`closedDate`) + `note`.
      Chose **enum + dated milestones** (simpler than an event log). `currentDate` helper.
- [x] **Auto-stamp on transition.** Pure `advanced(to:on:)` stamps the milestone for the
      new stage (forward milestones stamp-if-nil to preserve the first date; terminal
      outcomes stamp `closedDate`, latest-wins). The clock is injected by the use case
      (`now` closure) so production uses `Date()` and tests are deterministic.
- [x] **Tests.** `DomainModelTests`: `ApplicationStatus` round-trip; `advanced(to:on:)`
      stamps the right milestone, advances the stage, and preserves earlier stamps;
      `settable`/`isClosed`.

### P-B — Persist status (extends O's repository)  ✅ done

- [x] **Store status by job id.** `SavedStatusRepository` (Data/Persistence), `kind`
      "applicationStatus", keyed by `JobListing.id`, upsert. Since the status blob doesn't
      carry the id, the `PersistentRecordStore` gained `entries(ofKind:)` (id+blob pairs)
      to back `allStatuses()`. `@Model` stays in Infrastructure.
- [x] **`MarkStatusUseCase` (Business).** `callAsFunction(jobID:stage:)` loads-or-defaults,
      `advanced(to:on: now())`, persists, returns the new status. `LoadStatusUseCase` +
      `LoadTrackedJobsUseCase` (joins statuses with saved jobs) round out the set.
- [x] **Fetch applied set.** `SavedStatusRepository.allStatuses()` (id → status);
      `LoadTrackedJobsUseCase` produces the `[TrackedJob]` the tracker lists.
- [x] **Tests.** `SavedStatusRepositoryTests` (round-trip, upsert, allStatuses map);
      `StatusUseCaseTests` (mark stamps+persists with an injected clock, advances keeping
      earlier stamps, the tracked-jobs join, empty cases).

### P-C — Tracker UI + status affordances  ✅ done

- [x] **Status control on the detail view.** `JobDetailView` gained a "Application status"
      section: a one-tap "Mark as applied" (when untracked) + a "Set status" menu for the
      other stages, showing the current `StatusBadge`. Loads the status on `.task`, marks
      via `MarkStatusUseCase` (auto date).
- [x] **Tracker screen (`Tracker/View` + `Tracker/ViewModel`).** `TrackerViewModel` lists
      `TrackedJob`s sorted by most-recent status activity; `TrackerView` shows them
      (reusing `RankedRow` + badge), tap opens the detail; reloads after the sheet closes.
- [x] **Status badge on `RankedRow`.** New reusable `StatusBadge` ("Applied · Jun 12",
      coloured by stage). `ResultsViewModel` loads statuses (via `LoadTrackedJobsUseCase`)
      and badges rows; refreshes when the detail sheet closes.
- [x] **Navigation.** Added a **Tracker** tab to `RootView`'s `TabView`, wired through
      `Composition` (`makeTrackerViewModel`; `markStatus`/`loadStatus` threaded to the
      detail from both Results and Tracker).
- [x] **Tests / previews.** `TrackerViewModelTests` (empty, most-recent-first ordering,
      select); `StatusBadge`/`TrackerView` previews.
- [x] **Docs.** SPEC (tracker in the flow, human-in-the-loop); CLAUDE.md (`ApplicationStatus`
      + `TrackedJob` in Key types, Tracker screen, the three status use cases, and the
      `SavedStatusRepository` mapping).

Note: P-A/P-B/P-C layer bottom-up (model → persistence → UI). The whole milestone sits on
Milestone O's persistence port — do O-B first. Keeps the "no auto-submission" non-goal
intact: this records what the user did, it doesn't act on job sites.

---

# v3 — output & polish

Get the generated materials cleanly *out* of the app (Export), finish the persistence
fast-follow (saved/re-runnable searches), and polish the app that produces them. Milestones
Q (Export), R (Saved searches), S (Polish), T (two-document portfolio), U (expanded search
parameters), V (results ↔ tracker interaction), W (results filtering); X (templates + one-page
gate) is a stretch. **The letters are a catalogue, not the build order** — follow the recommended
order just below. Layer dependency rule still applies (Presentation → Business → Data →
Infrastructure); respect it within each milestone.

## Recommended implementation order (v3)

Build in these phases — fixes first, then features grouped so dependencies flow forward, then a
cohesive polish pass, then the stretch. **Hard dependencies** are called out; everything else is a
soft preference a session can reorder.

**Phase 1 — Fix what's broken (fast, low-risk, do first)**
1. **Hotfix — job-posting URL fetch.** A shipped feature is dead; the fix is small and high-visibility.
2. **S-D — scrollable screens** (small-window scroll bug) + **S-E — saved-profile tile gestures**
   (whole-tile tap/long-press). Cheap Presentation fixes; land them alongside the hotfix.

**Phase 2 — Highest-value output**
3. **Q — Export** (**Q-A** copy/Markdown → **Q-B** PDF → **Q-C** DOCX — hard order; Q-C hand-rolled
   OOXML is heaviest, so last). The flagged top-value feature. Attach the export control to the
   **Application sheet** (where the generated kit lives), *not* the Results job-detail footer — V
   removes generation from there.

**Phase 3 — Grounding & search depth**
4. **T — Two-document portfolio** (**T-A** input + model → **T-B** generation grounding; T-A ships on
   its own).
5. **U — Expanded search parameters** (fields + stores U-A/U-B/U-C → **U-D** result-count goal →
   **U-E** search-time min-rank → **U-F** wiring). Grows `JobSearchRequest`.
6. **R — Saved / re-runnable searches.** *Recommended after U* so a saved search captures the new
   optional params from the start (otherwise R is revisited when `JobSearchRequest` grows).

**Phase 4 — Results experience**
7. **V — Results ↔ Tracker interaction overhaul** (**V-A** delete → **V-B** save → **V-C** swipe →
   **V-D** generation-move → **V-E** wiring). Reshapes how results are acted on; moves generation to
   the Tracker.
8. **W — Results filtering.** **After V** (hard-ish): W's delete/save act on the *filtered* rows and
   it shares the Results view V just changed.

**Phase 5 — Cohesive polish (after the features that add new states)**
9. **S-A / S-B / S-C** — in-app markdown rendering, empty/loading/error states, results/saved/Tracker
   cohesion. Do these near the end so the empty/error states cover the *new* states from U (result
   shortfall / none-met-minimum), V (save/tracker flows), and W (empty-filtered). S-A composes with
   Q-A's copy action.

**Stretch (only if time remains)**
10. **X — Export templates + one-page gate.** Depends on the Q-B renderer choice; promote only if Q
    finished early, else it seeds v4.

**Hard dependencies at a glance:** Q-A→Q-B→Q-C · T-A→T-B · **U before R** · **V before W** · broad
polish (S-A/B/C) after U/V/W · X after Q-B. (Milestone **S is deliberately split**: its two bug-fixes
S-D/S-E go in Phase 1; its broad polish S-A/B/C lands in Phase 5.)

**Start at the Hotfix below.**

## 🔧 Hotfix — job-posting URL fetch is broken  ⬜ do first  (Search flow: `SearchViewModel` / `SearchView` / `FetchPostingUseCase` / `LinkJobPostingSource` / RootView)

Goal: the Search screen's "Or generate from a specific posting" flow (shipped in Milestone
M-A) doesn't work — pasting a URL and pressing **Fetch** produces no result: the posting is
never fetched/ranked and nothing appears in the Results tab. It must behave **exactly like a
keyword search**: fetch → extract → rank → push a single `RankedJob` into Results (auto-jump),
or show a clear, prominent failure with the paste-text fallback. The plumbing already exists
end-to-end, so this is **reproduce → root-cause → fix**, not a rebuild.

- [ ] **Reproduce with a real posting URL** and confirm the failure mode. The known-good
      path is `SearchView` Fetch button → `SearchViewModel.fetchFromLink()` sets
      `results = [try await fetchPosting(url:profile:)]` → `RootView.onChange(of: search.results)`
      copies to `results.results` and jumps to the Results tab. Determine **where it breaks**.
- [ ] **Check the strongest candidates first** (found during planning — verify, don't assume):
      1. **Button gated / no fetch attempted.** `canFetchLink` requires `hasProfile` **and** a
         non-empty `postingURL`; if the Search VM's `profile` isn't set (or the URL fails the
         `http/https` scheme check), the button is disabled or `fetchFromLink` returns early —
         "it doesn't even fetch." Confirm `search.profile` is actually populated on the Search tab.
      2. **`.unreadable` thrown but not noticed.** Most real job boards are JS-gated or block
         non-browser requests → `LinkJobPostingSource.fetchPosting` throws `JobPostingSourceError.unreadable`
         (non-2xx, non-UTF8 body, stripped text under `minReadableCharacters`, or extractor
         returns not-`looksReal`). The VM sets a small red `errorMessage` the user may overlook.
      3. **Result set but not propagated.** Verify `onChange(of: search.results)` fires for the
         single-item fetch result the same way it does for `search()` (same `results` property,
         so it should — but confirm it isn't overwritten by `ResultsViewModel`'s saved-jobs load).
- [ ] **Fix the identified break** so a valid posting URL yields a ranked result in Results,
      indistinguishable from a keyword-search result (same detail → generate flow).
- [ ] **Make failure visible + actionable.** If a page truly can't be read, surface the error
      prominently (not a small trailing label) and point to the paste-text fallback. Never fail silently.
- [ ] **Harden the fetch (as needed).** Consider a browser-like `User-Agent`/`Accept` header
      and non-UTF8 decoding fallback so common boards succeed rather than tripping `.unreadable`;
      keep the "fail loudly, never guess a role" contract intact.
- [ ] **Regression test.** `SearchViewModelTests`: a stubbed `FetchPostingUseCase` success sets
      `results` to the single ranked job (so RootView would propagate + jump); a `.unreadable`
      throw sets a visible `errorMessage` and leaves `results` untouched; the pasted-text path
      likewise. Assert the Fetch gating (`canFetchLink`) with/without profile + URL.
- [ ] **Docs.** Tick the ROADMAP hotfix; note the root cause + fix in this item when done.

Note: this is a defect in v2's Milestone M-A, pulled to the front of v3 because it blocks a
shipped feature. It touches only the Search/fetch flow — no new seam, no layer-rule change.

## Milestone Q — Export résumé & cover letter  ⬜ not started  (`Infrastructure/Export`, `Business/UseCases`, Application/detail UI)

Goal: let the user get a generated `ApplicationKit` (résumé + cover letter) out of the app as
polished files — copy, Markdown/plain-text, PDF, and true DOCX. New `DocumentExporter` seam
(Infrastructure — CLAUDE.md reserves "exporters" as protocol-worthy). Native rendering only;
AGENT.md's LaTeX/PDF toolchain stays out of scope. Q-A lands first (no rendering questions),
Q-B is the core value, Q-C is the heaviest single piece — all three share one port + use case.

### Q-A — Copy + Markdown / plain-text export  ⬜

- [ ] **`DocumentExporter` port (Infrastructure/Export).** `export(_ kit: ApplicationKit,
      as: ExportFormat) throws -> Data` (bytes; the Presentation layer owns the file dialog).
      `ExportFormat` enum (`.markdown`, `.plainText`, `.pdf`, `.docx`). Port declared in
      Infrastructure; format impls live here. `Sendable`, no UIKit/AppKit file coupling.
- [ ] **Markdown + plain-text impls.** Markdown = the kit's `resumeMarkdown` + `coverLetter`
      assembled under clear headings; plain-text = markdown stripped (reuse the
      `HTMLStripper`-style plain rendering pattern). Pure, unit-testable.
- [ ] **`ExportApplicationUseCase` (Business).** `ApplicationKit` + `ExportFormat` → `Data`;
      no SwiftUI, no `.fileExporter`, no `Process`.
- [ ] **Presentation affordance.** Export menu + **copy-to-clipboard** on `ApplicationSheet`
      / `JobDetailView`; save-as via `.fileExporter`. Disabled until a kit exists. Wired
      through `Composition`.
- [ ] **Tests.** Exporter (markdown assembles both docs with headings; plain-text strips
      markup); `ExportApplicationUseCase`; VM export/copy action (format routing, disabled
      when no kit).

### Q-B — PDF export  ⬜

- [ ] **Decide the renderer (design step, record the choice in this milestone).**
      HTML-template→PDF (WebKit print — best fidelity, enables the one-page gate + templates)
      vs AttributedString→PDF (native, lighter, coarser layout, harder one-page gate). Note
      *why* before building — this gates Milestone X.
- [ ] **PDF impl (Infrastructure/Export).** Markdown → styled PDF `Data` via the chosen path;
      deterministic layout; embeds nothing external (self-contained, no network/fonts fetch).
- [ ] **Wire into the export menu + `.fileExporter`** (`.pdf`).
- [ ] **Tests.** A sample kit produces non-empty, valid PDF bytes; failure is surfaced, never
      crashes. (Visual fidelity is a manual check — note it.)

### Q-C — DOCX export (hand-rolled OOXML)  ⬜

- [ ] **Minimal OOXML `.docx` writer (Infrastructure/Export).** macOS has **no native `.docx`
      writer** — build a minimal zipped-OOXML package (`[Content_Types].xml`,
      `word/document.xml`, `_rels/.rels`, `word/_rels/document.xml.rels`) from the kit's
      Markdown. Pure Swift, no external deps (Foundation + a small zip helper / `Compression`).
- [ ] **Map Markdown → OOXML.** Headings, paragraphs, bold/italic, bullet lists — the subset
      the résumé/cover letter actually use. Unsupported markup degrades to plain paragraphs
      (never crashes). Document the fidelity limits in the milestone.
- [ ] **Wire into the export menu + `.fileExporter`** (`.docx`).
- [ ] **Tests.** Output is a valid zip containing the required parts; a known kit yields the
      expected `document.xml` structure (assert on parsed XML, not byte-exact); opens in Word
      (manual check).

Note: all three formats sit behind the single `DocumentExporter` port + `ExportApplicationUseCase`
— adding a format is a new `ExportFormat` case + impl, no new seam.

## Milestone R — Saved / re-runnable searches  ⬜ not started  (`Data/Persistence`, `Business/UseCases`, Search UI)

Goal: finish the persistence fast-follow — let the user **save a search** (titles + shared
location + salary floor) and **re-run** it later against the current profile, deduping against
already-seen listings. Builds on Milestone O's `PersistentRecordStore`. (The other half of the
old fast-follow — caching the built profile across launches — already shipped via named
`SavedProfile`s, so it's **done**; don't re-spec it.)

- [ ] **Persist `JobSearchRequest`.** New `SavedSearchesRepository` (Data/Persistence) on the
      existing `PersistentRecordStore`, `kind` "savedSearch", keyed by a stable id derived from
      the request (or a generated id + a display name). `JobSearchRequest` stays a clean
      `Codable` domain type; `@Model` stays in Infrastructure. Upsert so re-saving the same
      request doesn't duplicate.
- [ ] **Save / load / delete use cases (Business).** `SaveSearchUseCase`,
      `LoadSavedSearchesUseCase`, `DeleteSavedSearchUseCase`; **re-run reuses
      `SearchAndRankUseCase`** (no new search logic).
- [ ] **Dedupe against already-seen.** On re-run, flag or filter listings already in
      `SavedJobsRepository` (reuse `contains(jobID:)`) so "new since last run" is visible.
- [ ] **Search UI.** A "Saved searches" affordance on the Search screen: a **Save this search**
      action (enabled once a profile + at least one title exist) and a list of saved searches,
      each with **Run** (feeds the existing pipeline → Results tab) and **Delete**.
      `SearchViewModel` holds the saved list; wired through `Composition`.
- [ ] **Tests.** `SavedSearchesRepositoryTests` (round-trip, upsert collapses dupes, delete);
      `SearchViewModel` save/list/run/delete; re-run dedupes against saved jobs.
- [ ] **Docs.** SPEC (persistence note → saved searches now persist — done in this planning
      pass); CLAUDE.md (`SavedSearchesRepository` in Data/Persistence + the three use cases);
      ROADMAP v3 tick.

## Milestone S — Polish pass  ⬜ not started  (mostly Presentation; small Data/use-case touches)

Goal: make the six-tab app feel finished. Three independent parts — ship in any order.

### S-A — In-app markdown rendering  ⬜

- [ ] **Render the generated résumé + cover letter as styled text** (SwiftUI
      `Text(AttributedString(markdown:))` or an equivalent renderer) instead of raw markdown,
      on `ApplicationSheet` / `JobDetailView`.
- [ ] **Copy buttons** per document (résumé, cover letter) — composes with Q-A's clipboard export.
- [ ] **Tests / previews.** Renderer helper unit-tested (markdown → attributed); previews for
      both documents.

### S-B — Empty / loading / error states  ⬜

- [ ] **Consistent states across all six tabs** — no profile (Portfolio/Search gated), no
      results, no saved/tracked jobs, and clear fetch/generation **failure** messaging (reuse
      the existing warning/unavailable copy patterns). No silent blank screens.
- [ ] **Loading affordances** for the async steps (build profile, search, fetch posting,
      generate, export) — a consistent spinner / disabled-state convention.
- [ ] **Tests.** VM state flags (`isLoading`, empty vs populated, error message) per screen.

### S-C — Results / saved-jobs / Tracker cohesion  ⬜

- [ ] **One history story.** Make "already seen" (saved listing), "already generated" (saved
      `ApplicationKit`), and "applied" (`ApplicationStatus`) legible together — badges on
      `RankedRow` and a coherent path between Results, saved jobs, and the Tracker.
- [ ] **Reconcile loads.** Results/Tracker read the same persisted sources without clobbering a
      fresh search (extends O/P load behaviour).
- [ ] **Tests.** Badge/state assembly (seen / generated / applied) on a `RankedJob`; no-clobber
      on a fresh search.

### S-D — Scrollable screens / small-window layout (bug fix)  ⬜

Bug: the **Portfolio tab can't scroll when the window is short** — its content is a plain
`VStack { … Spacer() }.padding(24)` with no scroll container, so once the stacked content
(title → description → `TextEditor` → buttons → profile summary → source-document disclosure →
save row → saved-profiles list) exceeds the window height it's clipped and the lower controls
are **unreachable**. The trailing `Spacer()` compounds it. At least `SearchView` shares the
same pattern, so treat this as a cross-tab fix.

- [ ] **Wrap Portfolio content in a `ScrollView`.** Move the `VStack` into a `ScrollView`
      (vertical) so all controls stay reachable at any window size; drop the now-meaningless
      trailing `Spacer()` (or move alignment handling to the scroll content). Keep the `.padding(24)`.
      File: `lib/src/Presentation/Portfolio/View/PortfolioView.swift`.
- [ ] **Audit + fix the other tabs sharing the pattern.** Confirmed: `SearchView`
      (`VStack { … Spacer() }.padding`, no `ScrollView`). Check `Results`, `Tracker`,
      `Settings`, and the `Application` sheet too; wrap any that clip when the window is short.
      Prefer a consistent convention (e.g. a small `ScrollableScreen` container or the same
      `ScrollView` wrapper on each) so it doesn't regress per-screen.
- [ ] **Preserve inner scroll regions.** Portfolio's source-document `DisclosureGroup` already
      has its own bounded `ScrollView` (`maxHeight: 220`); make sure the outer `ScrollView`
      composes with it (and with the `TextEditor`) without gesture conflicts or a collapsed frame.
- [ ] **Manual check.** Resize the window very short on each tab and confirm every control is
      reachable by scrolling; no clipped buttons, no trapped content. (Layout is a manual/visual
      check — note it; no unit test asserts scrollability.)

### S-E — Saved-profile tile gestures  ⬜

Today a saved-profile tile's tap (`toggleSelection`) and long-press (`setDefault`) gestures sit
on the inner radio-dial + text HStack only, so the user has to hit the dial/title. Make the
**whole tile** the target.

- [ ] **Long-press anywhere → set default.** Move the `setDefault` long-press gesture from the
      inner HStack to the entire row/tile in `savedProfileRow`
      (`lib/src/Presentation/Portfolio/View/PortfolioView.swift`).
- [ ] **Tap anywhere → show/load the profile.** Move the `toggleSelection` tap gesture to the whole
      tile (with `.contentShape(Rectangle())` so empty space is hittable), so a click anywhere loads
      the profile — not only the radio dial. The dial stays as the selection **indicator**, no longer
      the required tap target.
- [ ] **Keep the trash button independent.** The delete button must still intercept its own taps
      (not trigger select/default); verify the row tap + long-press coexist with it (the existing
      `simultaneousGesture` pattern for tap-vs-long-press stays).
- [ ] **Tests / manual.** `PortfolioViewModel` `toggleSelection` / `setDefault` are already covered;
      this is a gesture-placement change — a manual check that tapping/long-pressing anywhere on the
      tile (including padding) works and delete is unaffected.

## Milestone T — Two-document portfolio (résumé + cover letter) as generation grounding  ⬜ not started  (`Data/Models`, Portfolio input, `TidyDocumentUseCase`, `GenerateApplicationUseCase` / `LLMProvider` / `Prompts`, Application plumbing)

Goal: the Portfolio tab accepts **two** documents — a résumé/portfolio (the existing import,
now the primary slot) and an **optional cover letter** — and both are referenced when
generating a job's tailored materials. The résumé/portfolio stays the **factual** grounding
(the `CandidateProfile` is still distilled from it; its real text grounds both outputs); the
uploaded cover letter is a **voice / tone / structure exemplar** for the generated cover letter
— mirror the candidate's real style, but **never import facts, claims, metrics, employers, or
dates from it** (the "never fabricate" guardrail holds; facts come from the résumé/profile).
Cover letter is optional and back-compatible with existing single-document profiles. This is
the concrete realization of SPEC's "inject the bounded portfolio directly into generation",
extended to two documents (later upgradable to embedding retrieval over the same documents).

### T-A — Two-document input + model  ⬜

- [ ] **Extend `SavedProfile` with cover-letter document fields.** Add `coverLetterFileName:
      String?`, `coverLetterText: String` (raw), `coverLetterReadableText: String` (LLM-tidied)
      alongside the existing résumé/portfolio `sourceFileName` / `sourceText` / `readableText`.
      Keep the custom `init(from:)` legacy-decode pattern so older single-document saves still
      load (new fields default to nil/empty). `@Model` stays in Infrastructure (blob only).
- [ ] **Second import/paste slot on the Portfolio tab.** Relabel the existing import as
      **"Résumé / portfolio"**; add an optional **"Cover letter"** import/paste slot. Both reuse
      `ImportPortfolioUseCase` / `DocumentTextExtractor` + `.fileImporter` (same accepted types).
      The cover letter never gates Build Profile (`canBuild` unchanged).
- [ ] **Tidy both documents on build.** Run `TidyDocumentUseCase` (routed through the `.profile`
      task) on the cover letter too, storing `coverLetterReadableText`. The `CandidateProfile`
      is **still distilled from the résumé/portfolio only** — the cover letter is not mined into
      profile facts.
- [ ] **Show both source documents.** The Portfolio source-document `DisclosureGroup` gains a
      second (collapsed) section for the cover letter when present.
- [ ] **Tests.** `SavedProfile` round-trip incl. cover-letter fields + legacy decode (old blob →
      empty cover-letter fields); `PortfolioViewModel` imports/pastes a cover letter; build tidies
      both; build still works with no cover letter (optional).

### T-B — Reference both documents in generation  ⬜

- [ ] **Carry the documents to generation.** Introduce a lightweight `PortfolioGrounding` value
      (`resumeText: String`, `coverLetterText: String?` — the tidied readable forms) and thread it
      from the active profile / `SavedProfile` through `ApplicationViewModel.open` / `generate` and
      the RootView / Results / Tracker wiring, so generation has the documents even for a freshly
      built, unsaved profile.
- [ ] **Grow the generation seam.** `GenerateApplicationUseCase.callAsFunction(job:profile:grounding:)`
      passes the grounding to `LLMProvider.generateApplication(for:profile:brief:grounding:)`. Keep
      both engines in lockstep — all new text lives in the shared `Prompts` enum.
- [ ] **Inject grounding in the prompt.** The résumé/portfolio real text = **factual grounding**
      for both outputs (reorder/rephrase real experience only). The cover letter = a **voice / tone
      / structure exemplar** for the generated cover letter, with an explicit guardrail: match the
      candidate's voice and the *About Me / Why \<company\> / Why Me* structure, but **do not** import
      claims, metrics, employers, or dates from it as facts — facts come from the résumé/profile.
      Bound both inputs (truncate for the small on-device context; reuse the existing `max…Characters`
      bounds).
- [ ] **Back-compat / fallback.** No cover letter (optional) or no stored document text (legacy
      profile) → generation falls back to today's profile-only grounding, unchanged.
- [ ] **Tests.** `PromptsTests`: the generation prompt includes the résumé grounding + a
      cover-letter voice section + the "don't fabricate from the letter" guardrail; bounding applies;
      an absent cover letter omits the voice section cleanly. `GenerateApplicationUseCase` threads
      `grounding`; `ApplicationViewModel` passes the active documents; router/use-case delegation.
- [ ] **Docs.** SPEC (two-document input + cover-letter-as-voice-reference under "Grounded
      generation" — done in this planning pass); CLAUDE.md (`SavedProfile` second document,
      `PortfolioGrounding`, the grown `generateApplication` signature + `GenerateApplicationUseCase`).

Note: T-A (input + model) is independently shippable — it enriches what's saved even before
generation uses it; T-B wires the grounding into output. The cover letter stays voice-only **by
decision** (facts strictly from the résumé/portfolio), keeping the "never fabricate" principle
enforceable. Composes with the embedding-RAG backlog item, which would later retrieve top-k chunks
from these same documents instead of injecting them whole.

## Milestone U — Expanded, optional search parameters  ⬜ not started  (`Data/Models`, `Data/Search`, `AdzunaJobSource`, `SearchAndRankUseCase`, `SearchViewModel` + Search UI)

Goal: enrich the search step with more control — a position-type filter, a typeable **and
saveable** location and salary, a **desired-result-count goal**, and a **minimum-rank filter**.
Every field is **optional**: leaving them blank produces exactly today's `JobSearchRequest` and
today's behaviour. Sub-parts A–F are separable and each lands without breaking the current flow.

### U-A — Position-type filter  ⬜

- [ ] **`PositionType` domain type (`Data/Models`).** `nonisolated` `Codable`/`Sendable` enum
      (e.g. `fullTime`, `partTime`, `contract`, `permanent`) with a `label`. Add an optional
      `positionType` to `JobSearchRequest` (shared across titles) → `JobQuery`.
- [ ] **Map to Adzuna.** `AdzunaJobSource.buildURL` translates it to Adzuna's contract params
      (`full_time` / `part_time` / `contract` / `permanent`); Adzuna specifics stay private. Nil
      ⇒ no param (unchanged URL).
- [ ] **UI.** An optional picker on Search ("Any" default).
- [ ] **Tests.** `buildURL` includes the right param when set and is unchanged when nil;
      `JobSearchRequest.query(forTitle:)` propagates it.

### U-B — Typeable + saveable location (can become a preset)  ⬜

- [ ] **`LocationStore` (Data/Search, on `KeyValueStore`).** Mirrors `RoleTitleStore`: a
      persisted library of user-saved locations; round-trip + corrupt→empty. `SuggestionProvider`
      merges static locations + saved ones (dedup, keep "Anywhere"/"Remote").
- [ ] **Typeable input.** Location becomes a combo — type a custom value *or* pick a preset;
      single-value semantics unchanged (`JobSearchRequest.location` stays one optional string).
- [ ] **Save / remove as preset.** A "save this location" affordance persists a typed value into
      `LocationStore` (and a remove-from-library control), mirroring the common-role-titles UX but
      single-select.
- [ ] **Tests.** `LocationStoreTests` (round-trip, shared-backing persistence, corrupt→empty);
      `SuggestionProvider` merge; `SearchViewModel` type/save/select/remove.

### U-C — Typeable + saveable minimum salary (can become a preset)  ⬜

- [ ] **Custom salary presets store (Data/Search).** Same pattern as U-B for salary — a persisted
      library of user-saved salary floors joined with `SuggestionProvider.salaryPresets`.
- [ ] **Typeable input.** A numeric field alongside the preset brackets; parse + validate (ignore
      non-numeric); nil ⇒ "Any". `JobSearchRequest.salaryMin` stays one optional value.
- [ ] **Save / remove as preset.** Save a typed floor into the library (+ remove).
- [ ] **Tests.** Store round-trip/persist; `SearchViewModel` parse/save/select; invalid input ignored.

### U-D — Desired result count (a soft goal)  ⬜

- [ ] **Optional `desiredResultCount: Int?` on `JobSearchRequest`.** Drives how many listings the
      search pulls/ranks: `SearchAndRankUseCase` raises `JobQuery.resultsPerPage` (up to Adzuna's
      max, 50) and/or **pages** additional pages per title until the merged + deduped count reaches
      the goal or the sources are exhausted.
- [ ] **Never fail if unreachable.** If the goal can't be met, return what's available with a soft
      note (e.g. `Output.resultShortfall` → "found 12 of a desired 25"); the run never throws for a
      shortfall. Bound the effort with a **page cap** + the existing `maxConcurrentSearches`
      rate-limit guard.
- [ ] **Design note (record in the milestone).** Whether the goal counts candidates *fetched/ranked*
      vs *final results after the U-E score filter*. Default: it targets fetched/ranked candidates,
      and the final shown count may be lower once U-E trims — note this to the user.
- [ ] **Tests.** Goal reached stops paging early; goal unreachable returns all available + note (no
      throw); page cap respected; nil ⇒ today's single-page behaviour.

### U-E — Minimum-rank (score) filter  ⬜

- [ ] **Optional `minimumScore: Int?` (0–100) on `JobSearchRequest`.** After `ranker.rank`,
      `SearchAndRankUseCase` keeps only `RankedJob`s with `match.score >= minimumScore`.
- [ ] **Distinguish "none qualified" from "none found".** When the filter empties the set, the
      output flags it (e.g. `Output.filteredOutByScore` / a `noneMetMinimum` note) so the VM shows
      "No results met your minimum rank of N" — different copy from "no results found at all".
- [ ] **Composes with multi-title + the goal.** Filter applies once, post-rank, over the merged set.
      Nil ⇒ no filtering.
- [ ] **Tests.** Filters below threshold; all-below → empty + `noneMetMinimum`; nil ⇒ unfiltered;
      composes with U-D (goal fetches, filter trims).

### U-F — Search UI + wiring  ⬜

- [ ] **`SearchViewModel` fields.** Add optional `positionType`, typeable `location` + saved
      locations, typeable `salaryMin` + saved salary presets, `desiredResultCount`, `minimumScore`.
      `canSearch` is **unchanged** (all new fields optional). Assemble the `JobSearchRequest` from
      whatever is set.
- [ ] **Surface the new notes distinctly.** Wire the result-count shortfall and the
      none-met-minimum outcomes into separate, clear messages (feeds Milestone S's empty/error-state
      polish).
- [ ] **Composition.** Wire the new `LocationStore` / salary-preset store; persisted presets reload
      on launch like role titles.
- [ ] **Tests.** Request assembly with any subset of optional fields; **back-compat** — all blank ⇒
      byte-for-byte the same `JobSearchRequest` the app builds today.
- [ ] **Docs.** SPEC ("Search → listings": the optional new params — done in this planning pass);
      CLAUDE.md (`PositionType`, `LocationStore` + salary-preset store, the grown `JobSearchRequest`/
      `JobQuery`, the use-case goal-paging + score filter, the `SuggestionProvider` merge).

Note: A–F are independent and every field is optional, so each ships on its own and none changes
the default search. U-D (paging toward a goal) is the one that adds real API load — cap pages and
respect Adzuna's free-tier rate limits. U composes with Milestone R (a saved search can carry these
new optional fields once `JobSearchRequest` grows) and with Milestone N's existing title fan-out.

## Milestone V — Results ↔ Tracker interaction overhaul  ⬜ not started  (`Data/Persistence`, `Business/UseCases`, Results/Tracker Presentation, `JobDetailView`)

Goal: change how the user acts on a ranked result. Add per-row **Save to Tracker** + **Delete**
icons; make the opened result a **swipeable card** (right = save, left = dismiss); and **move
generation entirely to the Tracker** — from Results the user reads the posting and chooses only
whether to save. "Save to Tracker" = mark the job `saved` (`MarkStatusUseCase`, Milestone P), so
it appears in the Tracker; "Delete" = fully forget it (per decision). Generation from the Tracker
(brief → tailor, persisted `ApplicationKit`) is unchanged.

### V-A — Delete a result (row trash icon + persistence)  ⬜

- [ ] **Repository + use case.** `SavedJobsRepository.delete(jobID:)` (on the store's existing
      delete); a `DeleteSavedJobUseCase` (Business) that — per the "remove from both" decision —
      also clears the job's **status** (`SavedStatusRepository.delete(jobID:)`, add if absent) and
      its saved **`ApplicationKit`** (`SavedApplicationsRepository.delete(jobID:)`), so nothing is
      orphaned.
- [ ] **Trash icon on the Results row.** A trailing trash button on each result tile (right-most).
      Keep `RankedRow` reusable — add the actions in the Results row composition (or via optional
      `onDelete`/`onSave` closures), **not** baked into `RankedRow` (the Tracker reuses it and must
      not get a Results trash).
- [ ] **`ResultsViewModel.delete(_:)`.** Remove from `results` and call `DeleteSavedJobUseCase`;
      refresh badges. Consider a lightweight confirm (destructive + persistent).
- [ ] **Tests.** `SavedJobsRepository` delete; `DeleteSavedJobUseCase` clears job + status + kit;
      `ResultsViewModel.delete` drops the row and persists; deleting a tracked job also removes it
      from the tracker (via `LoadTrackedJobsUseCase` no longer returning it).

### V-B — Save a result to the Tracker (row save icon)  ⬜

- [ ] **Save icon left of the trash icon.** Tapping marks the job `saved` via
      `MarkStatusUseCase(jobID:, stage: .saved)` (ensuring the listing is persisted first so the
      tracker join has it), then the row shows a "Saved" `StatusBadge`.
- [ ] **`ResultsViewModel.saveToTracker(_:)`.** Marks `.saved`, upserts the listing if needed,
      refreshes `statusesByID`. Idempotent — an already-tracked job shows its current badge and the
      icon reflects the tracked state (no downgrade of a later stage).
- [ ] **Tests.** Save marks `.saved` + persists the listing + badge appears; already-tracked job is
      reflected and not downgraded.

### V-C — Swipeable result card (right = save, left = dismiss)  ⬜

- [ ] **Draggable detail card.** In the Results context, the opened `JobDetailView` becomes a card
      the user drags horizontally (macOS trackpad/mouse `DragGesture`): drag **right** past a
      threshold → save to Tracker (`.saved`) then dismiss; drag **left** past threshold → dismiss
      without saving/deleting; small drags snap back, with a card offset + a subtle save/dismiss hint.
- [ ] **Pure outcome helper.** Extract `swipeOutcome(forTranslation:threshold:) -> {save|dismiss|none}`
      so the decision logic is unit-testable; the gesture wiring + animation are a manual-feel check.
- [ ] **Tests.** `swipeOutcome` thresholds (right→save, left→dismiss, small→none). Note the gesture
      feel is manual.

### V-D — Move generation to the Tracker only  ⬜

- [ ] **Generation-context flag on `JobDetailView`.** Add e.g. `canGenerate: Bool` (or a
      `context: .results | .tracker`). **Results** passes `false`; **Tracker** passes `true`.
- [ ] **Results context.** No "Generate résumé & cover letter" button and no `ApplicationSheet`
      path; the footer instead offers **Save to Tracker** (mark `.saved`). The user reads the JD +
      saves; generation is unreachable from Results.
- [ ] **Tracker context.** Generate button + the `ApplicationSheet` save/load `ApplicationKit`
      flow (Milestone O-C) unchanged.
- [ ] **Tests.** `JobDetailView` in Results context exposes Save and no Generate; in Tracker context
      exposes Generate; routing holds.

### V-E — Wiring, empty states, copy  ⬜

- [ ] **Composition.** Wire `DeleteSavedJobUseCase`; thread `markStatus` to the Results **rows**
      (not just the detail) for the save icon; pass the generation-context flag from Results vs Tracker.
- [ ] **Copy.** Update the Tracker `ContentUnavailableView` ("Save a result from the Results tab to
      track it here.") and any Results help text. Composes with Milestone S (empty/error states).
- [ ] **Tests / previews.** Composition smoke; Results row with save+trash preview; Tracker
      empty-state copy.
- [ ] **Docs.** SPEC (save-from-results → generate-from-tracker; delete — done in this planning
      pass); CLAUDE.md (`DeleteSavedJobUseCase`, `SavedJobsRepository.delete`, the Results row
      actions, the `JobDetailView` generation-context flag, "save to tracker = mark `.saved`", and
      the updated Tracker entry path).

Note: V builds on Milestones O (persistence) and P (status) — no new status model, and "save" is
just marking `.saved`. Sub-parts are mostly independent (V-A delete, V-B save-icon, V-C swipe, V-D
generation-move); V-D is the one behaviour change users will notice most, so pair it with the
Tracker-copy update in V-E.

## Milestone W — Results filtering  ⬜ not started  (`ResultsViewModel`, a pure `ResultsFilter`, Results UI)

Goal: let the user **interactively narrow the displayed ranked results** in the Results view — by
minimum rank, keywords, location, and a few more facets — **without re-running the search**.
Non-destructive: filters only hide rows (delete/save still act on what's shown). **Distinct from
Milestone U-E's search-time min-rank filter** (which trims the persisted/ranked set); W is a **live,
reversible view filter** over the already-loaded `[RankedJob]`.

- [ ] **Pure `ResultsFilter`** (Presentation/Results, or Data if reused). A `Sendable`/`Equatable`
      value holding the active filters — `minScore: Int?`, `keywords: String`, `location: String?`,
      plus optional facets (`company: String?`, `salaryMin: Double?`, a tracked-status facet) — with a
      pure `apply(to: [RankedJob]) -> [RankedJob]` (AND across active filters; an empty filter ⇒
      identity). Keyword match is case-insensitive substring over title + company + description +
      matched skills (**record the exact field set** as a small design decision). Unit-tested.
- [ ] **`ResultsViewModel` filter state.** Hold a `ResultsFilter`; expose `filteredResults`
      (`filter.apply(to: results)`) and `visibleCount` / `totalCount`. The `List` iterates
      `filteredResults`; the status/badge map is unchanged. Filters **never** mutate `results` or
      persistence.
- [ ] **Filter bar UI.** A collapsible filter section atop the Results list: a **min-rank**
      slider/stepper (0–100), a **keyword** search field, a **location** picker (populated from the
      locations present in the current results, + "Any"), and the optional facets (company field,
      salary floor, tracked-status). A **Clear filters** button and a "Showing X of Y" count.
- [ ] **Options from the data.** Populate the location (and company) pickers from the *distinct*
      values in the loaded results, so they only offer values that can actually match.
- [ ] **Empty-filtered state.** When the active filter excludes everything, show "No results match
      your filters" + a Clear action — distinct from the "No results yet" empty state (composes with
      Milestone S-B).
- [ ] **Composes with V.** Delete (V-A) and save-to-tracker (V-B) act on the **visible (filtered)**
      rows; a filtered-out row is never deleted. Filters are session-only (reset on relaunch; a
      saved-filter option is a later idea).
- [ ] **Tests.** `ResultsFilter.apply` (each facet; AND composition; empty ⇒ identity; keyword field
      coverage; min-rank boundary); `ResultsViewModel` filteredResults + counts + clear;
      empty-filtered state.
- [ ] **Docs.** SPEC (ranked results are interactively filterable — done in this planning pass);
      CLAUDE.md (`ResultsFilter` + the Results filter state; note it's view-only, distinct from U-E).

Note: W is **view-only** over loaded results — no new persistence, no re-search. It layers cleanly
on V (row actions over the filtered list) and complements U without overlap: **U decides what gets
searched/ranked; W decides what's shown of the results.**

## Milestone X — Export templates + one-page gate  ⬜ stretch (v3 stretch / v4 seed)

Goal (only if Q-B lands with room to spare): 1–2 selectable résumé templates and AGENT.md's
**one-page length gate**. Depends on the Q-B renderer choice — the HTML-template path makes both
realistic; the AttributedString path makes them harder (revisit if that was chosen).

- [ ] **Template selection.** A small set of styled templates the exporter can target; the user
      picks one at export time. Seam: extend `DocumentExporter` / `ExportFormat` with a template
      parameter (don't add a new port).
- [ ] **One-page gate.** Measure rendered length; warn (or offer a tightened variant) when the
      résumé overflows one page — AGENT.md discipline, surfaced, **never** silently truncating
      content.
- [ ] **Tests.** Template selection routes to the right layout; the length check flags an
      over-long kit.

Note: parked as a stretch — promote into v3 proper only if Q completes early; otherwise it seeds v4.
