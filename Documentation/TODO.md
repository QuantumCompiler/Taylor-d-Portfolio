# Taylor'd Portfolio — TODO

The **granular, current** working checklist — a segmented breakdown of `ROADMAP.md`.
This is the source of truth for *where we are*. See `CLAUDE.md` → "Working process"
for how this file, `ROADMAP.md`, and `SPEC.md` fit together.

**How to use it:** work top-down through the milestones. When you finish an item,
check it off here **and** tick the matching line in `ROADMAP.md`. Keep the
"Current focus" line below pointing at the next unchecked item so a fresh session
can pick up instantly. Add newly-discovered sub-tasks as checkboxes in the right
milestone.

> **Current focus:** Milestone E — Job seam (`lib/src/Infrastructure/Net`,
> `lib/src/Data/Jobs`). The LLM gateway is complete and tested; next is the HTTP
> client, the `JobSource` protocol, and `AdzunaJobSource`.

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

## Milestone E — Job seam  (`lib/src/Infrastructure/Net`, `lib/src/Data/Jobs`)

- [ ] `HTTPClient` — thin `URLSession` wrapper (Infrastructure/Net)
- [ ] `JobSource` protocol — returns `[JobListing]`, no API types leak past it
- [ ] `AdzunaJobSource` — concrete Adzuna implementation
- [ ] Tests with a stubbed `HTTPClient`

## Milestone F — Settings  (`lib/src/Infrastructure/Store`, `lib/src/Data/Settings`)

- [ ] `KeyValueStore` — UserDefaults / keychain (Infrastructure/Store)
- [ ] `AppSettings` — llmChoice, Adzuna app_id/app_key, country code
- [ ] `SettingsStore` — load/save `AppSettings`

## Milestone G — Business: ranking & use cases  (`lib/src/Business`)

- [ ] `JobRanker` (Business/Ranking): `prefilter(...)` cheap shortlist +
      batched `rank(...)` → `[RankedJob]`
- [ ] `BuildProfileUseCase` (Business/UseCases)
- [ ] `SearchAndRankUseCase`
- [ ] `GenerateApplicationUseCase`
- [ ] Use-case + ranker tests (`Tests/Business/*`)

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
