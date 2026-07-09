# Taylor'd Portfolio — TODO

The **granular, current** working checklist — a segmented breakdown of `ROADMAP.md`.
This is the source of truth for *where we are*. See `CLAUDE.md` → "Working process"
for how this file, `ROADMAP.md`, and `SPEC.md` fit together.

**How to use it:** work top-down through the milestones. When you finish an item,
check it off here **and** tick the matching line in `ROADMAP.md`. Keep the
"Current focus" line below pointing at the next unchecked item so a fresh session
can pick up instantly. Add newly-discovered sub-tasks as checkboxes in the right
milestone.

> **Current focus:** v1 core is **complete** (Milestones A–J done + document import).
> Now working **v2 — reliability**. Done so far: **K** (build-time Adzuna creds),
> **M-B** (two-stage structured generation), **N** (multi-title search + field autocomplete),
> **O-A** (job-detail view), **M-A** (generate from a job-posting URL), **O-B** (persist searched
> listings — first SwiftData slice), **O-C** (persist generated `ApplicationKit`, reopen without
> regenerating). **Milestone O is fully done.** Next per the suggested order is **Milestone P**
> (application status tracker — mark applied with an automatic date, flag interview/offer/outcome;
> builds on O's persistence). Other
> largely-independent milestones: **Milestone L** (prefer AFM 3 Core Advanced) is gated on spike **L0** — confirm
> whether an app can select/verify the Core Advanced tier before building on it;
> **Milestone M** (job-URL input + AGENT.md-grade generation prompts) can start with
> M-B (better prompts) since it helps regardless of input source; **Milestone N**
> (multi-title search + field autocomplete) improves search recall/UX once a profile
> is loaded; **Milestone O** (save pulled listings + a job-detail view to read the full
> description); **Milestone P** (application status tracker — mark applied with an
> automatic date, flag interview/offer/outcome). Sensible order: K → M-B → N → O-A →
> M-A → O-B → O-C → P, with L0 run whenever and L2 after L0's answer.

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
Milestone K (build-time creds) and Milestone L (AFM 3 model) are independent —
K can proceed immediately; L is gated on a spike (L0 below).

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

## Milestone L — Prefer AFM 3 Core Advanced on-device  (`lib/src/Infrastructure/LLM`)

Goal: target the AFM 3 generation and prefer the 20B sparse **Core Advanced** model on
capable Macs, degrading to AFM 3 Core (3B) on older Apple-Intelligence Macs and to
Claude when on-device is unavailable. This is a quality upgrade to the primary engine —
better profiles, ranking, and grounded generation, and fewer Claude escalations.

- [ ] **L0 — SDK spike (BLOCKING; do this first).** Against the macOS 27 / AFM 3 SDK,
      determine whether an app can: (a) request Core Advanced explicitly, (b) query which
      on-device tier will be served, or (c) neither (tier is purely device-driven). The
      public framework today is `SystemLanguageModel.default` (+ use-case initializers),
      not a by-name picker, and Core-vs-Core-Advanced is understood to be an OS/hardware
      decision. **Record the finding here** — the rest of this milestone forks on it.
      Check: macOS 27 SDK headers for `SystemLanguageModel`, WWDC 2026 session 339
      ("Bring an LLM provider to the Foundation Models framework") and any on-device
      tier-selection session, and the updated Foundation Models docs.
- [ ] **L1 — Target bump.** Move the on-device path to the AFM 3 generation
      (macOS 27 target as needed). Verify `FoundationModelsClient` still builds and its
      `availability` mapping is complete (`.deviceNotEligible` / `.appleIntelligenceNotEnabled`
      / `.modelNotReady` / unknown).
- [ ] **L2a — IF the app can select/verify the tier:** encode the request/verification
      in `FoundationModelsClient` behind the existing `availability` surface; expose a
      `modelTier` (e.g. `.coreAdvanced` / `.core` / `.unavailable`) the router and UI can
      read. Prefer Core Advanced, fall back to Core, then Claude.
- [ ] **L2b — IF tier is OS/device-driven only:** this milestone becomes "target AFM 3 +
      guarantee graceful degradation." Document that tier selection is OS-driven; the
      client's job is availability + degradation, not model-name selection. No by-name
      API is invented.
- [ ] **L3 — Degradation is required, not optional.** Ensure the router still falls back
      cleanly (on-device unavailable → Claude) and that a Core-only Mac produces correct
      output. Extend `LLMRouterTests` coverage for the availability/degradation paths
      that can be unit-tested with stubs.
- [ ] **L4 — Docs.** SPEC ("On-device first" principle + the AFM 3 tiers and the degrade
      path), CLAUDE.md (Stack: name AFM 3 Core / Core Advanced, silicon requirement, and
      that tier selection is OS-driven unless L0 proved otherwise).

Note: macOS-only means more users clear the Core Advanced silicon bar than on iPhone,
but not all — the degrade path is required. Pairs naturally with adopting the native
`LanguageModel` protocol seam (ROADMAP backlog), which the L0 spike will also inform.

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

## Milestone P — Application status tracker  (`Data/Models`, `Business/UseCases`, Infrastructure persistence, Tracker screen)

Goal: record where each job stands. **Mark as applied** with an **automatic** date stamp,
and flag later stages — interview offered, offer received, rejected, accepted/declined,
withdrawn — each auto-stamped when set. A tracker view lists applied jobs by stage; a
status badge appears on results/detail. Builds on Milestone O's persistence. Consistent
with the human-in-the-loop principle (the user applies themselves, then records it).

### P-A — Status model + auto date stamps

- [ ] **`ApplicationStatus` domain type (`Data/Models`).** `nonisolated`, `Codable`,
      `Equatable`, `Sendable` like the other models. Model a current stage plus dated
      milestones — e.g. a `Stage` enum (`saved` / `applied` / `interviewing` / `offer` /
      `accepted` / `declined` / `rejected` / `withdrawn`) and dates for the key
      transitions (`appliedDate`, `interviewDate`, `offerDate`, `closedDate`), plus an
      optional free-text `note`. Decide enum-with-dates vs. an event log
      (`[StatusEvent]`) during design — event log keeps history for free; enum+dates is
      simpler. Default: enum + optional dated milestones.
- [ ] **Auto-stamp on transition.** Setting a stage stamps `Date()` automatically for that
      milestone — the user never types a date. Marking applied sets `appliedDate = now`;
      flagging an interview/offer stamps the corresponding date. (Manual date editing is an
      optional later touch, not v1 of this feature.)
- [ ] **Tests.** `DomainModelTests`: `ApplicationStatus` Codable round-trip; a transition
      helper stamps the right dated milestone and advances the stage.

### P-B — Persist status (extends O's repository)

- [ ] **Store status by job id.** Extend Milestone O's persistence port / `SavedJobsRepository`
      to save + fetch `ApplicationStatus` keyed by `JobListing.id` (mapped to/from an
      Infrastructure `@Model`, same `@Model`-stays-in-Infrastructure rule). Upsert per job.
- [ ] **`MarkStatusUseCase` (Business).** A `callAsFunction` use case (or a small set) that
      applies a transition — stamps the date, persists via the repository. Keeps ViewModels
      off the repository directly.
- [ ] **Fetch applied set.** Repository query for "jobs with a status" (and by stage) to
      back the tracker list and any "already applied" checks.
- [ ] **Tests.** Repository round-trip for status (save → fetch by id; upsert replaces);
      `MarkStatusUseCase` stamps + persists.

### P-C — Tracker UI + status affordances

- [ ] **Status control on the detail view.** On the job-detail view (O-A), a "Mark as
      applied" button and controls to advance stage (interview / offer / outcome). Show the
      stamped dates read-only. Marking applied is one tap; the date is automatic.
- [ ] **Tracker screen (`Tracker/View` + `Tracker/ViewModel`).** A `@MainActor @Observable`
      VM lists jobs that have a status, grouped/sortable by stage, showing company/role +
      current stage + relevant date. Tapping a row opens the detail.
- [ ] **Status badge on `RankedRow`.** A small badge (e.g. "Applied · Jun 12", "Interview")
      on results rows for jobs that have a status, so state is visible without opening them.
- [ ] **Navigation.** Add the Tracker as a tab (or a section) in `RootView`'s `TabView`;
      wire its VM through `Composition`.
- [ ] **Tests / previews.** `TrackerViewModel` suite (lists by stage, ordering); detail
      status-control VM behavior (mark applied stamps + persists via a stub repository);
      previews with sample statuses.
- [ ] **Docs.** SPEC (add the tracker to the core flow / scope; note it stays
      human-in-the-loop, no auto-submission); CLAUDE.md (add `ApplicationStatus` to Key
      types, the Tracker screen to Presentation, `MarkStatusUseCase` to Business, and the
      repository's status mapping).

Note: P-A/P-B/P-C layer bottom-up (model → persistence → UI). The whole milestone sits on
Milestone O's persistence port — do O-B first. Keeps the "no auto-submission" non-goal
intact: this records what the user did, it doesn't act on job sites.
