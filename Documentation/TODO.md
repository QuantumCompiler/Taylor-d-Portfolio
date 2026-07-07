# Taylor'd Portfolio — TODO

The **granular, current** working checklist — a segmented breakdown of `ROADMAP.md`.
This is the source of truth for *where we are*. See `CLAUDE.md` → "Working process"
for how this file, `ROADMAP.md`, and `SPEC.md` fit together.

**How to use it:** work top-down through the milestones. When you finish an item,
check it off here **and** tick the matching line in `ROADMAP.md`. Keep the
"Current focus" line below pointing at the next unchecked item so a fresh session
can pick up instantly. Add newly-discovered sub-tasks as checkboxes in the right
milestone.

> **Current focus:** Milestone H — Presentation screens
> (`lib/src/Presentation/<Screen>/{View,ViewModel}`). The entire non-UI stack is done
> and tested; next is the Portfolio / Search / Results / Application / Settings screens
> and their `@MainActor @Observable` ViewModels.

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

## Milestone H — Presentation screens  (`lib/src/Presentation/<Screen>/{View,ViewModel}`)

- [ ] `Portfolio` — paste portfolio → build profile
- [ ] `Search` — role/location/salary params → run search
- [ ] `Results` — ranked list; `RankedRow` lives in `Results/View`
- [ ] `Application` — generate resume + cover letter (sheet)
- [ ] `Settings` — LLM choice, Adzuna keys
- [ ] `LandingViewModel` — wire the "Get Started" button to route into Search

## Milestone I — Composition root wiring  (`lib/src/Presentation/App/App.swift`)

- [ ] Assemble: Infrastructure clients → Data gateways → Business use cases →
      ViewModels, injected via `.environment`
- [ ] Replace the static landing entry with real navigation between screens

## Milestone J — End-to-end vertical slice

- [ ] Portfolio → profile → search → ranked results → generate resume/cover letter,
      end to end, on-device, with Claude as fallback  ← closes v1
