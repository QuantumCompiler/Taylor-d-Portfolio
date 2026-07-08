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
> Now working **v2 — reliability**. **Milestone K (build-time Adzuna creds) is ✅ done.**
> Next per the suggested order is **Milestone M-B** (two-stage, structured generation
> prompts — helps every generation regardless of input source). Other largely-independent
> milestones: **Milestone L** (prefer AFM 3 Core Advanced) is gated on spike **L0** — confirm
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

## Milestone M — Job-URL input + AGENT.md-grade generation  (`Prompts`, `Data/Jobs`, `LLMProvider`, Presentation)

Goal: port the discipline of Taylor's hand-built LaTeX résumé agent (`AGENT.md`) into
the app — (M-A) generate an application from a **job posting URL**, and (M-B) upgrade
the generation prompts from a single shot to a **structured target-brief → tailored
output** flow. Same "never fabricate" guardrail the SPEC already states. Out of scope:
AGENT.md's LaTeX/PDF/`.docx` build toolchain (that's the "Export" fast-follow).

### M-A — Generate from a job URL

- [ ] **`JobPostingSource` seam (Data/Jobs).** New port: fetch + extract a *single*
      posting from a URL → `JobListing` (distinct from `JobSource`, which searches many).
      Reuse `HTTPClient` for the fetch. Keep any page-specific parsing private to the impl.
- [ ] **Fetch + extract impl.** Fetch the page HTML; extract company, role title,
      requirements, stack, and stated values. HTML is messy → an LLM extraction pass is
      the pragmatic route (a new `Prompts.extractPosting(...)` + an `LLMProvider` method,
      or reuse the brief step in M-B). Strip boilerplate before sending to bound tokens.
- [ ] **Fail loudly, don't guess.** If the page is JS-gated, paywalled, empty, or blocks
      fetching, return a clear "couldn't read this posting — paste the text instead"
      error. **Never** invent a role from a failed fetch (AGENT.md guardrail).
- [ ] **Presentation affordance.** Let the user paste a URL (Search screen or a new
      "From a link" entry) → runs fetch/extract → drops into the same rank/generate flow.
      Also keep a plain "paste the posting text" fallback for blocked pages.
- [ ] **Composition + sandbox.** Wire `JobPostingSource` in `Composition`. URL fetch needs
      the outgoing-connections entitlement (already on for Adzuna) — confirm it covers
      arbitrary hosts, not just the Adzuna API.
- [ ] **Tests.** `JobPostingSource` against a stubbed `HTTPClient` (good HTML → fields;
      blocked/empty → the paste-instead error); extraction-prompt shape in `PromptsTests`.

### M-B — Two-stage, structured generation prompts (from AGENT.md §1, §5)

- [ ] **Target brief step.** Add `Prompts.buildTargetBrief(job:)` (+ an `LLMProvider`
      method, or an internal step of `generateApplication`) that distils: company, exact
      role title, top 5–8 **must-have vs. nice-to-have** keywords, tech stack, domain,
      and stated mission/values. This is AGENT.md Step 1's "internal brief."
- [ ] **Map to truth + gaps.** In the generation prompt, instruct the model to map each
      brief signal to the closest TRUE profile fact and to **list gaps** (requirements the
      candidate lacks) rather than papering over them — feeds the existing
      `ApplicationKit.gapNote`.
- [ ] **Tailored résumé prompt.** Ask for a role-specific headline/summary and
      experience/projects re-angled to foreground overlap — **feature the single best-fit
      item** (AGENT.md's "lead with the most relevant project"). Reorder/rephrase real
      experience only.
- [ ] **Three-section cover letter.** Restructure `generateInstructions` /
      `generateApplication` so the cover letter follows AGENT.md's rhythm: *About Me* /
      *Why \<company\>* / *Why Me* (the middle section is the company-specific one that
      pays off the brief research). Keep it grounded and specific; no invented metrics.
- [ ] **Keep engines in lockstep.** All new text lives in the shared `Prompts` enum so
      `FoundationModelsProvider` (constrained decoding) and `ClaudeCodeProvider` (JSON)
      stay identical (existing convention). If a brief becomes its own `@Generable`
      /`Codable` type, it conforms to both like the other structured types.
- [ ] **Bound inputs.** Extend the `maxPortfolioCharacters` / `maxDescriptionCharacters`
      truncation to any new fetched-posting / brief text so on-device context stays bounded.
- [ ] **Tests.** `PromptsTests` for brief fields + the three cover-letter sections + the
      gap/feature-project instructions; provider decode tests if the brief is a new type.
- [ ] **Docs.** SPEC (note the URL input path in "Core user flow" / v1-scope-plus, and the
      structured generation approach under "Grounded generation"); CLAUDE.md (add
      `JobPostingSource` to the Data/Jobs seam list and the layer map; note the two-stage
      generation in the LLM-seam description).

Note: M-A and M-B compose but are separable — M-B (better prompts) helps every generation
regardless of input source, so it can land first; M-A (URL input) is the new entry path.
The AGENT.md file itself is Taylor's ground-truth reference for tone and the tailoring
"levers" (which project to feature for which role type) — worth keeping alongside SPEC.

## Milestone N — Multi-title search + field autocomplete  (`SearchAndRankUseCase`, `Data/Jobs` or `Data/Search`, `SearchViewModel`, Search UI)

Goal: once a profile is loaded, let the user run **several role titles in one search**
(iOS Developer, iOS Engineer, Software Developer, Software Engineer, …) and **autocomplete**
the input fields, seeded from the loaded profile. More relevant recall, less typing.
This is a search-quality/UX item — could sit in fast-follow instead of v2 if you'd rather;
kept here since it directly touches the reliability of getting good results.

### N-A — Multiple title searches, merged and ranked once

- [ ] **Fan-out in the use case.** Extend `SearchAndRankUseCase` to accept multiple
      titles (a `[String]` of titles, or a small `JobSearchRequest { titles, location,
      salaryMin }`) sharing one location/salary. Expand → one `JobQuery` per title →
      run the searches, **concurrently** (`withThrowingTaskGroup`), then flatten.
- [ ] **Dedupe.** Merge results and dedupe by `JobListing.id` (preserve first occurrence),
      so the same posting returned by two title searches isn't ranked/shown twice.
- [ ] **Rank once.** Feed the merged, deduped set into `ranker.rank(_:for:)` a single time
      — the existing prefilter/shortlist already caps the LLM re-rank, so merging first is
      correct and keeps cost bounded.
- [ ] **`JobQuery` stays single.** Do **not** add a title list to `JobQuery` — it remains
      the one-`what` unit a `JobSource` understands. The fan-out is orchestration above the
      seam, so `JobSource` / `AdzunaJobSource` are unchanged.
- [ ] **Concurrency + rate-limit guard.** Cap the number of concurrent title searches
      (Adzuna free-tier rate limits) — e.g. a small bounded task group or a max-titles
      limit. Decide + document the cap.
- [ ] **Partial-failure policy.** If one title's search throws (e.g. transient HTTP),
      prefer to continue with the successful titles and surface a soft note
      ("couldn't search 'X'") rather than failing the whole run. Only fail hard if *all*
      searches fail. Wire the note into `SearchViewModel.errorMessage` / a warning field.
- [ ] **ViewModel.** `SearchViewModel` gains `titles: [String]` (the chips) plus the
      in-progress text field; `canSearch` requires a profile + at least one title. Location
      and salary stay single, shared.
- [ ] **Tests.** `UseCaseTests` / a new suite: two titles → merged+deduped results ranked
      once; duplicate `id` across titles collapses; one failing title still returns the
      rest with a note; empty titles handled.

### N-B — Field autocomplete (seeded by the loaded profile)

- [ ] **Suggestion source (Data).** New `SuggestionProvider` (or pure helper) that yields
      title suggestions from the loaded `CandidateProfile` (`targetTitles`, `coreSkills`)
      **plus a small curated static vocabulary** of common role titles; and location
      suggestions from a static list (+ "Remote"). On-device, no network — keep it in Data
      so it's testable and later swappable (Adzuna categories / embeddings).
- [ ] **Pre-fill from profile.** When a profile loads, seed the title chips/suggestions
      from `profile.targetTitles` (the LLM already produces these) so the user starts from
      sensible defaults.
- [ ] **Title input UI.** Chip/token input on the Search screen with a suggestions
      dropdown (macOS SwiftUI has no first-class token field — build a suggestions list /
      chips, or use `.searchable` suggestions). Selecting a suggestion adds a chip; free
      text is allowed too (a title need not be in the vocab).
- [ ] **Location autocomplete + salary presets.** Location field suggests from the static
      list; salary offers preset brackets (a picker/stepper), not free-text autocomplete.
- [ ] **Tests.** `SuggestionProvider` (profile-derived + static merge, dedupe, ordering);
      `SearchViewModelTests` for chip add/remove, profile-seeded defaults, and `canSearch`.
- [ ] **Docs.** SPEC ("Search → listings" flow note: multiple titles + autocomplete);
      CLAUDE.md (the `SuggestionProvider` seam + the use-case fan-out; note `JobQuery`
      stays the single-search unit).

Note: N-A and N-B are separable — N-A (multi-search) delivers value even with a plain
text field; N-B (autocomplete) helps single or multi search. Composes with Milestone M:
a URL-extracted posting (M-A) can pre-fill a title chip here.

## Milestone O — Save pulled listings + job-detail view  (Presentation detail view; Infrastructure persistence + `Data` repository)

Goal: persist what a search pulls down (each `JobListing` + its `JobMatch`) and let the
user **read the full job description from the UI**. Closes a real gap — the pulled
`description` isn't shown anywhere today (`RankedRow` shows only title/company/location +
the match reason). O-A is the viewing part (in-session, no persistence); O-B is the
persistence part (the first concrete slice of the SwiftData fast-follow).

### O-A — Job-detail view (Presentation; no persistence needed)

- [ ] **`JobDetailView`.** A read-only detail screen/sheet for one `RankedJob`: full
      `JobListing.description`, `salary` (via `SalaryRange`), a "View original posting"
      link when `JobListing.url` is present, and the match score/reason + matched/missing
      skills from `JobMatch`. Pure display — can be VM-less (value-driven) or a tiny VM if
      it grows actions (save/unsave, open link).
- [ ] **Wire into Results.** From `ResultsView`, tapping a row opens the detail (a sheet,
      or a `NavigationSplitView` detail pane on macOS). Keep the existing "generate
      application" action reachable from the detail (it already lives in `ApplicationSheet`).
      If saved materials exist for the job (O-C), show them here and offer "view" (no
      regeneration) alongside "regenerate."
- [ ] **HTML handling.** Adzuna descriptions can contain HTML — render readable text
      (strip/convert on display, or on ingest; decide once and note it). Guard against
      empty/very long descriptions in layout.
- [ ] **Tests / previews.** Detail view `#Preview` with `Preview.sampleRankedJobs`; if a
      VM is added, a small `@MainActor @Suite` for it.

### O-B — Persist searched listings (first SwiftData slice)

- [ ] **Persistence port.** Declare a persistence capability behind a protocol in the
      layer that owns it (mirrors `KeyValueStore` for settings) — e.g. a `JobStore` /
      `SavedJobsRepository` port. Keep domain `JobListing` / `RankedJob` as clean `Codable`
      structs.
- [ ] **SwiftData impl (Infrastructure).** A SwiftData-backed store: define `@Model`
      class(es) for the stored listing + match, **map to/from the domain structs** so
      `@Model` never leaks upward into Data/Business/Presentation.
- [ ] **Data-layer repository.** A gateway that maps stored rows ↔ domain types and
      exposes save / fetch (and later, "seen?" checks). Save the merged, ranked results
      after a search completes.
- [ ] **Composition + lifecycle.** Build the SwiftData container/context in the
      composition root; inject the repository into the search flow (or a new use case,
      e.g. `SaveResultsUseCase`) and into whatever screen lists saved jobs.
- [ ] **Dedupe / upsert.** Key stored listings by `JobListing.id` (upsert, so re-pulling
      the same posting updates rather than duplicates) — reuses the N-A dedupe identity.
- [ ] **Tests.** Repository round-trip against an in-memory SwiftData container
      (save → fetch → equals domain value; upsert by id collapses duplicates).
- [ ] **Docs.** SPEC (revise "No persistence beyond the current session" — pulled
      listings now persist; note the detail view in the flow); CLAUDE.md (add the
      persistence port + SwiftData impl to Infrastructure and the repository to Data in
      the layer map; note the `@Model`-stays-in-Infrastructure rule).

### O-C — Persist generated materials with the posting

- [ ] **Store `ApplicationKit` by job id.** Extend the persistence port / repository to
      save an `ApplicationKit` (resumeMarkdown, coverLetter, gapNote) linked to its
      `JobListing.id`. SwiftData: either a relationship from the stored job to a stored
      kit, or a kit `@Model` keyed by job id — mapped to/from the domain `ApplicationKit`
      struct (no `@Model` in the domain, same rule as O-B).
- [ ] **Save after generate.** After `GenerateApplicationUseCase` produces a kit, persist
      it — either in `ApplicationViewModel.generate` via the repository, or a small
      `SaveApplicationUseCase`. Latest-wins per job to start (upsert by job id); note that
      keeping a history of regenerations is a possible later extension.
- [ ] **Load saved on open.** When the detail/Application view opens for a job that already
      has a saved kit, load and show it instead of auto-generating — the user explicitly
      regenerates if they want fresh output. Avoids a redundant LLM call (cost/latency win)
      and makes prior output durable.
- [ ] **Tests.** Repository round-trip for `ApplicationKit` (save → fetch by job id →
      equals domain value; upsert replaces prior kit for the same job); an
      `ApplicationViewModel` test that generating persists, and that opening a job with a
      saved kit loads it without calling the provider (stub asserts no generate call).
- [ ] **Docs.** Fold into the O-B doc updates — SPEC (generated materials persist with the
      posting) and CLAUDE.md (repository maps `ApplicationKit` too).

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
