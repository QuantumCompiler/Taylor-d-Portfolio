# CLAUDE.md

Project context for Claude Code. Read this before making changes. See `SPEC.md`
for what we're building, `ROADMAP.md` for the high-level plan, and `TODO.md` for
the granular, current checklist of where we are. **Starting a fresh session? Read
`TODO.md` first — its "Current focus" line tells you exactly where to pick up.**

## What this is

Taylor'd Portfolio: a native macOS app that searches jobs, ranks them against the user's
portfolio, and generates a tailored resume + cover letter for a chosen job. No
auto-submission — the user applies themselves.

## Stack & environment

- **UI:** SwiftUI, macOS 26 (Tahoe) target, Xcode 26.
- **Primary LLM:** Apple Foundation Models (`import FoundationModels`), on-device.
- **Secondary LLM:** Claude Code headless — `claude -p "<prompt>" --output-format json`.
- **Job source:** Adzuna REST API (free tier) to start.
- **Persistence:** none yet; SwiftData planned (see ROADMAP).

Requires an Apple-Intelligence-capable Mac with Apple Intelligence turned on for
the on-device model. `claude -p` requires Claude Code installed and authenticated.

## Architecture

Four-layer clean architecture with an MVVM presentation layer.

### Layers and the dependency rule

A pyramid — Presentation is the tip, Infrastructure the base:

```
  Presentation    SwiftUI Views + ViewModels (MVVM)
  Business        Use cases, domain rules (JobRanker)
  Data            Models, gateways/repositories, prompts
  Infrastructure  Raw plumbing: FM, Process, HTTP, embeddings, stores
  ───────────────────────────────────────────────────────────────
  dependencies point DOWN only
```

**The rule:** a layer may import its own layer and any layer *below* it, and must
never import a layer above it. ("Below" means any lower layer, not only the
adjacent one — e.g. Presentation may read domain models that live in Data.)

**How dependency inversion stays legal under this rule:** a protocol is declared
in the *lower* layer that owns the capability, and higher layers depend on that
protocol. Every arrow points down; nothing below ever imports something above.
So `TextGenerating` (the raw generation port) is declared in Infrastructure and
implemented there; Data's `LLMProvider` (domain-shaped) is declared in Data and
Business depends on it. No implementation reaches upward to conform to a protocol
above it.

### What lives in each layer

**Presentation** — SwiftUI Views (dumb, declarative) and one `@Observable`,
`@MainActor` ViewModel per screen (`PortfolioViewModel`, `SearchViewModel`,
`ResultsViewModel`, `ApplicationViewModel`, `SettingsViewModel`). ViewModels hold
view state and call Business use cases; they hold no business rules and do no data
access. `Taylor_d_PortfolioApp` is the composition root (below). This replaces the single
`AppModel` from early sketches — split it into per-screen ViewModels.

**Business** — use cases that orchestrate the pipeline (`BuildProfileUseCase`,
`SearchAndRankUseCase`, `GenerateApplicationUseCase`) and pure domain logic like
`JobRanker`. No SwiftUI, no `Process`, no `URLSession`. Depends only on Data.

**Data** — domain models plus the gateways that turn raw plumbing into domain shapes:
- Models: `CandidateProfile`, `JobListing`, `JobMatch`, `ApplicationKit`,
  `JobQuery`, `RankedJob`.
- LLM gateway: `LLMProvider` (protocol) + `FoundationModelsProvider` +
  `ClaudeCodeProvider` + `LLMRouter` + `Prompts`.
- Job gateway: `JobSource` (protocol) + `AdzunaJobSource`.
- Search suggestions: `SuggestionProvider` (Data/Search) — profile-seeded starting
  titles + static locations + salary presets; pure, on-device. Common role titles are
  **user-curated and persisted** via `RoleTitleStore` (Data/Search, on `KeyValueStore`),
  not a static vocabulary.
- Retrieval gateway: `Retriever` (protocol) + impl (roadmap).
- `AppSettings` (`llmChoice` + `adzunaCountry`) + `SettingsStore`. Adzuna
  credentials are **not** here — they're baked in at build time via `AppConfig`.
Depends only on Infrastructure ports.

**Infrastructure** — lowest-level, domain-agnostic plumbing behind small protocols
declared here: `TextGenerating` + `FoundationModelsClient` (wraps
`LanguageModelSession`, `@Generable`, availability) + `ClaudeProcessClient` (runs
`claude -p`, unwraps `result`, strips fences); `HTTPClient` (URLSession wrapper);
`EmbeddingClient` (`NLContextualEmbedding`, roadmap); `KeyValueStore` (UserDefaults
/ keychain); `AppConfig` + `BundleAppConfig` (build-time secrets read from the
bundle Info.plist — the Adzuna keys, injected from a gitignored `Secrets.xcconfig`).

### The three seams, now placed in layers

- **LLM seam** — `LLMProvider` (Data), task-oriented (not generic `generate<T>`)
  because the engines structure output differently: `FoundationModelsProvider`
  uses constrained decoding against `@Generable` types; `ClaudeCodeProvider` asks
  for JSON and decodes. `LLMRouter` picks one from `AppSettings.llmChoice` (`auto`
  = on-device first, fall back to Claude). Shared prompts in `Prompts`; structured
  types are both `Generable` and `Codable`. **Generation is two-stage** (AGENT.md
  discipline): `buildTargetBrief(for:)` distils the posting into a `TargetBrief`,
  then `generateApplication(for:profile:brief:)` tailors against it. Both are
  `LLMProvider` methods; `GenerateApplicationUseCase` orchestrates the two calls. Availability via
  `SystemLanguageModel.default.availability` → `.available` /
  `.unavailable(.deviceNotEligible | .appleIntelligenceNotEnabled | .modelNotReady)`.
- **Job seam** — `JobSource` (Data). Implement it (Adzuna, JSearch, USAJOBS…),
  return `[JobListing]`, don't leak API-specific types past the protocol.
- **Ranking funnel** — `JobRanker` (Business): `prefilter(...)` (cheap shortlist;
  upgrade to embedding similarity) then batched `rank(...)` → `[RankedJob]`.
- **Multi-title fan-out** — `SearchAndRankUseCase` (Business) expands a
  `JobSearchRequest` (many titles, shared location/salary) into one `JobQuery` per
  title, runs them with bounded concurrency (Adzuna rate-limit guard), merges and
  de-dupes by `JobListing.id`, then ranks the combined set **once**. A single title's
  failure is a soft note (`Output.failedTitles`); it only throws if *all* fail.
  `JobQuery` stays the single-`what` unit the seam understands.

### Composition root

`Taylor_d_PortfolioApp` (Presentation) is the one place allowed to reference every layer, to
assemble it: build Infrastructure clients → wrap them in Data gateways → inject
those into Business use cases → inject use cases into ViewModels → inject
ViewModels via `.environment`. All wiring lives here; nothing else news-up a
lower layer.

## Suggested file layout

One top-level folder per layer:

```
Taylor'd Portfolio/
  Presentation/
    App/            Taylor_d_PortfolioApp (composition root)
    Landing/        one folder per screen; each screen holds two subfolders:
      View/           the SwiftUI view(s)                  — LandingView
      ViewModel/      the @MainActor @Observable ViewModel — LandingViewModel
    Portfolio/, Search/, Results/, Application/, Settings/  (same View/ + ViewModel/ shape;
                  e.g. Results/View holds ResultsView + RankedRow, Application/View the sheet)
  Business/
    UseCases/     BuildProfileUseCase, ImportPortfolioUseCase, SearchAndRankUseCase,
                  GenerateApplicationUseCase
    Ranking/      JobRanker
  Data/
    Models/       CandidateProfile, JobListing, JobMatch, TargetBrief, ApplicationKit,
                  JobQuery, JobSearchRequest, RankedJob
    LLM/          LLMProvider, FoundationModelsProvider, ClaudeCodeProvider,
                  LLMRouter, Prompts
    Jobs/         JobSource, AdzunaJobSource
    Search/       SuggestionProvider, RoleTitleStore
    Retrieval/    Retriever            (roadmap)
    Settings/     AppSettings, SettingsStore
  Infrastructure/
    LLM/          TextGenerating, FoundationModelsClient, ClaudeProcessClient
    Net/          HTTPClient
    Documents/    DocumentTextExtractor, PlatformDocumentTextExtractor
    Config/       AppConfig, BundleAppConfig   (build-time secrets ← Info.plist ← Secrets.xcconfig)
    Embedding/    EmbeddingClient      (roadmap)
    Store/        KeyValueStore
```

Enforce the dependency rule at review time. Optional but recommended later: make
each layer its own SwiftPM target so the compiler enforces "no upward imports"
for you.

## Key types

- `CandidateProfile` (`@Generable`, `Codable`): seniority, yearsExperience,
  coreSkills, domains, targetTitles, summary.
- `JobListing` (`Codable`): id, title, company, location, description, url, salary.
- `JobMatch` (`@Generable`, `Codable`): jobId, score (0–100), reason,
  matchedSkills, missingSkills.
- `TargetBrief` (`@Generable`, `Codable`): company, roleTitle, mustHaveKeywords,
  niceToHaveKeywords, techStack, domain, missionValues — the stage-1 distillation
  of a posting that stage-2 generation tailors against.
- `ApplicationKit` (`@Generable`, `Codable`): resumeMarkdown, coverLetter, gapNote.

## Conventions

- Keep provider prompts in the shared `Prompts` enum — never let the two engines
  drift apart.
- Any structured output type must conform to both `Generable` and `Codable`.
- Bound inputs sent to the on-device model (limited context) — truncate long
  portfolios/descriptions.
- New capabilities go behind a protocol if there's any chance of a second
  implementation (LLM engines, job sources, exporters).
- Respect the layer dependency rule: never import upward. A protocol lives in the
  layer that owns the capability; higher layers depend on it.
- Views stay dumb. All view state and user intent live in a `@MainActor`
  `@Observable` ViewModel, which calls Business use cases only — no `URLSession`,
  `Process`, or `LanguageModelSession` in the Presentation layer.
- Wire dependencies only in the composition root (`Taylor_d_PortfolioApp`).
- ViewModels are `@MainActor`; do async work in use cases off the main actor and
  assign results back on the main actor.

## Hard rules for generated content

- Resumes and cover letters must be grounded strictly in the user's portfolio.
  **Never** invent employers, job titles, dates, degrees, or credentials.
- Reordering and rephrasing real experience is fine; fabrication is not.

## Build & run

- Signing & Capabilities → App Sandbox → **Outgoing Connections (Client)** on
  (for Adzuna HTTP).
- To use the `claude -p` provider, turn **App Sandbox off** (a sandboxed app
  can't launch an external binary). Foundation Models works sandboxed.
- **Adzuna credentials are build-time secrets, not settings.** Copy
  `Secrets.example.xcconfig` → `Secrets.xcconfig` (repo root; gitignored) and fill in
  `ADZUNA_APP_ID` / `ADZUNA_APP_KEY`. They flow `Secrets.xcconfig` → the app target's
  base configuration → `Info.plist` (`AdzunaAppID` / `AdzunaAppKey` via `$(…)`
  substitution) → `BundleAppConfig` at runtime. A build without them still runs, but
  Search is disabled with a clear "unavailable in this build" banner (fail-fast).
  Only the Adzuna **country** is a user setting.

## Working process (docs as source of truth)

The three planning docs form a pipeline, from broadest to most current:

- **`SPEC.md`** — what we're building and why (stable; the north star).
- **`ROADMAP.md`** — the high-level plan: v1 target, fast-follow, backlog, ideas.
- **`TODO.md`** — the granular, *current* checklist. A segmented breakdown of the
  ROADMAP's current target, with a "Current focus" line marking the next task.

The loop, so any session can pick up where the last left off:

1. **On a fresh session,** read `CLAUDE.md` → `TODO.md` (start at "Current focus").
   `SPEC.md` / `ROADMAP.md` give the why and the wider plan when you need them.
2. **Do the next unchecked `TODO.md` item** (respecting the layer dependency rule),
   in small focused changes.
3. **When it's done,** check it off in `TODO.md`, tick the matching line in
   `ROADMAP.md`, and move the "Current focus" pointer to the next item.
4. **When you discover new sub-tasks,** add them as checkboxes under the right
   `TODO.md` milestone. When a whole feature is discussed/specced in chat, write it
   into `SPEC.md` / `ROADMAP.md` in the same change so the docs stay the truth.

Keep these updates in the same commit/change as the code they describe.

## How to work in this repo

- Prefer small, focused changes that respect the seams and the layer dependency
  rule above.
- Don't add auto-submission / job-site automation — it's an explicit non-goal.
