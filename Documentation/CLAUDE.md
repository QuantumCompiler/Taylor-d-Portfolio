# CLAUDE.md

Project context for Claude Code. Read this before making changes. See `SPEC.md`
for what we're building and `ROADMAP.md` for what's planned.

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
- Retrieval gateway: `Retriever` (protocol) + impl (roadmap).
- `AppSettings` + `SettingsStore`.
Depends only on Infrastructure ports.

**Infrastructure** — lowest-level, domain-agnostic plumbing behind small protocols
declared here: `TextGenerating` + `FoundationModelsClient` (wraps
`LanguageModelSession`, `@Generable`, availability) + `ClaudeProcessClient` (runs
`claude -p`, unwraps `result`, strips fences); `HTTPClient` (URLSession wrapper);
`EmbeddingClient` (`NLContextualEmbedding`, roadmap); `KeyValueStore` (UserDefaults
/ keychain).

### The three seams, now placed in layers

- **LLM seam** — `LLMProvider` (Data), task-oriented (not generic `generate<T>`)
  because the engines structure output differently: `FoundationModelsProvider`
  uses constrained decoding against `@Generable` types; `ClaudeCodeProvider` asks
  for JSON and decodes. `LLMRouter` picks one from `AppSettings.llmChoice` (`auto`
  = on-device first, fall back to Claude). Shared prompts in `Prompts`; structured
  types are both `Generable` and `Codable`. Availability via
  `SystemLanguageModel.default.availability` → `.available` /
  `.unavailable(.deviceNotEligible | .appleIntelligenceNotEnabled | .modelNotReady)`.
- **Job seam** — `JobSource` (Data). Implement it (Adzuna, JSearch, USAJOBS…),
  return `[JobListing]`, don't leak API-specific types past the protocol.
- **Ranking funnel** — `JobRanker` (Business): `prefilter(...)` (cheap shortlist;
  upgrade to embedding similarity) then batched `rank(...)` → `[RankedJob]`.

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
    UseCases/     BuildProfileUseCase, SearchAndRankUseCase, GenerateApplicationUseCase
    Ranking/      JobRanker
  Data/
    Models/       CandidateProfile, JobListing, JobMatch, ApplicationKit,
                  JobQuery, RankedJob
    LLM/          LLMProvider, FoundationModelsProvider, ClaudeCodeProvider,
                  LLMRouter, Prompts
    Jobs/         JobSource, AdzunaJobSource
    Retrieval/    Retriever            (roadmap)
    Settings/     AppSettings, SettingsStore
  Infrastructure/
    LLM/          TextGenerating, FoundationModelsClient, ClaudeProcessClient
    Net/          HTTPClient
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
- Add Adzuna `app_id` / `app_key` and country code in Settings before searching.

## How to work in this repo

- Prefer small, focused changes that respect the seams and the layer dependency
  rule above.
- When adding a feature from the roadmap, update `SPEC.md` / `ROADMAP.md` in the
  same change so the docs stay the source of truth.
- Don't add auto-submission / job-site automation — it's an explicit non-goal.
