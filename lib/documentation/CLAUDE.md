# CLAUDE.md

Project context for Claude Code. Read this before making changes. The root
[`README.md`](../../README.md) is the public-facing overview (what the app is + a per-version
summary); this file and the rest of `lib/documentation/` are the contributor-facing detail. See
`SPEC.md` for what we're building, `ROADMAP.md` for the high-level plan, `TODO.md` for the
granular checklist of **remaining** work in the *in-progress* version, `MILESTONES.md` for the record of
**completed** milestones, and `PLANNED.md` for specced-but-**not-yet-versioned** features/fixes (a staging
area between `ROADMAP.md`'s Backlog and `TODO.md`). **Starting a fresh session? First ask the user what the current
version is** (form `v0.x.0` / `v0.x.y`, e.g. `v0.3.0` or `v0.4.1`) so commits/labels track correctly,
**then read `TODO.md`** — its "Current focus" line tells you exactly where to pick up. **If Taylor says
he wants to _plan_ a release (rather than build), follow "Working process → Planning sessions" below** —
it's a docs-and-design pass that writes no implementation code (only the project-version bump).

## What this is

Taylor'd Portfolio: a native macOS app that searches jobs, ranks them against the user's
portfolio, and generates a tailored resume + cover letter for a chosen job. No
auto-submission — the user applies themselves.

## Stack & environment

- **UI:** SwiftUI, macOS 26 (Tahoe) target, Xcode 26.
- **Primary LLM:** Apple Foundation Models (`import FoundationModels`), on-device.
  The on-device model tier is **OS/hardware-driven, not app-selectable** — the SDK has no
  API to choose or query a model tier (only `SystemLanguageModel.default` + `availability`),
  so `FoundationModelsClient`'s job is availability + graceful degradation, never model
  selection. (Don't try to build a tier picker — there's nothing to call.)
- **Secondary LLM:** Claude Code headless — `claude -p "<prompt>" --output-format json`.
  The engine **and** Claude model are chosen **per task** in Settings (each `LLMTask`
  gets a `TaskEngineConfig`); the `ClaudeModel` catalog — Fable 5, Opus 4.8/4.7,
  Sonnet 5/4.6, Haiku 4.5; default `claude-opus-4-8` — is passed via the CLI's
  `--model` flag.
- **Job source:** Adzuna REST API (free tier) to start.
- **Persistence:** SwiftData-backed `PersistentRecordStore` (blobs by `kind`+`id`) for saved
  jobs / applications / statuses / profiles / searches, plus `UserDefaults` (`KeyValueStore`) for
  settings and small preferences. `@Model` stays in Infrastructure.

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
- Single-posting gateway: `JobPostingSource` (protocol) + `LinkJobPostingSource`
  (fetch a URL via `HTTPClient` → `HTMLStripper` → LLM `extractPosting` → `JobListing`;
  fails loudly with `.unreadable` on blocked/empty pages, plus a paste-text path).
- Persistence: `SavedJobsRepository` + `SavedApplicationsRepository` +
  `SavedStatusRepository` + `SavedProfilesRepository` + `SavedSearchesRepository`
  (the last persists named `SavedSearch`es — a `JobSearchRequest` + id/name — re-run via
  `SaveSearchUseCase` / `LoadSavedSearchesUseCase` / `DeleteSavedSearchUseCase`, Milestone R)
  (Data/Persistence) map domain
  `RankedJob` / `ApplicationKit` / `ApplicationStatus` / `SavedProfile` ↔ the
  Infrastructure record store's blobs (upsert by id — `JobListing.id`, or `SavedProfile.id`
  for profiles; each under its own `kind`), so pulled listings + matches, generated
  materials, application statuses, and **named profiles** survive relaunch. `@Model` never
  leaves Infrastructure. A built `CandidateProfile` is saved as a named `SavedProfile`
  (Save/Update on the Portfolio tab) and re-selected at build or search time via
  `SaveProfileUseCase` / `LoadProfilesUseCase` / `DeleteProfileUseCase` — no regeneration.
  The profile's **summary/description can be regenerated** from a user prompt without
  rebuilding the whole profile: `RefineSummaryUseCase` → `LLMProvider.refineSummary(profile:
  portfolio:instruction:)` (a plain-text task routed through `.profile`, grounded in the
  profile + portfolio, never fabricating) rewrites only `summary`; the Portfolio tab exposes a
  prompt field + Submit, and the user Saves/Updates to persist it.
  Long-pressing a saved profile marks it the **default** (persisted via `DefaultProfileStore`,
  a single-id KeyValueStore pointer); the Portfolio VM auto-loads it once on launch.
  The `UserDefaults`-backed stores (`SettingsStore`, `DefaultProfileStore`, `RoleTitleStore`,
  `LocationStore`, `SalaryPresetStore`) key their entries under the `com.veritum.taylordportfolio.*`
  namespace. These were renamed from a legacy `com.vivint.*` prefix when the bundle id was corrected;
  a one-time `LegacyKeyMigration` (`Data/Persistence`, run in `Composition.init`) copies old values
  forward so preferences survive the rename.
  A `SavedProfile` also pairs the **source document** it was built on: `sourceFileName`,
  the raw `sourceText`, and a `readableText` — the raw import reflowed into clean plain
  text by `TidyDocumentUseCase` (`LLMProvider.tidyDocument`, routed through the `.profile`
  task so it uses the same engine that built the profile). Viewable with the profile on
  the Portfolio tab. It optionally pairs a **second document, a cover letter**
  (`coverLetterFileName` / `coverLetterText` / `coverLetterReadableText`) — imported/pasted
  in its own Portfolio slot and tidied the same way, but **never distilled into the profile**
  (the profile stays résumé-only; the cover letter is a voice/tone exemplar for generation —
  ROADMAP Milestone T). `SavedProfile` decodes legacy blobs (source- and cover-letter fields
  default to empty) so older single-document saves still load.
- Search suggestions: `SuggestionProvider` (Data/Search) — profile-seeded starting
  titles + static locations + salary presets; pure, on-device. Common role titles are
  **user-curated and persisted** via `RoleTitleStore` (Data/Search, on `KeyValueStore`),
  not a static vocabulary. Custom **locations** and **salary floors** the user types are
  likewise saveable and persisted via `LocationStore` / `SalaryPresetStore` (Data/Search),
  merged into the suggestions (Milestone U-B/U-C).
- Retrieval gateway: `Retriever` (protocol) + impl (roadmap).
- `AppSettings` (`engines: [LLMTask: TaskEngineConfig]` + `adzunaCountry`) +
  `SettingsStore`; `LLMTask` (profile / ranking / extraction / application),
  `TaskEngineConfig` (per-task `LLMChoice` + Claude model), `ClaudeModel` (the
  selectable-model catalog). The engine is chosen **per task**, not globally — each
  task defaults to Claude on `claude-opus-4-8` (on-device is no longer automatic, but
  stays selectable via `.onDevice` / `.auto`). Adzuna credentials are **not** here —
  they're baked in at build time via `AppConfig`.
Depends only on Infrastructure ports.

**Infrastructure** — lowest-level, domain-agnostic plumbing behind small protocols
declared here: `TextGenerating` + `FoundationModelsClient` (wraps
`LanguageModelSession`, `@Generable`, availability) + `ClaudeProcessClient` (runs
`claude -p`, unwraps `result`, strips fences); `HTTPClient` (URLSession wrapper);
`EmbeddingClient` (`NLContextualEmbedding`, roadmap); `KeyValueStore` (UserDefaults
/ keychain); `PersistentRecordStore` + `SwiftDataRecordStore` (a list-oriented blob
store backed by SwiftData; the `@Model` `StoredRecord` lives here and never leaks up —
callers see only `Data` blobs by `(kind, id)`); `AppConfig` + `BundleAppConfig`
(build-time secrets read from the bundle Info.plist — the Adzuna keys, injected from a
gitignored `lib/secrets/Secrets.xcconfig`).

### The three seams, now placed in layers

- **LLM seam** — `LLMProvider` (Data), task-oriented (not generic `generate<T>`)
  because the engines structure output differently: `FoundationModelsProvider`
  uses constrained decoding against `@Generable` types; `ClaudeCodeProvider` asks
  for JSON and decodes. `LLMRouter` maps each `LLMProvider` method to an `LLMTask`
  and picks that task's engine from `AppSettings` (`.auto` = on-device first, fall
  back to Claude; `.claude`/`.onDevice` force one), building the Claude client with
  the task's chosen model. Shared prompts in `Prompts`; structured
  types are both `Generable` and `Codable`. **Generation is two-stage** (AGENT.md
  discipline): `buildTargetBrief(for:)` distils the posting into a `TargetBrief`,
  then `generateApplication(for:profile:brief:grounding:)` tailors against it. Both are
  `LLMProvider` methods; `GenerateApplicationUseCase` orchestrates the two calls. The optional
  `grounding: PortfolioGrounding?` injects the candidate's **real** résumé text (factual
  grounding) + an **optional cover-letter voice exemplar** (Milestone T); that requirement has a
  forwarding default (ignores grounding) so stubs/engines needn't change, and it's threaded from
  `PortfolioViewModel.grounding` → Results/Tracker → `JobDetailView` → `ApplicationSheet`, nil
  falling back to profile-only. Availability via
  `SystemLanguageModel.default.availability` → `.available` /
  `.unavailable(.deviceNotEligible | .appleIntelligenceNotEnabled | .modelNotReady)`.
- **Job seam** — `JobSource` (Data). Implement it (Adzuna, JSearch, USAJOBS…),
  return `[JobListing]`, don't leak API-specific types past the protocol.
- **Ranking funnel** — `JobRanker` (Business): `prefilter(...)` (cheap shortlist;
  upgrade to embedding similarity) then batched `rank(...)` → `[RankedJob]`.
- **Results view filter** — `ResultsFilter` (Presentation/Results): a pure, session-only
  `apply(to:isTracked:)` over the loaded `[RankedJob]` (minScore / keywords / location /
  company / salaryMin / tracked-status), non-destructive — it only hides rows, never
  re-runs the search or touches persistence (Milestone W). Distinct from U-E's search-time
  min-rank filter, which trims the ranked set before it's stored.
- **Multi-title fan-out** — `SearchAndRankUseCase` (Business) expands a
  `JobSearchRequest` (many titles, shared location/salary) into one `JobQuery` per
  title, runs them with bounded concurrency (Adzuna rate-limit guard), merges and
  de-dupes by `JobListing.id`, then ranks the combined set **once**. A single title's
  failure is a soft note (`Output.failedTitles`); it only throws if *all* fail.
  `JobQuery` stays the single-`what` unit the seam understands. With an optional
  **desired-result-count** goal it pages toward the target (round-robin pages, 50/page,
  a page cap; a shortfall is `Output.resultShortfall`, never an error), and an optional
  **minimum-rank** score filter trims after ranking (`Output.noneMetMinimum` when it empties
  a non-empty set) — Milestone U-D/U-E.

### Composition root

`Taylor_d_PortfolioApp` (Presentation) is the one place allowed to reference every layer, to
assemble it: build Infrastructure clients → wrap them in Data gateways → inject
those into Business use cases → inject use cases into ViewModels → inject
ViewModels via `.environment`. All wiring lives here; nothing else news-up a
lower layer.

## Suggested file layout

All app source lives under **`lib/src/`**, one top-level folder per layer; the test target
mirrors that structure under **`lib/tests/`** (see "Where tests live" below).

```
lib/src/
  Presentation/
    App/            Taylor_d_PortfolioApp (composition root); RootView (the NavigationSplitView
                  sidebar shell, opening on the Portfolio area) + ShellNavigation (the sidebar/
                  inner-nav state holder + the per-area section enums — PortfolioSection /
                  SearchSection / TrackerSection / SettingsSection — that both label the segmented
                  inner nav and route each screen's `section:` param) — v0.4.0 Milestones A–B
    Portfolio/      one folder per screen; each screen holds two subfolders:
      View/           the SwiftUI view(s)                  — PortfolioView
      ViewModel/      the @MainActor @Observable ViewModel — PortfolioViewModel
    Search/, Results/, Application/, Tracker/, Settings/  (same View/ + ViewModel/ shape;
                  e.g. Results/View holds ResultsView + RankedRow + JobDetailView + StatusBadge,
                  Tracker/View holds TrackerView, Application/View the sheet)
    Components/     shared view helpers — ScrollableScreen (scroll wrapper), ExportFileDocument,
                  InlineEmptyState (left-aligned empty state for scrolling screens),
                  ExpandableRow (disclosure whose whole header row toggles, not just the caret),
                  CursorStyle (clickableCursor pointer affordance)
  Business/
    UseCases/     BuildProfileUseCase, ImportPortfolioUseCase, SearchAndRankUseCase,
                  GenerateApplicationUseCase, FetchPostingUseCase, ExportApplicationUseCase,
                  SaveResultsUseCase, LoadSavedJobsUseCase, DeleteSavedJobUseCase,
                  SaveApplicationUseCase, LoadApplicationUseCase,
                  MarkStatusUseCase, LoadStatusUseCase, LoadTrackedJobsUseCase,
                  SaveSearchUseCase, LoadSavedSearchesUseCase, DeleteSavedSearchUseCase, RefineSummaryUseCase
    Ranking/      JobRanker
  Data/
    Models/       CandidateProfile, JobListing, JobMatch, TargetBrief, ExtractedPosting,
                  ApplicationKit, ApplicationStatus, JobQuery, JobSearchRequest, PositionType,
                  RankedJob, TrackedJob, SavedProfile, SavedSearch, PortfolioGrounding
    LLM/          LLMProvider, FoundationModelsProvider, ClaudeCodeProvider,
                  LLMRouter, LLMChoice, LLMTask, TaskEngineConfig, ClaudeModel, Prompts
    Jobs/         JobSource, AdzunaJobSource, JobPostingSource, LinkJobPostingSource
    Search/       SuggestionProvider, RoleTitleStore
    Persistence/  SavedJobsRepository, SavedApplicationsRepository, SavedStatusRepository, SavedProfilesRepository, SavedSearchesRepository   (domain ↔ PersistentRecordStore blobs)
                  DefaultProfileStore, LegacyKeyMigration (one-time com.vivint→com.veritum UserDefaults key rename)
    Retrieval/    Retriever            (roadmap)
    Settings/     AppSettings (per-task engine map), SettingsStore
  Infrastructure/
    LLM/          TextGenerating, FoundationModelsClient, ClaudeProcessClient
    Net/          HTTPClient
    Documents/    DocumentTextExtractor, PlatformDocumentTextExtractor
    Config/       AppConfig, BundleAppConfig   (build-time secrets ← lib/xcode/Info.plist ← lib/secrets/Secrets.xcconfig)
    Export/       ExportFormat, DocumentExporter (domain-agnostic: Markdown → Data), RoutingDocumentExporter
                  → MarkdownDocumentExporter (md/txt) + PDFDocumentExporter (Core Text, MarkdownAttributedRenderer)
                  + DocxDocumentExporter (OOXMLDocument + ZipArchiveWriter — hand-rolled minimal .docx)
    Text/         HTMLStripper, MarkdownPlainText, MarkdownBlockParser, MarkdownInline
                  (HTML/Markdown → text/blocks/runs; shared by Data + Presentation + Export)
    Embedding/    EmbeddingClient      (roadmap)
    Store/        KeyValueStore, UserDefaultsStore,
                  PersistentRecordStore, SwiftDataRecordStore (+ StoredRecord @Model)
```

Enforce the dependency rule at review time. Optional but recommended later: make
each layer its own SwiftPM target so the compiler enforces "no upward imports"
for you.

### Where tests live

All tests live under **`lib/tests/`** (moved there from a former top-level `Tests/`),
mirroring the source layer folders: `lib/tests/Business/`, `lib/tests/Data/`,
`lib/tests/Infrastructure/`, `lib/tests/Presentation/`, plus `lib/tests/Integration/`
(e.g. `EndToEndTests`). A new test file dropped anywhere under `lib/tests/` is picked up
automatically — no project edit needed (see the Xcode note next).

### Xcode project structure

The project (`Taylor'd Portfolio.xcodeproj`) uses **file-system-synchronized groups**, so the
folders on disk *are* the target membership — there's no manual "add file to target" step:

- The **app target** (`Taylor'd Portfolio`) synchronizes **`lib/src`** — every file under it is
  compiled into the app.
- The **test target** (`Taylor'd PortfolioTests`) synchronizes **`lib/tests`**.

Because the two synchronized roots are `lib/src` and `lib/tests` (siblings), the app target never
picks up test files even though both sit under `lib/`. Add a new source or test file by simply
creating it in the right folder; there's nothing to wire in `project.pbxproj`.

More folders live under `lib/`. The two config folders are explicit file references (**not**
synchronized groups, so they're not compiled into any target); `documentation/` isn't in the Xcode
project at all:

- **`lib/xcode/Info.plist`** — the app's base Info.plist (custom build-time keys only;
  `GENERATE_INFOPLIST_FILE` still merges Xcode's generated keys on top). Wired via the app target's
  `INFOPLIST_FILE = lib/xcode/Info.plist` build setting.
- **`lib/secrets/`** — `Secrets.xcconfig` (the app target's **base configuration**, gitignored) and
  its committed template `Secrets.example.xcconfig`. See "Build & run" for the credential flow.
- **`lib/documentation/`** — the contributor docs (`SPEC.md`, `ROADMAP.md`, `TODO.md`,
  `MILESTONES.md`, and this `CLAUDE.md`), relocated here from a former root-level `Documentation/`.
  The root `README.md` is the only doc that stays at the repo root. (Per-release design references
  can live in a temporary `design/` subfolder during a rework and are removed once it ships.)

Build & test from the CLI:

```
xcodebuild test -project "Taylor'd Portfolio.xcodeproj" -scheme "Taylor'd Portfolio" -destination 'platform=macOS'
```

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
- `ApplicationStatus` (`Codable`): `stage` (`ApplicationStage`) + auto-stamped dated
  milestones; `advanced(to:on:)` is pure. `TrackedJob` pairs a `RankedJob` with its status.

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

- **Grounded by default.** With the generation-fidelity control at its default (0), resumes
  and cover letters are grounded strictly in the user's portfolio: reorder and rephrase real
  experience only, and **never** invent employers, job titles, dates, degrees, or credentials.
- **Opt-in embellishment is always disclosed.** Raising the fidelity control (ROADMAP v0.5.0
  Milestone D) permits curation and, at the top of the scale, invented content — but only as an
  explicit user choice, and every addition not supported by the profile must be **surfaced**:
  listed in the gap note / disclosures, flagged in the UI, and marked "draft — verify before
  sending." **Never emit fabricated content silently or by default**, and keep the default
  (fidelity 0) generation path byte-for-byte grounded.

## Build & run

- **App Sandbox is OFF** for the app target (`ENABLE_APP_SANDBOX = NO`). This is
  deliberate: the `claude -p` provider launches an external binary, which a sandboxed
  app can't do (it fails with "Operation not permitted"). Unsandboxed, both the Claude
  CLI and Adzuna HTTP work, and Foundation Models still works. Trade-off: no Mac App
  Store distribution — fine for a personal/dev tool. (`ENABLE_OUTGOING_NETWORK_CONNECTIONS
  = YES` is kept for when/if the sandbox is re-enabled, but is moot while unsandboxed.)
- The `claude -p` provider needs the `claude` CLI installed and on a resolvable path.
  GUI apps inherit a minimal `PATH`, so `ClaudeProcessClient` widens it
  (`searchPATH`) to include `~/.local/bin`, Homebrew, and npm-global before launching.
- **Adzuna credentials are build-time secrets, not settings.** Copy
  `lib/secrets/Secrets.example.xcconfig` → `lib/secrets/Secrets.xcconfig` (same folder;
  gitignored) and fill in `ADZUNA_APP_ID` / `ADZUNA_APP_KEY`. They flow
  `lib/secrets/Secrets.xcconfig` (the app target's base configuration) → `lib/xcode/Info.plist`
  (`AdzunaAppID` / `AdzunaAppKey` via `$(…)` substitution) → `BundleAppConfig` at runtime.
  A build without them still runs, but Search is disabled with a clear "unavailable in this
  build" banner (fail-fast). Only the Adzuna **country** is a user setting.
- **Bundle identifier** is `com.veritum.Taylor-d-Portfolio` (tests: `…PortfolioTests`). It was
  corrected from a legacy `com.vivint.*`; see `LegacyKeyMigration` for the matching `UserDefaults`
  key migration.

## Working process (docs as source of truth)

The root **`README.md`** is the public overview — what the app is, its stack, and a
**high-level summary of each `v0.x.0` release**. It's the front door; keep it current when a
version ships (add/refresh that version's one-paragraph summary), but keep the granular detail
in the four docs below, not in the README.

Four contributor docs, from broadest to most granular:

- **`SPEC.md`** — what we're building and why (stable; the north star).
- **`ROADMAP.md`** — the high-level plan: v0.1.0 target, fast-follow, backlog, ideas
  (a progress board — items are ticked as they land, but the detail lives elsewhere).
- **`TODO.md`** — the granular checklist of **work that still needs doing**, with a
  "Current focus" line marking the next task. It should *only* contain remaining work.
- **`MILESTONES.md`** — the record of **completed** milestones (the detailed write-ups,
  moved here out of `TODO.md`). History and reference: what shipped and how.
- **`PLANNED.md`** — specced features/fixes that are **not yet assigned to a version** (a staging area
  between `ROADMAP.md`'s loose Backlog and `TODO.md`'s in-progress milestones). Entries name real seams/files
  so a scheduled item lifts straight into a version's `TODO.md`/`ROADMAP.md` as lettered milestones; **remove
  it from `PLANNED.md` when it's scheduled** (this file holds only *unscheduled* work).

The loop, so any session can pick up where the last left off:

1. **On a fresh session,** read `CLAUDE.md` → `TODO.md` (start at "Current focus").
   `SPEC.md` / `ROADMAP.md` give the why and the wider plan; `MILESTONES.md` shows what's
   already done when you need the history.
2. **Do the next unchecked `TODO.md` item** (respecting the layer dependency rule),
   in small focused changes.
3. **When a milestone (or self-contained sub-part) is done,** *move its write-up out of
   `TODO.md` into `MILESTONES.md`* (marked ✅), tick the matching line in `ROADMAP.md`, and
   advance the "Current focus" pointer. `TODO.md` shrinks as work completes — it never
   accumulates checked-off items.
4. **When you discover new sub-tasks,** add them as checkboxes under the right `TODO.md`
   milestone. When a whole feature is discussed/specced in chat, write it into `SPEC.md` /
   `ROADMAP.md` in the same change so the docs stay the truth.

Keep these updates in the same commit/change as the code they describe.

**Versioning.** Feature releases are numbered **`v0.x.0`** (`v0.1.0` foundation, `v0.2.0` reliability,
`v0.3.0` output & polish, `v0.4.0` navigation & shell, `v0.5.0` document generation fixes). **Patch /
point releases** use
**`v0.x.y`** with `y > 0` (first one: **`v0.4.1`**) for a batch of **bug fixes and small refinements**
on top of a shipped `v0.x.0`, when the changes don't warrant a new feature theme. A patch release is a
first-class release: it gets its own `## v0.x.y —` header in `ROADMAP.md` / `MILESTONES.md`, its own
`MARKETING_VERSION` bump, and its milestones **restart at A** (committed `v0.x.y : Milestone X
Completed`) — exactly like a `.0`, just themed as fixes rather than a feature. The **current version
isn't hard-coded in these docs** — at the **start of every session, ask the user what version is in
progress** and use that number for commit-label suggestions. (The `## v0.x.0 —` / `## v0.x.y —` headers
in `ROADMAP.md` / `MILESTONES.md` name the release *themes*, not the live working version.)

> **Never pre-name the next version.** Taylor doesn't decide the next version's number — or whether it's a
> feature `.0` or a patch `.y` — until he actually starts developing it. So the docs must **not** name an
> unstarted version (don't write `v0.6.0` in `ROADMAP.md` / `TODO.md` / `README.md` / `MILESTONES.md` before
> it's begun). Refer to it generically as **"the next version"**; forward-pointers (the `README.md`
> **Next:** line, `TODO.md`'s next-version placeholder, the merge-ready wrap) describe the likely *theme*
> without a number. The number is assigned only at the planning kickoff of that version (per the planning
> steps above), when the `MARKETING_VERSION` bump and headers are added.

**Keep the project version in sync — update it when a new version starts.** The app's
`MARKETING_VERSION` build setting (in `Taylor'd Portfolio.xcodeproj/project.pbxproj` — **4 copies**,
one per Debug/Release × app/test config) feeds `CFBundleShortVersionString`, which the
**Settings → About** pane displays. When a new `v0.x.0` begins, set **every** `MARKETING_VERSION` to
that bare `0.x.0` (e.g. `MARKETING_VERSION = 0.5.0;`) so About reports the real version — never leave
it at a stale or template value. (This was missed until `v0.4.0`, where it sat at the Xcode template
`1.0` until corrected — see `MILESTONES.md` → v0.4.0 Milestone C.) The build number
`CURRENT_PROJECT_VERSION` isn't shown, so it needn't track the milestone.

**Milestone letters restart at A each version.** `v0.1.0`–`v0.3.0` ran A–X *continuously*, but
from **`v0.4.0` onward every new version begins its milestones again at Milestone A** (A, B, C…) —
**including patch releases** (`v0.4.1` restarts at A, independent of v0.4.0's A–C).
So a milestone ID is only unique *within* its version — always pair it with the version when it
could be ambiguous (e.g. "v0.4.0 Milestone A"), and note that `MILESTONES.md` groups completed
milestones under `## v0.x.0 —` headers precisely to keep the reused letters unambiguous.

**Commits are milestone-based and made by the user (Taylor), not the agent.** Taylor commits
manually with the message format **`v0.x.0 : Milestone X Completed`** (using the version you
confirmed at session start). So when a unit of work finishes, **always state which milestone /
sub-part / hotfix it was** (e.g. "Milestone S-A", "Milestone Q-A", "URL-fetch Hotfix") — that
label is what goes in the commit message. Do this even for partial completions (name the milestone
and say it's partial). Ad-hoc user-requested tweaks have no milestone letter — say so and suggest a
`v0.x.0 : <short description>` message instead. Don't run `git commit` unless explicitly asked.

### Planning sessions ("I'd like to start a planning session")

When Taylor opens a session by asking to **plan** a release (or says something like "let's plan
v0.x.y", "I want to plan the next version"), the job is to turn the features / fixes / bugs he
describes — **together with the relevant entries already specced in `PLANNED.md`** — into **properly
structured milestones in the docs** — **no implementation code**. This is a docs-and-design pass, not a
build pass. Run it like this:

0. **Read `PLANNED.md` first — it's the standing backlog to pull from.** `PLANNED.md` holds features/fixes
   that were specced in earlier sessions (with real seams/files named) but **not yet assigned to a version**.
   At the start of every planning session, read it and decide **which entries belong in the version being
   planned**. Treat each selected entry exactly like an item Taylor described in chat: convert it into lettered
   milestone(s) in `TODO.md` + `ROADMAP.md` (steps 3–4 below) — reusing the seams/files/open-calls it already
   documents — and then **delete that entry from `PLANNED.md`** so the file only ever holds *unscheduled* work.
   Confirm the selection with Taylor (its scope may make it a `.0` vs. a patch — see step 1). Conversely, any
   new feature Taylor raises this session that he **doesn't** want in the current version goes the other way:
   capture it as a fresh `PLANNED.md` entry (same rigor — real seam + files) rather than a version milestone.

1. **Confirm the version & release type.** Ask/confirm the working version (per **Versioning** above).
   Decide **feature release (`v0.x.0`)** vs. **patch release (`v0.x.y`)**: a batch of bug fixes / small
   refinements on top of a shipped `.0` is a **patch** (e.g. v0.4.1); a new coherent theme is a new
   `.0`. Milestones **restart at A** either way.
2. **If this planning session opens a NEW version, set it up first:** add the release header
   (`## v0.x.y — <theme> (in progress)`) to `ROADMAP.md` and a matching section to `TODO.md`, point
   `TODO.md`'s **"Current focus"** at it, update the `README.md` **Next:** line, and — importantly —
   **bump the project version** (see step 6). For an established in-progress version, just append the
   new milestones.
3. **For each item Taylor describes, read the real code first.** Before writing a milestone, open the
   view / view-model / use-case / seam it touches so the write-up names **actual files, types, and the
   correct seam** (e.g. "`ResultsViewModel.filteredResults`", "`ShellNavigation.breadcrumbTitle`,
   `RootView.swift:119`"). Don't write a milestone from guesswork or from a screenshot alone — verify
   in the source. Respect the **layer dependency rule**, and **call out when a milestone is not
   Presentation-only** (most are; some, like a warnings sweep, touch Infrastructure too).
4. **Write each item as a lettered milestone (A, B, C…).** Two places, in the same pass:
   - **`TODO.md`** — a detailed write-up: what's wrong / wanted → the **seam + files** → concrete
     sub-tasks as `- [ ]` checkboxes → a **Tests** note → an **On-device** note. Keep the **"Current
     focus"** line and the A→X milestone queue current as you add each one.
   - **`ROADMAP.md`** — a one-paragraph `- [ ]` bullet under the version header (summary + seam +
     on-device), mirroring the TODO milestone.
5. **Surface real decisions instead of silently making them.** When a change has a genuine UX/design
   fork (e.g. "9 tracker tabs won't fit a segmented control" or "does an unsaved profile appear here"),
   write it as an explicit **"(open call)"** sub-task with a **recommended default**, and leave it for
   build time. Don't bury a judgement call inside a checkbox.
6. **Keep the project version in sync — this is part of planning a new version.** When a planning
   session starts a new `v0.x.y`, **update every `MARKETING_VERSION` (4 copies in `project.pbxproj` —
   Debug/Release × app/test) to that number** so Settings → About reports it (see **"Keep the project
   version in sync"** above). This is the **one build-setting change that belongs to starting a
   version** — do it as part of kickoff, or, if Taylor wants a pure docs-only pass, record it as a
   ticked-when-done **release-hygiene checkbox** in the version's `TODO.md` section so it isn't
   forgotten. (The rest of a planning session writes **no** code.)
7. **Name the label.** Each planned item is a milestone; when Taylor implements it later it commits as
   `v0.x.y : Milestone X Completed`. Planning itself produces only doc edits — if he commits the
   planning pass on its own, suggest `v0.x.y : Planning` (mirroring the existing "Planning" commits).

The output of a good planning session: `TODO.md` + `ROADMAP.md` (and `README.md` / `SPEC.md` /
`CLAUDE.md` where a new pattern or whole feature warrants it) fully describe the release's milestones,
every seam is named from the real code, open decisions are flagged with recommendations, the
project version matches the new number, and any `PLANNED.md` entries pulled into the version have been
**moved out of `PLANNED.md`** (it's left holding only still-unscheduled work) — so implementation can start
straight from the docs.

### Making a branch merge-ready (shipping a version)

Each `v0.x.0` is developed on its **own branch** (e.g. `v0.4.0`) and merged into `main` via a **PR**
when the version's milestones are all done (see the `v0.2.0` / `v0.3.0` merge PRs in the history).
Before a version branch is merge-ready, bring the docs **and** the project to a *shipped* state — not
mid-flight state — and check each of these:

- **`ROADMAP.md`** — the version's `## v0.x.0 —` header reads **(complete)**, and every milestone under
  it is ticked ✅. The fast-follow / "next version" note points forward.
- **`MILESTONES.md`** — every completed milestone / sub-part has its write-up here (moved out of
  `TODO.md`), grouped under the version's `## v0.x.0 —` header.
- **`TODO.md`** — holds **no remaining work for the shipped version**; "Current focus" points at the
  next version (milestones restart at A) with only its **un-numbered** placeholder + the carried-forward
  "Awaiting device checks" note below. Don't name the next version (see "Never pre-name the next version").
- **`README.md`** — has the shipped version's one-paragraph summary under "Version history", and the
  **Next:** line points forward to the likely theme **without a version number** (chosen when it's started).
- **Project version** — every `MARKETING_VERSION` equals the shipped `0.x.0` (see **Versioning**
  above); confirm the built app's `CFBundleShortVersionString` matches.
- **Scaffolding removed** — any temporary per-release references (e.g. a `design/` subfolder) are
  deleted and their doc links stripped, so nothing dangles.
- **Tests green** — the full suite passes (`xcodebuild test …`); genuinely manual/device-only checks
  are called out in the `TODO.md` "Awaiting device checks" note, never silently skipped.

The agent prepares all of this **in the working tree**; **Taylor makes the actual commit, merge, and
PR** (the agent doesn't run `git commit` / `git merge` or open the PR unless explicitly asked). When
the branch is ready, say so and suggest the wrap-up message (e.g. `v0.x.0 : <theme> complete`).

## How to work in this repo

- Prefer small, focused changes that respect the seams and the layer dependency
  rule above.
- Don't add auto-submission / job-site automation — it's an explicit non-goal.
