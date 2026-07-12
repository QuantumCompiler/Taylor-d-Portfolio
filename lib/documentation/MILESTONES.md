# Taylor'd Portfolio — Completed Milestones

The **record of finished work** — milestones (and sub-parts) that are done, moved here out of
`TODO.md` so that file stays focused on what's left. This is history and reference: what shipped
and how it was built. For the product spec see `SPEC.md`; for the high-level plan and backlog see
`ROADMAP.md`; for the remaining work see `TODO.md`. See `CLAUDE.md` → "Working process" for how
these docs fit together.

Grouped by release: **v0.1.0 — foundation**, **v0.2.0 — reliability**, **v0.3.0 — output & polish**,
**v0.4.0 — navigation & shell**, **v0.4.1 — fixes & refinements** (the first patch release), then
**ad-hoc / quality-of-life** enhancements. (A former Milestone L —
"prefer AFM 3 Core Advanced on-device" — was dropped: on-device tier selection has no developer API;
see `CLAUDE.md` → Stack.)

---

# v0.1.0 — foundation

## Milestone A — Project scaffold & app shell  ✅ done

- [x] Restructure repo: `lib/src` (sources) + `Tests`; drop UI tests
- [x] Four-layer folder scaffold in `lib/src` and `Tests`
- [x] Remove Apple's Core Data template (ContentView / Persistence / .xcdatamodeld)
- [x] App entry `Taylor_d_PortfolioApp` — `lib/src/Presentation/App/App.swift`
- [x] Landing screen — `lib/src/Presentation/Landing/View/LandingView.swift`
- [x] Rebrand product name to "Taylor'd Portfolio"
- [x] Feature-based Presentation convention (`<Screen>/View` + `<Screen>/ViewModel`)

## Milestone B — Domain models  ✅ done  (`lib/src/Data/Models`, tests in `lib/tests/Data/Models`)

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
- [x] Tests: one `@MainActor @Suite` per ViewModel (`lib/tests/Presentation/<Screen>`)

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

## Milestone J — End-to-end vertical slice  ✅ done  ← closes v0.1.0

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

Added on top of the v0.1.0 core (from the ROADMAP ideas list).

- [x] `DocumentTextExtractor` port + `PlatformDocumentTextExtractor` — PDFKit for PDFs,
      `NSAttributedString` for Word/RTF/ODT, direct read for text (Infrastructure/Documents)
- [x] `ImportPortfolioUseCase` (Business/UseCases) — depends on the extractor port
- [x] Portfolio screen: "Import Document…" via `.fileImporter` fills the text box; then
      Build Profile runs as before
- [x] Tests: extractor (temp files + routing/errors), use case, `PortfolioViewModel.importDocument`

Notes: security-scoped file access handled; supported types pdf/txt/md/rtf/rtfd/doc/docx/odt.
Portfolio-**URL** import (fetch + extract) is still open (ROADMAP ideas).

---

# v0.2.0 — reliability

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
- [x] **Docs in the same change.** SPEC (build-time creds note in v0.1.0 scope), CLAUDE.md
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
This is a search-quality/UX item — could sit in fast-follow instead of v0.2.0 if you'd rather;
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

# v0.3.0 — output & polish

## 🔧 Hotfix — job-posting URL fetch is broken  ✅ done  (Search flow: `SearchViewModel` / `SearchView` / `FetchPostingUseCase` / `LinkJobPostingSource` / RootView / `HTTPClient`)

Goal: the Search screen's "Or generate from a specific posting" flow (shipped in Milestone
M-A) doesn't work — pasting a URL and pressing **Fetch** produces no result: the posting is
never fetched/ranked and nothing appears in the Results tab. It must behave **exactly like a
keyword search**: fetch → extract → rank → push a single `RankedJob` into Results (auto-jump),
or show a clear, prominent failure with the paste-text fallback. The plumbing already exists
end-to-end, so this is **reproduce → root-cause → fix**, not a rebuild.

**Root cause (two compounding defects — the propagation was fine):** the wiring
(`fetchFromLink` → `onChange(of: search.results)` → Results tab) was correct all along, so
candidate #3 was ruled out. What actually broke it:
  1. **The fetch failed for virtually every real job board.** `URLSessionHTTPClient.get` used
     `session.data(from:)` with URLSession's default (non-browser) `User-Agent`, no `Accept`
     headers, and decoded the body only as UTF-8 — so real boards answered 403/429, a JS/consent
     shell, or non-UTF-8 bytes and `LinkJobPostingSource.fetchPosting` threw `.unreadable`
     (candidate #2 confirmed as the dominant cause). The happy path almost never ran.
  2. **The failure was invisible.** `fetchFromLink` / `generateFromPastedText` set the shared
     `errorMessage`, but `SearchView` rendered `errorMessage` **only next to the Search button**,
     never in the link section — so pressing Fetch set an error far above/off-screen and "nothing
     happened" at the action.

**Fix:**
- [x] **Reproduce / root-cause.** Traced the whole path (`SearchView` Fetch → `fetchFromLink`
      → `onChange(of: search.results)` → `results.results` + tab jump). Confirmed propagation is
      correct and `ResultsViewModel.loadSavedIfNeeded()` guards on `results.isEmpty` so it can't
      clobber a fresh single-item fetch. Ruled candidate #1 out (a wired profile enables *both*
      Search and Fetch) and #3 out; #2 (fetch fails + error unnoticed) is the real cause.
- [x] **Harden the fetch.** Extended the `HTTPClient` port with `get(_:headers:)` (protocol-
      extension default calls `get(_:)`, so stubs are untouched); `URLSessionHTTPClient` now sends
      the headers via a `URLRequest`. `LinkJobPostingSource.fetchPosting` passes browser-like
      headers (`browserHeaders`: Safari `User-Agent` + `Accept` / `Accept-Language`) and decodes
      via a new `decode(_:)` helper that falls back from UTF-8 to ISO Latin-1 (never fails). The
      "fail loudly, never guess a role" contract is intact — a genuinely unreadable page still
      throws `.unreadable`.
- [x] **Make failure visible + actionable.** Added a dedicated `linkErrorMessage` on
      `SearchViewModel` (separate from the search `errorMessage`); `fetchFromLink` /
      `generateFromPastedText` set it. `SearchView` renders it **prominently in the link section**
      (triangle icon, red, multi-line) right at the Fetch action, and a failed fetch auto-expands
      the "paste the posting text" disclosure so the recovery path is visible.
- [x] **Regression test.** `SearchViewModelTests`: fetch success pushes the single ranked job to
      `results` (RootView would propagate + jump) with no error; `.unreadable` sets a visible
      `linkErrorMessage` (pointing to the paste fallback) and leaves `results` untouched and the
      search `errorMessage` nil; invalid-URL and empty-paste guards; `canFetchLink` gating with/
      without profile + URL; link flow unavailable when unwired; pasted-text success/empty.
      `LinkJobPostingSourceTests`: `fetchPresentsAsABrowser` (a `RecordingHTTP` asserts the
      `User-Agent`/`Accept` headers reach the client) and `nonUTF8PageStillDecodesAndExtracts`
      (an ISO-Latin-1 body that isn't valid UTF-8 still extracts). Full suite green on macOS.
- [x] **Docs.** ROADMAP hotfix ticked; this item records the root cause + fix.

Note: this is a defect in v0.2.0's Milestone M-A, pulled to the front of v0.3.0 because it blocks a
shipped feature. It touches only the Search/fetch flow plus a backward-compatible `HTTPClient`
port addition — no new seam, no layer-rule change.

## Milestone Q — Export résumé & cover letter  ✅ done (Q-A + Q-B + Q-C)  (`Infrastructure/Export`, `Business/UseCases`, Application/detail UI)

Goal: let the user get a generated `ApplicationKit` (résumé + cover letter) out of the app as
polished files — copy, Markdown/plain-text, PDF, and true DOCX. New `DocumentExporter` seam
(Infrastructure — CLAUDE.md reserves "exporters" as protocol-worthy). Native rendering only;
AGENT.md's LaTeX/PDF toolchain stays out of scope. Q-A lands first (no rendering questions),
Q-B is the core value, Q-C is the heaviest single piece — all three share one port + use case.

### Q-A — Copy + Markdown / plain-text export  ✅ done

- [x] **`DocumentExporter` port (Infrastructure/Export).** Declared **domain-agnostic** to
      respect the layer rule (Infrastructure can't import the Data-layer `ApplicationKit`):
      `nonisolated func export(markdown: String, as: ExportFormat) throws -> Data` — Markdown
      `String` in, `Data` out. `ExportFormat` enum (`.markdown`, `.plainText`, `.pdf`, `.docx`
      with `displayName` / `fileExtension` / `contentType`) + `ExportError.unsupportedFormat`.
      Port + format impls live in `Infrastructure/Export`; `Sendable`, no AppKit file coupling.
- [x] **Markdown + plain-text impls.** `MarkdownDocumentExporter`: `.markdown` = the assembled
      Markdown as UTF-8 bytes; `.plainText` = stripped via a new `MarkdownPlainText` helper
      (`Infrastructure/Text`, the counterpart to `HTMLStripper` — headings/bullets/emphasis/
      links/inline-code). `.pdf` / `.docx` throw `unsupportedFormat` (Q-B/Q-C). Pure, unit-tested.
- [x] **`ExportApplicationUseCase` (Business).** Assembles `ApplicationKit` → one Markdown
      document (`# Résumé` + `# Cover Letter`, empty sections omitted; the advisory `gapNote`
      is **not** exported), then calls the exporter. No SwiftUI / `.fileExporter` / `Process`.
- [x] **Presentation affordance.** `ApplicationSheet` header gains **Copy** (assembled Markdown →
      `NSPasteboard`) and an **Export** menu (Markdown / Plain Text) that renders bytes and
      presents `.fileExporter` via a small `ExportFileDocument` (Presentation/Components). Shown
      only when `canExport` (a kit + a wired exporter); filename derives from the job
      (company · role, sanitised). Wired through `Composition` (always-on `MarkdownDocumentExporter`).
      (Attached to the Application sheet only, per the v0.3.0 order — V removes generation from Results.)
- [x] **Tests.** `MarkdownDocumentExporterTests` (markdown verbatim; plain-text strips; pdf/docx
      throw; format metadata) + `MarkdownPlainTextTests`; `ExportApplicationUseCaseTests`
      (assembles headings, omits gapNote, empty-section omission, format routing end-to-end);
      `ApplicationViewModel` export tests (canExport gating, markdown/plain-text text, unsupported
      → nil, no-exporter unavailable, job-derived filename + fallback). Full suite green, no warnings.

### Q-B — PDF export  ✅ done

- [x] **Renderer decision — native `NSAttributedString` → Core Text pagination (not WebKit).**
      *Why:* the `DocumentExporter` port is **synchronous + `nonisolated` + `Sendable`**; WebKit's
      `WKWebView.createPDF` is `@MainActor` **and async**, which would force a port/signature change
      and main-actor coupling. Core Text + Core Graphics are synchronous, off-main-safe (matching the
      existing `nonisolated` PDFKit/`NSAttributedString` use in `PlatformDocumentTextExtractor`),
      self-contained (no network/bundled fonts), and deterministically testable. **Trade-off:** coarser
      layout and a harder one-page gate — so **Milestone X (templates + one-page gate) may need the
      HTML-template path if promoted.**
- [x] **PDF impl (Infrastructure/Export).** `MarkdownAttributedRenderer` (Markdown → styled
      `NSAttributedString`: heading levels, bullets, inline **bold**/*italic*/`code` via Foundation's
      inline Markdown with symbolic traits merged onto block fonts; **black** text for print) +
      `PDFDocumentExporter` (Core Text framesetter paginating into a US-Letter PDF with 0.75″ margins;
      a non-advancing-page guard prevents infinite loops). Self-contained; `.pdf` only, throws for others.
- [x] **Routing.** New `RoutingDocumentExporter` dispatches `.markdown`/`.plainText` → the text
      exporter, `.pdf` → the PDF exporter, `.docx` → unsupported (Q-C). `Composition` injects it, so
      the same `ExportApplicationUseCase` now yields PDF. Added **PDF** to the `ApplicationSheet` menu.
- [x] **Tests.** `PDFDocumentExporterTests` (valid `%PDF` bytes + `PDFDocument(data:)` pageCount ≥ 1;
      a long doc paginates to ≥ 2 pages without looping; empty markdown still yields a valid page;
      rejects non-PDF formats) + `RoutingDocumentExporterTests` (dispatch per format; docx still
      unsupported). Full suite green, no warnings. **Visual fidelity is a manual (device) check.**

### Q-C — DOCX export (hand-rolled OOXML)  ✅ done

- [x] **Minimal OOXML `.docx` writer (Infrastructure/Export).** macOS has **no native `.docx`
      writer**, so `DocxDocumentExporter` assembles the four minimal parts (`[Content_Types].xml`,
      `_rels/.rels`, `word/document.xml`, `word/_rels/document.xml.rels`) and packages them with a
      new **`ZipArchiveWriter`** — a pure-Foundation ZIP writer using the **STORED (uncompressed)**
      method + a hand-written CRC-32, so no compression dependency and no external libs.
- [x] **Map Markdown → OOXML.** `OOXMLDocument` maps blocks (shared `MarkdownBlockParser`) +
      inline (shared `MarkdownInline`) to `document.xml` with **direct run formatting** (no
      `styles.xml`): headings = bold + larger `w:sz`, bullets = a literal `•` + `w:ind` indent
      (no `numbering.xml`), inline **bold**/*italic* as `w:b`/`w:i`. XML-escaped. **Fidelity limits
      (documented):** no tables/images/nested lists/real list numbering; links collapse to text.
- [x] **Wire into the export menu + `.fileExporter`** (`.docx`). `RoutingDocumentExporter` routes
      `.docx` → `DocxDocumentExporter`; **Word (.docx)** added to the `ApplicationSheet` menu.
- [x] **Tests.** `OOXMLDocumentTests` (well-formed via `XMLDocument`; heading/bold runs; bullet
      indent + glyph; `&`/`<`/`>` escaping); `ZipArchiveWriterTests` (CRC-32 known-answer 0xCBF43926;
      signatures + entry names); `DocxDocumentExporterTests` (PK zip with all four parts; rejects
      non-docx; **a pure-Swift STORED-zip round-trip** that re-extracts `word/document.xml` and
      confirms it's byte-identical + valid XML — proving the offsets/CRC are correct);
      `MarkdownBlockParser`/`MarkdownInline` parser tests. Full suite green, no warnings.
      **Opening in Word is a manual (device) check.**

Note: all three formats sit behind the single `DocumentExporter` port + `ExportApplicationUseCase`,
now composed by `RoutingDocumentExporter` — adding a format is a new sub-exporter + one `case`, no new seam.

## Milestone R — Saved / re-runnable searches  ✅ done  (`Data/Persistence`, `Business/UseCases`, Search UI)

Goal: finish the persistence fast-follow — let the user **save a search** (titles + shared
location + salary floor) and **re-run** it later against the current profile, deduping against
already-seen listings. Builds on Milestone O's `PersistentRecordStore`. (The other half of the
old fast-follow — caching the built profile across launches — already shipped via named
`SavedProfile`s, so it's **done**; don't re-spec it.)

- [x] **Persist `JobSearchRequest`.** New `SavedSearch` model (id + name + `JobSearchRequest` +
      createdAt) persisted by `SavedSearchesRepository` (Data/Persistence) on the existing
      `PersistentRecordStore`, `kind` "savedSearch", keyed by a generated id (upsert, newest-first).
      `JobSearchRequest` stays a clean `Codable` domain type — the **full** grown request (incl. the
      U-A/U-D/U-E fields) round-trips; `@Model` stays in Infrastructure.
- [x] **Save / load / delete use cases (Business).** `SaveSearchUseCase` (auto-names from the
      request via `SavedSearch.defaultName`), `LoadSavedSearchesUseCase`, `DeleteSavedSearchUseCase`;
      **re-run reuses `SearchAndRankUseCase`** — `search()` was refactored into `buildRequest()` +
      `performSearch(_:isRerun:)`, and re-run replays the saved request through the same path.
- [x] **Dedupe against already-seen.** On a re-run, `performSearch(isRerun: true)` snapshots the
      already-saved job ids (`LoadSavedJobsUseCase`) and reports **"N new since your last search."**
      as a soft note alongside the existing U-D/U-E notes.
- [x] **Search UI.** A "Saved searches" section on the Search screen: a **Save Search** button
      (enabled once a profile + ≥1 title exist) and a list of saved searches, each with a one-line
      parameter summary + **Run** (repopulates the form and runs → Results tab) and **Delete** (trash).
      `SearchViewModel` holds the list; wired through `Composition`; reloads on appear.
- [x] **Tests.** `SavedSearchesRepositoryTests` (round-trip newest-first incl. new fields, upsert
      collapses dupes, delete, default name); `SearchViewModel` save/list/run/delete, `canSaveSearch`
      gating, run repopulates + produces results, and re-run reports the "N new" dedupe note.
      Suite green.
- [x] **Docs.** SPEC (saved searches persist — already noted); CLAUDE.md (`SavedSearchesRepository`
      + the three use cases + `SavedSearch`); ROADMAP tick.

## Milestone S — Polish pass  ✅ (S-A, S-B, S-C, S-D, S-E)

S-D and S-E shipped early as small bug-fixes; S-A (markdown rendering), S-B (empty/loading/error
states), and S-C (results/saved-jobs/Tracker cohesion) followed. **Milestone S is complete.**

### S-C — Results / saved-jobs / Tracker cohesion  ✅ done

- [x] **One history story.** A single pure value type, `JobHistory` (`Data/Models`), assembles the
      three cross-screen facts about a job — `isSaved` ("already seen" — its listing is persisted),
      `isGenerated` (an `ApplicationKit` exists), and `status` (its `ApplicationStatus` when tracked) —
      and exposes a tested `facets` policy that decides which badges to show without redundancy: the
      status badge subsumes "Seen" (a tracked job is obviously saved), and "Generated" is always its
      own trailing badge. `RankedRow` now renders these facets (new `FacetBadge` chip alongside the
      existing `StatusBadge`), so Results **and** the Tracker tell the same story — a row can read
      "Seen", or "Applied · Jun 12 + Generated", etc.
- [x] **Reconcile loads (no clobber).** New `LoadJobHistoryUseCase` (`Business/UseCases`) joins the
      saved-jobs, status, and application-kit stores by job id (the read-side twin of
      `DeleteSavedJobUseCase`). `ResultsViewModel` swapped its `statusesByID` for a `historyByID` map,
      fed by `refreshHistory()` (renamed from `refreshStatuses`; prefers the three-source join, falls
      back to statuses-only when history isn't wired). `loadSavedIfNeeded` still only loads persisted
      results **when the list is empty**, so a fresh search is never overwritten — but it now always
      refreshes history, so badges are correct whichever way the list was populated. `TrackerViewModel`
      gained the same optional `loadJobHistory` seam + a `history(for:)` (falls back to the tracked
      job's own status) so Tracker rows also show the "Generated" badge. Wired in `Composition`.
      `SavedApplicationsRepository.savedJobIDs()` added to list generated ids.
- [x] **Tests.** `JobHistoryTests` (facet assembly: none / seen / status-subsumes-seen /
      status+generated / generated-alone); `LoadJobHistoryUseCaseTests` (three-source join, plus ids
      present in only one source via the id union); `ResultsViewModelTests`
      (`historyBadgesReflectSeenGeneratedApplied`, `loadKeepsFreshSearchResultsButStillPopulatesHistory`
      — the no-clobber + coherent-load case); `TrackerViewModelTests` (`historyIncludesGeneratedFacet…`,
      `historyFallsBackToTrackedStatusWhenUnwired`). Existing `refreshStatuses` call sites renamed. Suite
      green.

### S-B — Empty / loading / error states  ✅ done

- [x] **Consistent states across all six tabs.** Audited each screen: Search already has the
      unavailable banner (unconfigured build) + no-profile hint + error/warning messaging + button
      spinners; Portfolio has build/import/refine spinners + error text; the Application sheet has a
      "Generating…" spinner + a "Couldn't generate" `ContentUnavailableView`; Results/Tracker have
      empty states. **The gap was a loading state on Results + Tracker** — their on-appear persisted
      load briefly flashed the empty state before data appeared.
- [x] **Loading affordances.** Added `isLoading` to `ResultsViewModel` (`loadSavedIfNeeded`) and
      `TrackerViewModel` (`load`); the views now show a centered `ProgressView` **before** the empty
      state, so there's no flash of "No results yet" / "No tracked applications" while the SwiftData
      read is in flight. (Search/Portfolio/Application already followed this spinner + disabled-state
      convention.)
- [x] **Tests.** `ResultsViewModelTests` / `TrackerViewModelTests`: `isLoading` is false initially,
      resets to false after the load (never stuck), stays false when unwired or when results are
      already populated (the load is skipped). Suite green.

### S-A — In-app markdown rendering  ✅ done

- [x] **Render the generated résumé + cover letter as styled text.** New `MarkdownText`
      (`Presentation/Components`) renders Markdown as styled, selectable SwiftUI `Text` —
      heading levels, bullet lists, and inline **bold**/*italic* — by **reusing the same tested
      parsers the exporters use** (`MarkdownBlockParser` for blocks + `MarkdownInline` for inline
      runs, mapped to an `AttributedString` with presentation intents, so the on-screen rendering
      stays in step with the PDF/DOCX output). `ApplicationSheet`'s résumé and cover-letter sections
      now use it instead of raw markup; the advisory `gapNote` stays plain secondary text.
- [x] **Copy buttons per document.** Each of the résumé / cover-letter section headers gained a
      copy icon that puts that document's raw Markdown on the clipboard (composes with Q-A's export;
      the header still has the whole-kit Copy + Export menu).
- [x] **Tests / previews.** `MarkdownTextRenderingTests` asserts a realistic generated document
      decomposes into the expected blocks + inline (bold/italic) runs the view renders; `#Preview`s
      for both a résumé and a cover letter. Suite green, no warnings.

### S-D — Scrollable screens / small-window layout (bug fix)  ✅ done

Bug: the **Portfolio tab can't scroll when the window is short** — its content is a plain
`VStack { … Spacer() }.padding(24)` with no scroll container, so once the stacked content
(title → description → `TextEditor` → buttons → profile summary → source-document disclosure →
save row → saved-profiles list) exceeds the window height it's clipped and the lower controls
are **unreachable**. The trailing `Spacer()` compounds it. At least `SearchView` shares the
same pattern, so treat this as a cross-tab fix. **This is the likely cause of the reported
"Fetch button can't be clicked"** — Fetch is the last control in `SearchView`, so on a short
window it sat below the fold with no way to scroll to it.

- [x] **Wrap Portfolio content in a scroll container.** Added a reusable `View.scrollableScreen()`
      modifier (`lib/src/Presentation/Components/ScrollableScreen.swift`) — wraps the content in a
      vertical `ScrollView` and makes it fill the width (left-aligned as before). `PortfolioView`
      drops its trailing `Spacer()` and applies `.scrollableScreen()` after `.padding(24)`.
- [x] **Audit + fix the other tabs sharing the pattern.** `SearchView` got the same treatment
      (drop `Spacer()` + `.scrollableScreen()`), so the Fetch button is reachable. Audited the rest:
      `ResultsView` / `TrackerView` use `List` (scrolls natively), `SettingsView` uses `Form(.grouped)`
      (scrolls natively), and `ApplicationSheet` is a min-sized sheet whose body already scrolls — none
      need the wrapper. Chose the shared modifier so it doesn't regress per-screen.
- [x] **Preserve inner scroll regions.** Portfolio's source-document `DisclosureGroup` (bounded
      `ScrollView`, `maxHeight: 220`) and the `TextEditor(minHeight: 200)` compose inside the outer
      `ScrollView` — each keeps its own bounded scroll; the page scrolls around them.
- [ ] **Manual check (device).** Resize the window very short on Portfolio + Search and confirm every
      control — especially Search's **Fetch** button — is reachable by scrolling. (Layout is a
      manual/visual check; no unit test asserts scrollability. Full test suite green.)

### S-E — Saved-profile tile gestures  ✅ done

Today a saved-profile tile's tap (`toggleSelection`) and long-press (`setDefault`) gestures sit
on the inner radio-dial + text HStack only, so the user has to hit the dial/title. Make the
**whole tile** the target.

- [x] **Long-press anywhere → set default.** Moved the `setDefault` `LongPressGesture` from the
      inner HStack to the whole row in `savedProfileRow`
      (`lib/src/Presentation/Portfolio/View/PortfolioView.swift`).
- [x] **Tap anywhere → show/load the profile.** Moved the `toggleSelection` tap gesture to the whole
      tile with `.contentShape(Rectangle())` (over the row's `.padding(.vertical, 2)` + the `Spacer`),
      so a click anywhere loads the profile. The dial is now only the selection **indicator**.
- [x] **Keep the trash button independent.** The trash `Button` is a control, so it still handles its
      own taps and isn't triggered by the row-level tap/long-press; the `simultaneousGesture` pattern
      for tap-vs-long-press is retained.
- [x] **Tests / manual.** `PortfolioViewModel.toggleSelection` / `setDefault` stay covered by the
      existing VM tests (this is only gesture placement); full suite green. Manual (device) check that
      tapping/long-pressing anywhere on the tile — including padding — works and delete is unaffected.

## Milestone T — Two-document portfolio (résumé + cover letter) as generation grounding  ✅ done (T-A + T-B)  (`Data/Models`, Portfolio input, `TidyDocumentUseCase`, `GenerateApplicationUseCase` / `LLMProvider` / `Prompts`, Application plumbing)

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

### T-A — Two-document input + model  ✅ done

- [x] **Extended `SavedProfile` with cover-letter document fields.** Added `coverLetterFileName:
      String?`, `coverLetterText: String` (raw), `coverLetterReadableText: String` (LLM-tidied)
      alongside the résumé/portfolio fields. The custom `init(from:)` decodes them with
      `decodeIfPresent` → empty defaults, so **older single-document (and pre-source-document)
      saves still load**. `@Model` stays in Infrastructure (blob only). `SaveProfileUseCase`
      threads the three new fields through.
- [x] **Second import/paste slot on the Portfolio tab.** Refactored the input into a reusable
      `documentSlot` (label + `TextEditor` + per-slot `Import…`): the existing one is relabelled
      **"Résumé / portfolio"**; a new optional **"Cover letter (optional)"** slot sits below it,
      reusing `importPortfolio`/`DocumentTextExtractor` via `importCoverLetter`. The cover letter
      **never gates Build** (`canBuild` unchanged — still requires only the résumé text).
- [x] **Tidy both documents on build.** `build()` tidies the cover letter through the same
      `TidyDocumentUseCase` (→ `coverLetterReadableText`), captured into `coverLetterSourceText`.
      The `CandidateProfile` is **still distilled from the résumé/portfolio only** — the cover
      letter is never mined into profile facts. An absent cover letter leaves all three fields empty.
- [x] **Show both source documents.** The source-document area now renders one collapsed,
      scrollable `documentDisclosure` per document — résumé and (when present) cover letter.
- [x] **Tests.** `SavedProfileTests` (round-trip incl. cover-letter fields; **legacy** blob and
      single-document blob both decode with empty cover-letter defaults); `PortfolioViewModelTests`
      (cover-letter import fills its own slot; doesn't gate build; build tidies it while the profile
      stays résumé-only; build without one leaves it empty; save+select round-trip). Suite green.

### T-B — Reference both documents in generation  ✅ done

- [x] **Carry the documents to generation.** New `PortfolioGrounding` value (`resumeText: String`,
      `coverLetterText: String?` — the tidied readable forms) is threaded from
      `PortfolioViewModel.grounding` (a computed property over the active profile's readable
      documents, so it works for a freshly built, unsaved profile too) through
      `RootView` → `ResultsView`/`TrackerView` → `JobDetailView` → `ApplicationSheet` →
      `ApplicationViewModel.open` / `generate` (incl. Regenerate).
- [x] **Grew the generation seam.** `GenerateApplicationUseCase.callAsFunction(job:profile:grounding:)`
      passes grounding to a new `LLMProvider.generateApplication(for:profile:brief:grounding:)`
      requirement. To keep the seam back-compatible, that requirement has a **forwarding default**
      (ignores grounding → base method), so every existing stub is untouched; the real engines
      (`FoundationModelsProvider`, `ClaudeCodeProvider`), `LLMRouter`, and the composition's
      `SettingsBackedLLMProvider` override it. All new text lives in the shared `Prompts` enum.
- [x] **Inject grounding in the prompt.** `Prompts.groundingSection` appends: the résumé real text
      as **factual grounding** (reorder/rephrase only, never add absent facts), and — when present —
      a **cover-letter voice/tone/structure exemplar** with an explicit guardrail (*match the voice,
      but do NOT import facts, metrics, employers, or dates from it*). Both bounded
      (`maxPortfolioCharacters` / new `maxCoverLetterCharacters`).
- [x] **Back-compat / fallback.** `nil` grounding (no active documents / legacy profile) or an empty
      cover letter omits the corresponding block — a profile-only prompt is **byte-for-byte
      unchanged** (asserted by a test).
- [x] **Tests.** `PromptsTests`: résumé grounding injected as factual grounding; cover letter as a
      voice exemplar with the no-fabrication guardrail; absent cover letter omits the section; both
      bounded; nil grounding == the old prompt. `ApplicationViewModelTests`: `generate` threads
      grounding to the provider (recording provider), and without grounding falls back to nil.
      Suite green, no warnings.
- [x] **Docs.** SPEC (two-document input + cover-letter-as-voice reference under "Grounded
      generation"); CLAUDE.md (`PortfolioGrounding`, the grown `generateApplication` signature +
      `GenerateApplicationUseCase`); ROADMAP tick.

Note: T-A (input + model) is independently shippable — it enriches what's saved even before
generation uses it; T-B wires the grounding into output. The cover letter stays voice-only **by
decision** (facts strictly from the résumé/portfolio), keeping the "never fabricate" principle
enforceable. Composes with the embedding-RAG backlog item, which would later retrieve top-k chunks
from these same documents instead of injecting them whole.

## Milestone U — Expanded, optional search parameters  ✅ done (U-A…U-F)  (`Data/Models`, `Data/Search`, `AdzunaJobSource`, `SearchAndRankUseCase`, `SearchViewModel` + Search UI)

Goal: enrich the search step with more control — a position-type filter, a typeable **and
saveable** location and salary, a **desired-result-count goal**, and a **minimum-rank filter**.
Every field is **optional**: leaving them blank produces exactly today's `JobSearchRequest` and
today's behaviour. Sub-parts A–F are separable and each lands without breaking the current flow.

**✅ Done (all of U).** New `PositionType` (U-A) + optional `positionType`/`desiredResultCount`/
`minimumScore` on `JobSearchRequest` (existing `location`/`salaryMin` reused); `AdzunaJobSource`
maps position type to its contract flag. `SearchAndRankUseCase` pages toward the goal
(round-robin pages, 50/page, a 5-page cap; never throws on a shortfall → `Output.resultShortfall`)
and applies a post-rank score filter (`Output.noneMetMinimum`, distinct from no-results). New
`LocationStore` + `SalaryPresetStore` (U-B/U-C) with `SuggestionProvider` merges. `SearchViewModel`
gained typeable location + saved-location chips, typeable salary + saved-salary chips (lenient
parsing), position-type picker, desired-count field, and a 0–100 min-rank slider; `canSearch` is
unchanged and an all-blank form assembles byte-for-byte today's request (asserted). Shortfall +
none-met-minimum surface as distinct notes. Full suite green; the visual layout of the new Search
filters is a manual (device) check.

### U-A — Position-type filter  ✅ done

- [x] **`PositionType` domain type (`Data/Models`).** `nonisolated` `Codable`/`Sendable` enum
      (e.g. `fullTime`, `partTime`, `contract`, `permanent`) with a `label`. Add an optional
      `positionType` to `JobSearchRequest` (shared across titles) → `JobQuery`.
- [x] **Map to Adzuna.** `AdzunaJobSource.buildURL` translates it to Adzuna's contract params
      (`full_time` / `part_time` / `contract` / `permanent`); Adzuna specifics stay private. Nil
      ⇒ no param (unchanged URL).
- [x] **UI.** An optional picker on Search ("Any" default).
- [x] **Tests.** `buildURL` includes the right param when set and is unchanged when nil;
      `JobSearchRequest.query(forTitle:)` propagates it.

### U-B — Typeable + saveable location (can become a preset)  ✅ done

- [x] **`LocationStore` (Data/Search, on `KeyValueStore`).** Mirrors `RoleTitleStore`: a
      persisted library of user-saved locations; round-trip + corrupt→empty. `SuggestionProvider`
      merges static locations + saved ones (dedup, keep "Anywhere"/"Remote").
- [x] **Typeable input.** Location becomes a combo — type a custom value *or* pick a preset;
      single-value semantics unchanged (`JobSearchRequest.location` stays one optional string).
- [x] **Save / remove as preset.** A "save this location" affordance persists a typed value into
      `LocationStore` (and a remove-from-library control), mirroring the common-role-titles UX but
      single-select.
- [x] **Tests.** `LocationStoreTests` (round-trip, shared-backing persistence, corrupt→empty);
      `SuggestionProvider` merge; `SearchViewModel` type/save/select/remove.

### U-C — Typeable + saveable minimum salary (can become a preset)  ✅ done

- [x] **Custom salary presets store (Data/Search).** Same pattern as U-B for salary — a persisted
      library of user-saved salary floors joined with `SuggestionProvider.salaryPresets`.
- [x] **Typeable input.** A numeric field alongside the preset brackets; parse + validate (ignore
      non-numeric); nil ⇒ "Any". `JobSearchRequest.salaryMin` stays one optional value.
- [x] **Save / remove as preset.** Save a typed floor into the library (+ remove).
- [x] **Tests.** Store round-trip/persist; `SearchViewModel` parse/save/select; invalid input ignored.

### U-D — Desired result count (a soft goal)  ✅ done

- [x] **Optional `desiredResultCount: Int?` on `JobSearchRequest`.** Drives how many listings the
      search pulls/ranks: `SearchAndRankUseCase` raises `JobQuery.resultsPerPage` (up to Adzuna's
      max, 50) and/or **pages** additional pages per title until the merged + deduped count reaches
      the goal or the sources are exhausted.
- [x] **Never fail if unreachable.** If the goal can't be met, return what's available with a soft
      note (e.g. `Output.resultShortfall` → "found 12 of a desired 25"); the run never throws for a
      shortfall. Bound the effort with a **page cap** + the existing `maxConcurrentSearches`
      rate-limit guard.
- [x] **Design note (record in the milestone).** Whether the goal counts candidates *fetched/ranked*
      vs *final results after the U-E score filter*. Default: it targets fetched/ranked candidates,
      and the final shown count may be lower once U-E trims — note this to the user.
- [x] **Tests.** Goal reached stops paging early; goal unreachable returns all available + note (no
      throw); page cap respected; nil ⇒ today's single-page behaviour.

### U-E — Minimum-rank (score) filter  ✅ done

- [x] **Optional `minimumScore: Int?` (0–100) on `JobSearchRequest`.** After `ranker.rank`,
      `SearchAndRankUseCase` keeps only `RankedJob`s with `match.score >= minimumScore`.
- [x] **Distinguish "none qualified" from "none found".** When the filter empties the set, the
      output flags it (e.g. `Output.filteredOutByScore` / a `noneMetMinimum` note) so the VM shows
      "No results met your minimum rank of N" — different copy from "no results found at all".
- [x] **Composes with multi-title + the goal.** Filter applies once, post-rank, over the merged set.
      Nil ⇒ no filtering.
- [x] **Tests.** Filters below threshold; all-below → empty + `noneMetMinimum`; nil ⇒ unfiltered;
      composes with U-D (goal fetches, filter trims).

### U-F — Search UI + wiring  ✅ done

- [x] **`SearchViewModel` fields.** Add optional `positionType`, typeable `location` + saved
      locations, typeable `salaryMin` + saved salary presets, `desiredResultCount`, `minimumScore`.
      `canSearch` is **unchanged** (all new fields optional). Assemble the `JobSearchRequest` from
      whatever is set.
- [x] **Surface the new notes distinctly.** Wire the result-count shortfall and the
      none-met-minimum outcomes into separate, clear messages (feeds Milestone S's empty/error-state
      polish).
- [x] **Composition.** Wire the new `LocationStore` / salary-preset store; persisted presets reload
      on launch like role titles.
- [x] **Tests.** Request assembly with any subset of optional fields; **back-compat** — all blank ⇒
      byte-for-byte the same `JobSearchRequest` the app builds today.
- [x] **Docs.** SPEC ("Search → listings": the optional new params — done in this planning pass);
      CLAUDE.md (`PositionType`, `LocationStore` + salary-preset store, the grown `JobSearchRequest`/
      `JobQuery`, the use-case goal-paging + score filter, the `SuggestionProvider` merge).

Note: A–F are independent and every field is optional, so each ships on its own and none changes
the default search. U-D (paging toward a goal) is the one that adds real API load — cap pages and
respect Adzuna's free-tier rate limits. U composes with Milestone R (a saved search can carry these
new optional fields once `JobSearchRequest` grows) and with Milestone N's existing title fan-out.

## Milestone V — Results ↔ Tracker interaction overhaul  ✅ done (V-A…V-E)  (`Data/Persistence`, `Business/UseCases`, Results/Tracker Presentation, `JobDetailView`)

Goal: change how the user acts on a ranked result. Add per-row **Save to Tracker** + **Delete**
icons; make the opened result a **swipeable card** (right = save, left = dismiss); and **move
generation entirely to the Tracker** — from Results the user reads the posting and chooses only
whether to save. "Save to Tracker" = mark the job `saved` (`MarkStatusUseCase`, Milestone P), so
it appears in the Tracker; "Delete" = fully forget it (per decision). Generation from the Tracker
(brief → tailor, persisted `ApplicationKit`) is unchanged.

**✅ Done (all of V).** `delete(jobID:)` added to the jobs/status/applications repositories;
`DeleteSavedJobUseCase` clears all three (no orphans). `ResultsViewModel` gained `saveToTracker`
(persist listing + `MarkStatusUseCase(.saved)`, idempotent — never downgrades a later stage) and
`delete` (drop from list + forget everywhere). Results rows carry a **bookmark** (Save, filled when
tracked) + **trash** (Delete) icon; opening a result presents a **swipeable card** — a pure
`SwipeOutcome.resolve(translation:threshold:)` (unit-tested) drives right = save + dismiss, left =
dismiss, small = snap back, with a drag offset + hint. `JobDetailView` gained a `canGenerate` flag:
**Results** passes `false` + an `onSaveToTracker` closure (footer shows **Save to Tracker**, no
Generate, and the swipe is enabled); **Tracker** keeps `canGenerate = true` (Generate unchanged).
Tracker empty-state copy updated. `Composition` wires `deleteSavedJob` + `markStatus`/`saveResults`
into the Results VM. Suite green; the swipe *feel* + row layout are a manual (device) check.

### V-A — Delete a result (row trash icon + persistence)  ✅ done

- [x] **Repository + use case.** `SavedJobsRepository.delete(jobID:)` (on the store's existing
      delete); a `DeleteSavedJobUseCase` (Business) that — per the "remove from both" decision —
      also clears the job's **status** (`SavedStatusRepository.delete(jobID:)`, add if absent) and
      its saved **`ApplicationKit`** (`SavedApplicationsRepository.delete(jobID:)`), so nothing is
      orphaned.
- [x] **Trash icon on the Results row.** A trailing trash button on each result tile (right-most).
      Keep `RankedRow` reusable — add the actions in the Results row composition (or via optional
      `onDelete`/`onSave` closures), **not** baked into `RankedRow` (the Tracker reuses it and must
      not get a Results trash).
- [x] **`ResultsViewModel.delete(_:)`.** Remove from `results` and call `DeleteSavedJobUseCase`;
      refresh badges. Consider a lightweight confirm (destructive + persistent).
- [x] **Tests.** `SavedJobsRepository` delete; `DeleteSavedJobUseCase` clears job + status + kit;
      `ResultsViewModel.delete` drops the row and persists; deleting a tracked job also removes it
      from the tracker (via `LoadTrackedJobsUseCase` no longer returning it).

### V-B — Save a result to the Tracker (row save icon)  ✅ done

- [x] **Save icon left of the trash icon.** Tapping marks the job `saved` via
      `MarkStatusUseCase(jobID:, stage: .saved)` (ensuring the listing is persisted first so the
      tracker join has it), then the row shows a "Saved" `StatusBadge`.
- [x] **`ResultsViewModel.saveToTracker(_:)`.** Marks `.saved`, upserts the listing if needed,
      refreshes `statusesByID`. Idempotent — an already-tracked job shows its current badge and the
      icon reflects the tracked state (no downgrade of a later stage).
- [x] **Tests.** Save marks `.saved` + persists the listing + badge appears; already-tracked job is
      reflected and not downgraded.

### V-C — Swipeable result card (right = save, left = dismiss)  ✅ done

- [x] **Draggable detail card.** In the Results context, the opened `JobDetailView` becomes a card
      the user drags horizontally (macOS trackpad/mouse `DragGesture`): drag **right** past a
      threshold → save to Tracker (`.saved`) then dismiss; drag **left** past threshold → dismiss
      without saving/deleting; small drags snap back, with a card offset + a subtle save/dismiss hint.
- [x] **Pure outcome helper.** Extract `swipeOutcome(forTranslation:threshold:) -> {save|dismiss|none}`
      so the decision logic is unit-testable; the gesture wiring + animation are a manual-feel check.
- [x] **Tests.** `swipeOutcome` thresholds (right→save, left→dismiss, small→none). Note the gesture
      feel is manual.

### V-D — Move generation to the Tracker only  ✅ done

- [x] **Generation-context flag on `JobDetailView`.** Add e.g. `canGenerate: Bool` (or a
      `context: .results | .tracker`). **Results** passes `false`; **Tracker** passes `true`.
- [x] **Results context.** No "Generate résumé & cover letter" button and no `ApplicationSheet`
      path; the footer instead offers **Save to Tracker** (mark `.saved`). The user reads the JD +
      saves; generation is unreachable from Results.
- [x] **Tracker context.** Generate button + the `ApplicationSheet` save/load `ApplicationKit`
      flow (Milestone O-C) unchanged.
- [x] **Tests.** `JobDetailView` in Results context exposes Save and no Generate; in Tracker context
      exposes Generate; routing holds.

### V-E — Wiring, empty states, copy  ✅ done

- [x] **Composition.** Wire `DeleteSavedJobUseCase`; thread `markStatus` to the Results **rows**
      (not just the detail) for the save icon; pass the generation-context flag from Results vs Tracker.
- [x] **Copy.** Update the Tracker `ContentUnavailableView` ("Save a result from the Results tab to
      track it here.") and any Results help text. Composes with Milestone S (empty/error states).
- [x] **Tests / previews.** Composition smoke; Results row with save+trash preview; Tracker
      empty-state copy.
- [x] **Docs.** SPEC (save-from-results → generate-from-tracker; delete — done in this planning
      pass); CLAUDE.md (`DeleteSavedJobUseCase`, `SavedJobsRepository.delete`, the Results row
      actions, the `JobDetailView` generation-context flag, "save to tracker = mark `.saved`", and
      the updated Tracker entry path).

Note: V builds on Milestones O (persistence) and P (status) — no new status model, and "save" is
just marking `.saved`. Sub-parts are mostly independent (V-A delete, V-B save-icon, V-C swipe, V-D
generation-move); V-D is the one behaviour change users will notice most, so pair it with the
Tracker-copy update in V-E.

## Milestone W — Results filtering  ✅ done  (`ResultsViewModel`, a pure `ResultsFilter`, Results UI)

Goal: let the user **interactively narrow the displayed ranked results** in the Results view — by
minimum rank, keywords, location, and a few more facets — **without re-running the search**.
Non-destructive: filters only hide rows (delete/save still act on what's shown). **Distinct from
Milestone U-E's search-time min-rank filter** (which trims the persisted/ranked set); W is a **live,
reversible view filter** over the already-loaded `[RankedJob]`.

**✅ Done.** Pure `ResultsFilter` (Presentation/Results) with facets `minScore` / `keywords`
(title + company + description + matched skills, case-insensitive substring) / `location` /
`company` / `salaryMin` / a `trackedStatus` facet — `apply(to:isTracked:)` ANDs active facets,
empty ⇒ identity; unit-tested. `ResultsViewModel` holds the filter and exposes `filteredResults`
(what the List iterates), `visibleCount`/`totalCount`, `isFilteredEmpty`, `clearFilter`, and
distinct `locationOptions`/`companyOptions` from the loaded results. `ResultsView` gained a
collapsible filter bar (min-rank slider, keyword field, location/company pickers, salary floor,
tracked segmented control), a "Showing X of Y" + Clear header, and a distinct "No results match
your filters" empty state. Filters are session-only and never mutate `results`/persistence, so V's
delete/save act on the visible rows. Suite green; the filter-bar layout is a manual (device) check.

- [x] **Pure `ResultsFilter`** (Presentation/Results, or Data if reused). A `Sendable`/`Equatable`
      value holding the active filters — `minScore: Int?`, `keywords: String`, `location: String?`,
      plus optional facets (`company: String?`, `salaryMin: Double?`, a tracked-status facet) — with a
      pure `apply(to: [RankedJob]) -> [RankedJob]` (AND across active filters; an empty filter ⇒
      identity). Keyword match is case-insensitive substring over title + company + description +
      matched skills (**record the exact field set** as a small design decision). Unit-tested.
- [x] **`ResultsViewModel` filter state.** Hold a `ResultsFilter`; expose `filteredResults`
      (`filter.apply(to: results)`) and `visibleCount` / `totalCount`. The `List` iterates
      `filteredResults`; the status/badge map is unchanged. Filters **never** mutate `results` or
      persistence.
- [x] **Filter bar UI.** A collapsible filter section atop the Results list: a **min-rank**
      slider/stepper (0–100), a **keyword** search field, a **location** picker (populated from the
      locations present in the current results, + "Any"), and the optional facets (company field,
      salary floor, tracked-status). A **Clear filters** button and a "Showing X of Y" count.
- [x] **Options from the data.** Populate the location (and company) pickers from the *distinct*
      values in the loaded results, so they only offer values that can actually match.
- [x] **Empty-filtered state.** When the active filter excludes everything, show "No results match
      your filters" + a Clear action — distinct from the "No results yet" empty state (composes with
      Milestone S-B).
- [x] **Composes with V.** Delete (V-A) and save-to-tracker (V-B) act on the **visible (filtered)**
      rows; a filtered-out row is never deleted. Filters are session-only (reset on relaunch; a
      saved-filter option is a later idea).
- [x] **Tests.** `ResultsFilter.apply` (each facet; AND composition; empty ⇒ identity; keyword field
      coverage; min-rank boundary); `ResultsViewModel` filteredResults + counts + clear;
      empty-filtered state.
- [x] **Docs.** SPEC (ranked results are interactively filterable — done in this planning pass);
      CLAUDE.md (`ResultsFilter` + the Results filter state; note it's view-only, distinct from U-E).

Note: W is **view-only** over loaded results — no new persistence, no re-search. It layers cleanly
on V (row actions over the filtered list) and complements U without overlap: **U decides what gets
searched/ranked; W decides what's shown of the results.**

## Milestone X — Export templates + one-page gate  ✅ done (promoted from stretch into v0.3.0)  (`Infrastructure/Export`, `Business/UseCases`, Application UI)

Q-B chose the Core Text / `NSAttributedString` renderer (not HTML), so templates are typography/layout
variations threaded through that renderer, and the one-page gate reuses the same Core Text pagination.

- [x] **Template selection.** New `ExportTemplate` (Infrastructure) — **Classic** (the original look, the
      default so existing exports are unchanged), **Compact** (smaller type + tighter margins/spacing to
      fit more), **Modern** (system-serif body + navy accent headings) — each resolving to a pure
      `TemplateStyle` (body/heading sizes, margin, spacing, serif flag, heading colour; `RGBColor` keeps
      it AppKit-free and testable). `MarkdownAttributedRenderer` now renders against a `TemplateStyle`
      (serif face via `NSFontDescriptor.withDesign(.serif)`, accent heading colour, black body). The
      **seam is a `template:` parameter on the `DocumentExporter` port** (no new port); a protocol
      extension keeps the old `export(markdown:as:)` call site working with `.classic`. Text formats
      (Markdown / plain / DOCX) ignore the template; `RoutingDocumentExporter` forwards it to the PDF
      exporter. The Export menu on the Application sheet gained a **PDF template** picker.
- [x] **One-page gate.** `PDFDocumentExporter` factored its pagination into a shared `pageRanges(...)`
      used by both `render(...)` and a new `pageCount(markdown:template:)`; the port declares
      `pageCount` (default 1 for non-paginated formats), `RoutingDocumentExporter` routes it to the PDF
      exporter (measurement is a print concern). `ExportApplicationUseCase.resumePageCount` measures the
      **résumé alone** (the one-page discipline is a résumé rule; 0 when there's no résumé).
      `ApplicationViewModel` holds `exportTemplate` + `resumePageCount` (recomputed on load/generate and
      on template change via `refreshLengthGate()`); the sheet shows an **advisory orange banner** when
      the résumé overflows a page, suggesting Compact / tightening — it **never truncates content**.
- [x] **Tests.** `ExportTemplateTests` (distinct styles; Compact denser than Classic; Modern serif +
      accent; heading-size clamp); `PDFDocumentExporterTests` (pageCount matches the rendered PDF; empty
      ⇒ 1 page; Compact ≤ Classic pages; template changes the bytes); `ExportApplicationUseCaseTests`
      (template forwarded + defaults to Classic; résumé-only measurement; 0 when no résumé);
      `ApplicationViewModelTests` (gate flags a long résumé, stays quiet for one page, remeasures on
      template switch, export uses the selected template). Suite green.

## Ad-hoc / quality-of-life enhancements  ✅ done

Small, user-requested improvements made outside the numbered milestones:

- **Regenerate profile description.** A prompt field + Submit on the Portfolio tab rewrites **only**
  the profile `summary`, grounded in the real portfolio (never fabricating): `RefineSummaryUseCase`
  → `LLMProvider.refineSummary(profile:portfolio:instruction:)` (a `.profile`-routed plain-text
  task with a forwarding default, so stubs are untouched). The prompt field grows vertically like a
  chat composer.
- **Collapsible portfolio text editors.** The résumé / cover-letter raw-text editors are hidden by
  default behind a per-slot **"Show text"** toggle, with a character-count summary when collapsed.
- **Pointing-hand cursor on clickables.** A reusable `View.clickableCursor()` (`pointerStyle(.link)`)
  applied to every button / link / picker / slider / tappable row across the app; text fields keep
  the native I-beam.
- **Custom top tab bar.** Replaced the native macOS `TabView` strip with a custom button bar in
  `RootView` so the tabs are real controls that show the pointing-hand cursor — same icons/labels,
  a selected-tab highlight, content switched on the `MainTab` enum.
- **Trackpad swipe on the result card.** The swipeable job-detail card (Milestone V-C) now also
  responds to a **two-finger trackpad swipe** with no click, via a reusable `View.trackpadSwipe(...)`
  (`Presentation/Components`) that installs a local scroll-wheel monitor and consumes only
  horizontally-dominant precise-scroll gestures (vertical scrolling passes through to the inner
  `ScrollView`). Left = dismiss, right = save; the mouse click-drag `DragGesture` stays as a fallback,
  and both paths share one `endSwipe(translation:)` + the existing `SwipeOutcome.resolve` threshold.

## Project structure & tooling  ✅ done

Repo/project housekeeping done alongside v0.3.0 (no milestone letter; see `CLAUDE.md` →
"Suggested file layout" / "Xcode project structure" for the living description):

- **Tests relocated under `lib/`.** The former top-level `Tests/` moved to **`lib/tests/`** (mirroring
  the `lib/src/` layer folders). The Xcode **file-system-synchronized groups** were repointed so the app
  target syncs `lib/src` and the test target syncs `lib/tests` — siblings, so the app never compiles
  test files.
- **Config folders under `lib/`.** `Info.plist` → **`lib/xcode/Info.plist`** (wired via the app target's
  `INFOPLIST_FILE`), and the Adzuna secrets → **`lib/secrets/`** (`Secrets.xcconfig` — the gitignored
  base configuration — plus its committed `Secrets.example.xcconfig` template). Verified the credential
  flow still injects the Adzuna keys into the built app.
- **Docs folder under `lib/`.** The root-level `Documentation/` moved to **`lib/documentation/`**
  (`SPEC.md`, `ROADMAP.md`, `TODO.md`, `MILESTONES.md`, `CLAUDE.md`); the root `README.md` stays at the
  repo root and its links were repointed. Docs aren't part of the Xcode project, so no `.pbxproj` change.
- **Nested `lib` navigator group.** Added a real `lib` parent group in `project.pbxproj` so Xcode's
  navigator shows **lib ▸ src / tests / secrets / xcode** instead of four flat `lib/…`-pathed entries
  (cosmetic; target membership is unchanged, referenced by id).
- **Bundle identifier corrected `com.vivint.*` → `com.veritum.*`.** Both targets' bundle ids (and the
  redundant per-SDK overrides, collapsed to one line) are now `com.veritum.…`. The `UserDefaults`
  preference keys shared that prefix, so they were renamed to `com.veritum.taylordportfolio.*`, and a
  one-time **`LegacyKeyMigration`** (`Data/Persistence`, run once in `Composition.init`, guarded by a
  done flag) copies any values still under the old `com.vivint.*` keys to the new ones and clears the
  old keys — so existing local preferences (settings, saved locations / salary presets / role titles,
  default profile) carry over with no data loss. Covered by `LegacyKeyMigrationTests`.

---

# v0.4.0 — navigation & shell

The theme: give the app room to grow. Primary navigation moves to a left **sidebar** (the five
top-level areas) and each area's sub-screens become a **segmented inner nav** at the top of the
content pane. **Presentation-only** — every screen's content, view models, and use cases are
preserved and only re-homed. Milestones restart at **A** (per `CLAUDE.md` → Versioning). (The full UI
spec + interactive mockup lived in a temporary `design/` scaffolding folder, removed when v0.4.0
shipped — see Milestone C.)

## Milestone A — Navigation shell  ✅ done  (`Presentation/App`: `RootView` + new `ShellNavigation`)

Goal: replace `RootView`'s custom full-width tab bar (`VStack { tabBar; Divider; selectedTab }`) with
a native sidebar shell, without touching anything below Presentation. The five screen views are reused
verbatim — only their host changed.

- [x] **Sidebar (primary nav).** `RootView` is now a `NavigationSplitView`; the sidebar is a
      `List(selection:)` over `MainArea.allCases` — Portfolio, Search, Results, Tracker, Settings —
      each a `Label` with its existing SF Symbol (`person.text.rectangle`, `magnifyingglass`,
      `list.number`, `briefcase`, `gearshape`). **Top-level areas only, no nested rows** (deliberate:
      the sidebar stays a clean area switcher). Standard accent-fill sidebar selection; the window
      traffic lights sit in the sidebar header (default `NavigationSplitView` look). A fixed column
      width (min 180 / ideal 210 / max 280) keeps it stable.
- [x] **Count badges.** Native `.badge(_:)` on the Results row (loaded-result count,
      `results.results.count`) and Tracker row (tracked-job count, `tracker.trackedJobs.count`) —
      reusing existing VM state, no new data. A zero badge renders as nothing, so the other rows stay
      clean and the counts appear only when there are items.
- [x] **Inner segmented nav.** A per-area `Picker(.segmented)` at the top of the content pane, bound
      to the nav holder's sub-view index. **Milestone A ships one segment per area** (the existing
      whole screen) so the pattern is consistent and Milestone B slots sub-views in without a layout
      change; `.fixedSize()` keeps it left-aligned at its natural width.
- [x] **Content header.** An `Area / Sub-view` breadcrumb title above the segmented control
      (`ShellNavigation.breadcrumbTitle`). With one sub-view per area it reads as the bare area name;
      it becomes `Area / Sub-view` automatically once Milestone B gives an area multiple sub-views.
- [x] **Nav-state holder.** New `ShellNavigation` (`@MainActor @Observable`) owns `selectedArea` +
      `selectedSubView` and the `MainArea` enum (title / SF Symbol / `subViews`, promoted out of the
      old `private enum MainTab`). `select(_:)` **resets the inner nav to the first sub-view** on an
      area change (no-op when re-selecting the current area); `selectSubView(_:)` ignores negatives.
      The `List` selection and the segmented `Picker` bind to it through small `Binding`s so every
      change flows through those rules. Cross-screen wiring (profile → Search, saved-profiles reload,
      results → jump to the Results area) is preserved; the results jump now calls `nav.select(.results)`.
- [x] **Carried-over polish.** `clickableCursor()` stays on the sidebar rows + the segmented control;
      the result-card swipe / trackpad-swipe behaviour is untouched (it lives inside the reused
      screens). Sidebar collapse/restore comes free with `NavigationSplitView`; keyboard nav + an
      About sub-view are Milestone C.
- [x] **Tests.** `ShellNavigationTests` (`lib/tests/Presentation/App`): opens on Portfolio/first
      sub-view; **area change resets the sub-view to the first** (and re-selecting the same area keeps
      it); `selectSubView` ignores negatives; the breadcrumb is the bare area name while each area has
      one sub-view; every area has a non-empty title / icon / sub-view list; the five areas are listed
      in order. Full suite green on macOS; the shell's visual feel is a manual (device) check.
- [x] **Docs.** CLAUDE.md file-layout entry updated (`RootView` = the `NavigationSplitView` shell +
      `ShellNavigation`); ROADMAP Milestone A ticked; this write-up. (The per-area sub-view structure
      and the CLAUDE.md Presentation-description refresh land with Milestone B/C.)

Note: A is the shell only — mechanism, not the per-area split. Milestone B expands each `MainArea`'s
`subViews` and routes the real sub-screens behind the inner nav; Milestone C adds collapse/keyboard
polish + the About view. Nothing below Presentation changed, so ranking/generation/persistence/export
are all untouched.

## Milestone B — Sub-view routing per area  ✅ done  (`Presentation/App` section enums + the five screens)

Goal: give each area's inner segmented nav real sub-views, splitting the existing screens behind them.
Presentation-only — the view models and use cases are untouched; the screens' internal sections were
re-homed, not rewritten.

- [x] **Type-safe section taxonomy.** New per-area `Int`-backed enums in `ShellNavigation.swift` —
      `PortfolioSection` (Profile / Saved Profiles / Source Documents), `SearchSection` (New Search /
      Saved Searches / From a Link), `TrackerSection` (All / Applied / Interviewing / Offers),
      `SettingsSection` (Engines / Adzuna / About). `rawValue` == segment index; `title` == segment
      label; `init(index:)` clamps out-of-range to the first case. `MainArea.subViews` now **derives**
      its labels from these enums (Results stays a single `["Ranked"]`), so the segmented labels and
      `RootView`'s routing share one source of truth. `RootView.selectedContent` maps
      `nav.selectedSubView` → the section enum and passes it to each screen.
- [x] **Each screen takes a `section:` param.** `PortfolioView`, `SearchView`, `TrackerView`, and
      `SettingsView` gained a defaulted `section:` parameter and render only that sub-view; `ResultsView`
      is unchanged (single Ranked). Defaults keep every `#Preview` and direct caller working. The old
      in-content `Text("Portfolio"/"Search").largeTitle` headers and the `.navigationTitle` on
      Results/Tracker/Settings were removed — the shell's breadcrumb header + `RootView`'s
      `.navigationTitle(nav.breadcrumbTitle)` now own the title.
- [x] **Portfolio split.** **Profile** = the two document slots + Build + summary + Regenerate + Save;
      **Saved Profiles** = the saved-profile library; **Source Documents** = the tidied readable
      disclosures. The saved-profiles/source-docs pieces moved out of the Profile scroll into their own
      sub-views, each with an empty state when there's nothing yet.
- [x] **Search split.** **New Search** = profile picker + title chips/common titles + optional filters +
      Search/Save Search + result/warning notes; **Saved Searches** = the saved-search list (Run /
      Delete); **From a Link** = the URL fetch + paste-text fallback. Empty states for no-saved-searches
      and link-unavailable.
- [x] **Tracker stage filters.** A pure `TrackerSection.includes(_ stage:)` policy (All = everything;
      Applied/Interviewing = exact stage; Offers = offer **or** accepted; saved/rejected/declined/
      withdrawn show only under All) + `TrackerViewModel.jobs(in:)` filter the tracked list per
      sub-view. Reuses the existing `ApplicationStatus` data — no new model. A stage-specific empty
      state distinguishes "nothing at this stage" from "no tracked jobs at all".
- [x] **Settings split + About stub.** Engines and Adzuna panes (each with the shared Save control) +
      a functional **About** stub (app name, bundle version, one-liner) — Milestone C polishes it.
- [x] **Shared empty state.** New `Presentation/Components/InlineEmptyState` (left-aligned, for the
      scrolling Portfolio/Search sub-views, where the centered `ContentUnavailableView` doesn't sit
      right). List-based screens keep `ContentUnavailableView`.
- [x] **Tests.** `SectionRoutingTests` (`MainArea.subViews` == the section labels in order; label/index
      alignment; `init(index:)` clamping; the full `TrackerSection.includes` stage policy);
      `TrackerViewModelTests.jobsInSectionFilterByStage` (the VM filter); updated `ShellNavigationTests`
      breadcrumb tests (bare area name for single-sub-view Results; `Area / Sub-view` for multi-sub-view
      areas). Full suite green on macOS; the per-area layouts + empty states are a manual (device) check.

Note: B routes and splits; it changes no behaviour below Presentation. Milestone C adds the sidebar
collapse/keyboard polish and the About view's final treatment, then the README v0.4.0 summary + this
milestone's move are the closing docs step.

## Milestone C — Polish + About  ✅ done  ← closes v0.4.0  (`RootView`, `ShellNavigation`, `SettingsView`, project version)

Goal: finish the shell — keyboard navigation, sidebar collapse/restore, the About view's real
treatment — and correct the app version string. Presentation-only, plus a build-setting fix.

- [x] **Keyboard navigation.** `RootView` renders invisible, zero-size shortcut buttons (opacity 0,
      `accessibilityHidden`) that are active window-wide: **⌘1…⌘5** jump to each sidebar area and
      **⌘⇧[ / ⌘⇧]** step through the current area's inner-nav sub-views. Backed by new
      `ShellNavigation.nextSubView()` / `previousSubView()` (clamped; no-op for single-sub-view areas).
      The sidebar list + segmented control remain natively keyboard-navigable when focused.
- [x] **Sidebar collapse/restore.** Comes free with `NavigationSplitView` — the toolbar sidebar toggle
      collapses/restores the sidebar; the fixed column width (Milestone A) keeps the restored state
      stable. (No extra code; verified behaviour.)
- [x] **Pointer-cursor + swipe polish.** `clickableCursor()` is on the sidebar rows and the segmented
      inner nav; the result-card swipe / trackpad-swipe (Milestone V-C) is unchanged under the new
      host. Final pass — nothing further needed.
- [x] **About sub-view.** The Settings **About** pane now shows the app icon
      (`NSApplication.shared.applicationIconImage`), name, **Version <marketing version>**, and the
      one-liner — replacing the Milestone B stub.
- [x] **Version-string fix.** The Xcode `MARKETING_VERSION` was left at the template `1.0` (so About
      read "1.0"); corrected to **`0.4.0`** across the app + test target configs. This project versions
      by `v0.x.0` milestones, so About shows only the marketing version (the build number isn't
      meaningful here). Verified the built app's `CFBundleShortVersionString` is `0.4.0`.
- [x] **Tests.** `ShellNavigationTests` gained `nextAndPreviousSubViewStepAndClamp` (step + clamp at
      both ends) and `nextSubViewIsANoOpForSingleSubViewAreas`. Full suite green on macOS; keyboard
      feel, the About layout, and sidebar collapse are manual (device) checks.
- [x] **Docs + cleanup.** README v0.4.0 summary added; ROADMAP Milestone C ticked + v0.4.0 marked
      complete; this write-up. The `design/` scaffolding (UI spec + mockup) was removed now that the
      rework has shipped, and the `design/…` references were stripped from the docs.

Note: C closes **v0.4.0 — navigation & shell**. The whole release was Presentation-only (plus the
version build-setting): the sidebar shell (A), the per-area sub-view split (B), and this polish pass
(C). Nothing below Presentation changed, so ranking / generation / persistence / export / grounding
are exactly as they were in v0.3.0. The next version (v0.5.0) restarts milestones at A.

---

# v0.4.1 — fixes & refinements

This project's **first patch release** (`v0.x.y`): bug fixes and small refinements on top of the v0.4.0
navigation shell, not a new feature theme. Milestones restart at **A** and commit as
`v0.4.1 : Milestone X Completed` (see `CLAUDE.md` → Working process → Versioning). The project version
was bumped to **0.4.1** across all four `MARKETING_VERSION` copies at kickoff.

## Milestone A — Move the profile preview & its controls to Saved Profiles  ✅ done  (`Presentation/Portfolio`: `PortfolioView`)

Goal: make the Portfolio → **Profile** sub-view purely "import & build", and move the built profile's
preview and edit controls to the Portfolio → **Saved Profiles** sub-view. Presentation-only — the
`PortfolioViewModel` API is unchanged; the subviews were re-homed, not rewritten (they already called
existing VM methods).

- [x] **Three blocks moved.** The `ProfileSummary(profile:isDefault:)` preview, the
      `regenerateSummaryControl` (Regenerate description → `viewModel.regenerateSummary()`), and the
      `saveRow` (Save / Update Profile → `viewModel.saveProfile()`) moved out of `profileTab` into
      `savedProfilesTab` in `PortfolioView.swift`. Their definitions are unchanged and still gated on
      `supportsSummaryRegeneration` / `supportsSavedProfiles`.
- [x] **Profile sub-view = inputs only.** After the move, Profile is the résumé slot + optional
      cover-letter slot + **Build Profile** (with its busy/error affordances) — nothing rendered from
      `viewModel.profile`.
- [x] **Saved Profiles sub-view.** Renders the current built/loaded profile's preview + regenerate +
      save at the top (when `viewModel.profile != nil`), then the existing saved-profiles library below.
- [x] **Empty-state gate widened.** `savedProfilesTab` now shows the preview/save block whenever a
      current profile exists, the library section when it's non-empty, and the `InlineEmptyState`
      (retitled "No profile yet") only when there's **neither** a current profile **nor** any saved
      profiles. The empty-state copy was reworded for the new home (build on the Profile tab → preview /
      refine / save here; saved profiles load / set default / delete).
- [x] **Tests + build.** No VM API change, so the existing `PortfolioViewModelTests` (incl. the
      `regenerateSummary…` cases) still pass; full suite green on macOS and the app builds clean. (The
      pre-existing `ExportTemplate.style` main-actor warning is v0.4.1 Milestone H, unrelated.)

Resolved the milestone's open UX call as recommended: a just-built, **unsaved** profile shows its
preview/save block on Saved Profiles with **no** library empty-state note beneath it — the empty state
appears only when the whole sub-view has nothing. Presentation-only; nothing below Presentation changed.

## Milestone B — Remove the content-pane header text entirely (tabs only)  ✅ done  (`Presentation/App`: `RootView` + `ShellNavigation`)

Goal: drop the `Area / Sub-view` header text everywhere — above the content **and** in the window title
bar — so the segmented **tabs** are the only sub-view indicator and the **sidebar** is the only area
indicator. Presentation-only.

- [x] **In-content header text removed.** `RootView.contentHeader` no longer renders
      `Text(nav.breadcrumbTitle)` — it's now just the segmented `innerNav` (with its padding).
- [x] **Window title is the app name.** The content pane's `.navigationTitle(nav.breadcrumbTitle)` became
      `.navigationTitle("Taylor'd Portfolio")`, so the title bar never shows the area/sub-view.
- [x] **Results (single-sub-view areas) show no header and no tabs.** `contentPane` renders the header
      band + `Divider` only when `nav.selectedArea.subViews.count > 1`; Results (1 sub-view) fills the
      pane from the top with no empty band or stray divider. The selected sidebar row identifies it.
- [x] **`breadcrumbTitle` retired.** Removed `ShellNavigation.breadcrumbTitle` (nothing displays it) and
      the two `ShellNavigationTests` breadcrumb assertions; a stale doc-comment reference was cleaned up.
- [x] **Tests + build.** Full suite green on macOS; app builds clean.

Note: Presentation-only; nothing below Presentation changed. The content header now conditionally
appears (multi-sub-view areas only), which is also what makes Results render as its own plain section.

## Milestone C — Saved-to-Tracker jobs leave the Results list  ✅ done  (`Presentation/Results`: `ResultsViewModel` + `ResultsView`)

Goal: once a job has any tracker status, drop it from the **Results** list so Results shows only the
*un-triaged* ranked jobs; the job then lives in the **Tracker** (as "Saved" until advanced).
Presentation only — no new persistence or domain type; it reads the Milestone O/P status data that
already loads for the row badges.

- [x] **Tracked jobs excluded from the list.** New `ResultsViewModel.untrackedResults` = `results`
      minus any job with a persisted status (`isTracked`, from `historyByID`). `filteredResults`,
      `totalCount`, `isFilteredEmpty`, and the location/company picker options all derive from this
      un-tracked set; the underlying `results` array is untouched (delete/save still act on it).
- [x] **Live removal on save.** `saveToTracker` already marks `.saved` and calls `refreshHistory()`,
      which updates `historyByID` — so the saved row leaves `untrackedResults` immediately (row button,
      swipe-right, or the detail sheet's Save all flow through it). No extra plumbing needed.
- [x] **Distinct empty state.** New `allResultsTracked` (`results` non-empty but `untrackedResults`
      empty) drives an "All results are in your Tracker" `ContentUnavailableView`, kept separate from
      "No results yet" (nothing searched) and the filter-bar "No results match your filters".
- [x] **Dead UI cleaned up.** Removed the filter bar's now-meaningless **Tracked** facet (all shown
      rows are un-tracked). The Results status/"Saved" badge needed no code change — `RankedRow` renders
      the `.status` facet only when `status != nil`, and no shown row has a status now; `RankedRow` stays
      shared and unchanged so the **Tracker** keeps its status badges. `ResultsFilter.trackedStatus`/
      `TrackedFilter` stay (default `.any`, still unit-tested) — only the control was removed.
- [x] **Tests.** Replaced the obsolete `trackedFacetUsesTheStatusMap` test with Milestone C coverage in
      `ResultsViewModelTests`: a tracked job is excluded (list + counts); saving a job removes it live;
      `allResultsTracked` when every job is saved; the `ResultsFilter` still applies over the un-tracked
      set. Full suite green on macOS; build clean.

Note: Presentation-only. Reuses V's save/delete flow and the O/P status/history data; nothing below
Presentation changed. Milestone D gives the Tracker a **Saved** tab so these moved-out jobs have a home.

## Milestone D — Tracker: one tab per application status  ✅ done  (`Presentation/App`: `TrackerSection` + `RootView`)

Goal: expand the Tracker's inner nav from **All / Applied / Interviewing / Offers** to **All + a tab
per `ApplicationStage`**, so every status is directly reachable. Presentation only — reuses the existing
`ApplicationStage` / `ApplicationStatus` data.

- [x] **`TrackerSection` = All + 8 stages.** Rewrote the enum to `all, saved, applied, interviewing,
      offer, accepted, declined, rejected, withdrawn` (`ShellNavigation.swift`). A new `stage:
      ApplicationStage?` maps each case to its stage (`nil` for `All`); `title` derives from
      `stage?.label ?? "All"` (kept identical to the status badge); `rawValue` is still the segment index
      and `init(index:)` still clamps. `MainArea.subViews` for `.tracker` keeps deriving from
      `TrackerSection.allCases`, so the segment labels update automatically.
- [x] **Exact-stage filtering.** `includes(_:)` is now `stage == nil || stage == theStage` — All shows
      everything, every other tab matches its exact stage. This **un-bundles** the old Offers tab
      (which used to include `accepted`): Offer and Accepted are now separate tabs. `TrackerViewModel.
      jobs(in:)` is unchanged — it just sees the new cases.
- [x] **9-segment fit (the open call).** Resolved by wrapping the inner nav in a horizontal
      `ScrollView(.horizontal, showsIndicators: false)` in `RootView.contentHeader`, so the Tracker's 9
      tabs scroll rather than overflow the pane. Narrow areas (Portfolio/Search/Settings, 2–3 tabs) fit
      without scrolling and look identical.
- [x] **Per-tab empty states — no new code.** `TrackerView`'s per-stage empty state already derives its
      copy from `section.title` ("No <stage> applications" / "Nothing at the <stage> stage yet…"), so
      each new tab gets its own empty state automatically.
- [x] **Tests.** `SectionRoutingTests`: updated the tracker `subViews` list + `init(index:)` clamp;
      replaced the Offers-grouping test with `everyStageTabMatchesExactlyItsOwnStage`,
      `offerAndAcceptedAreDistinctTabs`, and `everyStageHasItsOwnReachableTab`. `TrackerViewModelTests.
      jobsInSectionFilterByStage` now seeds one job per stage and asserts each lands in exactly its own
      tab (and all under All). Full suite green on macOS; build clean.

Note: Presentation-only; the status model, persistence, and `TrackerViewModel` filter shape are
unchanged. The inner-nav scroll wrapper is shared but only actually scrolls where the content exceeds
the pane (today just the Tracker).

## Milestone E — Center the Tracker empty-state icon & text in the sub-view  ✅ done  (`Presentation`: `TrackerView` + `ResultsView`)

Goal: the Tracker's empty-state `ContentUnavailableView` hugged the top of the pane (just under the
tabs) instead of centering. Cause: the sibling `ProgressView` branch had
`.frame(maxWidth: .infinity, maxHeight: .infinity)` but the empty-state branches didn't, so they
rendered at their natural top-leading position. Presentation-only.

- [x] **Tracker empty states centered.** Added `.frame(maxWidth: .infinity, maxHeight: .infinity)` to
      both `ContentUnavailableView` branches in `TrackerView` ("No tracked applications" and the per-stage
      "No <stage> applications"), so the icon + title + description center vertically and horizontally.
      Applies to every one of Milestone D's per-status tabs.
- [x] **Consistency sweep — Results.** Centered the Results empty states the same way: "No results yet",
      the "All results are in your Tracker" state (added in Milestone C), and the filter-empty "No results
      match your filters" (centered below the filter bar).
- [x] **Left-aligned empty states untouched.** The scrolling Portfolio/Search sub-views keep their
      left-aligned `InlineEmptyState` (correct by design) — this milestone only affects the centered
      `ContentUnavailableView` panes.
- [x] **Build + tests.** Centering isn't unit-testable (a device/visual check), but the full suite stays
      green and the app builds clean.

Note: Presentation-only, pure layout — no ViewModel or lower-layer change. The exact centered
appearance across window sizes is a manual (device) check.

## Milestone F — Source Documents browsable by profile  ✅ done  (`Presentation/Portfolio`: `PortfolioView`)

Goal: the Portfolio → **Source Documents** sub-view showed only the *currently-loaded* profile's tidied
documents; make it **keyed by profile** so each saved profile's résumé + cover letter are discoverable
individually. A view restructure over existing data — each `SavedProfile` already carries its own
`sourceFileName` / `readableText` and `coverLetterFileName` / `coverLetterReadableText`, and
`viewModel.savedProfiles` already loads them. Presentation only — no ViewModel/persistence change.

- [x] **Per-profile disclosures.** `sourceDocumentsSection` now iterates `viewModel.savedProfiles`,
      rendering each as a `profileDocuments(_:)` `DisclosureGroup` titled with the profile name
      (`person.text.rectangle`). Expanding it reveals that profile's documents via the existing collapsed,
      scrollable `documentDisclosure` — résumé (`readableText`, labelled with `sourceFileName`) and, if
      present, the cover letter (`coverLetterReadableText` / `coverLetterFileName`). Net result is a
      two-level **profile → documents** disclosure.
- [x] **Per-profile empty note.** A saved profile with no tidied source text (older/empty saves) shows an
      inline "No source documents saved for this profile." note when expanded.
- [x] **Empty state + gate.** Replaced the `hasSourceDocuments` gate (which keyed off the loaded profile's
      readable text) with `hasSavedProfiles` (`supportsSavedProfiles && !savedProfiles.isEmpty`); the
      `InlineEmptyState` copy was reworded for the per-profile framing (build & save a profile → its docs
      appear here, grouped by profile).
- [x] **Open call resolved.** Source Documents lists **only saved profiles** (the recommended option) — an
      unsaved, just-built profile appears here once saved, consistent with Milestone A putting the save
      controls on Saved Profiles.
- [x] **Whole header row clickable (`ExpandableRow`).** SwiftUI's `DisclosureGroup` only toggles on the
      caret; both Portfolio disclosures now use a new shared **`Presentation/Components/ExpandableRow`**
      whose entire header row is the tap target, with the pointing-hand cursor on the header (the expanded,
      selectable text keeps its native I-beam). So clicking anywhere on a profile row expands its documents.
      The same component now also backs the Search **"Paste the posting text"** fallback (via its
      caller-controlled `isExpanded:` initializer, so the auto-expand-on-fetch-error still works). The
      Results **filter bar** keeps `DisclosureGroup` on purpose — its header holds an interactive Clear
      button, so a whole-row tap would conflict.
- [x] **Tests + build.** No ViewModel API change (the view reads `SavedProfile` fields directly), so no new
      unit tests were needed; full suite stays green and the app builds clean.

Note: Presentation-only. Reuses the `SavedProfile` source/cover-letter fields and `documentDisclosure`;
nothing below Presentation changed. `ExpandableRow` is a reusable component (self-managed or
caller-controlled expansion) available for future disclosures.

## Milestone G — Settings Save button: drop the surrounding section background  ✅ done  (`Presentation/Settings`: `SettingsView`)

Goal: the Settings **Save** button sat inside a grouped-form `Section`, so `.formStyle(.grouped)` drew an
inset background band around it. Make it just the button, no container. Presentation-only.

- [x] **Bare Save button in the section footer.** The old `saveSection` (a form `Section`, which drew the
      band) was replaced by a `saveButton` placed in each section's **`footer:`** — footers render outside
      the grouped section's rounded fill, so the button has **no background band**, yet it's **attached to
      the end of the section and scrolls with the content**. (Two earlier attempts were corrected: an
      out-of-`Form` `VStack` was pinned to the view bottom and didn't scroll; a loose in-`Form` row with
      `.listRowBackground(Color.clear)` still showed the band.) Engines keeps its explanatory footer text
      with the button below it; Adzuna gained a footer holding just the button.
- [x] **Both editing panes, About unaffected.** `saveButton` sits in the Engines and Adzuna footers; the
      About pane has nothing to save and shows no button.
- [x] **Behaviour preserved.** Same `viewModel.save()` action, `.borderedProminent` style, and
      `clickableCursor()` — only the surrounding background is gone.
- [x] **Build + tests.** Full suite green on macOS; app builds clean. The bare-button appearance is a
      device/visual check.

Note: Presentation-only; no ViewModel or lower-layer change.

## Milestone H — Clear the concurrency & unused-result build warnings  ✅ done  (`Infrastructure/Export` + `SearchViewModel`)

Goal: silence the batch of build warnings — a family of "main actor-isolated … can not be referenced
from a nonisolated context" plus one unused-`try?`. Root cause of the family: the project **defaults
type isolation to `MainActor`**, so several pure Export value types were MainActor-isolated while the
nonisolated renderer / zip writer referenced them. Compile-time hygiene only — no behaviour change.

- [x] **Export value types marked `nonisolated`.** `ExportTemplate`, `TemplateStyle`, and `RGBColor`
      (all pure `Sendable` value types) are now `nonisolated`, clearing the `ExportTemplate.style`
      default-argument warning and every nonisolated call site at once.
- [x] **Nonisolated accessors/helpers.** `RGBColor.nsColor` (the AppKit bridge) and the private `Data`
      little-endian `append(le16:)` / `append(le32:)` helpers are now `nonisolated` — the latter cleared a
      large batch of warnings in `ZipArchiveWriter` that only a **clean** build surfaced (incremental
      builds had masked them behind the first `style` warning).
- [x] **Unused `try?` fixed.** `SearchViewModel.saveCurrentSearch()` now discards the save result
      explicitly: `_ = try? await saveSearch(buildRequest())`.
- [x] **Verified warning-free.** A full **clean** build reports **zero** code warnings across the whole
      project; the full test suite passes on macOS. No runtime behaviour changed (annotations only).

Note: touches Infrastructure/Export (the one non-Presentation milestone in v0.4.1) + Presentation/Search.
Because the export renderer and zip writer were re-annotated, PDF/DOCX export is on the v0.4.1 device
checks — behaviour is unchanged but worth a re-verify.

---

**v0.4.1 — fixes & refinements is complete** (Milestones A–H). It was mostly Presentation — profile/
Saved-Profiles reorg (A), header removal (B), Results↔Tracker triage (C), a Tracker tab per status (D),
centered empty states (E), per-profile Source Documents with whole-row-clickable `ExpandableRow`
disclosures (F), and the Settings Save button (G) — plus a warnings-cleanup pass that also touched
Infrastructure/Export (H). The project version was bumped to **0.4.1**. Next is **v0.5.0** (restarts at
Milestone A).

---

# v0.5.0 — document generation fixes

Theme: round out the tailored résumé + cover letter experience — the paths to view and regenerate the
generated documents, and (later milestones) controls over how they're generated. Milestones restart at
**A**; the project version is bumped to **0.5.0**.

## Milestone A — View generated résumé & cover letter from the Tracker  ✅ done  (`Presentation`: `JobDetailView`, `TrackerView`, `RootView`, `Composition`, `ApplicationSheet` + `ApplicationViewModel`)

Goal: after generating a job's materials from the Tracker, give the user a clear way back to them. The kit
already persisted and reloaded without an LLM call (`ApplicationViewModel.open(for:)`), but the detail
footer showed only a lone "Generate résumé & cover letter" button with no "already generated" signal — so
the materials were effectively invisible.

- [x] **Detect saved materials.** `JobDetailView` gained an optional
      `loadApplication: LoadApplicationUseCase?`; its `.task` now loads both the status and a
      `hasGeneratedMaterials` flag (`refreshHasMaterials()`), and re-checks after the Application sheet
      closes (`.onChange(of: showingApplication)`), so the View button appears immediately after a first
      generation. Follows the existing `loadStatus` direct-use-case pattern (the view has no ViewModel).
- [x] **View + Regenerate footer.** A pure
      `JobDetailFooter.resolve(canGenerate:hasGeneratedMaterials:canSaveToTracker:)` decides the footer:
      Results context → Save-to-Tracker (unchanged); Tracker with no kit → **Generate**; Tracker with a
      saved kit → **View résumé & cover letter** (primary) + **Regenerate**.
- [x] **View vs regenerate routing.** New `ApplicationStartMode` (`.viewOrGenerate` / `.forceGenerate`)
      passed into `ApplicationSheet`; its `.task` calls `open` (load saved, no LLM) or `generate` (fresh)
      accordingly. **View** loads only; **Regenerate** forces fresh. *(Resolved the two planning open calls:
      the second button is "Regenerate" and force-regenerates; the in-sheet Regenerate button coexists
      harmlessly.)*
- [x] **Wiring.** `LoadApplicationUseCase` exposed on `Composition` (`var loadApplication`, also reused by
      `makeApplicationViewModel`), threaded `RootView` → `TrackerView` → `JobDetailView`. Results context
      (`canGenerate == false`) is unaffected — no View/Generate there.
- [x] **Tests.** `JobDetailFooterTests` covers the pure resolver (tracker with/without materials; Results
      stays Save-only even if a kit exists; no-action fallback). Full suite green.

On-device: yes — the existence check is a local `PersistentRecordStore` read; regeneration uses the current
`.application` engine. Note (A × B): once Milestone B converts the Application sheet to a window, the View /
Regenerate buttons should open that **window** instead of the sheet.

## Milestone B — Job detail & Application as real windows, not sheets  ✅ done (B-A + B-B + B-C)  (`Presentation`: new `AppSession` / `JobDetailWindow` / `ApplicationWindow`, `App`, `RootView`, `JobDetailView`, `ApplicationSheet`, `ResultsView`, `TrackerView`)

Goal: replace the modal **sheets** (the job-detail `.sheet(item:)` in Results + Tracker, and the Application
`.sheet(isPresented:)` nested inside it) with genuine detached macOS **windows**.

**Design decision — session-driven single-instance `Window`s (not value-keyed `WindowGroup(for:)`).** A
detached scene renders outside `RootView`'s tree, and `PortfolioGrounding` isn't `Codable`, so profile +
grounding must be shared via app-level state regardless. Given that, the selected job is also held on the
shared state (in-memory) rather than serialized as a window value — which sidesteps the id→load round-trip,
the `Hashable` requirement on `RankedJob`/`JobListing`, and a value-dedup-vs-regenerate conflict. Net: two
reusable single-instance `Window`s that re-target on each open.

- [x] **B-A — Shared session.** New `@MainActor @Observable AppSession` (`Presentation/App/AppSession.swift`):
      `profile` + `grounding` (mirrored from `PortfolioViewModel` by `RootView`), the detail/application
      selections, and a **revision token** (`dataChanged()`). Owned by `Taylor_d_PortfolioApp` as `@State`,
      injected into every scene via `.environment`. `RootView.onChange(of: session.revision)` reloads
      `tracker.load()` + `results.refreshHistory()` (a detached window has no sheet-dismiss callback).
      Tests: `AppSessionTests`.
- [x] **B-B — Job Detail window.** Single-instance `Window("Job Detail", id: JobDetailWindow.id)`;
      `JobDetailWindow` reads `session.detailJob` + profile/grounding and builds `JobDetailView` from
      `Composition`. Results + Tracker rows call `session.showDetail(_:context:)` + `openWindow` instead of
      the removed `.sheet(item:)`. `canGenerate = (context == .tracker)`; Results Save-to-Tracker is a direct
      `MarkStatusUseCase(.saved)` call. `JobDetailView` gained `allowsSwipe` (off in-window) + an `onMutate`
      callback (→ `session.dataChanged()`).
- [x] **B-C — Application window.** Single-instance `Window("Application", id: ApplicationWindow.id)`;
      `ApplicationWindow` reads `session.applicationJob` + start mode + `applicationRequestID` and hosts
      `ApplicationSheet`. `JobDetailView`'s View/Generate/Regenerate buttons now call an `onOpenApplication`
      closure → `session.showApplication(_:mode:)` + `openWindow` (the nested `.sheet` + its per-window
      `ApplicationViewModel` param are gone). `ApplicationSheet` gained `requestID` (re-runs its start mode
      when the single window re-opens for a new request) + `onGenerated` (→ `session.dataChanged()`, so the
      lists and the detail window's View button refresh). Generation/export/one-page-gate logic unchanged —
      only the container moved.
- [x] **Cleanup.** Removed the now-dead detail params (`profile`, `applicationViewModel`, `markStatus`,
      `loadStatus`, `grounding`, `loadApplication`) from `ResultsView` / `TrackerView` and their `RootView`
      call sites, plus the shared `application` VM + status use-case props on `RootView`.

Tests: `AppSessionTests` (revision bump, `showDetail` targeting); existing VM/footer suites unchanged; full
suite green, warning-free. **Window presentation itself is a manual (device) check** — B-A/B-B verified on a
real run; B-C (Application window open / View↔Regenerate re-run / list refresh) to confirm on device.
On-device: yes — local reads + existing engines, no network, no new persistence.

## Milestone C — Remove the redundant "Mark as applied" button  ✅ done  (`Presentation/Results`: `JobDetailView`)

Goal: the detail view's Application-status section showed a prominent **"Mark as applied"** button for
untracked jobs, next to a **"Set status"** menu that already lists every settable stage — so the button was
redundant.

- [x] Removed the `if status == nil { Button("Mark as applied") … }` block from `JobDetailView.statusSection`.
      Applied stays reachable via **Set status → Applied** (`ApplicationStage.settable` excludes only `.saved`)
      with the identical auto-date-stamp (`mark(.applied)`). The `StatusBadge` / "Not tracked yet" text and
      the "Set status" menu are unchanged.

Seam: Presentation only, one file; `MarkStatusUseCase` / stamping untouched. Existing status coverage
(`StatusUseCaseTests`) stands; full suite green. On-device: n/a (UI only).

## Fix — Restore swipe-to-save/delete on Results  ✅ done  (`Presentation/Results`: `ResultsView`)  — Milestone B follow-up

Milestone B moved the result detail into a window, which dropped the V-C swipe gesture (it lived on the
old detail *card*). Restored it directly on the **Results list rows** using native macOS `List`
`.swipeActions`, reusing the same view-model methods as the existing row icons:

- [x] **Swipe right (leading) = Save to Tracker** (`viewModel.saveToTracker`, green, full-swipe enabled).
- [x] **Swipe left (trailing) = Delete** (`viewModel.delete`, destructive). `allowsFullSwipe: false` — a
      full swipe *reveals* the Delete button rather than firing instantly, since delete also clears the
      job's saved status + generated materials. (Open to enabling full-swipe delete if preferred.)
- [x] Gated on `supportsRowActions` (same as the icons); the explicit save/delete icons remain. Build +
      full suite green, warning-free.

Seam: Presentation only (`ResultsView.resultRow`). On-device: n/a (UI only).

## Feature — Remove a job from the Tracker (return to Results or delete)  ✅ done  (`Business/UseCases`, `TrackerViewModel`, `TrackerView`, `Composition`)

Ad-hoc request: from the Tracker, remove a job — either **put it back in Results** or **delete it entirely**.

- [x] **Untrack (return to Results).** New `UntrackJobUseCase` (`Business/UseCases`) clears **only** the job's
      `ApplicationStatus` (`SavedStatusRepository.delete`), keeping the saved listing + any generated
      materials — so the job drops out of the Tracker and reappears in Results as an un-triaged result
      (reversible). `TrackerViewModel.returnToResults(_:)`.
- [x] **Delete entirely.** Reuses `DeleteSavedJobUseCase` (listing + status + materials).
      `TrackerViewModel.delete(_:)`.
- [x] **UI.** Swipe actions on the Tracker list rows (symmetric with the Results rows): **swipe right = "To
      Results"** (blue, full-swipe), **swipe left = "Delete"** (destructive, `allowsFullSwipe: false` →
      reveal + tap). Both call `session.dataChanged()` so the main window's Results list refreshes (the
      returned job reappears there). Gated on `supportsRowActions` (both use cases wired).
- [x] **Wiring + tests.** `untrackJob` + `deleteSavedJob` threaded through `Composition.makeTrackerViewModel`.
      `TrackerViewModelTests`: untrack clears status but keeps the listing; delete forgets listing + status +
      materials; `supportsRowActions` gating.

Also (drive-by): marked the pure `SwipeOutcome` and `JobDetailFooter` enums `nonisolated` to clear
main-actor-isolated `Equatable`-conformance warnings surfaced in the test target (would be Swift 6 errors).
Full suite green, warning-free. Note: a returned job reappears in Results once the list reflects the store
(it does within a session / after a fresh Results load). Seam: Presentation + one Business use case.
On-device: yes (local status/store writes).
