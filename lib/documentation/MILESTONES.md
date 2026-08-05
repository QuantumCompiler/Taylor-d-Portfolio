# Taylor'd Portfolio — Completed Milestones

The **record of finished work** — milestones (and sub-parts) that are done, moved here out of
`TODO.md` so that file stays focused on what's left. This is history and reference: what shipped
and how it was built. For the product spec see `SPEC.md`; for the high-level plan and backlog see
`ROADMAP.md`; for the remaining work see `TODO.md`. See `CLAUDE.md` → "Working process" for how
these docs fit together.

Grouped by release: **v0.1.0 — foundation**, **v0.2.0 — reliability**, **v0.3.0 — output & polish**,
**v0.4.0 — navigation & shell**, **v0.4.1 — fixes & refinements** (the first patch release),
**v0.5.0 — document generation fixes**, **v0.5.1 — LaTeX résumé & cover letter output**,
**v0.6.0 — richer grounding, job detail & sources**, and **v0.6.1 — keyword match & ATS coverage**, plus
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

## Milestone D — Generation controls: fidelity, tailored aspects, presets, disclosure & rank-target  ✅ done (D-A…D-F)  (`Data/Models` + `Data/LLM` + `Data/Persistence` + `Business/UseCases` + Application Presentation)

Goal: give the user control over how a job's tailored application is generated — a controls panel with a
fidelity scale, section checkboxes, saved presets, disclosed embellishment, and an outcome-driven rank
target. **Grounded stays the default**; embellishment/fabrication is opt-in and always disclosed. The
default (`GenerationSettings.default`) path is **byte-for-byte** the pre-D prompt.

- [x] **D-A — Model + threading + button.** `GenerationSettings` (`fidelity` + `aspects` + `desiredRankMatch`)
      / `TailoredAspect` / `FidelityBand` (`Data/Models`). `settings` threaded `GenerateApplicationUseCase`
      → `LLMProvider.generateApplication(…settings:)` (new requirement + forwarding default, like `grounding`)
      → `Prompts.generateApplication` via a `generationControls(_:)` addendum (empty for `.default`). Both
      engines + router override; `ApplicationViewModel.generationSettings`. Button renamed
      **"Generate application"** / **"View application"**.
- [x] **D-B — Fidelity scale.** A `0…1` slider (Authentic / Curated / Embellished bands at 0.15 / 0.75)
      mapped to **prompt latitude** (open call resolved: no LLM sampling-temperature, to keep the two engines
      in lockstep). Authentic = today's guardrail; curated = emphasize + infer adjacent skills; embellished =
      permit plausible additions.
- [x] **D-C — Tailored aspects (four résumé sections).** `TailoredAspect` = `summary` / `experience` /
      `projects` / `skills` (empty = all). *Revision applied:* dropped `education` (verbatim) and
      `coverLetter` (derived from the tailored résumé); each targeted section carries the objective to
      **match the job post's keywords + description**; the cover letter is written from the tailored résumé.
- [x] **D-D — Presets.** `GenerationPreset` + `GenerationPresetsRepository` (`kind` "generationPreset") +
      `SaveGenerationPresetUseCase` / `LoadGenerationPresetsUseCase` / `DeleteGenerationPresetUseCase`
      (mirroring `SavedSearch`); a **Presets** menu (apply / delete) + **Save as preset** (auto-named) in the
      panel. Presets are global.
- [x] **D-E — Disclosure.** The embellished band's prompt lists additions as `EMBELLISHED:` lines in
      `gapNote`; a pure `GapNoteParts.parse` splits those from the honest gaps, and the Application view shows
      a distinct **"Disclosures — verify before sending"** section + an embellished-mode warning banner.
      *(open call resolved: no export "draft" watermark — stamping the deliverable is counterproductive; the
      in-app warning is the safeguard.)*
- [x] **D-F — Desired rank-match target (the master control).** A rank slider (0–100) that, when set,
      **overrides fidelity + aspects** (they grey out) and runs `GenerateToTargetUseCase`: a new
      `LLMProvider.scoreApplication(job:brief:kit:) → JobMatch` step scores the tailored résumé, and the loop
      **generate → score → escalate latitude → regenerate** (curated → embellished → full fabrication) repeats
      to a hard cap (default 4 rounds), stopping at the target or returning the best attempt with the achieved
      score ("Reached 78 of your 85 target"). The winning kit carries its own D-E disclosures.

**Integrity:** SPEC "Grounded generation" + CLAUDE.md "Hard rules" were revised (during planning) to
*grounded-by-default + opt-in + disclosed*. The rank-target loop is the most aggressive mode; its D-E
disclosure is mandatory.

Also shipped as a follow-up (see the "Fix — Generation is user-initiated" entry below): generation is
**explicit** (no auto-generate on open), so the controls can be set first.

Tests: `GenerationSettingsTests`, `PromptsTests` (default byte-for-byte / curated / embellished-disclosure /
aspect-scope + keyword goal), `GenerationPresetsRepositoryTests`, `GapNotePartsTests`,
`GenerateToTargetUseCaseTests` (stop-at-target / cap-returns-best / fidelity escalation / VM uses the loop).
Full suite green, warning-free. **Live LLM behaviour (does fidelity/rank actually shift output, does the
loop converge) is a manual device check.** On-device: yes — presets are local; prompt-driven fidelity keeps
both engines in lockstep; the rank loop's extra scoring calls run on the current `.application` engine.

## Fix — Runtime provider dropped the D settings/score methods + stale length banner  ✅ done  (`Composition.SettingsBackedLLMProvider`, `ApplicationViewModel`)  — Milestone D follow-up

Two bugs surfaced on a device run (rank-target generation failed with "Couldn't generate"):

- [x] **Root cause — the runtime provider adapter was missing the new methods.** `SettingsBackedLLMProvider`
      (the live `LLMProvider` the app uses, which forwards each call to a freshly-built `LLMRouter`) explicitly
      forwards every protocol method, but the two added in Milestone D weren't added to it. So
      `generateApplication(…settings:)` fell through to the **ignore-settings** forwarding default (fidelity /
      aspects were silently dropped at runtime, even though unit tests passed via the router/providers), and
      `scoreApplication(…)` fell through to the **throwing** default → the D-F rank-target loop threw. Fixed by
      forwarding both to `router()`. **This also means D-B/D-C now actually affect real output** (they didn't
      before this fix).
- [x] **UI — stale length-gate banner.** `resumeExceedsOnePage` was `resumePageCount > 1` regardless of a
      kit, so a page count from a prior generation lingered as a "Résumé is 3 pages…" banner after a
      failed/cleared generation. Now requires `kit != nil`.
- [x] **UI — center the Application content messages.** The "Couldn't generate" `ContentUnavailableView`
      lacked the `.frame(maxWidth: .infinity, maxHeight: .infinity)` stretch (its loading / "Ready to
      generate" siblings had it), so it hugged the top instead of centering. Added the frame; audited the
      other `ContentUnavailableView`s app-wide — all centered (Portfolio/Search deliberately use the
      left-aligned `InlineEmptyState` for scrolling screens, per v0.4.1 Milestone E).
- [x] **Regression guard.** `LLMRouterTests.routesRankAndGenerateToo` extended to exercise
      `generateApplication(…settings:)` + `scoreApplication` forwarding. Full suite green, warning-free.

Seam: Presentation (Composition adapter + ApplicationViewModel). On-device: yes.

## Fix — Spurious Photos/Music privacy prompts from the Claude subprocess  ✅ done  (`Infrastructure/LLM/ClaudeProcessClient`)

The unsandboxed app launched `claude -p` **without a working directory**, so the child inherited the app's
CWD (the user's home for a Finder-launched app). The Claude CLI's startup context-scan then reached
TCC-protected locations (Photos = `~/Pictures`, Music = `~/Music`, Documents…), and because the app is
unsandboxed macOS attributed those accesses to **Taylor'd Portfolio** and prompted the user — access that
makes no sense for a job app. (Confirmed the built app's entitlements are clean: only file-picker /
network / debug — no media entitlements, so these were runtime TCC prompts, not declared capabilities.)

- [x] `ClaudeProcessClient.runProcess` now sets `process.currentDirectoryURL` to a neutral, app-owned
      **Caches subdirectory** (`…/Caches/ClaudeProcess`, not TCC-protected, created on demand) via
      `neutralWorkingDirectory()`. The child has nothing to traverse into the home folder, so the prompts
      stop. `HOME` is left intact so Claude still finds its `~/.claude` auth/config.

Note for the user: macOS caches prior TCC decisions, so already-granted/denied entries persist in
System Settings → Privacy & Security; they can be cleared with `tccutil reset Photos com.veritum.Taylor-d-Portfolio`
(and `... SystemPolicyDocumentsFolder`, `MediaLibrary`, etc.) if desired. Seam: Infrastructure only.

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

## Fix — Generation is user-initiated (explicit Generate button)  ✅ done  (`ApplicationViewModel`, `ApplicationSheet`, + `AppSession`/`ApplicationWindow`/`JobDetailView` cleanup)  — Milestone D follow-up

Opening the Application view auto-generated immediately, so the Milestone D options panel (fidelity /
aspects) couldn't be set first. Made generation **explicit**:

- [x] `ApplicationViewModel.open(...)` (load-or-generate) replaced by **`loadSaved(for:)`** — loads saved
      materials if present (no LLM call), otherwise leaves `kit` nil. Opening never auto-generates.
- [x] `ApplicationSheet` now shows the **Generation options** panel (expanded by default) + a prominent
      **"Generate application"** button (→ "Regenerate" once a kit exists); a "Ready to generate" placeholder
      invites setting options first. Generation runs only on that button (`runGeneration`).
- [x] **Cleanup:** removed the vestigial `ApplicationStartMode` / `startMode` / auto-generate machinery from
      B-C (`AppSession.showApplication` drops the mode; `ApplicationWindow` / `JobDetailView.onOpenApplication`
      updated). The Tracker detail footer simplified to **"Generate application"** / **"View application"**
      (the Application window now owns generate/regenerate); `JobDetailFooter.viewAndRegenerate` → `.view`.
- [x] Tests updated (`ApplicationViewModelTests`: loadSaved never auto-generates, then explicit generate
      persists; loads saved without a provider call; `JobDetailFooterTests`). Full suite green, warning-free.

Seam: Presentation only. On-device: yes.

---

**v0.5.0 — document generation fixes is complete** (Milestones A–D + fixes). A: view generated materials
from the Tracker. B: job detail + Application as real single-instance `Window`s driven by a shared
`AppSession`. C: removed the redundant "Mark as applied" button. D (D-A…D-F): the generation-controls panel
— fidelity scale, tailored-section checkboxes (four résumé sections aimed at the JD keywords), presets,
disclosed embellishment (`GapNoteParts`), and the outcome-driven rank-target loop (`GenerateToTargetUseCase`
+ `scoreApplication`). Grounded stays the default; embellishment is opt-in and disclosed (SPEC / CLAUDE
hard-rules revised accordingly). Plus fixes: explicit user-initiated generation, swipe-to-save/delete on
Results, remove-from-Tracker, the runtime provider forwarding the D settings/score methods, and the Claude
subprocess running in a neutral directory (no spurious Photos/Music prompts). The project version is
**0.5.0**. The next version — number and theme chosen when it's started — restarts at Milestone A.

---

# v0.5.1 — LaTeX résumé & cover letter output

Theme: give the app a **second, high-fidelity PDF output path** — render the generated `ApplicationKit` into
`.tex` against Taylor's own awesome-cv classes and compile with `lualatex` (Milestones A–E, in progress) —
plus a batch of export/Tracker refinements (F–I). A **patch release** on shipped v0.5.0; milestones restart
at **A**; the project version is bumped to **0.5.1**. (Milestone A done; B–E tracked in `TODO.md`.)

## Milestone A — Bundle the awesome-cv LaTeX assets in the app  ✅ done  (`Infrastructure/Tex/TexAssets` (new); `lib/tex/` bundled assets; `project.pbxproj` folder reference)

Goal: ship the awesome-cv **presentation** assets inside the app bundle so the LaTeX compile (Milestone B)
can stage them into a scratch build dir where an app-generated `.tex` resolves `\documentclass{Class/…}` and
`\fontdir[fonts/]`. Only presentation assets are bundled — never the candidate's content sections.

- [x] **Assets copied** to a new **`lib/tex/`** folder (kept OUT of the synchronized `lib/src` root to avoid a
      sync-group conflict): `Class/{Resume,CoverLetter,Portfolio}.cls`, `fonts/` (19 Roboto / Source Sans /
      FontAwesome faces), `Images/` (Signature + logo), and `fontawesome.sty` / `fontawesome5.sty` (~3.6 MB).
- [x] **Xcode integration (open call resolved).** Added `lib/tex` as a **blue folder reference** in the app
      target's (previously empty) Resources build phase, so the whole tree copies into
      `…/Taylor'd Portfolio.app/Contents/Resources/tex/` with structure preserved (verified in the built
      `.app`). Chose the folder-reference route over a synchronized-group membership exception because the
      assets sit outside `lib/src` and the `.tex`/`.cls` need the directory layout intact — mirroring how
      `lib/secrets` / `lib/xcode` are non-synchronized explicit references. Needed a new `PBXBuildFile` section
      (the project had none — everything else is synchronized).
- [x] **`TexAssets`** (`Infrastructure/Tex`, `nonisolated`): `init?(bundle:)` resolves the bundled `tex/`
      folder (nil when absent — degrades gracefully), `init(root:)` for fixtures, typed `classesDirectory` /
      `fontsDirectory` / `imagesDirectory` accessors, and `isComplete` (the three classes + fonts present).
- [x] **Header identity (open call resolved as recommended):** the classes' `\pageHeader` keeps Taylor's fixed
      contact block; the app supplies only the role headline + content. Profile-driven identity is a later idea.
- [x] **Tests.** `TexAssetsTests` resolves the assets **from the running app bundle** (which doubles as the
      "assets are in the built `.app`" check — Resume.cls / CoverLetter.cls / a Roboto face / fontawesome5.sty
      present + `isComplete`), returns nil for the asset-free test bundle, and flags incomplete/complete
      fixtures. Full suite green.

Seam: Infrastructure/Tex (new) + the Xcode project (folder reference). On-device: n/a (static packaging).
Note: the `CLAUDE.md` layer-map / Build-&-run update for the new `Infrastructure/Tex` seam + `lib/tex/` assets
+ the `lualatex` dependency is **deferred to Milestone E** (the docs milestone).

## Milestone B — `LaTeXCompiling` port + `LaTeXProcessClient` (shell `lualatex`)  ✅ done  (`Infrastructure/Tex/LaTeXCompiling` + `LaTeXProcessClient` (new), `Infrastructure/Process/ProcessSupport` (new), `Infrastructure/LLM/ClaudeProcessClient`)

Goal: the engine that turns a `.tex` document into PDF bytes — the second external binary the (unsandboxed)
app shells out to, mirroring `ClaudeProcessClient`.

- [x] **`LaTeXCompiling` port** (`Infrastructure/Tex`): `func compile(tex:jobName:) async throws -> Data` +
      `var isAvailable: Bool`, with a `LaTeXProcessError` enum (`notInstalled`, `assetsUnavailable`,
      `launchFailed`, `nonZeroExit(code:log:)`, `noOutput`).
- [x] **`LaTeXProcessClient`** (`nonisolated struct`): resolves `lualatex` via a `.env`/`.path` `Launcher`;
      a compile stages the bundled ``TexAssets`` (Milestone A) into a fresh app-owned Caches build dir by
      **symlinking** each item (`Class/`, `fonts/`, `Images/`, `*.sty` — so `\documentclass{Class/…}` /
      `\fontdir[fonts/]` resolve), writes the `.tex`, runs `lualatex` **twice**
      (`-interaction=nonstopmode -halt-on-error`), reads the produced PDF, and tears the dir down (defer).
      Non-zero exit surfaces the `logTail` of lualatex's output; missing PDF → `noOutput`.
- [x] **Shared PATH helper (open call resolved).** Lifted `searchPATH` into a new
      `Infrastructure/Process/ProcessSupport` (now taking `extraDirectories`) + a `locateExecutable(named:inPATH:)`
      probe; `ClaudeProcessClient.searchPATH` delegates to it (signature/behaviour unchanged, its tests
      untouched). `LaTeXProcessClient` prepends the TeX bin dirs (`/Library/TeX/texbin`, TeX Live, Homebrew) so
      `lualatex` resolves from a GUI app's minimal `PATH`; `isAvailable`/`locate()` drive Milestone D's disabled
      state. *(Open call: stage by symlink — resolved to symlink, per the recommendation.)*
- [x] **Tests.** Pure helpers unit-tested without launching a process (arg vector, `safeBaseName`, `logTail`,
      PATH prepending, executable location, staging symlinks) plus deterministic compile guards
      (`assetsUnavailable`, `notInstalled`) — and a **real end-to-end compile** (`compilesATrivialDocumentEndToEnd`)
      that runs `lualatex` and asserts `%PDF` output, **guarded on `isAvailable`** so a TeX-less environment
      skips it rather than failing. Full suite green.

Seam: `Infrastructure/Tex` + `Infrastructure/Process` (new) + `Infrastructure/LLM` (delegation). On-device:
n/a for the model; **needs a local TeX install** (`lualatex`) — a new optional external dependency, like the
`claude` CLI. (Verified against the machine's `/Library/TeX/texbin/lualatex`.)

## Milestone C — `TexDocumentBuilder`: `ApplicationKit` → awesome-cv `.tex`  ✅ done  (`Infrastructure/Tex/TexDocumentBuilder` (new); reuses `Infrastructure/Text/MarkdownBlockParser` + `MarkdownInline`)

Goal: the mapping piece — the inverse of the repo's `tex2docx.py`. Render the generated résumé / cover-letter
**Markdown** into `.tex` that drives the bundled awesome-cv classes. Pure + domain-agnostic (Markdown in,
`.tex` out), fully unit-testable. **Resolved the C-parse vs C-structured open call to C-parse** (best-effort
structural map, no generation-seam change) for the patch; C-structured stays the flagged fast-follow.

- [x] **Résumé** (`resume(fromMarkdown:)`): emits the `Class/Resume` driver + `\makecvheader`, a `\position`
      role headline (the leading fully-bold line), a `\paragraphstyle` summary, then a `\cvsection` per H2.
      Skills-like sections (`skill`/`qualification`/`competenc`) → `cvskills` + `\cvskill{bucket}{items}`
      (split on the first `": "`); other sections → entries: a heading or fully-bold line is the title
      (`\entrytitlestyle`), the next plain line a subtitle (`\entrydatestyle`, e.g. location · date), bullets
      → `\begin{cvitems}\item{…}`. The **name** H1 and **contact** lines are dropped (the class header renders
      them). Loose prose falls back to a justified paragraph.
- [x] **Cover letter** (`coverLetter(fromMarkdown:)`): emits the `Class/CoverLetter` driver, `\begin{cvletter}`,
      one `\lettersection` per H2 with its paragraphs, and `\makeletterclosing`.
- [x] **Escaping + inline.** A char-by-char `escape` for the LaTeX specials (`& % $ # _ { } ~ ^ \`); `inlineLaTeX`
      renders `**bold**`/`*italic*`/links via `MarkdownInline` → `\textbf`/`\textit` (links collapse to text);
      `plainLaTeX` strips emphasis for titles a class style already bolds. Only the FontAwesome icons already in
      the classes are used (none introduced). The `gapNote` never reaches the builder (it takes the per-document
      Markdown, matching Milestone G).
- [x] **Split fix.** Sections are headings at *exactly* the section level, so an H1 name lands in the preamble
      (not a spurious `\cvsection`) and H3 entries fall inside their section.
- [x] **Layout fidelity (revised after visual review).** The first pass rendered entries as loose
      `\entrytitlestyle`+`\par` lines in Markdown order — which didn't match the hand-authored résumé's
      spacing/ordering. Reworked to emit the **exact** awesome-cv structure: `\begin{cventries}` +
      `\cventry`/`\cvproject` (with dash-free `\cventrysolo`/`\cvprojectsolo` helpers injected for entries
      missing an org/role), the canonical **Education → Experience → Projects → Qualifications** order
      (`canonicalOrder`), the per-section `\vspace` tweaks (`-1em`/`-1.5em`/`-0.5em`, `sectionVSpace`), and
      `\renewcommand{\arraystretch}{0.7}` before `\begin{cvskills}`. Entry metadata is split from the app's own
      "Title — Org" / "Location · Date" shapes — the location/date splits on the **middot** (never the date
      range's dash). A "Summary" section renders as a lead paragraph. Verified by compiling a realistic résumé
      through the app's staging and comparing to the hand-built PDF — order, spacing, entry layout, and skills
      grid now match. (FontAwesome fonts were already byte-identical; the manual's per-entry link icons remain
      content-specific and out of scope.)
- [x] **Tests.** Pure unit tests (escaping, inline bold/italic + link, section split + reorder, per-section
      vspace, `cventries`/`cventry`/`cvproject`/`cvprojectsolo` shapes, `arraystretch`+`cvskills`, title vs
      location/date splitting, dropped contact line, summary-as-lead) — **and a real end-to-end
      `emittedTexCompilesUnderLualatex`** that compiles a realistic résumé + cover letter under the bundled
      classes to `%PDF` (guarded on `lualatex` availability). Full suite green.

Seam: `Infrastructure/Tex` (new, pure). On-device: yes — pure local string transform. Note: entry metadata
fidelity is best-effort (loose Markdown has no explicit org/date fields); C-structured is the upgrade path if
needed.

## Milestone D — Wire the awesome-cv PDF route through export + the Application sheet  ✅ done  (`Business/ExportApplicationUseCase`, `Presentation`: `Composition`, `ApplicationViewModel`, `ApplicationSheet`)

Goal: expose the LaTeX path to the user beside the existing exports. Because `DocumentExporter` is a
**synchronous** port and `lualatex` is an **async** external process, the LaTeX route rides its own async path
(the sync `RoutingDocumentExporter` is untouched — the recommended open-call resolution).

- [x] **Use case.** `ExportApplicationUseCase` gains an injected `compiler: (any LaTeXCompiling)?`,
      `isLaTeXAvailable`, a deterministic `texSource(_:_:)` (per-document `.tex`, no compile — works without a
      TeX install), and an async `latexPDF(_:_:)` (builds via `TexDocumentBuilder` → compiles via
      `LaTeXCompiling`; throws `notInstalled` when no compiler).
- [x] **Composition.** Wires `LaTeXProcessClient()` into the use case unconditionally; it self-reports
      availability so the UI only offers the route when `lualatex` is installed.
- [x] **ViewModel.** `canExportLaTeX` / `canExportLaTeX(_:)` (available **and** document present), async
      `exportLaTeXPDF(_:)` (sets `exportError` with the real `lualatex` log on failure; records the compiled
      résumé's real page count), `exportTexSource(_:)` + `texFilename(for:)`, a PDFKit `pdfPageCount` helper,
      and `latexResumeExceedsOnePage` (the real compiled count, distinct from the Core Text gate).
- [x] **Application sheet.** Each document submenu (Milestone G) gains **"PDF — Portfolio (LaTeX)"** (when
      available) and **"LaTeX source (.tex)"** (always — the PortfolioBuddy handoff); an "install a TeX
      distribution" note when `lualatex` is absent; a compile spinner; and a `latexNotices` banner surfacing
      the compile-error log + the résumé-overflow advisory. The `.tex` export uses a `tex` `UTType`.
- [x] **One-page gate.** For the LaTeX route the compiled PDF's **real** page count (PDFKit) drives the
      overflow advisory, not the Core Text estimate — resolved the open call to keep the résumé-only rule.
- [x] **Tests.** Use-case: `texSource` drivers, availability reflects the compiler, `latexPDF` throws without
      one / compiles the right source via a recording stub, **+ a guarded real end-to-end compile**. VM:
      availability × presence gating, PDF bytes + real page count, compile-error surfacing, `.tex` export works
      without TeX but respects presence, and `pdfPageCount`. Full suite green.

Seam: Business + Presentation. On-device: yes for the app logic; the compile needs the local TeX install.
**Device check (awaiting):** actually saving a "PDF — Portfolio (LaTeX)" / ".tex" file from the running app's
Export menu (the tests prove the compile + wiring; the file dialog is a manual step).

## Milestone E — Availability surfacing, docs, and release hygiene  ✅ done  (`Presentation`: `SettingsViewModel`, `SettingsView`, `Composition`; docs)

Goal: make the new `lualatex` dependency legible and bring the docs to a shipped state.

- [x] **Availability in Settings → About.** `SettingsViewModel` gains a `latexAvailable` flag (probed once in
      `Composition` via `LaTeXProcessClient().isAvailable`, per the composition-root convention); the About pane
      shows "LaTeX output: available" or an "install a TeX distribution (MacTeX)" hint.
- [x] **`CLAUDE.md`.** Documented `lualatex` as a **second optional external binary** (Build & run, beside the
      `claude` CLI, sharing `ProcessSupport.searchPATH`), added `Infrastructure/Process/` + `Infrastructure/Tex/`
      to the layer map, and described `lib/tex/` (the bundled awesome-cv assets as a blue folder reference).
- [x] **`SPEC.md`.** Noted the awesome-cv LaTeX PDF (+ `.tex` source) as a second export path in the core flow.
- [x] **`README.md`.** Added the v0.5.1 summary under Version history; the **Next:** line points forward
      without a number (per "never pre-name the next version").
- [x] **Release hygiene.** `MARKETING_VERSION` = `0.5.1` (4 copies, bumped at kickoff); About reads 0.5.1.

Seam: Presentation (a read-only availability display) + docs. On-device: n/a (a local availability read).

---

**v0.5.1 — LaTeX résumé & cover letter output is complete** (Milestones A–I). A: the awesome-cv presentation
assets ship in the bundle (`lib/tex/`). B: `LaTeXCompiling` + `LaTeXProcessClient` shell `lualatex`. C:
`TexDocumentBuilder` renders an `ApplicationKit` into `.tex` matching the hand-authored layout (order, spacing,
`cventries`/`cventry`/`cvproject`, `cvskills`). D: the async export route + "PDF — Portfolio (LaTeX)" / ".tex"
items in the Application-sheet menu. E: availability surfacing + docs. Plus the independent refinements — F
(Markdown `---` → real rule), G (résumé & cover letter as separate documents), H (Tracker sort), I
(additional-context box). `lualatex` is an optional external dependency (like the `claude` CLI); the native
exports are untouched. The project version is **0.5.1**. Carried device checks: v0.5.0's list, plus saving a
LaTeX PDF / `.tex` from the Export menu on a machine with TeX installed.

## Milestone F — Render Markdown thematic breaks (`---`) instead of printing them literally  ✅ done  (`Infrastructure`: `Text/MarkdownBlockParser`, `Export/MarkdownAttributedRenderer` + `Export/OOXMLDocument`; `Presentation`: `Components/MarkdownText`)

Goal: the generated résumé/cover-letter Markdown uses `---` as section separators, but every native renderer
printed the literal characters `---` on the page (visible in an exported PDF). Root cause: the shared
`MarkdownBlockParser.classify` had no thematic-break case — a `---` line isn't blank, isn't a heading, and
fails the bullet test — so it fell through to `.paragraph(text: "---")` and each renderer drew it verbatim.

- [x] **Parser.** Added `case thematicBreak` to `MarkdownBlock` and an `isThematicBreak(_:)` detector (3+ of
      a single `-`/`*`/`_`, spaces allowed between, whole-line), classified **before** the bullet rule so
      `- - -` / `***` aren't misread as bullets.
- [x] **PDF** (`MarkdownAttributedRenderer`): draws a subtle rule as an **underlined tab** filling the
      US-Letter text column (Core Text has no paragraph border) — never literal dashes.
- [x] **DOCX** (`OOXMLDocument`): emits an empty paragraph with a bottom border (`<w:pBdr>`), Word's standard
      horizontal rule.
- [x] **In-app preview** (`MarkdownText`): renders a SwiftUI `Divider()`. The new enum case is
      compiler-enforced across all three exhaustive switches.
- [x] **Tests.** Parser classification (`---`/`***`/`___`/`- - -`/spaced) + the misclassification traps (a
      real `- item` bullet, `--`, `-nospace`, `mix-of---dashes` stay correct); golden-string checks that the
      PDF renderer emits an underline rule (no `---` in the text) and the DOCX emits a border (no literal
      dashes). Full suite green.

On-device: yes — pure local rendering, no network, no model.

## Milestone G — Export the résumé and cover letter as separate documents  ✅ done  (`Business`: `ExportApplicationUseCase`; `Presentation`: `ApplicationViewModel`, `ApplicationSheet`)

Goal: export merged both deliverables into one file (`assembleMarkdown` joined `# Résumé` + `# Cover Letter`).
A résumé and a cover letter are separate deliverables — sent as two files, named differently, often only one
wanted — so export is now per-document. Also aligns the native path with the LaTeX path (A–E), which emits two
files.

- [x] **Use case.** New `ApplicationDocument` selector (`.resume` / `.coverLetter`, with `displayName` /
      `filenameSuffix`); `callAsFunction(_:_:as:template:)` exports one document (no combined wrapper
      heading), plus `markdown(for:from:)` / `isPresent(_:in:)`. The combined `assembleMarkdown` path is
      retained for the "copy everything" affordance.
- [x] **ViewModel.** Per-document `exportData(_:_:)` (guarded on presence so an empty section never exports
      an empty file), `canExport(_:)`, and `exportFilename(for:_:)` → `Company - Role - Résumé.pdf` /
      `… - Cover Letter.pdf`. `exportedText` still yields the combined document for clipboard.
- [x] **UI.** The `ApplicationSheet` export menu is now **Résumé** / **Cover Letter** submenus (each with
      PDF / Word / Markdown / Plain Text), showing only present documents; `startExport(_:_:)` carries the
      document and per-document filename.
- [x] **Tests.** Per-document assembly (résumé file has no cover-letter content and vice-versa; no wrapper
      heading), presence reflects empty sections, filename suffixes, and VM availability/filenames + the
      empty-document guard (which caught a real defect: it had been exporting empty bytes). Full suite green.

On-device: yes — pure local assembly + export, no network, no model.

## Milestone H — Sort control in the Tracker  ✅ done  (`Presentation`: `Tracker/View/TrackerSort` (new), `Tracker/ViewModel/TrackerViewModel`, `Tracker/View/TrackerView`)

Goal: the Results tab has a live `ResultsFilter`; the Tracker had a fixed load-time order and no interactive
control. Added an interactive **sort**, built the same way — a pure value the view holds and applies live over
each stage tab's rows.

- [x] **`TrackerSort`** (pure, `Equatable`/`Sendable`): a `Key` (recent activity / date applied / stage /
      match score / company / role title) + a `Direction`, with `apply(to:)` and `isDefault`. Dated keys keep
      **undated jobs last** in both directions; equal keys break ties on title for stable ordering. `.default`
      (recent activity, descending) reproduces the historic load order.
- [x] **ViewModel.** Holds `var sort` and applies it in `jobs(in:)`; the load-time `.sorted { … }` block is
      retired in favour of `TrackerSort.default` (rows are ordered on read, so the raw `trackedJobs` store is
      order-agnostic).
- [x] **View.** A compact sort bar above the list (key picker + direction toggle + a Reset that appears once
      off-default), mirroring the Results filter bar; shown only when there are rows.
- [x] **Tests.** New `TrackerSortTests` covers every key + direction (incl. undated-last, stage progression,
      case-insensitive company/title, `dateApplied` vs current-stage date, and title tie-breaking) and that
      `.default` reproduces most-recent-first; the existing `listsTrackedJobsMostRecentFirst` now asserts via
      `jobs(in:)`. Full suite green (434 tests).

On-device: yes — pure local sort, no network, no persistence, no model.

## Milestone I — Additional-context text box on the generate / regenerate flow  ✅ done  (`Data`: `GenerationSettings`, `LLM/Prompts`; `Business`: `GenerateToTargetUseCase`; `Presentation`: `ApplicationViewModel`, `ApplicationSheet`)

Goal: give the Application view a free-text box for **extra guidance to steer generation** ("lean into the
API-gateway angle for this role"), behaving like the Portfolio tab's "Regenerate description" prompt but
feeding the **application** generation. It rides the existing `settings:` thread — no new provider overload.

- [x] **`GenerationSettings.additionalContext`** — a `String` on the settings struct. **Excluded from
      `Codable`** (custom `CodingKeys`) so it's per-job and never captured into a reusable `GenerationPreset`,
      and so legacy preset blobs still decode; **included in `Equatable`**, so non-empty context makes
      `isDefault` false. A new `hasDefaultControls` (fidelity/aspect/target only, ignoring context) drives the
      prompt's controls block.
- [x] **`Prompts`.** New `additionalContextSection(_:)` appends an "ADDITIONAL USER GUIDANCE (steer emphasis
      and framing, NOT facts)" block when non-empty (bounded to `maxAdditionalContextCharacters`); empty
      context is byte-for-byte the base prompt. `generationControls` now guards on `hasDefaultControls`, so
      context-only generation adds the guidance without the fidelity/scope block.
- [x] **Threading.** Single-pass generation already carried it inside `settings`; the outcome-driven
      `GenerateToTargetUseCase` gained an `additionalContext` parameter folded into each round's settings, and
      `ApplicationViewModel.generate` passes `generationSettings.additionalContext` into that path.
- [x] **UI.** A multiline "Additional context (optional)" `TextField` in `ApplicationSheet`'s generation-options
      panel, bound to `generationSettings.additionalContext`, applied on Generate/Regenerate (no separate
      Submit). Stays enabled under a rank target (context steers both paths). Applying a preset clears the
      typed context (presets are about fidelity/aspects/target).
- [x] **Guardrail.** The guidance steers emphasis/framing only — the grounding + fidelity rules still bind, so
      at the default fidelity it can't introduce fabricated facts (SPEC "Grounded generation" / CLAUDE hard
      rules unchanged).
- [x] **Tests.** Prompt injection (present when set, byte-for-byte base when empty, no fidelity block for
      context-only, bounded); `GenerationSettings` (context counts against `isDefault` not `hasDefaultControls`,
      and is not persisted); the rank-target loop forwards context each round; and applying a preset clears the
      typed context. Full suite green.

On-device: yes — the field is prompt text; both engines honour it through the shared `Prompts`.

*(Open calls resolved as recommended: the field lives on `GenerationSettings` but is excluded from presets;
no separate Submit — it feeds the existing Generate/Regenerate.)*

---

# v0.6.0 — richer grounding, job detail & sources

The theme: give ranking and — especially — tailored résumé/cover-letter generation **more real signal to work
from**, and **more (and better-fed) sources to get it from**. Eleven milestones (**A–K**), several drawn from
`PLANNED.md`: A–C improve grounding — capture and surface much more of a job posting (Milestone A), choose a
profile to ground on (Milestone B), regenerate a saved result (Milestone C); D–F widen the pipe — user-editable
API credentials (Milestone D), full posting text (Milestone E), multi-source search (Milestone F); G–H build on
the credential seam — per-provider setup help (Milestone G) and a Search provider selector (Milestone H), both on
one data-driven provider registry; then supporting profile documents (Milestone I), an LLM job source
(Milestone J), and standardized result descriptions (Milestone K). **Transparency to the user** holds throughout —
enrichment *structures* what a posting says, and generated / LLM-sourced content is surfaced as such. Milestones
restart at **A**; commit as `v0.6.0 : Milestone X Completed`.

## Milestone A — Richer job postings (capture & surface full posting detail)  ✅ done

A search result used to keep very little about a job — `JobListing` was only `id/title/company/location/
description/url/salary`, and Adzuna's `description` is often a truncated snippet. Milestone A captures and
surfaces **much more** — job/work type, posted date, category, qualifications, responsibilities, about-the-role/
company, benefits — and feeds it into generation. Six sub-parts:

- [x] **A-A — Adzuna decode (no LLM).** `JobListing` gained `positionTypes: [PositionType]` + `postedDate: Date?`
      + `category: String?`, with a custom `init(from:)` that decodes-with-defaults so legacy `RankedJob` blobs
      still load (else `SavedJobsRepository` would silently drop the row). `AdzunaJobSource.Job` decodes
      `contract_type` / `contract_time` / `category` / `created` and maps them in `toDomain()` — both contract
      fields → the `PositionType` flag list, ISO-8601 `created` → `postedDate`, category label. *(Employment type
      is a list because Adzuna splits it across two orthogonal fields.)*
- [x] **A-B — Enrichment model + step.** New `WorkType` enum (`on_site`/`remote`/`hybrid`, lenient `init(loose:)`)
      and a `@Generable` `PostingDetails` (workTypeRaw + qualifications / responsibilities / niceToHaves /
      aboutRole / aboutCompany / benefits, with `workType`/`hasContent` accessors); `JobListing` gained
      `details: PostingDetails?`. The `enrichPosting(fromPostingText:)` step threaded through the whole seam —
      `LLMProvider` requirement + throwing default, both providers (FM constrained-decode / Claude JSON),
      `LLMRouter` (routed through `.extraction`), and `Prompts.enrichPosting` + `enrichInstructions` (extract-only,
      "never invent"). `WorkType` stays a plain enum mapped from a raw string so `PostingDetails` is all
      `String`/`[String]` and both engines produce it reliably.
- [x] **A-C — Full-page fetch feeding enrichment.** Extended `JobPostingSource` with `readableText(from:)`
      (default throws `.unreadable`; `LinkJobPostingSource` implements it by refactoring the fetch→decode→strip→
      min-length half of `fetchPosting` into a shared method — URL path behaviour unchanged). New Business
      `EnrichPostingUseCase` prefers the full posting page (when richer than the snippet) and **falls back to the
      description snippet** on any fetch failure / no url / no source; attaches `PostingDetails` only when
      `hasContent` (never overwrites with emptiness).
- [x] **A-D — Trigger + persist.** Enrichment-timing open call resolved as recommended: **enrich on save to
      Tracker**. `EnrichPostingUseCase` wired in `Composition` (over the shared `jobPostingSource`) and injected
      into `ResultsViewModel`; `saveToTracker` marks `.saved` + refreshes history first (the row drops out of
      Results immediately), then best-effort enriches and re-persists the `RankedJob`. Persistence needed **no
      repository change** — `details` rides along in the `RankedJob` JSON, and A-B's decode-with-default keeps
      legacy jobs loading (`details == nil`).
- [x] **A-E — Into generation (the payoff).** No seam change: `buildTargetBrief(for job:)` already receives the
      full `JobListing`, which carries `details` — so the richer signal reaches **stage 1** and stage 2 tailors
      against the fuller brief (two-stage discipline preserved). `Prompts.postingDetailSection` renders only the
      non-empty enriched fields into the brief prompt; absent/empty details return "" so the un-enriched path is
      byte-for-byte the pre-A-E prompt. `GenerateApplicationUseCase` / `GenerateToTargetUseCase` benefit
      automatically.
- [x] **A-F — Surface in the UI.** Pure, SwiftUI-free `PostingMetaBadge.badges(for:)` derives at-a-glance chips
      (work type, employment type(s), posted date, category). `JobDetailView` shows the chips near the top plus a
      collapsible "Posting details" section (About the role / company + Qualifications / Responsibilities /
      Nice-to-have / Benefits via `ExpandableRow`); `RankedRow` shows compact work/employment chips (so enriched
      jobs read richer in the Tracker list). All gated on presence — un-enriched rows/detail look exactly as
      before.

**Guardrail.** Enrichment extracts and organizes what the posting states — it never invents requirements or
company facts (same discipline as `ExtractedPosting`), and it's signal about the *role*, never about the
candidate, so the never-fabricate rule on the résumé is untouched.

**Tests.** Adzuna decode + legacy-blob decode; `PostingDetails`/`WorkType` round-trip + loose-parse + empty;
`enrichPosting` provider decode + router routing + prompt fields/bounds/guardrail; `readableText` +
`EnrichPostingUseCase` full-page/snippet/empty paths; enrich-on-save persists + reflects; brief prompt
injects/omits detail; `PostingMetaBadge` derivation + relative posted text. Full suite green.

**On-device.** Adzuna decode is pure/local; enrichment is `.extraction` LLM work (on-device-friendly; Claude
when chosen); the optional full-page fetch needs network. Posting text is bounded before extraction.

*(Open calls resolved as recommended: enrich **on save**; `JobListing` optionals for Adzuna fields **plus** a
separate `@Generable` `PostingDetails` for the LLM structure.)*

## Milestone B — Select a profile at generation time and ground on its source documents  ✅ done

Grounding was tied to the single loaded/default profile (`PortfolioViewModel.grounding` → `AppSession.grounding`
→ `ApplicationWindow` → `ApplicationSheet`), with a silent fall-back to profile-summary-only when grounding
wasn't set up. Milestone B adds an **explicit per-generation profile picker** and grounds on the chosen
profile's real source documents.

- [x] **Grounding mapper (Data).** New `SavedProfile.grounding` (an extension mirroring
      `PortfolioViewModel.grounding`) yields any saved profile's `PortfolioGrounding` — `readableText ??
      sourceText` as factual grounding + the tidied cover letter as a voice exemplar — or `nil` for a legacy
      profile with no source document (→ profile-only). Each `SavedProfile` also carries its `CandidateProfile`,
      so a selection supplies **both** `profile:` and `grounding:`.
- [x] **Picker + wiring (Presentation).** `ApplicationViewModel` gained `loadProfiles` (injected via
      `Composition.makeApplicationViewModel`), a `savedProfiles` list, a session-only `selectedProfileID`,
      `canPickProfile`, `loadSavedProfiles()`, and a pure `resolvedTarget(fallbackProfile:fallbackGrounding:)`
      that returns the **picked** saved profile + its grounding, or the ambient fallback when "Current profile"
      is selected / the pick is gone. `ApplicationSheet`'s "Generation options" panel shows a **Profile** picker
      (default **Current profile** → byte-for-byte the old behaviour, hidden when there are no saved profiles);
      `runGeneration` resolves the target before calling `generate`.
- [x] **Prompt depth.** The curation prompt already receives `resumeText` and compares it against the full job
      result (now richer via Milestone A). The résumé/cover-letter grounding stays bounded in `Prompts`
      (`maxPortfolioCharacters` / `maxCoverLetterCharacters`) — adequate for a typical résumé; larger bounds
      would risk the on-device context window, so left unchanged.

**Guardrail.** Grounding on the source documents strengthens factual fidelity without loosening never-fabricate:
the résumé source grounds facts; the cover-letter source stays a voice/tone exemplar only.

**Tests.** `SavedProfile.grounding` (prefers tidied text, raw fallback, carries/omits cover letter, nil without
a résumé); `ApplicationViewModel` (loads profiles + offers the picker; `resolvedTarget` defaults to ambient,
uses the picked profile + its grounding, and falls back safely when the pick is gone). Full suite green.

**On-device.** Yes — profile load + grounding are local; generation runs on the chosen engine.

*(Open calls resolved as recommended: **session-only** selection defaulting to Current; picker in the
**options panel**; **saved profiles only** — a just-built unsaved profile appears after Save.)*

## Milestone C — Regenerate result (re-rank & re-enrich a saved job against a chosen profile)  ✅ done

Mirrors the regenerate-application flow with a **"Regenerate result"** action on a saved job: re-run the fit
assessment (and, where enrichment is wired, backfill the posting detail) against a **chosen profile**, with an
optional steering context. The motivating case is **legacy entries** ranked against an older profile and
lacking the richer posting fields.

- [x] **C-A — Single-job re-rank seam (Data/LLM).** New `LLMProvider.rank(job:against:instruction:)` returning
      one `JobMatch`, with a forwarding default that reuses the batch `rank` (ignoring the instruction) so stubs
      are unchanged; real engines (FM constrained-decode / Claude JSON) and `LLMRouter` (routed `.ranking`)
      override it. `Prompts.rankOne` asks for a single match, carries the enriched posting detail (A-E), and
      appends the user's guidance via `rankGuidanceSection` (empty ⇒ plain assessment; steers *how to weigh*
      fit, never permission to credit absent skills).
- [x] **C-B — `RegenerateResultUseCase` (Business).** Best-effort re-enriches the listing (via the optional
      `EnrichPostingUseCase` — backfills legacy postings; no-ops if already enriched), re-ranks the single job
      against the chosen profile honouring the instruction, and persists the refreshed `RankedJob` latest-wins
      via `SaveResultsUseCase` (`SavedJobsRepository` upsert). A re-enrich failure is swallowed; a re-rank
      failure propagates.
- [x] **C-C — "Regenerate result" action (Presentation).** `JobDetailView` gained a compact re-rank control in
      the match section: an optional **profile picker** (default "Current profile" — the ambient one; reuses
      Milestone B's pattern) + a steering **context** box + the button, with a spinner and error line. A
      re-ranked result is held in `displayRanked` and shown in place (score / reason / skills / detail update
      live via a new `shown` accessor), and `onMutate` refreshes the main-window lists. Wired through
      `Composition.regenerateResult` / `loadProfiles` → `JobDetailWindow` → `JobDetailView`.

**Guardrail.** Re-ranking re-assesses fit **honestly** (the score may rise *or* fall); enrichment structures
what the posting says; the context steers emphasis/interpretation, never fabrication.

**Tests.** `Prompts.rankOne` (asks for one match, carries detail + guidance, omits guidance when blank);
`ClaudeCodeProvider.rank(job:instruction:)` decode + guidance in the prompt; router routes the single-job
re-rank; `RegenerateResultUseCase` re-ranks with the instruction + persists latest-wins, and re-enriches when
wired. Full suite green.

**On-device.** Yes — re-rank + enrich run on the chosen engine; persistence is local.

*(Open calls resolved as recommended: re-rank always + re-enrich when wired; **per-result** (not bulk);
latest-wins **overwrite**.)*

## Milestone D — User-editable API credentials (move keys from build-time secrets into in-app Settings)  ✅ done

Adzuna's `app_id` / `app_key` were baked in at build time (`Secrets.xcconfig` → Info.plist → `BundleAppConfig`
→ `AppConfig`), so only a build with the secret file could search and there was no in-app fix. Milestone D makes
credentials **user-entered** into a keychain-backed store, with the build-time keys kept as an optional fallback
so dev/CI builds keep working. Four sub-parts:

- [x] **D-A — `KeychainStore: KeyValueStore` (Infrastructure/Store).** Generic-password items namespaced by
      `service`, on the **legacy (file-based)** keychain so the unsandboxed target needs no keychain-access-group
      entitlement (the data-protection keychain would return `errSecMissingEntitlement`). The non-throwing
      `KeyValueStore` surface sits over a throwing `readData`/`writeData`/`clear` API that surfaces `OSStatus`
      (`KeychainError`, with `isEnvironmentUnavailable` so round-trip tests skip on CI without entitlements).
      `clear()` loops `SecItemDelete` until `errSecItemNotFound` — the legacy keychain deletes only one match per
      call, so a single delete left a multi-item service partly populated (caught by a full-suite-only test flake).
- [x] **D-B — `JobSourceCredentialsStore` (Data/Settings).** Provider-keyed: `JobProvider` (`.adzuna`, extensible
      for F) + `JobCredentialField` (namespaced `storageKey`, e.g. `adzuna.appID`). `value(for:)` resolves
      **user-entered (keychain) → build-time `AppConfig` → nil**, treating blank/whitespace as absent at *both*
      sources; `setValue` clears the entry for a blank value (revert to fallback, keeps the keychain clean);
      `hasCredentials(for:)` generalises `AppConfig.hasAdzunaCredentials` to "resolved from either source";
      `hasStoredValue`/`hasStoredCredentials` expose user-entry-only (gates the Clear affordance).
- [x] **D-C — Rewire the composition root.** `Composition` owns a `JobSourceCredentialsStore(store:
      KeychainStore(), config: appConfig)`; `SettingsBackedJobSource` resolves `appID`/`appKey` via
      `credentials.value(for:)` live on each search (was reading `config` directly); `isAdzunaConfigured` is now
      `credentialsStore.hasCredentials(for: .adzuna)` (feeds the Search/Settings VMs + the DEBUG console hint,
      reworded to cover both sources).
- [x] **D-D — Settings UI + live refresh.** `SettingsView`'s Adzuna section shows each credential field as an
      editable `SecureField` until it's saved, then as an **immutable, greyed masked indicator** (dots, never the
      real value) — a per-field `appIDSaved`/`appKeySaved` state drives the lock; **Clear saved credentials**
      unlocks them again. Plus a live **Status** (Configured / Not) and a **"How to get an Adzuna API key"** link
      (a single-provider down-payment on the `PLANNED` per-provider help entry). `SettingsViewModel` gained edit
      buffers + `save()` (persists non-blank buffers, clears the input buffers + **locks** the saved fields,
      **re-resolves** `adzunaConfigured`; a blank field leaves the saved value untouched) + `clearAdzunaCredentials()`
      (unlocks + reverts). `adzunaConfigured` became a `private(set) var`; `RootView`
      observes it and pushes changes to `SearchViewModel.adzunaConfigured` (now a `var`) so the Search banner +
      Generate gate refresh **without a relaunch** — closing the snapshot-staleness gap D-C surfaced. Flipped the
      two "secrets are build-time" doc comments (`AppSettings`, `AppConfig`).

**Guardrail (safety).** The app builds the credential *fields*; the **user** enters their own keys — the agent
never types or pastes real API keys.

**Storage note (post-D fix).** The credentials store is wired to **`UserDefaults`**, not `KeychainStore`: this
unsandboxed app is **ad-hoc-signed in dev**, so the legacy keychain re-prompts for access on every rebuild (the
signature changes each build, so "Always Allow" never sticks) — it popped a keychain dialog on every launch.
The keys are low-value Adzuna free-tier credentials (previously baked into the bundle), so local app preferences
are an acceptable home for a personal build. `KeychainStore` (D-A) stays available behind the same `KeyValueStore`
port for a future stably-signed / distributed build — swap it back in `Composition` once real signing is set up.

**Tests.** `KeychainStore` round-trip / missing-key / nil-removes / update-in-place / service isolation / port
surface / service-wide clear / error classification (8, guarded for keychain-less hosts);
`JobSourceCredentialsStore` resolution order / clear-reverts / blank-as-absent (both sources) / mixed
user+build-time / stored-only checks (16); `SettingsViewModel` seed-from-store / enter+persist+re-resolve /
blank-leaves-unchanged / clear-reverts-to-fallback / clear-without-fallback / no-store no-ops (6). Full suite green.

**On-device.** n/a — local Keychain/UserDefaults storage, no model or network.

*(Open calls resolved as recommended: **pure fallback**, no keychain seeding; **Keychain** for the secrets;
**save-and-see** validation; **per-provider** Settings section.)*

## Milestone E — Full job-posting text (capture the whole posting, not Adzuna's truncated snippet)  ✅ done

Adzuna's `/search` `description` is truncated (~500 chars, ends in `…`); the full body isn't in the API
response, so no decode recovers it. Milestone E recovers it from the posting page and grounds/display on it.
Because Milestone A's enrichment already fetches that page, E rides the **same fetch** — one network call
captures both the raw full text and the structured detail.

- [x] **E-A — `JobListing.fullDescription` + `effectiveDescription`.** New optional `fullDescription: String?`
      (the recovered full body; the snippet in `description` is never overwritten — both are kept), with
      decode-with-default back-compat (legacy blobs decode `nil`). A computed `effectiveDescription`
      (`fullDescription ?? description`) is the single accessor ranking, brief-building, and the detail view read.
- [x] **E-B — Capture + de-chrome in `EnrichPostingUseCase`.** The full posting page (fetched via
      `JobPostingSource.readableText` when richer than the snippet) is raw site text — navigation, "similar
      jobs", footer, country lists — so storing it verbatim looked terrible. A new **`cleanPostingText`** LLM
      step (`LLMProvider` + throwing default + both engines + `LLMRouter` `.extraction` + `Prompts.cleanPosting`
      / `cleanPostingInstructions`) extracts **just the posting, verbatim, as clean markdown**, and that is what
      lands on `fullDescription`, then the structuring pass runs on the clean text. Every step is best-effort:
      an unfetchable page falls back to the snippet with no `fullDescription`; if cleaning is unavailable /
      fails / finds no posting the **noisy raw page is not stored** (the snippet stands) though structuring
      still runs on the raw page (its prompt already ignores chrome); and a structuring failure keeps the
      cleaned text. `.details` is still only set when `hasContent`. Guardrail: cleaning **removes chrome and
      preserves the posting verbatim** — it never summarizes or invents.
      - **Fix (composition forwarding).** Building this surfaced a latent bug: `SettingsBackedLLMProvider`
        (`Composition`) — the runtime `LLMProvider` that forwards to the `LLMRouter` — was **missing forwards
        for `enrichPosting` and the single-job `rank(job:against:instruction:)`**, so in the real app those hit
        the throwing / batch-fallback defaults instead of a real engine (Milestone A enrichment silently
        no-op'd; Milestone C re-rank ignored its steering instruction). Added the missing forwards **plus**
        `cleanPostingText`, so all three now reach the router/engine.
- [x] **E-C — Persist (free).** `fullDescription` rides the `RankedJob` JSON like `details` — no repository
      change. `ResultsViewModel.saveToTracker`'s enrich-on-save now persists whenever the listing changed
      (`listing != job.listing`), so a job whose full text was captured but that structured nothing is still
      saved; the "already captured" guard skips jobs that already have full text or details.
- [x] **E-D — Into generation + display.** `Prompts` (batch rank / single-job re-rank / `buildTargetBrief`) read
      `job.effectiveDescription` — at search-time ranking that equals the snippet (nothing fetched yet), and
      after capture the brief and the Milestone-C re-rank ground on the full posting. `JobDetailView`'s
      Description section shows `effectiveDescription`.

**Guardrail.** The full text is captured **verbatim**; structuring only organizes it (Milestone A's discipline),
never inventing requirements or company facts.

**Tests.** `JobListing` full-description round-trip + legacy-blob decode + `effectiveDescription` preference;
`EnrichPostingUseCase` captures the full page and **keeps it when structuring is empty or throws**;
`buildTargetBrief` grounds on the full text over the snippet; `ResultsViewModel` save persists `fullDescription`.
Full suite green; build warning-free.

**On-device.** The page fetch needs network (same seam as the "generate from a link" path); storage + display
are local. Posting text is bounded before it reaches the model, as elsewhere.

*(Open calls resolved as recommended: **add** `fullDescription` (keep the snippet); **capture on save** via the
existing enrichment fetch; **store** it — no re-fetch.)*

## Milestone F — Multi-source job search (aggregate more providers behind `JobSource`)  ✅ done

Searches sometimes hit **Adzuna's index ceiling** for a query; the fix is **more sources**, not more tuning.
Milestone F aggregates providers behind one `JobSource`, so the fan-out over *providers* sits below the seam and
`SearchAndRankUseCase` (which fans out over *titles*) is unchanged.

- [x] **F-A — `CompositeJobSource`.** New `CompositeJobSource: JobSource` holds `[any JobSource]`, fans out with
      **bounded concurrency** (mirrors `SearchAndRankUseCase.searchAll`'s windowed task group) and merges.
      Partial failure is **soft** (skip a throwing provider); it throws only when **every** provider fails;
      empty sources → `[]`.
- [x] **F-B — `JobListing.fingerprint` + `source`.** `JobListing.id` is source-specific, so the composite
      dedups on a normalized **fingerprint** (lowercased title + company + location, collapsed whitespace),
      keeping the **first** occurrence in source order while preserving each listing's own `id` for persistence.
      Added an optional `source` label ("Adzuna" / "JSearch"), captured for future display (Codable back-compat).
- [x] **F-C — `JSearchJobSource` (RapidAPI).** New provider gateway (private wire types, the Adzuna pattern):
      folds keywords + location into JSearch's free-text `query`, maps `PositionType` → `employment_types`, sends
      the RapidAPI key/host as **headers**, and maps the rich response → `JobListing` **including the Milestone
      A/E fields** — full description, `PostingDetails` from `job_highlights` (qualifications / responsibilities
      / benefits + `is_remote`→workType), employment type, salary, posted date — so a JSearch result arrives
      **already-enriched** (no page-fetch / LLM pass needed downstream).
- [x] **F-D — Wiring + credentials + Settings.** `SettingsBackedJobSource` (`Composition`) now assembles every
      **configured** provider — Adzuna (id/key) and JSearch (key), resolved from the Milestone-D credentials
      store — into a `CompositeJobSource`; a provider with no resolved key is omitted (fail-soft). `JobProvider`
      gained `.jsearch` (+ `JobCredentialField.jsearchAPIKey`); the Settings **"Sources"** pane (renamed from
      "Adzuna") adds an **optional JSearch (RapidAPI) key** field with the same save / lock / mask / clear
      machinery, a "How to get a key" link, and a free-tier-limit note.

**Guardrail (safety).** The app builds the credential *field*; the **user** enters the RapidAPI key — the agent
never types or pastes it.

**Deferred (composes with the `PLANNED` "provider selector" / "credential-setup-help" entries).** Search
**availability still gates on Adzuna**, so a JSearch-**only** setup (no Adzuna) would show the "unavailable"
banner — generalize the gate to "any configured provider" when the provider-selection UI lands. (Adzuna +
optional JSearch — the common case — works today.)

**Tests.** `CompositeJobSource` fan-out / fingerprint dedup (case + whitespace) / soft-vs-total failure;
`JobListing` fingerprint + source round-trip; JSearch URL building + RapidAPI headers + fixture mapping (A/E
fields) + no-highlights→nil-details; `JobProvider.jsearch` resolution; `SettingsViewModel` JSearch
save/lock/clear + provider independence. Full suite green; build warning-free.

**On-device.** Search needs network; the composite + dedup are pure/local. *(Open calls resolved as recommended:
**JSearch only** first (The Muse / remote feeds later); **no** per-provider balancing; **capture** source, defer
display; bounded concurrency + the existing page cap for the metered RapidAPI tier.)*

## Milestone G — Per-provider credential-setup help (built on H-A's provider registry)  ✅ done

With API keys now user-entered (Milestone D), each provider's `SecureField` needed a **"How to get a key"** link;
D-D shipped a hardcoded Adzuna link. G generalises it so **every** provider draws its help from **one source of
truth** — which meant first standing up the **provider registry** the plan calls for (Milestone **H-A**, built
here as G's foundation).

- [x] **H-A — provider registry (the enumerable source of truth).** New `JobProviderDescriptor` +
      `JobProviderRegistry.all` (`Data/Jobs`): per provider — `provider`, `displayName`, `credentialFields`
      (field + UI label), `setupURL` + `setupSteps`, and a `makeSource` factory that builds the provider's
      `JobSource` from resolved credentials (or nil when a key is missing). The composition root's
      `SettingsBackedJobSource` (F) now builds the `CompositeJobSource` by mapping the registry — **no provider is
      hand-enumerated** in the composition root or any view. Adding a provider = appending one descriptor.
- [x] **G-A — `setupURL` / `setupSteps` on the descriptor.** Static, known developer pages (Adzuna dev portal,
      RapidAPI's JSearch listing) — not derived from any posting.
- [x] **G-B — Settings help driven by the registry.** `SettingsView`'s "Sources" pane now **iterates
      `JobProviderRegistry.all`**, rendering one credential Section per provider with a descriptor-driven
      `Link("How to get a key")` + a collapsible **Setup steps** disclosure — the hardcoded Adzuna/JSearch
      sections and URL literals are gone. `SettingsViewModel` was refactored from hand-named buffers
      (`adzunaAppID`…) to **field-keyed** state (`credentialBuffer(for:)` / `isCredentialSaved(_:)` /
      `hasStoredCredentials(_:)` / `clearCredentials(_:)`), all driven off the registry — so a new provider needs
      **zero** view/VM changes. Save / lock-and-mask / clear behaviour (D-D) is preserved per field.
- [x] **G-C — Populated for Adzuna + JSearch;** URLs verified as live developer pages.

**Guardrail (safety).** Links point only to official provider signup pages (static registry metadata) — the app
never creates accounts or enters keys; the user pastes their own.

**Tests.** Registry: every provider exposes an https `setupURL` + credential fields, covers every `JobProvider`,
and `makeSource` builds only when its credentials resolve. `SettingsViewModel`: the field-keyed save / lock /
clear works per provider and providers stay independent. Full suite green; build warning-free.

**On-device.** n/a — static metadata + a browser `Link`. *(Open calls resolved as recommended: ship the `Link`
first — inline steps added too, as a collapsible disclosure; per-provider inline, closest to the field.)*

## Milestone H — Provider selector in the Search view  ✅ done

F queries *every* configured provider; H lets the user **pick which to search**, from a selector that lists all
registered providers and **grows automatically** (H-A's registry — which shipped with Milestone G).

- [x] **H-B — `JobSearchRequest.sources` / `JobQuery.sources`.** Optional `[String]?` (nil ⇒ all), `Codable` —
      the optional decodes-with-default so **pre-H `SavedSearch`es stay valid**; `JobSearchRequest.query(forTitle:)`
      threads it into each `JobQuery`.
- [x] **H-C — `CompositeJobSource` honours the selection.** The composite now holds **labeled** providers
      (`Provider{id, source}`); `search` filters to the query's `sources` (nil/empty ⇒ all) before fanning out.
      The composition root builds it from the registry, labeling each by provider id. `SearchAndRankUseCase` is
      **unchanged** — it just passes the request's `sources` through the query.
- [x] **H-D — Search-view selector.** `SearchViewModel` gained `selectedProviderIDs` + `providers` (the registry)
      + `isProviderSelected`/`isProviderConfigured`/`setProvider`; `SearchView` shows a **checkbox per provider**
      (disabled + "add a key in Settings → Sources" when unconfigured). `buildRequest` carries the selection; a
      saved search restores it (nil ⇒ all).
- [x] **H-E — Availability gate generalised.** Replaced `adzunaConfigured` with `configuredProviderIDs` (pushed
      from Settings: `SettingsViewModel.configuredProviderIDs` → `RootView` → Search) and an
      `activeProviderIDs = selected ∩ configured` gate; `canSearch` / the unavailable banner / `search()` /
      `runSavedSearch` all use it. **This also fixes F's deferred JSearch-only case** — a setup with only a
      JSearch key can now search.

**Tests.** `JobSearchRequest.sources` round-trip + legacy-nil + threads into the query; `CompositeJobSource`
runs only the selected providers (nil/empty ⇒ all); `SearchViewModel` gate (≥1 selected-and-configured) +
`buildRequest` carries the selection; `SettingsViewModel.configuredProviderIDs` updates after save. Full suite
green; build warning-free.

**On-device.** Search needs network; the registry + selection state are pure/local. *(Open calls resolved as
recommended: **multi-select**, default all; **persist** the selection in `SavedSearch` (re-runs against the
providers it was saved with; legacy nil ⇒ all); a selected provider that loses its key just isn't in
`configured` (skipped); source labels **deferred** to F's `JobListing.source`.)*

## Milestone I — Supporting profile documents  ✅ done  (`Data/Models` + `Business` + `Data/LLM` + `Presentation/Portfolio`)

A `SavedProfile` carried only the **résumé source** (distilled into the profile *and* used as factual grounding)
and an **optional cover letter** (a voice/tone exemplar, never distilled). Milestone I lets a profile attach
**additional supporting documents** — e.g. a complete career portfolio — **baked into the profile** as **factual**
grounding, so both **ranking/search** and **application generation** draw on far more real signal. Unlike the
cover letter, their content *may* be used (like the résumé). This generalises the existing résumé/cover-letter
doc handling — no new generation seam; it rides Milestone B's existing grounding thread.

- [x] **I-A — `SupportingDocument` model + `SavedProfile.supportingDocuments`.** New
      [`SupportingDocument`](../src/Data/Models/SupportingDocument.swift) (`{ id, fileName?, rawText, readableText }`
      + an `effectiveText` accessor, mirroring the résumé/cover-letter triple; `nonisolated`, `Codable`,
      `Sendable`). Added `supportingDocuments: [SupportingDocument]` to
      [`SavedProfile`](../src/Data/Models/SavedProfile.swift) with a **decode-with-defaults** `init(from:)`
      (`decodeIfPresent … ?? []`) so pre-I profiles still load, and threaded it through
      [`SaveProfileUseCase`](../src/Business/UseCases/SaveProfileUseCase.swift) (new `supportingDocuments:` param,
      default `[]`).
- [x] **I-B — `PortfolioViewModel` multi-file import/remove + tidy + store.** New `supportingDocuments` state +
      `importSupportingDocument(from:)` (reuses `ImportPortfolioUseCase`, appends one per file) / `removeSupportingDocument(_:)`;
      `build()` tidies each (`TidyDocumentUseCase`, best-effort → raw fallback); `select`/`deselect`/`saveProfile`
      load/clear/persist them. Never gates Build.
- [x] **I-C — `PortfolioGrounding.supportingText` (bounded) threaded through `Prompts`.** Added
      `supportingText: String?` to [`PortfolioGrounding`](../src/Data/Models/PortfolioGrounding.swift); a shared
      `SavedProfile.joinedSupportingText(_:)` concatenates each doc's `effectiveText` (readable-preferred), fed into
      **both** grounding mappers (`SavedProfile.grounding` + `PortfolioViewModel.grounding`). `Prompts.groundingSection`
      injects it as an **additional factual-grounding** block (after the résumé), bounded by a new
      `maxSupportingCharacters` (8 000). Absent ⇒ byte-for-byte unchanged.
- [x] **I-D — Distil supporting docs into the `CandidateProfile` at build.** `build()` now passes the résumé
      **plus** the joined supporting text to `buildProfile` (résumé leading, so `Prompts.buildProfile`'s cap
      preserves it) — so ranking benefits with **no per-rank cost** (recommended path), while raw grounding still
      flows to generation.
- [x] **I-E — Portfolio UI: supporting-docs slot (add/remove/browse).** The **Profile** tab gained a
      multi-file **Supporting documents (optional)** slot (Add file… + per-file remove list) beside the source +
      cover-letter slots ([`PortfolioView`](../src/Presentation/Portfolio/View/PortfolioView.swift)); **Source
      Documents** lists each profile's supporting docs (readable form) under its disclosure.

**Tests.** `SavedProfile` round-trips with supporting docs + decodes legacy blobs (no `supportingDocuments`) as
empty; `grounding` concatenates their text (readable-preferred) and is nil when none usable; `Prompts` injects the
supporting block as factual grounding, omits it cleanly when absent, and bounds it; `PortfolioViewModel`
import/remove, build-tidy, grounding inclusion, save/select/deselect round-trip, and — via a recording provider —
that **both** the résumé and the supporting text reach `buildProfile` (résumé first). Full suite green; build
warning-free.

**On-device.** Import + tidy are `.profile`-task LLM work (on-device-friendly; Claude when chosen), all injected
text bounded. *(Open calls resolved as recommended: **distil + ground** (both channels); **bound** the injected
text as a first cut (RAG follow-on remains a Backlog item); **no per-doc "kind" tag** for now.)* Guardrail: factual
grounding about the candidate — the transparency rule still binds (nothing beyond these real documents + the
profile).

## Milestone J — LLM job source (find jobs from your résumé, no API required)  ✅ done  (`Data/LLM` + `Data/Jobs` + `Data/Settings` + `Presentation`)

Search needed an API key (Adzuna / JSearch). Milestone J wires an **LLM-backed `JobSource`** in as a first-class
source — the "paste your résumé and it finds jobs" flow — so search works with **no API keys**, spanning both the
**engines menu** (its own task) and the **Sources / provider selector** (its own source). The one hard rule is
**transparency**: results are **AI-suggested leads**, labelled as such and never presented as verified live
postings.

- [x] **J-A — `LLMTask.jobSearch`.** New task (+ displayName "AI job search" / detail). Since Settings iterates
      `LLMTask.allCases` and `AppSettings.defaultEngines` seeds from it, the task **auto-appears** in the engines
      menu with its own `TaskEngineConfig` — no view change, no migration (`config(for:)` defaults it).
- [x] **J-B — `searchJobs` seam.** New `GeneratedJobLead`/`GeneratedJobLeads` (`@Generable`+`Codable`, **no URL**
      field by design). `LLMProvider.searchJobs(query:grounding:)` with a **forwarding default `[]`**; implemented
      in `FoundationModelsProvider` (constrained decode) + `ClaudeCodeProvider` (JSON), routed through `.jobSearch`
      in `LLMRouter`, and **forwarded in `SettingsBackedLLMProvider`** (Composition). `Prompts.searchJobs` grounds
      on the profile/résumé + query with an explicit *"prefer real, plausibly-current roles; return fewer if unsure;
      do NOT invent application links"* (bounded).
- [x] **J-C — `JobProvider.llm` + `LLMJobSource`.** `JobProvider.llm` has **`requiredCredentials: []`** (no key).
      [`LLMJobSource`](../src/Data/Jobs/LLMJobSource.swift) calls `searchJobs` (grounding read via an **async
      closure**, since the source sits below the profile seam) and maps each lead → `JobListing` tagged
      `JobListing.aiSource`, with a **deterministic id** (`ai:…`, so re-runs dedup + persist stably) and a
      **web-search URL** (Google query — never a model-produced posting link).
- [x] **J-D — Registered in `JobProviderRegistry`.** Descriptor gained a **`kind`** (`.credentialed` / `.llm`) and
      an **optional `setupURL`**; `.llm` (kind `.llm`, no credential fields, nil setupURL) is appended to `all`.
      `SettingsBackedJobSource` special-cases `kind == .llm` to build `LLMJobSource` from the engine + a
      default-profile grounding closure; credentialed providers still build from resolved keys. Registry order puts
      `.llm` **last**, so a real API posting wins over an AI dupe on `fingerprint`.
- [x] **J-E — Engine-based availability.** For `.llm`, "configured / available" means the **engine** is available
      (on-device ready, or `claude` on PATH) — not credentials. `Composition.isLLMJobSearchAvailable` drives its
      inclusion in `configuredProviderIDs`; `SettingsViewModel(llmSourceAvailable:)` mirrors it in `isConfigured`;
      the Settings Sources section renders no key fields + no sign-up link for it; the Search selector's disabled
      hint points to **Engines**, not a key.
- [x] **J-F — AI-suggested labelling.** `JobListing.isAISuggested` drives an **AI-suggested chip** on `RankedRow`,
      a prominent **"AI-suggested lead — not a verified posting; confirm before applying"** banner in
      `JobDetailView`, and relabels the footer link to **"Search for this role"** (its URL is a search query).

**Tests.** `LLMJobSource` maps a stubbed `searchJobs` response → `JobListing`s tagged AI with a Google **search**
URL + deterministic id; the grounding closure is passed through; an AI lead **dedups against an API listing by
fingerprint** (API kept); the `.llm` descriptor is keyless (no fields, nil setupURL); `SettingsViewModel`'s
`.llm` status/`configuredProviderIDs` are **engine-based, not credential-based**; `Prompts.searchJobs` carries the
query + grounding + verify/never-invent-URL guidance and is bounded. Full suite green; build warning-free.

**On-device.** `.jobSearch` runs on-device (or Claude when chosen) — **no API key**; a web-search-capable engine
needs network. **Transparency (the one hard rule):** leads are **AI-suggested**, labelled, never shown as verified
postings, and linked to a **search query** rather than a fabricated posting URL. *(Open calls resolved as
recommended: **search-query URL** (never a fake posting link); leads are model-knowledge so the labelling carries
the weight; **capped** at `Prompts.maxJobLeads` (8) and **deduped** against API results by `fingerprint`.)*

## Milestone K — Standardized result descriptions (digest every posting into one format)  ✅ done  (`Data/Models` + `Business` + `Presentation`)

Descriptions were inconsistent (Adzuna's ~500-char snippet vs. JSearch full text vs. a page-fetch) and enrichment
ran **only on save-to-Tracker**. Milestone K **digests every search result** into the uniform
[`PostingDetails`](../src/Data/Models/PostingDetails.swift) and renders a **standardized description** from it, so
every result reads the same regardless of source and generation always grounds on one structure — done
**progressively** so results still appear immediately.

- [x] **K-A / K-E — digest in the search pipeline (bounded + cached).** `SearchAndRankUseCase` gains an optional
      injected `EnrichPostingUseCase` + a `digestStream(_:)` that **streams** each digested `RankedJob` as it
      completes, with **bounded concurrency** (reusing the search window), a **cache** (a job already carrying
      `details` is skipped), and a soft **fallback** (a digest that fails or changes nothing isn't yielded — the row
      keeps its raw description). `callAsFunction` stays fast (returns ranked rows un-digested); digestion is a
      separate, streamed step. Wired in `Composition`.
- [x] **K-B — always structure from best-available text.** The existing `EnrichPostingUseCase` already runs
      `enrichPosting` on the best available text (full page → cleaned → snippet) for **every** listing regardless of
      source, so "always digest, even already-full JSearch text" needed no gating change; the pipeline (K-A) simply
      runs it on **all** results now, not just save-to-Tracker.
- [x] **K-C — `PostingDetails.standardDescription` (pure).** A deterministic fixed-template markdown renderer —
      About the role → Responsibilities → Qualifications → Nice to have → About the company → Benefits → Work type —
      omitting empty sections and returning `""` when empty (raw fallback). It becomes the **displayed** description
      in `JobDetailView` (the redundant collapsible "Posting details" section is retired — its content now lives in
      the standardized description); raw `fullDescription` / snippet remain the fallback.
- [x] **K-D — progressive display + persist.** `SearchViewModel` shows ranked rows immediately, then consumes
      `digestStream` and swaps each row to its standardized description as it completes (an `isDigesting` indicator
      shows "Standardizing descriptions…"), re-persisting the standardized set. Applied to the search **and** the
      link/paste single-result flows.

**Tests.** `standardDescription` renders the fixed template in order, omits empty sections, and is `""` when blank;
`digestStream` structures every un-digested result, **caches** (skips those already carrying `details`), yields
nothing when un-wired, and skips results a digest didn't change; a `SearchViewModel` search digests results into the
standardized format. Full suite green; build warning-free.

**On-device.** One `.extraction`-task LLM call per result (+ a page-fetch attempt) — **cost scales with result
count**, guarded by the bounded window, the cache, and progressive display (rows appear before digestion finishes).
The digest **normalizes** the posting into the standard format (a normalized digest, not verbatim — consistent with
the transparency stance). *(Open calls resolved as recommended: the recommended section order; **bounded window**
first (no hard per-search cap); shipped with the **current `PostingDetails` fields**.)*

---

# v0.6.1 — keyword match & ATS coverage

A **patch release** on shipped v0.6.0, scheduled out of `PLANNED.md` (its sole `Target: v0.6.1` entry). The theme:
ATS / AI résumé screeners filter on a posting's keywords, and good candidates get auto-rejected for missing a few.
The answer here is **visible-text-only** — explicitly **not** hidden "invisible-ink" white-text keyword stuffing,
which backfires (ATS parse to plain text, recruiters see it, LLM screeners flag it) — so the app **shows** how well
the generated résumé covers the posting's **real** keywords and lets the user align truthfully. Four milestones
**A–D**; milestones restart at **A**; commit as `v0.6.1 : Milestone X Completed`.

## Milestone A — `KeywordCoverage`: pure covered-vs-missing computation  ✅ done  (`Data/Models/KeywordCoverage` (new); tests in `lib/tests/Data/Models`)

The foundation the rest of v0.6.1 renders (C) and complements (D): a pure, `Sendable`, unit-tested value type that
answers *"how much of this posting's keyword set actually appears in the generated **visible** résumé?"* — no store,
no view, no model call. Derived on demand, never persisted, and deliberately distinct from
`JobMatch.matchedSkills` / `missingSkills`, which score the **profile** during ranking rather than the generated text.

- [x] **The type.** [`KeywordCoverage`](../src/Data/Models/KeywordCoverage.swift) (Data · Models, `nonisolated` +
      `Sendable`) with a `Tier` enum (`mustHave` / `niceToHave` / `techStack` — the three `TargetBrief` keyword
      fields, each with a UI `label`) and a `TierCoverage` (`covered` / `missing` / `total`, `Identifiable` by tier
      for SwiftUI). Keywords are reported **as the posting wrote them** (whitespace-trimmed only), so the UI renders
      "C++", not a normalized form.
- [x] **Roll-ups.** `coveredCount` / `totalCount` are the **must-have** headline (what a screener actually filters
      on — the recommended resolution of the "which tiers count" open call), with `allCoveredCount` / `allTotalCount`
      across every tier and `isEmpty` so C can hide the panel rather than report a meaningless "0/0 covered". A tier
      that contributes no usable keyword is omitted from `tiers` entirely rather than rendered as an empty group.
- [x] **Matching.** `normalized(_:)` folds case + diacritics, collapses whitespace runs (including newlines, so a
      multi-word keyword matches across a line break), and trims **end** punctuation from a deliberately narrow set
      (sentence + quoting marks only — never `+`, `#`, or `/`, so "C++", "C#", and "Node.js" survive). Intentionally
      light: **no stemming, no synonyms** — over-matching would report coverage the user doesn't have.
- [x] **Word boundaries without a regex.** `contains(_:in:)` scans hits and requires the characters either side to
      be non-alphanumeric. This is the reason it isn't `NSRegularExpression`: `\bC\+\+\b` **never** matches "C++"
      (no word character follows the "+"), whereas the boundary scan matches "C++", ".NET", and "Node.js" while
      still keeping "Go" out of "Google" and "React" out of "reactive". The scan continues past a rejected hit, so a
      bounded occurrence later in the text still counts ("go" in "logo go").
- [x] **De-duplication.** A keyword listed in more than one tier is counted **once, in its highest tier**
      (must-have > nice-to-have > tech stack) — as are repeats within a tier — so the headline can't double-count a
      term the posting merely repeats. Empty / whitespace-only keywords are dropped, never counted as missing.
- [x] **Markdown entry point.** `init(brief:resumeMarkdown:)` reduces the résumé through
      [`MarkdownPlainText`](../src/Infrastructure/Text/MarkdownPlainText.swift) first (a legal downward Data →
      Infrastructure use), so a keyword behind emphasis or a bullet marker counts — it's visible text either way —
      while a keyword that appears **only** in a Markdown link target does not, since the URL was never visible.

**Tests.** `lib/tests/Data/Models/KeywordCoverageTests.swift` — 24 tests: present/absent, case-insensitivity,
diacritic folding, the word-boundary guarantees (Go/Google, React/reactive, the "logo go" continuation), keywords
ending or leading in punctuation (C++, C#, .NET, Node.js), trailing sentence punctuation on a keyword, multi-word
phrases (including across a line break, and scattered words *not* matching), no-stemming, Markdown reduction
(emphasis/bullets count, link targets don't), tier ordering, empty-tier omission, cross-tier and within-tier
de-duplication, the must-have headline vs. the all-tier breakdown, and the empty edges (no keywords, blank
keywords, empty résumé). Full suite green; build warning-free.

**On-device.** n/a — pure local string matching. No LLM call, no network, no persistence.

## Milestone B — Surface the `TargetBrief` out of generation  ✅ done  (`Business/UseCases` + `Data/Persistence/SavedApplicationsRepository` + `Presentation/Application/ApplicationViewModel`)

The posting's keywords existed only *inside* generation and were then thrown away:
[`GenerateApplicationUseCase`](../src/Business/UseCases/GenerateApplicationUseCase.swift) built the stage-1
`TargetBrief` and returned just the `ApplicationKit`, `GenerateToTargetUseCase.Outcome` carried no brief, and
`SavedApplicationsRepository` persisted only the kit — so `TargetBrief` never reached Presentation and a reopened
saved kit had no keywords either. Milestone A's computation had no input. B carries the brief out and pairs it with
the kit in storage. **No `LLMProvider` change** — nothing to forward in `SettingsBackedLLMProvider`.

- [x] **`GenerateApplicationUseCase` returns an `Outcome`.** A `struct Outcome: Sendable, Equatable { kit, brief }`
      mirroring `GenerateToTargetUseCase.Outcome`, so both generation paths hand back the same pair rather than one
      returning a bare kit.
- [x] **`GenerateToTargetUseCase.Outcome` carries the brief.** The loop already builds it once up front; it's now
      returned on **both** exits — target reached, and best-attempt-at-the-cap.
- [x] **`ApplicationViewModel.brief`.** A `private(set) var brief: TargetBrief?` set from whichever path ran and
      cleared in lockstep with `kit` (start of `generate`, and the miss branch of `loadSaved`), so a failed
      regeneration can never leave a stale brief pointing at a résumé that no longer exists.
- [x] **The brief is persisted *inside the kit's own record*** — resolving the open call, but not as the
      "sibling `SavedBriefsRepository`" the plan sketched. `SavedApplicationsRepository` now encodes a private
      `StoredApplication { kit, brief }` envelope under its existing `applicationKit` kind. Keyword coverage
      compares a résumé against **the brief that produced it**, so one latest-wins record makes it structurally
      impossible for the two to drift apart — and `DeleteSavedJobUseCase` already forgets both in its existing
      single delete, so the design adds **no orphan class and no new composition wiring**. `save(_:brief:forJobID:)`
      and `SaveApplicationUseCase` take the brief with a `nil` default; `brief(forJobID:)` is a new read on the
      repository and on `LoadApplicationUseCase`, leaving `kit(forJobID:)` (and `JobDetailView`'s
      "already generated?" probe) untouched.
- [x] **Back-compatible reads.** `kit(forJobID:)` tries the envelope, then falls back to the legacy bare-kit
      encoding, so records written before B still load — they simply report no brief, and coverage is *unavailable*
      for them rather than wrong.

**Tests.** Business — `GenerateApplicationUseCase` returns the brief it tailored against (and the existing
two-stage test now reads `outcome.kit`); the rank-target loop carries the brief out on both the target-reached and
capped exits. Data/Persistence — brief round-trips beside the kit, saving without one still stores the kit, a later
save replaces **both** (no stale brief outliving its résumé), and a legacy bare-kit blob still decodes with a nil
brief. Presentation — generate exposes the brief *and* persists it, reopening a saved result restores it without
calling the engine, a legacy record leaves it nil, and a failed regeneration clears it along with the kit. Full
suite green; build warning-free.

**On-device.** n/a — reuses the existing stage-1 call (no extra LLM work); the added persistence is local.

## Milestone C — Coverage panel in the Application view  ✅ done  (`Presentation/Application`: `ApplicationViewModel` + `ApplicationSheet`)

The user-facing half of the release: on a generated result, **"Posting keywords: X/Y must-haves covered"** with the
covered list (green) and the missing list (amber) per keyword tier — computed on the **visible** résumé and
recomputed after every generate / regenerate. Presentation only, over Milestone A's computation and Milestone B's
brief.

- [x] **`ApplicationViewModel.coverage`.** A computed `KeywordCoverage?` from `kit` + `brief` — both `@Observable`,
      so it recomputes after each generation with no explicit refresh and no stored state to invalidate. It returns
      `nil` for all three "nothing honest to report" cases at once: no kit, no brief (a record predating Milestone
      B), or a posting that yielded no keywords — so the view has a single condition to render on.
- [x] **`coverageSection` in `ApplicationSheet`.** A `GroupBox` in the same family as `documentSection` /
      `disclosuresSection` / `gapsSection`, listing each tier's covered and missing keywords as capsules via a
      `keywordRow` mirroring `JobDetailView.skillRow` — so covered/missing keywords read in the app's existing
      visual language for matched/missing skills rather than introducing a new one. A caption states the rule the
      feature exists for: *counted in the visible résumé text — never hidden keywords.*
- [x] **Placement (open call, resolved as recommended).** Below the two documents and above the disclosures / gaps:
      the user reads what was produced, then how it aligns to the posting, then what's claimed about it.
- [x] **Headline.** Leads with must-haves — what a screener actually filters on — and falls back to the all-tier
      count when a brief named no must-haves, so the panel can never read "0/0 must-haves covered" while listing
      keywords underneath it.
- [x] **Hidden, not empty.** With no coverage to report the section simply isn't rendered — no "0/0 covered" box,
      no empty group.

**Tests.** `lib/tests/Presentation/Application/` — `coverage` is nil before anything is generated; after a
generation against a keyword-bearing brief it reports the covered/missing split, the must-have headline, and the
nice-to-have tier in the breakdown but not the headline; it's nil for a thin posting whose brief has no keywords;
and nil for a saved record with no brief while the documents still show. The stub's résumé is deliberately Markdown
(`- **Swift** and Metal`) so the test proves coverage reads the visible text past the syntax. Full suite green;
build warning-free.

**On-device.** n/a — pure local rendering over Milestone A's string matching. *(Visual check pending — see the
device-checks note in `TODO.md`.)*

## Milestone D — Optional keyword-emphasis generation control  ✅ done  (`Data`: `GenerationSettings` + `LLM/Prompts`; `Business`: `GenerateToTargetUseCase`; `Presentation`: `ApplicationViewModel`, `ApplicationSheet`)

The only part of v0.6.1 that changes what generation *produces*. A–C report coverage; D lets the user act on it —
an **opt-in** control telling generation to weave the posting's must-have keywords into the **visible** résumé
where they truthfully apply, and route the rest into `gapNote`. Report-only remains the default.

- [x] **A dedicated flag, not a `TailoredAspect` case.** `GenerationSettings.emphasizeKeywords: Bool = false`.
      `PLANNED.md` recommended a `TailoredAspect` case for the free checkbox UI, but the code says otherwise:
      `TailoredAspect` is documented *and prompted* as a résumé **section**, and `Prompts.generationControls`
      renders the selection as "tailor ONLY these résumé sections — …" — a non-section case would corrupt that
      sentence and the preset semantics. A flag costs one checkbox and keeps both clean.
- [x] **Persisted into presets, back-compatible.** Added to `CodingKeys` so new presets carry it, with a
      hand-written `init(from:)` that `decodeIfPresent`s it — synthesized decoding requires every non-optional
      key, which would have broken **every preset saved before v0.6.1**. Absent ⇒ `false`, so a legacy preset
      still produces exactly the prompt it always did. Encoding stays synthesized.
- [x] **Counted as a control.** Folded into `hasDefaultControls`, so the flag alone turns on the GENERATION
      CONTROLS block; with it off the prompt is **byte-for-byte** what it was. `isDefault` follows from
      `Equatable` for free.
- [x] **The prompt clause.** `Prompts.generationControls` gains one line when the flag is on, sharpening the
      existing Objective line from "foreground the keywords where supported" into an explicit
      **cover-it-or-declare-it** instruction: use the posting's own wording for experience the candidate genuinely
      has; any must-have keyword they cannot truthfully claim must **not** appear as experience and is named in
      `gapNote` instead. It states the rule the feature exists for — *never emit a hidden, decorative, or bulk
      keyword list*, the résumé must still read as prose written for a human — and scopes the push to
      **must-haves** so nice-to-have and tech-stack terms aren't forced (the recommended resolution of that open
      call).
- [x] **Survives the rank-target loop (open call, resolved as recommended).** `GenerateToTargetUseCase` builds
      fresh settings each round, discarding the user's fidelity and aspects; `emphasizeKeywords` is now threaded in
      exactly as `additionalContext` already was, because the target overrides **latitude** controls and this isn't
      one. The checkbox is correspondingly left **enabled** under a rank target, outside the `rankTargetOn` disable
      that greys the fidelity slider and aspect checkboxes.
- [x] **UI.** A checkbox in the generation-options panel — "Match the posting's must-have keywords" — with a
      caption naming both halves of the deal: the posting's wording for experience you genuinely have, anything
      you can't claim listed in Gaps, visible text only.

**Tests.** `Data/Models` — off by default; the flag counts as a control but not as latitude (`band` stays
`.authentic`, `mayEmbellish` false); round-trips into a preset; and a v0.6.0-era blob with no
`emphasizeKeywords` key still decodes, to `false`, with its other controls intact. `Data/LLM` — with the flag off
the prompt is byte-for-byte unchanged; with it on the clause appears **exactly once**, carries the gap-note routing
and the no-hidden-list rule, and turning it on alone emits the controls block while keeping the grounded
"REAL experience only" latitude (no `EMBELLISHED:` disclosure). `Business` — the flag reaches every round of the
rank-target loop, both directly and through `ApplicationViewModel`. Full suite green; build warning-free.

**On-device.** `.application`-task LLM work on the existing engine and prompt path — no new engine, task, or seam.
The emphasis is prompt-driven, so both engines stay in lockstep. *(Visual/behavioural check pending — see the
device-checks note in `TODO.md`.)*

---

# v0.6.2 — list actions, sorting & document previews

A **patch release** on shipped v0.6.0/v0.6.1, scheduled out of `PLANNED.md` (all five of its `Target: v0.6.2`
entries, 2026-07-28). The theme is **the two list tabs and the Portfolio document previews**. Five milestones
**A–E**; milestones restart at **A**; commit as `v0.6.2 : Milestone X Completed`.

## Milestone A — Discoverable remove-from-Tracker  ✅ done  (`Presentation/Tracker/View/TrackerView`, `Presentation/Results/View/JobDetailView`, `Presentation/App/JobDetailWindow` + `Composition`; tests in `lib/tests/Presentation/Tracker`)

A **discoverability fix, not a behaviour change**. The Tracker already supported both removals — leading-swipe
"To Results" → `TrackerViewModel.returnToResults` (via `UntrackJobUseCase`) and trailing-swipe "Delete" → `.delete`
(via `DeleteSavedJobUseCase`), both shipped in v0.5.0 — but they were **swipe-only**, an iOS pattern with no visible
affordance on macOS, where users right-click or expect controls. In practice that read as *"there's no way to remove
a result from the Tracker."* This milestone adds the affordances and leaves the logic untouched: **no Business or
Data change**, no new use case, no `LLMProvider` change.

- [x] **Three ways to reach the same two actions**, in [`TrackerView.trackerRow`](../src/Presentation/Tracker/View/TrackerView.swift):
      **always-visible row icons** (`arrow.uturn.backward` + `trash`) in a new `rowActions(_:)`, a right-click
      **`contextMenu`** ("Return to Results" / "Delete", divider between), and the original **swipes**, kept as the
      secondary path. All three call the same `TrackerViewModel` methods.
- [x] **Always-visible icons rather than hover-revealed.** `PLANNED.md` suggested hover-revealed buttons "mirroring
      the Results tab's visible save/delete row icons" — but [`ResultsView.rowActions`](../src/Presentation/Results/View/ResultsView.swift:175)
      renders its icons **unconditionally**, so mirroring it *is* always-visible. Hover-only would also still be a
      semi-hidden affordance, which is the exact problem being fixed. The row was restructured into the same
      `HStack { RankedRow …; rowActions }` shape Results uses, so the two tabs are now structurally identical.
- [x] **One confirmation, shared by every delete path.** A `pendingDelete: RankedJob?` holds the job awaiting
      confirmation and a single `.confirmationDialog` on the view body resolves it — so the row icon, the context
      menu **and the swipe** all confirm identically (the swipe previously deleted outright). The message names the
      job, spells out what's forgotten (listing + status + generated materials), says it can't be undone, and points
      at "Return to Results" as the non-destructive alternative. **Return to Results is not confirmed** — it keeps
      the listing and materials, so there's nothing to lose.
- [x] **Reachable with the job open, not only from its row.** [`JobDetailView`](../src/Presentation/Results/View/JobDetailView.swift)
      takes two new optional closures (`onReturnToResults` / `onDelete`) and renders a **"Remove" menu** in the
      footer, on the leading side so the primary Generate/View button stays the visual focus and a destructive
      action isn't a stray click from it. Delete confirms with the same wording, then dismisses — the window's job
      no longer exists in the list behind it.
- [x] **Wiring.** [`JobDetailWindow`](../src/Presentation/App/JobDetailWindow.swift) supplies both closures only when
      `canRemove` — the **Tracker** context (a Results job isn't tracked yet) **and** both use cases available,
      mirroring `TrackerViewModel.supportsRowActions`. `Composition.untrackJob` / `.deleteSavedJob` changed from
      `private` to internal for this; they stay use cases, so the window never touches a repository.

**Tests.** `rowActionsRequireBothUseCases` extended to all four wirings (neither / untrack-only / delete-only /
both), since one half-wired use case would otherwise show an affordance that silently does nothing.
`removalsAreNoOpsWhenUnwired` pins both methods as safe no-ops without persistence, and
`removingOneJobLeavesTheOthers` covers the multi-row case for both removals plus the listing-survives-untrack /
listing-gone-after-delete distinction. Full suite green; build warning-free. The menu, hover and dialog rendering
itself is a device check.

**On-device.** n/a — pure Presentation over the existing persistence use cases. No model call, no new seam.

## Milestone B — Multi-select results: bulk save-to-Tracker / delete  ✅ done  (`Presentation/Results/{ViewModel,View}`, `Presentation/Tracker/{ViewModel,View}`; tests in `lib/tests/Presentation/Results` + `…/Tracker`)

Both list tabs were **one row at a time** — after a search returns 30 results, triaging them meant 30 individual
saves or deletes. Both now support **multi-select with bulk actions**, reusing the existing per-row logic and
persistence: **no new use case, no Business/Data change**.

- [x] **Selection state.** `selectedIDs: Set<String>` on [`ResultsViewModel`](../src/Presentation/Results/ViewModel/ResultsViewModel.swift)
      — ids, not jobs, so a selection survives the list being re-derived (a filter change, an enrichment swap).
      Distinct from `selectedJob`, which is the one job open for detail.
- [x] **Selection can only act on what's shown.** `selectedJobs` derives from `filteredResults`, and
      `selectionCount` counts *that* rather than `selectedIDs.count` — so a row the filter has since hidden can't be
      silently saved or deleted, and the bar's promise ("3 selected") can't disagree with what the button does. The
      Tracker's equivalents are `section`-scoped (`selectedJobs(in:)`), so a selection made under **All** can't be
      acted on from a different stage tab.
- [x] **Bulk methods.** `saveSelectedToTracker()` batches the listings through `SaveResultsUseCase([RankedJob])` in
      **one** write, loops the per-id `MarkStatusUseCase`, refreshes history **once** (so the saved rows drop out of
      Results together), then enriches. It keeps the per-row **no-downgrade** rule — an already-`.interviewing` job
      isn't knocked back to `.saved`. `deleteSelected()` drops the rows first (immediate feedback) then clears each
      from the store. The Tracker gets `returnSelectedToResults(in:)` / `deleteSelected(in:)` over one shared
      `removeSelected(in:using:)` runner, since both its removals are per-id use cases.
- [x] **⚠️ Bounded bulk enrichment — the real cost.** `saveToTracker` fires `enrichSavedJob` (a page fetch + LLM
      pass) per job, so bulk-saving N would have kicked off N at once. `enrichSavedJob` became **`enrichSavedJobs([RankedJob])`**
      running the batch through the same **sliding window** the search-side digest uses
      (`SearchAndRankUseCase.digestStream`), at most 4 in flight, with the enriched jobs written back in one batch.
      A single-row save is now just the one-element case — one code path, not two. It still runs *after* history
      refreshes, so the list never waits on it.
- [x] **The selection affordance (the milestone's primary open call) — resolved as recommended: native
      `List(selection:)`.** ⌘/shift-click extend, which is what a Mac user expects, and it costs no custom
      selection chrome. The consequence: **single-click now selects, so opening the detail moved to double-click**.
      The former `.onTapGesture { openDetail }` would have swallowed every selection click, so it became a
      `simultaneousGesture(TapGesture(count: 2))` — `onTapGesture(count: 2)` would have competed with the List for
      the single click, while a simultaneous gesture lets it through. A row `.help` spells out both interactions.
- [x] **Bulk action bar**, shown only while rows are selected: **"N selected · Save to Tracker · Delete · Clear"**
      in Results, **"N selected · Return to Results · Delete · Clear"** in the Tracker, with an inline
      `ProgressView` and the whole bar disabled while `isBulkActing` (so a slow batch can't be fired twice).
- [x] **Counted confirmation on bulk delete** ("Delete 7 results?"), spelling out that listings, statuses and
      generated materials all go. Bulk save isn't confirmed (it's reversible from the Tracker), and neither is bulk
      Return to Results (nothing is lost) — matching Milestone A's rule.
- [x] **The Tracker open call — resolved as recommended (yes).** The same pattern is mirrored there, so both list
      tabs now share one interaction model rather than the Tracker being the odd one out one milestone after A made
      its row actions match. The other open call (bulk actions beyond save/delete) stays deferred: save + delete
      first, bulk status-mark only if it proves useful.

**Tests.** Results: selection round-trip + clear, the filter-hides-a-selected-row guarantee, bulk save (persisted,
marked, dropped from the list, selection cleared) and its no-downgrade case, bulk delete (all three stores cleared
for the selected, the unselected job untouched *including* its kit), the empty-selection no-op — the guard that
stops "Delete" with nothing selected from wiping the list — and that a bulk save enriches **every** job it saved.
Tracker: stage-tab-scoped selection, bulk untrack (statuses gone, listings kept), bulk delete, empty-selection
no-op. Full suite green (686 tests); build warning-free.

**On-device.** Selection and the bars are pure Presentation. The bulk save's enrichment is `.extraction`-task LLM
work on the existing engine — unchanged per job, now capped at 4 concurrent instead of unbounded.

## Milestone C — Results sort + Tracker filter: sort/filter parity across both tabs  ✅ done  (`Presentation/Results/View/ResultsSort` (new) + `Presentation/Components/ListFilterBar` (new), both list `View`s + `ViewModel`s; tests in `lib/tests/Presentation/Results` + `…/Tracker`)

The two list tabs each had **one** of the pair — Results a live `ResultsFilter` (Milestone W) but no sort, the
Tracker a live `TrackerSort` (v0.5.1 Milestone H) but no filter. Both now sort **and** filter. The asymmetry in how
that was done is the interesting part: one side **reuses**, the other **parallels**, and which is which follows
from the data, not from taste.

- [x] **Tracker filter — the *same* `ResultsFilter`, not a copy.** `matches(_ job: RankedJob, isTracked:)` is
      generic over a `RankedJob` and a `TrackedJob` **wraps** one, so it applies directly to `tracked.job`. A
      `filter` property on [`TrackerViewModel`](../src/Presentation/Tracker/ViewModel/TrackerViewModel.swift) runs
      **alongside the stage predicate inside `jobs(in:)`, before the sort** — resolving the scope open call as
      recommended: the filter narrows **within the selected tab** rather than reaching across tabs, matching how the
      sort already worked per section. `isTracked` is hard-`true` there (everything in the Tracker is tracked),
      which is also why the UI hides that facet.
- [x] **Results sort — a *new*, parallel [`ResultsSort`](../src/Presentation/Results/View/ResultsSort.swift).**
      `TrackerSort` couldn't be reused: it sorts `[TrackedJob]` on **status-based** keys (recent activity / date
      applied / stage) that don't exist for an un-triaged `RankedJob`. So `ResultsSort` mirrors its shape — same
      `Key` / `Direction` / `apply(to:)`, pure, `Sendable`, `Equatable`, title tie-break for stability — with
      RankedJob-appropriate keys: **match score (default)**, company, role title, salary, posted date. Applied in
      `filteredResults` **after** the filter, with a `sortBar` mirroring `TrackerView.sortBar`.
- [x] **The default changes nothing.** `ResultsSort.default` is match-score-descending — the order the ranker
      already returns — so an untouched Results list is exactly what it was before this milestone. Pinned by a test.
- [x] **Unknowns sort last in *both* directions.** A listing with no salary or no `postedDate` goes to the end
      whichever way the arrow points — the same rule `TrackerSort` uses for undated jobs, so "unknown" never
      masquerades as the best or the worst value. Salary ranks on the top of the range, falling back to the floor
      (matching how `ResultsFilter`'s salary facet reads a range).
- [x] **One filter bar, not two.** `ResultsView.filterBar` was extracted to a shared
      [`ListFilterBar`](../src/Presentation/Components/ListFilterBar.swift) (Presentation · Components) that both
      tabs now render, with the option-list duplication behind a shared `ListFilterOptions.distinct`. Giving both
      tabs the same capability would otherwise have meant two copies of the same controls, free to drift. The
      `trackedStatus` facet is exposed by neither — moot in the Tracker, and Results hasn't shown tracked jobs since
      v0.4.1 Milestone C.
- [x] **A filtered-empty tab is not an empty stage.** `TrackerView`'s "No *stage* applications" branch keyed off
      `jobs`, which is now filtered — so a filter that hid every row would have shown that message **with the
      filter bar gone**, stranding the user with no way to clear it. The branch now keys off the **unfiltered**
      count, and a filtered-empty tab gets its own state with a **Clear filters** button, mirroring Results'
      `isFilteredEmpty`.
- [x] **Sort bars stay separate.** Sharing them would mean a protocol over both sort types with an associated
      `Key` and a hoisted `Direction` — churning `TrackerSort` and its tests to save ~30 lines of view code. Not
      worth it; the two ~30-line bars stay.

**Tests.** A new `ResultsSortTests` suite mirroring `TrackerSortTests`: every key in both directions, the
default-reproduces-ranking-order guarantee, salary's top-then-floor rule, unknowns-last in both directions, title
tie-break stability, empty/single input, and that every key is labelled for the picker. Plus VM-level wiring —
Results: filter-then-sort composition, `resetSort`, and that sorting never mutates `results`; Tracker: the filter
applying within a stage tab and before the sort, the tracked facet's behaviour on an all-tracked list, counts and
picker options coming from the **unfiltered** tab, and `isFilteredEmpty` firing only when a filter hides real rows.
Full suite green (703 tests); build warning-free.

**On-device.** n/a — pure Presentation value types, session-only and non-destructive. No persistence, no re-load,
no model call.

## Milestone D — Hide the raw-text preview for imported source documents (keep paste)  ✅ done  (`Presentation/Portfolio/{View,ViewModel}`; tests in `lib/tests/Presentation/Portfolio`)

Each Portfolio → Profile résumé/cover-letter slot had a **"Show text"** toggle revealing a raw `TextEditor` of the
document's extracted text. For an **imported file** that raw text is noise — the view worth reading is the
**tidied** one on the Source Documents tab after Build Profile. The editor still has to exist for the **paste**
path, though, since typing is the only way to get text in without a file. So the slot now has two states, keyed on
the `fileName: String?` it already knew.

- [x] **Imported (`fileName != nil`) — no raw preview.** The "Show text" toggle and the `TextEditor` are gone,
      replaced by a one-line summary: the file name, its character count, and where to read it properly
      ("Build Profile to read it tidied on the Source Documents tab"). This makes the résumé/cover-letter slots
      match the **supporting-documents** slot (v0.6.0 Milestone I), which has never had an editor.
- [x] **Pasted (`fileName == nil`) — unchanged.** Toggle, editor, and the existing `collapsedSummary` all behave
      exactly as before, so the paste path is untouched.
- [x] **Clear, resolving the open call as recommended.** An import was otherwise **un-undoable in-slot** — importing
      is precisely what hides the editor, so without this a mis-picked file could only be replaced, never removed.
      `clearDocument()` / `clearCoverLetter()` on [`PortfolioViewModel`](../src/Presentation/Portfolio/ViewModel/PortfolioViewModel.swift)
      drop the file name **and** its text, and the slot falls back to the paste editor. They deliberately **don't**
      touch `sourceText` / `readableText`: those belong to the profile that was *built*, not to the slot.
- [x] **Import… becomes Replace… once a file is in**, so the two buttons read as what they now do.
- [x] **The second open call resolved as recommended: no snippet.** Name + character count only — a read-only
      preview of the raw text is exactly what's being removed.

**Tests.** That Clear returns the slot to the paste state (`fileName` nil — what the view branches on — with no
orphaned text, `canBuild` back to false, and pasting working afterwards); that clearing one slot leaves the other
alone; that a cleared cover letter composes with `build()`'s own reset so no stale letter survives the next build;
and that clearing after a build leaves the built `sourceText` / `readableText` / profile intact. Full suite green
(707 tests); build warning-free. The rendering fork itself is a device check.

**On-device.** n/a — a conditional in one view helper plus two view-model setters. No model call, no persistence
change.

## Milestone E — Full source-document preview: remove both truncations  ✅ done  (`Presentation/Portfolio/View/PortfolioView`, `Business/UseCases/TidyDocumentUseCase`, `Data/LLM/Prompts`; tests in `lib/tests/Business/UseCases` + `…/Data/LLM`)

"The source-document preview truncates" was **two** faults wearing one symptom, and only one of them was visual.

- [x] **The UI cap (cosmetic).** `documentDisclosure` rendered the text in a nested `ScrollView` capped at
      `.frame(maxHeight: 220)` — every character was present, but confined to a ~220pt box that reads as cut off.
      The inner scroll view is **removed entirely** rather than enlarged: the tab already scrolls
      (`scrollableScreen`), and it was the nesting that made the content feel boxed in. `Text` doesn't line-limit,
      so it now renders in full. Resolves the inline-expand-vs-window open call as recommended: inline, no separate
      "View full document" window.
- [x] **The content truncation (the real one).** `Prompts.tidyDocument(rawText:)` truncated its input to
      `maxPortfolioCharacters` (6 000), so for a long document the **stored** `readableText` was genuinely shorter
      than the original — dropping the UI cap alone would have revealed nothing, because the tail had never been
      tidied. Fixed as recommended, in two parts:
      - **Its own, larger bound.** New `Prompts.maxTidyDocumentCharacters` (12 000, matching `maxPageCharacters` —
        the existing precedent for "one long document, on its own"). Deliberately **not** a raise of
        `maxPortfolioCharacters`: that cap also bounds text injected *alongside* other content (profile build,
        generation grounding, at four other call sites), where the on-device context budget is shared. A test pins
        that the shared budget was left at 6 000.
      - **A completeness guarantee.** [`TidyDocumentUseCase`](../src/Business/UseCases/TidyDocumentUseCase.swift)
        now splits the document itself: it tidies the head up to the bound and **appends anything beyond it
        as-extracted**, behind a short notice ("the rest of this document was too long to tidy and is shown exactly
        as extracted"). So the stored readable text is tidied where it could be and **complete regardless** — never
        silently short. It splits explicitly rather than leaning on the prompt's own `truncate`, so what the model
        saw and what gets appended can't drift apart; the prompt-level truncation stays as a backstop.
- [x] **Chunked tidy stays the follow-on.** Tidying the tail in segments would be nicer still, but costs one LLM
      call per chunk and has to keep structure consistent across boundaries — out of scope for a patch.

**Tests.** A new `TidyDocumentUseCaseTests`: short / exactly-at-bound / past-the-old-6 000-cap documents all tidy
whole with no notice; a long document keeps its remainder verbatim behind the notice; **nothing is dropped however
long the document** (the regression this milestone exists for); the remainder is never sent to the model (exactly
one tidy pass); a failing engine still propagates so `PortfolioViewModel.build` can fall back to raw; and empty
input is handled. Plus `Prompts` coverage for the new bound and for the shared 6 000 budget being untouched. Full
suite green (719 tests); build warning-free.

**On-device.** The UI change is free. Tidying now sends up to 12 000 characters instead of 6 000 on the
`.profile` task — twice the input for one document, still bounded, and the remainder path costs **no** extra model
work (it's appended locally, not generated).

---

# v0.7.0 — customizable LaTeX document styles

A **feature release**, scheduled out of `PLANNED.md`'s single `Target: v0.7.0` entry (2026-07-28). The theme is
**user-owned document presentation** for the awesome-cv LaTeX route. Six milestones **A–F**; milestones restart
at **A**; commit as `v0.7.0 : Milestone X Completed`.

## Milestone A — `LaTeXStyle` model + built-in template registry  ✅ done  (`Infrastructure/Tex/LaTeXStyle`, `Infrastructure/Tex/LaTeXTemplateRegistry`; tests in `lib/tests/Infrastructure/Tex`)

**The gap.** Every presentation choice the LaTeX route makes lived as a string literal inside
`TexDocumentBuilder`'s two preamble builders — class + base size, `\geometry`, `\fontdir`, section order
(`canonicalOrder`) and per-section `\vspace` (`sectionVSpace`) — with the cover letter carrying its own,
divergent set. There was nothing for a user setting to *be*.

**What landed.** Two pure, `nonisolated`/`Sendable`/`Codable` files in Infrastructure · Tex, and **no behaviour
change** — the builder still emits exactly what it did, so B and C can replace its literals behind a regression
rather than in the same breath.

- **`LaTeXStyle`** — `template`, `fontFamily`, `fontSizes`, `accent`, `pageSize`, `margins`, the letter's
  `parskip` / `linespread`, `sectionOrder` + `hiddenSections` + `sectionSpacingEm`, and F's optional
  `customPreamble`. Plus the small formatting helpers the builder will need (`geometryOptions` renders
  `left=0.50cm, …` exactly as today; `sectionVSpace(forSectionTitled:)` renders `-1.5em`), so B/C consume a
  string rather than re-deriving formats.
- **`LaTeXStyle.default` reproduces today's output.** Three controls carry an explicit **`.templateDefault`**
  case — font family, accent, page size — precisely because the current builder emits *no* `\newfontfamily`, no
  `\colorlet`, and no paper option on the résumé (the letter's `a4paper` is the class's own). Modelling
  "unchanged" as a first-class case is what keeps the default byte-identical instead of forcing a choice on the
  user; picking `.usLetter` / `.a4` then applies to **both** documents, which is the unification B promises.
- **Font size is the one per-document control** (`LaTeXFontSizes.resumePt` = 6, `.coverLetterPt` = 11). The two
  classes scale everything off their base very differently, so a single shared number would render as two
  unrelated text sizes. One style still, carrying the two bases.
- **Accent** is `.templateDefault` / `.named(LaTeXAwesomeColor)` / `.custom(hex:)`, the named palette mirroring
  the nine `awesome-*` colours the bundled classes define. A malformed custom hex resolves to **no override**
  rather than emitting broken LaTeX.
- **`LaTeXResumeSection`** (education / experience / projects / skills / other) is the vocabulary a style orders,
  hides, and spaces; `classify(_:)` mirrors the builder's own title heuristics. A bucket left **out** of
  `sectionOrder` sorts last rather than vanishing — only `hiddenSections` hides, so C can't silently drop a
  model-invented section.
- **`LaTeXTemplateRegistry`** — descriptors (identity, display name, summary, class names, required `.cls`
  files, default style) in the `JobProviderRegistry` shape (v0.6.0 H-A), so adding a template is one appended
  descriptor, never a view edit. `descriptor(for: style)` is **total** (falls back to the shipped template);
  `available(in: assets)` filters to templates whose classes actually shipped, the same fail-soft posture as
  `TexAssets.isComplete`. Two entries ship: **Portfolio (awesome-cv)**, whose default *is* `LaTeXStyle.default`,
  and **Portfolio — Compact**, which reuses the same bundled classes with tighter margins and section spacing —
  no new assets, and it keeps the registry (and E's picker) from being a list of one.

**One deliberate divergence, found by the tests.** The builder's two classifiers disagree with each other:
`canonicalOrder(_:)` treats "Employment" / "Work History" as *experience* (sorting them second), but
`sectionVSpace(_:)` never lists those synonyms, so they fall through to the generic `-1em`. A style has one
bucket per section, so the bucket wins and those titles pick up the experience `-1.5em`. C's byte-for-byte claim
therefore holds **except** for a résumé whose experience section is titled "Employment" or "Work History" — the
divergence is pinned by its own test (`experienceSynonymsGainTheExperienceSpacing`) rather than left to surface
as a mystery diff.

**Tests.** `LaTeXStyleTests` + `LaTeXTemplateRegistryTests` — the default style matches every value the builder
hardcodes (asserted against `TexDocumentBuilder` itself, so the two can't drift); classification and order
indices match `canonicalOrder`; reorder / hide / missing-spacing fallbacks; accent normalization and malformed
hex; `Codable` round-trips including the associated-value accent; every `LaTeXTemplateID` has exactly one
descriptor whose default style names its own template; availability against a fixture asset tree, a
missing-class tree, and the **real app bundle**. Suite green (758 cases), build warning-free.

**On-device.** n/a — pure value types, no model calls, no compile.

## Milestone B — Parameterize `TexDocumentBuilder` typography, geometry, colour & page size  ✅ done  (`Infrastructure/Tex/TexDocumentBuilder` + `LaTeXStyle`/`LaTeXTemplateRegistry`, `Business/UseCases/ExportApplicationUseCase`; tests in `lib/tests/Infrastructure/Tex`, `lib/tests/Business/UseCases`)

**The gap.** `resumePreamble(headline:)` and `coverLetterPreamble(headline:)` were two literal blocks —
`\documentclass[6pt]{Class/Resume}` / `\documentclass[11pt, a4paper]{Class/CoverLetter}`, a hardcoded
`\geometry`, `\fontdir[fonts/]`, and no colour or font control at all.

**What landed.** Both preambles now come from a **shared** `preambleHead(for:style:)`: the document class and its
options from the style's template descriptor + per-document base size + page size, `\geometry` from the style's
margins, then the optional font-family and accent overrides. `resume(fromMarkdown:style:)` /
`coverLetter(fromMarkdown:style:)` take the style (defaulted to `.default`), and
`ExportApplicationUseCase.texSource(_:_:style:)` / `.latexPDF(_:_:style:)` thread it from Business — Presentation
is untouched until E supplies the user's pick.

- **Page size unifies what was divergent.** The résumé passed no paper option and the letter passed `a4paper`;
  that asymmetry is the *template's*, so it moved to `LaTeXTemplateDescriptor.templateDefaultPaperOptions` and is
  consulted only while the style says `.templateDefault`. Choosing US Letter or A4 applies it to **both**
  documents — the unification the release promised, without forcing a choice on anyone who never opens the picker.
- **Font family repoints the class's own commands.** A chosen family emits two `\newfontfamily` declarations
  (regular + light weight groups, with per-family face suffixes — Roboto's `-Italic` vs Source Sans' `-It`) and
  `\renewcommand*{\bodyfont}` / `\bodyfontlight`, with an explicit `Extension=` so `fontspec` resolves the exact
  bundled file. Only **bundled** families are selectable, so `Path=fonts/` always resolves inside the staged
  compile directory. The literal path is used rather than `\@fontdir` — the latter would need `\makeatletter`
  in a document preamble.
- **Accent** emits `\colorlet{awesome}{awesome-red}` for a palette colour (already defined by the class) or
  `\definecolor{awesome}{HTML}{…}` for a custom one; a malformed hex emits **nothing** rather than LaTeX that
  would fail the compile.
- The letter's body spacing (`\parskip`, `\linespread`) now comes from the style too.

**Proving "no change by default" properly.** The pre-change output was captured from the builder *before* it was
touched (a throwaway test dumping both documents), and that capture is embedded in
`TexDocumentBuilderStyleTests` as a **whole-document** golden — not just the preamble, so a stray change anywhere
in the emitted `.tex` trips it. Two details the golden caught: the original preamble had **no** blank line
between `\pageHeader` and `\position`, and the résumé's class options are `[6pt]` alone.

**Tests.** Whole-document goldens for both deliverables (`resume(fromMarkdown:)` with no style argument, and the
explicit `.default`, both byte-identical); the default emits no `\newfontfamily`, no `\colorlet`/`\definecolor`,
and no `letterpaper`; font sizes / page size / margins / accent / font family each drive their own line and
nothing else; the **body is identical across styles**; the compact built-in brings its own geometry over the same
classes; `ExportApplicationUseCase` forwards the style through both entry points and is unchanged when omitted.
The integration test compiles a **fully styled** document (custom hex accent, Roboto body, US Letter, non-default
sizes and margins) and a Source Sans / named-accent letter under real `lualatex` — so the emitted overrides are
verified to compile, not merely to look right. Suite green (773 cases), build warning-free.

**On-device.** n/a — no model calls. The compile is the same optional `lualatex` dependency as before.

## Milestone C — Section order & visibility driven by the style  ✅ done  (`Infrastructure/Tex/TexDocumentBuilder` + `LaTeXStyle` + `LaTeXTemplateRegistry`; tests in `lib/tests/Infrastructure/Tex`)

**The gap.** The résumé's section order and per-section spacing were two hardcoded statics on the builder —
`canonicalOrder(_:)` (Education → Experience → Projects → Skills → everything else) and `sectionVSpace(_:)`. A
user could change the fonts and margins but not what their résumé led with, or drop a section they didn't want.

**What landed.** Ordering, visibility and spacing all read the style. `hiddenSections` filters whole sections out
**before** the emit loop, `sectionOrder` arranges what's left, and each `\vspace` comes from `sectionSpacingEm`.
The two statics were **deleted, not kept as delegates** — two live classifiers of the same thing is precisely the
drift Milestone A found, and a delegate would have left tests asserting values no document contains. Their
coverage was ported to `LaTeXStyleTests`, expectation for expectation, rather than dropped.

- **Ordering is a partition, not a sort.** The obvious `sorted(by:)` needs an index tiebreak to keep same-bucket
  sections in document order — and the absence of that tiebreak is **undetectable by test** (the current stdlib
  sort happens to be stable, so the mutation passes green). `LaTeXStyle.orderedSections(_:titledBy:)` groups by
  bucket instead, which makes document order structural and kills three edge cases by construction: a **duplicated**
  bucket in the order can't duplicate sections, an **empty** order degrades to document order, and unnamed buckets
  append last. Verified by mutation: reversing within-bucket order now fails four tests; the equivalent mutation
  against the sort version failed none.
- **Omitting a bucket means "put it last", never "drop it"** — the open call, resolved as recommended. Only
  `hiddenSections` removes anything.
- **Hiding leaves no double gap** — true *by construction*, not by new code: the `\vspace` is a prefix inside the
  section's own loop iteration, so it leaves with the section. An orphaned `\vspace` would be silent (TeX
  accumulates vertical glue without warning), so it's pinned as **byte equality**: hiding Projects produces
  exactly the document you get from Markdown that never had a Projects section.
- **The lead summary is out of the style's reach** — always first, never ordered, never hidden. "Summary"
  classifies as `.other`, so filtering one line too early would silently delete the user's opening paragraph when
  they hid `.other`; `leadSummary` deliberately reads the **unfiltered** sections, with a test for it.
- **`.other` is a deliberate bulk hide.** Hiding it removes Awards, Publications, Certifications and Volunteering
  together — the one place the "a model-invented section can't vanish" promise is in tension. Milestone E's
  toggle must be labelled as the catch-all it is.
- **Spacing is per *bucket*, not per section title**, and rendering still keys on the title (`isSkillsSection`):
  "Educational Qualifications" sorts as education but renders as a skills grid. That split is pre-existing and
  pinned by a test rather than quietly unified, which would have changed how sections render.

**The one default-style change.** "Employment" / "Work History" sections now take the experience `-1.5em` rather
than the generic `-1em`, because the old builder's two classifiers disagreed about them (it *sorted* them as
experience but *spaced* them as "other"). Recorded in Milestone A, pinned at document level here, and noted as
the single exemption on Milestone B's golden — which otherwise stays byte-identical and was **not** regenerated.

**Compact's spacing was measured and reverted.** The Compact built-in carried tighter per-section values from
Milestone A that were inert until this milestone made them live. Compiled under `lualatex` and measured with
`pdftotext -bbox`: the shipped look already runs the first section's rule ~2.6pt into the lead paragraph's glyph
box, and Compact's values pushed that to ~7.6pt — a visible collision. Compact's *margins alone* reproduce the
default's 2.6pt, so it keeps the canonical section spacing and margins remain its differentiator. Two
consequences worth carrying forward: negative section spacing is bounded by the lead paragraph, so **Milestone E
must bound what a user can enter**, and a future template that tightens spacing has to be measured, not eyeballed.

**Also hardened here** (both surfaced by the review pass): a non-finite spacing value now formats as `0` instead
of emitting `\vspace{nanem}`, which fails the compile outright — reachable from any numeric field E adds.
Magnitude is deliberately *not* clamped: bounding input is E's job, and silently rewriting a number would hide
what the user typed.

**Known follow-on, not fixed here.** `renderSkills` emits an ungrouped `\renewcommand{\arraystretch}{0.7}` that
is never restored, so it leaks into every section rendered after the skills grid (~3.15pt of row height). It's
pre-existing and changing it moves the golden's bytes, but C is what makes it *reachable* — a user can now move
skills to the top. It must land before or with Milestone E; a checkbox is recorded there.

**Tests.** A new `TexDocumentBuilderSectionTests` (21 tests) over a fixture covering all four canonical buckets
plus an unknown one in scrambled order: emitted-section **sequence** assertions for the default, reordered,
partial and unknown-bucket cases; hidden sections gone with their content; the byte-equality "no double gap"
test; the lead-summary guard; every-section-hidden still emitting a valid document; per-bucket spacing including
the fallback and the `0em` (not `-0em`) case; the Employment/Work History divergence; the cover letter proven
**immune** to section fields; and the converse guard that section fields never reach the preamble. Plus a second
whole-document golden captured **before** the change over the five-bucket fixture, unit tests for the ordering
partition in `LaTeXStyleTests`, and a real `lualatex` compile of a reordered + partly hidden résumé. Suite green
(801 cases), build warning-free.

**On-device.** n/a — no model calls.

## Milestone D — Persistence: the styles library + default pointer  ✅ done  (`Data/Models/SavedDocumentStyle`, `Data/Persistence/SavedDocumentStylesRepository` + `DefaultDocumentStyleStore`, `Business/UseCases/DocumentStyleUseCases`, `Composition`, `Infrastructure/Tex/LaTeXStyle`; tests in `lib/tests/Data/Persistence`, `lib/tests/Infrastructure/Tex`)

**The gap.** A style existed only for the length of one export. Nothing could name one, keep it, or reuse it.

**What landed**, mirroring the saved-profiles trio exactly: `SavedDocumentStyle` (id / name / style / `createdAt`),
`SavedDocumentStylesRepository` (`kind = "documentStyle"`, upsert-by-id / `all()` newest-first / `delete(id:)`
over `PersistentRecordStore`), and `DefaultDocumentStyleStore` — a single scalar pointer on `KeyValueStore` under
`com.veritum.taylordportfolio.defaultDocumentStyleID`, so "exactly one default" is true by construction rather
than an invariant something has to maintain. Three use cases (`Save` / `Load` / `Delete`) carry the id and
timestamp policy that the profile and preset precedents keep in Business, and `Composition` wires all four
privately. `createdAt` is an addition to the milestone's stated "(id / name / style)": `PersistentRecordStore`
documents no ordering, so every library repository sorts for itself and needs a key to sort on.

**The real work was making `LaTeXStyle` survive being read back.** Synthesized `Codable` is all-or-nothing: any
absent key, or any raw value this build doesn't recognise, throws — and because `all()` is best-effort
(`compactMap { try? … }`), a style that throws doesn't surface an error, it **disappears from the library while
its row stays in the store**, with nothing in the list to delete it by — `all()` reads `records(ofKind:)`, which
returns blobs without their ids. The
trigger is ordinary: appending one `LaTeXTemplateID` case is exactly how the registry says to add a template, and
Milestone E adds a template picker. So `LaTeXStyle` (and `LaTeXFontSizes` / `LaTeXMargins`) gained a
field-by-field `init(from:)`:

- **`(try? decode) ?? default` per field, not `decodeIfPresent`.** The `SavedProfile` recipe is all
  `decodeIfPresent ?? default`, which tolerates absence and null but still **throws on an invalid raw value** —
  it would have protected against only one of the two real failure modes.
- **Collections degrade element-wise**: an unknown section bucket is dropped rather than fatal to the whole
  arrangement, and `sectionSpacingEm` — which encodes as a flat *alternating array*, not an object, because a
  raw-value enum key isn't `CodingKeyRepresentable` — is read pairwise, so a malformed tail costs its own
  entries only.
- **Present-but-empty is honoured, not "missing".** The fallback is gated on `container.contains(_:)`, not on
  emptiness: `orderedSections` documents an empty order as a legitimate state, so an emptiness check would
  resurrect the canonical order a user deliberately cleared.
- **Deliberately not total.** A `style` that isn't a JSON object still throws, and `SavedDocumentStyle` catches
  *that* one layer up, loading the record as a named, deletable row with a default style. A missing field is
  drift; a wrong-shaped blob is an error, and the two deserve different answers. Encoding stays synthesized, so
  the wire format is unchanged and the existing round-trip fixtures pass untouched.

**Where the tolerance lives, and why.** In `LaTeXStyle` (Infrastructure), not in `SavedDocumentStyle` (Data).
`LaTeXStyle` decodes atomically, so an envelope-level `?? .default` is all-or-nothing too — one unknown template
string would silently discard the user's fonts, colour, margins and section arrangement. Making it *granular*
from Data would mean re-declaring the style's twelve keys and their defaults across the seam, which is the actual
layering violation. Holding an Infrastructure value in a Data model is the legal direction (Data → Infrastructure).

**A pointer that dangles resolves to `nil`, deliberately.** `resolved(in:)` does **not** copy the profile call
site's `?? profiles.first`: for a profile any grounding beats none, but silently applying a style the user never
chose changes the document they're about to send. E clears the pointer when its style is deleted.

**Tests.** `SavedDocumentStylesRepositoryTests` — the canonical four (round-trip newest-first, upsert-not-
duplicate, delete, empty); a **fully customised** style surviving the store with named per-field assertions; every
accent case; the two flat-array collections; a legacy blob missing later fields; a style from a *later* build
degrading field by field; the anti-zombie case (unusable style → still a named, deletable row); a corrupt blob
skipped without losing its neighbours; same-name and same-`createdAt` edges; cross-kind isolation; and a guard
that **every repository `kind` is distinct** (nothing checked that before D added the seventh). Plus a test that a
store round-trip produces byte-identical `.tex` — D is the first milestone where a *decoded* style reaches the
builder. `DefaultDocumentStyleStoreTests` covers load/save/clear/replace, corrupt data, the exact namespaced key,
non-interference with the profile pointer, and all three `resolved(in:)` outcomes. `LaTeXStyleTests` gained the
decoder's own pins, including the empty-vs-absent distinction and that a non-object still throws. Suite green
(849 cases), build warning-free.

**On-device.** n/a — no model calls.

## Milestone E — Style-manager UI + export-time picker  ✅ done  (`Presentation/Settings/{View,ViewModel}/DocumentStyles*`, `ShellNavigation` + `SettingsView` + `RootView` + `Composition`, `Presentation/Application` export menu + VM, `Business/UseCases/ExportApplicationUseCase`, `Infrastructure/Tex/TexDocumentBuilder`; tests in `lib/tests/Presentation`, `lib/tests/Infrastructure/Tex`)

**The gap.** Everything A–D built was unreachable: no way to create a style, name it, keep it, or choose one
when exporting. This is the release's only Presentation milestone and the first one a user can see.

**The manager** is a fourth Settings pane (`SettingsSection.documentStyles`, appended **last** — the raw value is
the segmented-control index, so inserting one would renumber every later pane). `DocumentStylesViewModel` is its
own view model rather than part of `SettingsViewModel`: that one loads synchronously and defers writes to an
explicit Save, which is right for engine settings and wrong for a library — a user who edits a style and switches
sub-tab must not lose it. It writes through on every action, mirroring the saved-profile library it's modelled
on: load-on-appear, save-or-update-in-place, duplicate (with `"Compact copy 2"` disambiguation), delete, and a
star toggle for the default. Deleting the default **clears the pointer on disk**, so it can't dangle.

**Every numeric control is bounded, and that is the safety mechanism.** Measured under `lualatex`: absurd
geometry doesn't fail — 1.6cm text width, twelve pages, even negative margins all **exit 0** and produce a wrecked
PDF. There is no compile error to catch and no banner to show, so the control's range is the only protection.
`Slider`/`Stepper` ranges (never a free text field, and never clamping the value — `LaTeXStyle` deliberately
refuses to rewrite what a user typed): section spacing **−1.5 … +3.0 em** (−1.5 is exactly the value C measured
as a visible collision and reverted; the heading structurally crosses the summary at −1.86em), margins
**0 … 4 cm** (the classes reserve a fixed 6cm column for dates, and 4+4 on A4 still leaves 13cm), footskip
**0 … 2 cm**, letter paragraph gap **0 … 3 em** (a negative one renders paragraphs out of order, on top of the
header, exit 0), letter line spread **0.8 … 2.0** (below 0.8 TeX's `\lineskip` floor absorbs it and the control
silently lies). One uniform spacing range for all five buckets, because *which* bucket renders first is
user-controlled — there is no reliably-non-first section.

**The base-size control is a discrete picker, not a number field.** `[6pt]` is an *unused* option: the classes
forward it to `article`, which honours only 10/11/12pt, and every text size in both classes is set absolutely.
So the control offers Template default / 10 / 11 / 12 and is labelled as what it actually does — scale vertical
spacing, not text.

**The export picker** offers built-ins and saved styles in one list, tagged by a `StyleChoice` (they have
separate id spaces). Two things it deliberately does: `nil` stays a **live** "follow my default" state rather
than being seeded once, so changing the default in Settings immediately changes what an unpicked export
produces; and a **dangling** default resolves to the built-in look, never to another saved style — silently
applying a style the user never chose changes the document they're about to send. It's grouped under a
`Section("Portfolio (LaTeX)")` header and the native picker was relabelled **"PDF / Word template"**, because two
bare pickers in one menu render identically and the milestone required them to read as different things. It's
gated on `canExport`, not `canExportLaTeX`: the `.tex` source export works with no TeX install and must stay
styleable.

**Preview** compiles a bundled sample through a new `ExportApplicationUseCase.previewPDF(style:)` — the sample
lives in Business so the view carries no content and never touches the compiler. Measured: **~4.0s** warm and
**~8.2s** on a cold font cache, which is what settles the open call for a button over a live preview; the button
shows a spinner plus "Compiling with lualatex…" for exactly that reason. Sample content is chosen for coverage,
not brevity (compile time is font loading, not typesetting): a lead summary, one section per bucket including an
unrecognised one, a dated `\cventry`, and a skills grid. Page 1 renders as a PDFKit thumbnail — nothing in the
app could display a PDF before, and one page is all a style preview needs. With no `lualatex`, the button is
**visible but disabled** with the About pane's exact wording, which is the first place that message actually
renders. `describeExport` was lifted from `private` to shared rather than copied, so the two compile paths can't
drift.

**The carried-over `\arraystretch` fix landed here** (it had to, before a user could reorder sections). The
`\renewcommand{\arraystretch}{0.7}` is now wrapped in a `{…}` group — grouping rather than resetting to `1`, so
it restores whatever the ambient value was. Measured on the same fixture: ungrouped, the following entry's
title→bullet gap compressed to **6.99pt**; grouped it is **10.860pt**, against **10.859pt** for a document with
no skills grid at all. This is the **second sanctioned golden exemption** and a deliberate change to the default
look: under the canonical order `.other` renders after `.skills`, so every résumé with an Awards / Publications /
Certifications section regains the row height the leak was compressing. Both goldens were amended by targeted
edit rather than blind re-capture — anything else that had moved would have failed them.

**Also fixed in passing:** `latexResumePages` survived a kit change and a style change, so the "compiled to N
pages" advisory could be measured under one style and shown under another.

**Known, accepted:** styles saved in Settings don't appear in an already-open Application window until it
reloads — its `.task` doesn't re-run on `requestID`. Identical to how generation presets behave today; the
alternative is an `AppSession.dataChanged()` bump, deferred rather than left undecided.

**Tests.** 21 `DocumentStylesViewModelTests` (library CRUD, blank-name refusal, save-failure message, duplicate
naming, the default pointer surviving a "relaunch" and clearing on delete, the auto-load-once latch not
clobbering edits, section moves preserving all five buckets exactly once, and the three preview paths including
the `lualatex` log surfacing) plus seven `ApplicationViewModelTests` for the picker — the selection reaching both
export routes, the default pointer, the dangling-pointer fallback, a built-in template, the no-library case being
byte-identical to pre-v0.7.0, and the stale page count clearing. Suite green (879 cases), build warning-free.

**On-device.** n/a — no model calls. Preview needs `lualatex`, the same optional dependency as the export route.

## Milestone F — Raw-LaTeX preamble override + graceful compile failure  ✅ done  (`Infrastructure/Tex/TexDocumentBuilder` + `LaTeXStyle` + `LaTeXProcessClient`, `Presentation/Settings` manager, `Presentation/Application` VM + sheet; tests in `lib/tests/Infrastructure/Tex`, `lib/tests/Presentation`)

**The gap.** `customPreamble` had existed on `LaTeXStyle` since Milestone A, read by nothing. A power user who
wanted a look the four control groups can't express had no way to write it — and, more pressingly, **the bundled
classes hardcode Taylor's name and contact details** in `\pageHeader`, so anyone else's export carried the wrong
identity with no control to fix it.

**What the override replaces — the decision that shapes the milestone.** Not "everything before
`\begin{document}`", but the **style block**: the `\geometry` line plus the font-family and accent overrides,
i.e. exactly what the Milestone B controls write. Three things force that cut, each verified by compiling:

- **`\documentclass` differs per document** (`Class/Resume` at 6pt vs `Class/CoverLetter` at 11pt/a4paper) while
  `customPreamble` is one string on a style that covers both. An override containing `\documentclass` is
  structurally wrong for one of the two, always — and yields `Two \documentclass commands`.
- **`\cventrysolo` / `\cvprojectsolo` exist only in the generated preamble**, and the body emits them
  **data-dependently** (an entry with no org, or no subtitle). If an override could displace them, the same
  style would compile one résumé and hard-fail the next. Verified: exit 1, `! Undefined control sequence`, no PDF.
- **`\position{…}` and `\pageFooter{…}` are generated content.** Letting an override delete them would make a
  presentation feature subtract content.

And the thing that cut appears to cost, it doesn't: `\pageHeader` is a `\newcommand`, and the override is
emitted *before* the frame invokes it — so `\renewcommand{\pageHeader}{\name{Alex}{Sample}…}` works, which is the
whole product story. Verified end to end: a real compile produces a PDF headed "Alex Sample" whose role line is
still the app's generated `\position`.

Under `LaTeXStyle.default` the style block collapses to the same single `\geometry` line in the same byte
position, so **both goldens stayed byte-identical** — and caught it when a first attempt added a stray blank
line, which is exactly what they're for.

**Graceful failure, three layers.**
1. A **blank** override is treated as no override (`effectiveCustomPreamble`), the same fail-soft rule as a
   malformed accent hex — an empty preamble compiles to `\normalsize is not defined`, which tells a user nothing.
2. The compile **cannot hang**: `-halt-on-error` is the real guard (not the `\nonstopmode` the docs credited),
   and the child process now gets `FileHandle.nullDevice` on stdin, so a preamble that makes TeX prompt for a
   file can't block on a prompt no one can answer. Structural rather than flag-dependent.
3. The error **names the likely cause** — `describeExport(_:customPreamble:)` appends one sentence when the
   failing style carries an override, as an overload so the manager and the export share one copy.

**Nobody gets stranded**, which needed answers in two windows:
- In the manager: **"Use the generated preamble"** (drops the override, keeps every other choice) and **"Revert
  to a built-in…"** (adopts a template's defaults while **keeping the style's id and name**, so Save updates the
  same row instead of leaving the broken one on disk beside a copy). Both **write through** when a saved style is
  open — the exports read the *store*, so a revert that only touched the draft would leave the manager looking
  fixed while every export still failed. Typed text is stashed on toggle-off, so nothing the user wrote is
  destroyed.
- At the export, a **different window** with no route to Settings: **"Use the built-in style for this export"**
  (session-only, touches neither the saved style nor the default pointer) and **"Export .tex source"**, promoted
  out of a per-document submenu because that is what a user needs after a compile error. The `.tex` route needs
  no TeX install and is never gated on a test compile — it is how a preamble gets debugged.

**The editor** is an eighth Settings section, sited between the section controls and Preview — after the controls
that build a preamble, immediately before the button that proves one compiles. It's gated by **conditional
rendering, not `.disabled`**: a disabled `TextEditor` still accepts typing on macOS 26. The controls an override
makes inert (template, typography, accent, margins) are dimmed; the ones that keep working are not — which is why
the cover letter's paragraph gap and line spacing **moved out of "Page & margins"** into their own section, since
they're emitted in the body and survive an override. Compile errors now render **in the Preview section** rather
than in the library footer six sections above, and a failed preview keeps the last good render on screen.

**A documentation claim was wrong and is now corrected.** A/B/C wrote that a style "themes presentation, it can't
inject content". That's true of the generated path and **false** of a hand-written preamble: LaTeX in the
preamble can typeset content (`\AtBeginDocument`), suppress generated content, and read files. The invariant the
app actually guarantees is narrower — the *body* is app-generated and escaped, and the app never writes user or
model data into the preamble. It cannot run shell commands (no `--shell-escape`). Corrected in `LaTeXStyle`,
`TODO.md` and `ROADMAP.md` rather than left overpromising.

**Tests.** Builder: the override replaces the style block verbatim (geometry, font and accent all gone); the
frame survives with every part the body depends on, and lands *after* the override so `\renewcommand` works; the
body is byte-identical with and without; one override serves both documents with their own classes; blank
overrides fall back; a `%`-comment ending doesn't swallow the next line; the `.tex` carries an uncompilable
override. Two **real `lualatex`** tests: a realistic override (custom `\pageHeader`, accent, geometry) compiles to
a PDF, and a broken one fails with an error rather than hanging. VM: seeding, stash/restore across a toggle,
blank reporting, re-seed, both reverts writing through to the saved row, an unsaved draft touching no storage, and
the failed-preview-keeps-the-render rule. Export side: the failure names the preamble, the built-in escape
unblocks without touching the saved style, and the `.tex` still exports. Suite green (904 cases), build
warning-free.

**On-device.** n/a — no model calls.

---

# v0.7.1 — bug fixes

A **patch release**, scheduled out of `PLANNED.md`'s single `Target: v0.7.1` entry (2026-08-04): **18 verified
defects** from the 2026-08-04 structured audit (five subsystems swept, every candidate re-verified by a pass
instructed to refute it), grouped into Milestones **A–H** by shared root cause. Milestones restart at **A**;
commit as `v0.7.1 : Milestone X Completed`.

## Milestone A — Stale-async writes corrupt visible state  ✅ done  (`Presentation/Application` VM, `Presentation/Search` VM + view; tests in `lib/tests/Presentation`)

**The defects (both re-verified against source before fixing).** **A-1 (high):** `ApplicationWindow` holds
**one** `ApplicationViewModel` across jobs and re-targets purely via `.onChange(of: requestID) → loadSaved(for:)`
— nothing cancels prior work — while `generate(...)` ran as an unstructured `Task` assigning `kit`/`brief`
unconditionally on completion. Generate for job A (tens of seconds), open job B, and A's run finishing late put
**A's résumé under B's header** — and an export **named for B containing A's content**. `loadSaved` clearing
`isGenerating` mid-flight also re-enabled Generate, so a second run for B could be clobbered by A finishing last.
**A-2 (low):** `search` and `fetchFromLink` both assign `results` wholesale with no guard on each other's busy
flag, so a link-fetched job could appear in Results and **silently vanish** when an earlier search landed.

**The fix, A-1 — cancel-and-replace plus a run token.** `ApplicationViewModel` now owns the in-flight generation
(`generationTask`) and a monotonic `generationRun` token, both `@ObservationIgnored`. `generate` cancels the prior
task, bumps the token, and runs the real work in a stored `Task` (awaited, so the sheet's `onGenerated` timing is
unchanged). `loadSaved(for:)` cancels-and-bumps **before** touching state, which is what finally makes its
`isGenerating = false` safe — B's Generate button usable immediately, per the open call. The token is the real
guard, not cancellation: the underlying LLM call may not honour `Task.cancel()`, so every state write is gated on
`run == generationRun` — the kit/brief/`rankOutcome` assignments, the `defer` that clears `isGenerating` (a
superseded run must not re-enable Generate for the job that replaced it), and the `catch` (a dead run's failure
isn't news about the job now shown). One deliberate asymmetry: a superseded run **still persists** its output —
it's keyed to *its own* job's id via the shadowing parameter (persistence was never the corrupt path), and the
generation was paid for.

**The fix, A-2 — one busy flag for every entry point.** `isResultsFlowBusy` (`isSearching || isFetchingLink`)
now gates **all four** results-producing entry points, not just the two the audit named: `canSearch` and
`canFetchLink` cross-gate, and `performSearch` / `fetchFromLink` / `generateFromPastedText` guard at entry — which
also covers `runSavedSearch` and direct programmatic calls. The saved-search Run and paste-generate buttons
disable off the same flag.

**Tests (5 new; suite green at 909, build warning-free).** A `GatedGenProvider` actor blocks generation until
released — and deliberately **ignores cancellation**, so the tests prove the token guard, the stronger property:
a stale run finishing after a re-target can't overwrite B's screen state (while A's output still persists under
A's id); the last targeted job wins regardless of finish order; a superseded run's failure surfaces no error.
Gated job/posting sources hold each Search flow mid-flight and assert the other's gates close, a direct call
no-ops without reaching its source, and the gates reopen after the flow lands.

**On-device.** n/a — pure state discipline, no model-behaviour change.

## Milestone B — Results/search handoff in `RootView`  ✅ done  (`Presentation/App/RootView`, `Presentation/Search` VM, `Presentation/Results` VM; tests in `lib/tests/Presentation`)

**The defects (all three re-verified against source).** One root cause: `RootView`'s
`.onChange(of: search.results)` handed the Results area **wholesale ownership** of the list — plus a navigation
jump — on **every** mutation, and the v0.6.0-K digest mutates `search.results` once per posting. So: **B-1**, the
digest yanked the user back to Results once per digested posting (25–50 times over a minute), also resetting the
destination area's inner sub-tab; **B-2**, a row deleted in Results popped back on the next digest swap, and the
digest's final `persistResults()` re-wrote it to the saved-jobs store; **B-3**, the sidebar badge counted all of
`results.results` while the list shows only `untrackedResults` — "Results 10" over a pane reading "All results
are in your Tracker", with saved jobs counted in two areas at once.

**The fix — separate "a result set landed" from "a row changed."** `SearchViewModel` gains a one-shot
`completedSearchID`, bumped exactly once at each of the three places a **new set** lands (`performSearch`,
`fetchFromLink`, `generateFromPastedText`) — and not on failure, so a failed fetch no longer navigates anywhere.
`RootView` drives the wholesale hand-off + jump off that signal alone. The old `.onChange(of: search.results)`
remains but now only **merges by id** through the existing `ResultsViewModel.applyRefreshed(_:)` path, which
replaces in place and never inserts — a digest swap updates a surviving row live, and an update for a deleted id
falls through. For the persistence half of B-2, deletions now flow *backwards*: `ResultsViewModel` fires
`onResultsRemoved` with the deleted ids (single and bulk paths both), `RootView` wires it to the new
`SearchViewModel.removeResults(_:)`, and the pruned copy means the digest's in-place swap skips the row and its
final re-persist writes only survivors. The badge is one line: `results.untrackedResults.count`.

**Tests (4 new; suite green at 913, build warning-free).** A `GatedEnrichProvider` holds the digest mid-flight
while the test deletes a row: the id is neither resurrected on screen nor re-written to the store, while the
surviving row still gets its standardized description. The signal fires exactly once per landed search despite
multiple digest swaps, fires for a landed link fetch, and doesn't fire for a failed one. Deletions (single and
bulk) notify the removal hook with exactly the deleted ids.

**On-device.** n/a.

## Milestone C — Stable posting identity  ✅ done  (`Data/Models/JobListing` + `ExtractedPosting`, `Data/Jobs/LLMJobSource`; tests in `lib/tests/Data/Models`)

**The defect (re-verified).** A pasted posting's fallback id was
`"pasted-posting-\(description.hashValue)"` — and Swift seeds `Hasher` **per process**, so the same posting got
a different id every launch. That id is the persistence key everywhere (`RankedJob.id`, the saved-jobs upsert,
status, application kit), so a relaunch **orphaned the saved kit and status**, `contains(jobID:)` never matched,
and the store grew a **duplicate row per launch** instead of upserting. Reachable from
`generateFromPastedText()` whenever the URL field is empty.

**The fix (C-A) — one shared normalization, three users.** The fingerprint normalization existed in two copies
(`JobListing.fingerprint` and `LLMJobSource.identifier(for:)`); it's now one static
`JobListing.normalizedFingerprint(title:company:location:)` used by both — behavior-identical, and the existing
tests for each confirmed it — plus the new third user: the pasted fallback id is
`"pasted:" + normalizedFingerprint(…)`. Keying on title/company/location rather than a digest of the description
is deliberate twice over: the description is **LLM-extracted prose** that can word itself differently run to run
(so even a same-launch re-paste would have missed a description hash), and re-pasting the same job *should*
upsert onto the same row — matching the `ai:` prefix precedent and cross-source dedup semantics. URL-backed
postings still key on their URL, unchanged.

**The open call (C-B) — resolved: no migration.** Old `pasted-posting-…` rows were already unreachable across
launches; a re-keying sweep risks colliding with a record the user has since re-created. Re-pasting now lands on
a stable id.

**Tests (1 new; suite green at 914, build warning-free).** Two independently constructed postings agree on the
id (the in-process-expressible half of launch stability) and the literal `"pasted:ios engineer | acme | remote"`
pins the launch-stable shape itself; a reworded description upserts onto the same id while a different role
doesn't; a URL-backed posting still keys on its URL.

**On-device.** n/a.

## Milestone D — Search goal & de-duplication  ✅ done  (`Business/UseCases/SearchAndRankUseCase`, `Business/Ranking/JobRanker`; tests in `lib/tests/Business/UseCases`)

**The defects (all three re-verified).** **D-1 (high):** a desired-result-count goal was silently capped at 20 —
paging dutifully gathered 50+ listings, then `ranker.rank` trimmed to its `shortlistLimit`, and the U-D shortfall
note **never fired** because it was measured on the pre-rank pool (which met the goal) rather than what the user
received. **D-2 (medium):** a title was kept paging only while it returned a *full* page
(`jobs.count >= perPage`) — but JSearch honours its own ~10/page regardless of the requested size, so a
goal-driven search fetched page 1 and stopped, implying "that's all there is" with pages 2–5 available.
**D-3 (medium):** the multi-title merge de-duped by source-specific `id` while `CompositeJobSource` de-dupes by
`fingerprint` — the same posting via Adzuna + JSearch/AI landed twice, saved twice, and burned two shortlist
slots.

**The fixes.** **D-A:** `JobRanker.rank` gains a `limit:` override (`nil` ⇒ the configured default — its other
caller is untouched), and the use case passes `max(boundedGoal, shortlistLimit)`. The shortfall is now measured
on **`ranked.count`** — the count the user actually receives, still before the U-E score filter as documented.
**The cost guard is explicit:** a new `maxRankedResults` (default **100**) bounds both the ranking *and the
paging* — the goal field is free text, so a typed "10000" now pages/ranks up to the ceiling and then reports the
shortfall honestly, instead of either silently returning 20 (before) or shipping thousands of listings to the
model (naïve fix). **D-B:** a title stays active while it returned **anything**; only an empty page retires it —
still bounded by `maxPagesPerTitle` and the goal check. **D-C:** the merge keys on the shared
`mergeKey(_:)` = `fingerprint`, falling back to `id` only when the fingerprint carries no alphanumeric content
(so two degenerate empty-field listings can't collapse); each kept listing retains its own `id` for persistence.

**Test-fixture ripple, embraced:** stub listings sharing title/company/location now (correctly) collapse into
one posting, so fixtures that meant "distinct jobs" got distinct titles (`t40`, `ta`/`tb`) — the one legitimate
behavioural break the fingerprint change surfaced, in `rerunReportsHowManyResultsAreNewSinceLastTime`.

**Tests (5 new; suite green at 919, build warning-free).** A goal of 50 against a 20-shortlist ranker yields
≥50 with no shortfall; a 60-ceiling run against a goal of 400 returns exactly 60 and reports "60 of 400"; a
~10/page source pages on to a 30-goal; the Adzuna/JSearch duplicate collapses to one row keeping the first-seen
id; `mergeKey` falls back to `id` for content-free listings. `pageCapBoundsTheEffort` now lifts the rank ceiling
explicitly so it still tests the page cap.

**On-device.** ⚠️ The cost profile changed as designed: a goal >20 now really ranks up to `maxRankedResults`
(100) jobs per search — the old 20 cap was also a cost guard, and the ceiling is the deliberate replacement.

## Milestone E — LLM layer correctness  ✅ done  (`Infrastructure/Process/ProcessSupport`, `Infrastructure/LLM/ClaudeProcessClient`, `Infrastructure/Tex/LaTeXProcessClient`, `Data/LLM/LLMRouter` + `Prompts`; tests in `lib/tests/Infrastructure/LLM`, `lib/tests/Data/LLM`)

**The defects (all three re-verified).** **E-1:** both process clients drained stdout to EOF *before* touching
stderr — a child that filled the ~64 KB stderr buffer while stdout was still open blocked on its write, stdout
never hit EOF, and the LLM call **hung forever** with no timeout and no cancellation path. **E-2:** the
`searchJobs` prompt described each lead's fields but never named the `leads` wrapper key `GeneratedJobLeads`
decodes — the Claude engine (the default) intermittently shaped the JSON differently, and the fail-soft
composite swallowed the decode error: zero AI leads, no message. **E-3:** `scoreApplication` truncated the
generated résumé to the **job-description** cap (2 000 chars) — the rank-target loop under-scored its own
output, saw tail skills as "missing", burned all 4 rounds, and escalated fidelity into the embellished band the
user never asked for.

**The fixes.** **E-A:** a shared `ProcessSupport.drainToEnd(stdout:stderr:)` reads both pipes concurrently
(stderr on a second queue joined by a `DispatchGroup` before `waitUntilExit()`); both clients use it. The
"consider a cancellation handler" call was taken — for the **Claude client only**, where Milestone A's
cancel-and-replace actually cancels in-flight calls: a `ProcessHolder` bridges `withTaskCancellationHandler` to
`Process.terminate()` (lock-guarded against the register/launch race; a cancel landing in that window is caught
by a post-exit check rather than a kill). And because `LLMRouter` falls back on *any* error, it now **rethrows
`CancellationError` immediately** — a cancelled call must not quietly re-run on the next engine. `lualatex`
compiles keep drain-only (nothing cancels them today). **E-B:** the prompt now opens with *Produce a "leads"
array — one element per suggested opening…*, the same shape as `rank`'s "matches". **E-C:** the résumé is
truncated to `maxPortfolioCharacters` (6 000, matching the grounding injection) instead of 2 000.

**Tests (5 new; suite green at 924, build warning-free).** Two launch **real scripted children**: one floods
~130 KB to stderr then emits a valid envelope — completes in ~0.6 s where the old code deadlocked (a
`.timeLimit` turns any regression into a failure, not a hung suite); one sleeps 30 s and is cancelled —
terminated in ~0.6 s, well under the sleep. The router rethrows `CancellationError` without falling back to a
Claude stub that would have succeeded. The `searchJobs` prompt contains `"leads" array`; a ~3 600-char résumé
reaches the scorer whole while the 6 000 budget still bounds a runaway one.

**On-device.** ⚠️ E-C sends up to ~4 000 more résumé characters per scoring round of the rank-target loop —
that's the fix working (the scorer must see the whole résumé). E-A/E-B are correctness-only.

## Milestone F — Settings wiring  ✅ done  (`Presentation/Settings` view + VMs, `Presentation/App/Composition`; tests in `lib/tests/Presentation/Settings`)

**The defects (both re-verified).** **F-1 (high):** `DocumentStylesViewModel.reloadStyles()` **had no caller** —
the pane opened empty every launch ("No saved styles yet…") even though styles were persisted, the default style
never reached the editor, and Save — finding no loaded selection to match — re-created the style as a **new
row**, filling the library with duplicates. v0.7.0's headline feature looked broken on relaunch. **F-2
(medium):** `llmSourceAvailable` was a `let Bool` snapshotted at launch — changing the `.jobSearch` engine left
the AI source's Configured status and Search-screen availability wrong until relaunch, including a search that
silently returned zero results.

**The fixes.** **F-A:** one line — `.task { await viewModel.reloadStyles() }` on `DocumentStylesView.body`, the
same pattern `PortfolioView`/`SearchView` use. **F-B verified as a consequence of F-A, not a second defect:**
`saveDraft` already updates in place whenever the selected style is present in the loaded library (the existing
`savingWithASelectionUpdatesInPlace` test pins it); the duplicates came purely from the library never loading, so
`existing` never matched. **F-C:** availability is now injected as a **live closure**
(`isLLMAvailable: @Sendable () -> Bool`, pointing at `Composition.isJobSearchEngineAvailable`);
`llmSourceAvailable` became a computed property over it, so `isConfigured(.llm)` reads live, and
`refreshCredentialState()` — which `save()` already runs *after* persisting the engine choice — re-resolves
`configuredProviderIDs` against the just-saved choice. The ordering matters and is what makes the flow work:
save settings → live check reads the new choice → provider set updates → `RootView` pushes it to Search.

**Tests (2 new; suite green, build warning-free).** The relaunch flow end to end at the VM level: a fresh VM
over the same store lists the persisted library after `reloadStyles()`, opens the default style in the editor,
and a save **updates** rather than duplicates. And the live-availability flow: with a closure reading the
settings store (modelling the composition root's), changing the `.jobSearch` engine and saving flips
`isConfigured(.llm)` and the provider set both off and back on — same VM, no relaunch.

**On-device.** n/a.

## Milestone G — Portfolio document state  ✅ done  (`Presentation/Portfolio/ViewModel/PortfolioViewModel`; tests in `lib/tests/Presentation/Portfolio`)

**The defects (both re-verified).** **G-1 (medium):** ✕ Clear on the imported cover letter reset only the slot
(`coverLetterText` + file name) — the **captured** `coverLetterSourceText`/`coverLetterReadableText` survived, so
`grounding` kept feeding the cleared letter to the LLM as the voice/tone exemplar on every generation, and a
save persisted it back into the record. A silent no-op for content. **G-2 (low):** `select(_:)` restored a saved
profile's file names and captured text but never seeded the editable **slots** (`portfolioText` /
`coverLetterText`) — a loaded profile showed "resume.pdf — 0 characters" with **Build disabled**, so rebuilding
from the profile's own document required re-importing the file.

**The fixes.** **G-A** took the first horn of the spec's either/or: `clearCoverLetter()` now clears the captured
text too. The asymmetry with `clearDocument()` (which deliberately leaves `sourceText`/`readableText` alone) is
kept and documented: the résumé's captured text belongs to the *profile* — it's what the profile was distilled
from — while the letter is never distilled, so "clear the letter" must mean "stop using this letter **now**",
not after the next build. **G-B:** `select(_:)` seeds both slots. One deliberate deviation from the spec's
sketch: the slots get the **raw** `sourceText` first (falling back to `readableText` for partial records), not
readable-first — the slot's semantic is "text a rebuild runs on", and tidying happens at build time; seeding the
tidied copy would re-tidy a tidy. Companion fix: `deselect()` now clears `portfolioText` — a gap that was
invisible while `select` never set it, but would otherwise leave the cleared profile's text in the slot.

**Tests (2 new; suite green at 927, build warning-free).** G-1 end to end: build with a letter → grounding
carries it; `clearCoverLetter()` → grounding omits it immediately; save → the persisted record has no letter
text, readable copy, or file name. G-2: save → deselect (slot empty, Build disabled) → select → the raw source
text is back in both slots and Build is enabled with no re-import.

**On-device.** n/a.
