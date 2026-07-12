# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.5.0 — document generation fixes — is in planning.** All of v0.1.0–v0.4.1 are
> done (see `MILESTONES.md`). v0.5.0's theme is **fixing the document-generation experience** (the tailored
> résumé + cover letter and the paths to view/regenerate them). Milestones restart at **A**; the project
> version is bumped to **0.5.0**. **Start with Milestone A below.** More milestones are being added as Taylor
> describes each generation-side gap in the planning session. Planned so far: **A** (view generated materials
> from the Tracker), **B** (present job detail + its Application view as real windows, not sheets), **C**
> (remove the redundant "Mark as applied" button), **D** (generation controls — fidelity scale, tailored
> aspects, presets, and a desired rank-match target that fabricates to a target score; grounded-by-default
> + opt-in disclosed embellishment).
>
> **⚠️ Awaiting device checks (v0.4.1)** — verify on a real run (carried across the merge): **A** the
> Portfolio Profile tab is inputs-only and the preview / regenerate / Save controls now sit on **Saved
> Profiles**; **B** no `Area / Sub-view` header anywhere (content or title bar), Results is a plain
> section with no tabs; **C** saving a result removes it from Results and it appears in the Tracker;
> **D** all 9 Tracker status tabs are reachable (the inner nav scrolls) and each filters correctly;
> **E** the Tracker / Results empty states are centered; **F** Source Documents lists saved profiles,
> each expanding to its docs, whole row clickable with a pointer cursor; **G** the Settings Save button
> has no background band and scrolls with the section; **H** exported **PDF/DOCX** still open correctly
> (the export renderer + zip writer were re-annotated in the concurrency cleanup — behaviour unchanged,
> but re-verify). Also confirm the running app's `CFBundleShortVersionString` reads **0.4.1** in
> Settings → About.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.5.0 — document generation fixes

**Milestones restart at Milestone A** for v0.5.0 (see the versioning note in `CLAUDE.md`). Theme: fix
and round out the **document-generation experience** — the tailored résumé + cover letter produced for a
saved job, and the paths to view and regenerate them.

**Release-hygiene (kickoff):**
- [x] **Project version bumped to 0.5.0** — all four `MARKETING_VERSION` copies in
      `Taylor'd Portfolio.xcodeproj/project.pbxproj` (Debug/Release × app/test) set to `0.5.0`, so
      Settings → About reports it. *(Done as part of planning kickoff.)*

---

## Milestone A — View generated résumé & cover letter from the Tracker

**What's wrong.** After the user generates a job's tailored résumé + cover letter from the **Tracker**,
there's no obvious way to get back to them. The materials *do* persist and reload without a fresh LLM
call — `SavedApplicationsRepository` stores the `ApplicationKit` by `JobListing.id`, and
`ApplicationViewModel.open(for:profile:)` loads it (badged "Saved") when the sheet reopens
(`ApplicationViewModel.swift:91`). **But the UI hides this:** in the Tracker context `JobDetailView`'s
footer shows a single **"Generate résumé & cover letter"** button (`JobDetailView.swift:219`) whether or
not materials already exist, and the detail view carries **no "already generated" indicator** — so the
user reads it as "generate anew" and can't tell their earlier documents are one tap away.

**Wanted.** In the Tracker context, when a saved kit exists, show a dedicated **"View résumé & cover
letter"** button **alongside** the Generate button (Taylor's call — both explicit in the footer). View
opens the sheet in load-only mode (no LLM); Generate produces fresh output.

**Seam + files (Presentation only; reuses the existing Business `LoadApplicationUseCase` — no new seam).**
- `lib/src/Presentation/Results/View/JobDetailView.swift` — footer (`footer`, ~:210) + a detection
  `@State`; only the Tracker context (`canGenerate == true`) is affected. Results context
  (`canGenerate == false`, Save-to-Tracker only) is untouched.
- `lib/src/Presentation/Tracker/View/TrackerView.swift` — thread the detection use case into
  `JobDetailView` (`TrackerView.swift:57`).
- `lib/src/Presentation/App/RootView.swift` (`TrackerView(...)`, ~:190) + `Composition.swift`
  (`makeTrackerViewModel` / the wiring around it) — provide `LoadApplicationUseCase`. It's **already
  built** in `makeApplicationViewModel` (`Composition.swift:195`); expose the same instance to the
  Tracker path rather than constructing a second.
- `lib/src/Presentation/Application/View/ApplicationSheet.swift` + `ApplicationViewModel.swift` — support
  opening the sheet in a **forced-regenerate** mode for the footer's Generate button (see open call).

**Sub-tasks.**
- [ ] **Detect existing materials.** Give `JobDetailView` an optional
      `loadApplication: LoadApplicationUseCase?`; in `.task` set `@State private var hasGeneratedMaterials`
      = `(try? await loadApplication?(forJobID: ranked.id)) != nil`. This mirrors the existing `loadStatus`
      call already made in `JobDetailView.task` (the view intentionally has no ViewModel and calls use
      cases directly).
- [ ] **Keep it live.** Refresh `hasGeneratedMaterials` when the application sheet closes
      (`.onChange(of: showingApplication)` → `false`), so the **View** button appears immediately after a
      first generation without leaving the detail view.
- [ ] **Footer buttons (Tracker context).** When `hasGeneratedMaterials`: show **"View résumé & cover
      letter"** (opens the sheet in load-only mode) **and** the **Generate** button. When no materials
      exist: show only **"Generate résumé & cover letter"** (today's behaviour). Both stay disabled while
      `profile == nil`.
- [ ] **Wire the use case** `Composition` → `RootView` → `TrackerView` → `JobDetailView`, reusing the
      `LoadApplicationUseCase` already created for the Application VM.
- [ ] **(open call) What "Generate" does when materials already exist.** **Recommended:** force a **fresh
      regeneration** (so View vs Generate are genuinely distinct) — add a `forceRegenerate` entry to
      `ApplicationSheet` that calls `ApplicationViewModel.generate(...)` instead of `open(...)` in `.task`,
      and consider **relabeling it "Regenerate"** for clarity. *Alternative:* keep the "Generate" label and
      just open the sheet (which would load the saved kit — redundant with View). Leave the final label to
      Taylor at build time.
- [ ] **(open call) Overlap with the in-sheet Regenerate button.** `ApplicationSheet` already offers a
      **Regenerate** button once a kit is shown (`ApplicationSheet.swift:68`). Decide whether the footer's
      second button is still wanted given that, or whether **View alone** (relying on in-sheet Regenerate)
      is enough. **Recommended:** keep both per Taylor's choice, but note the overlap so the wording stays
      consistent.

**Tests.** `JobDetailView` has no ViewModel, so make the footer decision testable by extracting a **pure
helper** — e.g. a small `enum GenerationFooter { case generateOnly, viewAndGenerate, saveToTracker }`
derived from `(canGenerate, hasGeneratedMaterials, onSaveToTracker != nil)` — and unit-test its mapping.
Add an `ApplicationViewModel` test that the **forced-regenerate** path calls the provider **even when a
saved kit exists** (the mirror of the existing O-C test where `open` loads a saved kit with *zero*
provider calls). Reuse `Preview.sampleRankedJobs`.

**On-device.** Yes — the existence check is a local `PersistentRecordStore` read; regeneration uses
whatever engine the `.application` task is set to (unchanged from today).

> **Note (A × B).** Milestone B converts the Application sheet (and the Job Detail sheet) into real
> windows. Once B lands, Milestone A's **View** / **Generate** buttons should open the Application
> **window** rather than the sheet. Coordinate the build order (B's window mechanism, then A's buttons
> target it — or build A as sheets first and let B migrate it). Same footer/presentation code is touched
> by both.

---

## Milestone B — Present job detail (and its Application view) as real windows, not sheets

**What's wrong.** Tapping a job — in the **Tracker** and in **Results** — presents `JobDetailView` as a
modal **sheet** (`.sheet(item: $viewModel.selectedJob)` — `TrackerView.swift:57`, `ResultsView.swift:73`),
and generating from there opens `ApplicationSheet` as a **nested sheet** (`JobDetailView.swift:57`). Taylor
wants these to be **genuine separate macOS windows** (detached, resizable, movable, sitting alongside the
main window) instead of modal sheets — for **everything currently presented as a sheet**. (The
`.fileImporter` / `.fileExporter` calls are OS file panels, not custom sheets — leave them.)

**Why this isn't a one-line swap (verified in source).** The app has a single `WindowGroup` scene
(`App.swift:20`); the sheets render **inside** `RootView`'s view tree, so they can read its `@State` (the
current `profile`, `PortfolioGrounding`, and the wired use cases). A second top-level window scene renders
**outside** that tree and can't see it. Two hard constraints from the model layer:
- **`PortfolioGrounding` is not `Codable`** (`PortfolioGrounding.swift:19` — only `Equatable, Sendable`),
  and `profile` is live session state — so grounding/profile **cannot be passed as a `WindowGroup` value**.
  They must come from **shared app-level state** injected into every scene.
- `RankedJob` / `JobListing` are `Codable` + `Identifiable` but **not `Hashable`** (`RankedJob.swift:12`,
  `JobListing.swift:14`), and `WindowGroup(id:for:)` needs a `Codable & Hashable` value — so the window is
  keyed by the job **id (`String`)** and loads the `RankedJob`, unless we add `Hashable` (open call B-B).

**Seam + files (Presentation-heavy; Presentation-only under the recommended id-based approach).**
- `lib/src/Presentation/App/App.swift` — add the new `WindowGroup(id:for:)` scenes (job detail,
  application) beside the main one; own + inject the shared session.
- `lib/src/Presentation/App/RootView.swift` + `Composition.swift` — vend use cases to the new scenes; hold
  the shared session.
- `lib/src/Presentation/Tracker/View/TrackerView.swift` + `Results/View/ResultsView.swift` — replace
  `.sheet(item:)` with `@Environment(\.openWindow)` + `openWindow(id:value:)`; drop the
  `onChange(selectedJob == nil)` reload in favour of the cross-window refresh signal (B-A).
- `lib/src/Presentation/Results/View/JobDetailView.swift` — becomes a window root; replace its nested
  `.sheet(isPresented: $showingApplication)` with `openWindow`; reconcile the Results-context swipe (B-B).
- `lib/src/Presentation/Application/View/ApplicationSheet.swift` — hosted in a window (likely rename off
  "Sheet"); its `.fileExporter` stays.

### B-A — Shared app-level session + cross-window refresh

- [ ] **Hoist shared session state.** Add an app-level `@Observable` (e.g. `AppSession`) owned by
      `Taylor_d_PortfolioApp`, holding the current `profile: CandidateProfile?` and
      `grounding: PortfolioGrounding?` (today RootView `@State`), injected via `.environment` into **every**
      scene so the detail/application windows read the same live values. `PortfolioViewModel` writes through
      to it (or the session becomes the source of truth RootView already observes).
- [ ] **Cross-window refresh signal.** Because a detached window gives no sheet-dismiss callback, add a
      shared **revision token** on `AppSession` (a bumped counter / `objectWillChange`) that the detail and
      application windows increment when they mutate persistence (mark status, generate). `TrackerViewModel`
      / `ResultsViewModel` observe it and reload, so status/generation changes reflect back in the lists.
      *(open call: revision-token vs. reload-on-window-focus via `scenePhase`. Recommend the token — precise
      and immediate.)*

### B-B — Job Detail window (replaces the two `.sheet(item:)`)

- [ ] **New scene.** `WindowGroup("Job", id: "job-detail", for: String.self)` (the job **id**) in
      `App.swift`; its root loads the `RankedJob` (from `SavedJobsRepository` via a use case — both Tracker
      and Results jobs are persisted, per O-B) and builds `JobDetailView` with session + composition deps.
- [ ] **Open from lists.** Tracker + Results rows call `openWindow(id: "job-detail", value: ranked.id)`
      instead of setting `selectedJob`. `WindowGroup(id:for:)` **reuses one window per id**, so re-tapping a
      job re-activates its window rather than duplicating it.
- [ ] **Context without closures.** The Results-vs-Tracker differences currently ride on view params
      (`canGenerate`, `onSaveToTracker` closure) — closures can't cross a window boundary. Resolve context
      from persisted state / a value flag: Save-to-Tracker becomes a **direct `MarkStatusUseCase` call**
      (not a passed closure); `canGenerate` derives from context.
- [ ] **(open call) Results swipe.** The Results detail is a **swipeable card** (left = dismiss, right =
      save — V-C). A window has no card to swipe. **Recommended:** drop the swipe in the window and keep the
      explicit **Save to Tracker** button (already in the footer) plus the existing row-level save/delete
      icons; leave V-C's `SwipeOutcome` for any remaining card usage. Confirm with Taylor.
- [ ] **(open call) Window value type.** Recommended: key by **`String` job id** + load (no Data-layer
      change). Alternative: add `Hashable` to `RankedJob` / `JobListing` / `JobMatch` (Data) and pass the
      value directly (avoids a load, but is a Data-layer touch and risks a stale snapshot).

### B-C — Application window (replaces the nested `.sheet(isPresented:)`)

- [ ] **New scene.** A second `WindowGroup(id: "application", for: String.self)` (job id) hosting the
      renamed `ApplicationSheet` (→ `ApplicationWindow`/`ApplicationView`), building `ApplicationViewModel`
      from composition and reading `profile`/`grounding` from `AppSession`.
- [ ] **Open from Job Detail.** The detail window's **View** / **Generate** / **Regenerate** actions
      (incl. Milestone A's buttons) call `openWindow(id: "application", value: job.id)` instead of toggling
      `showingApplication`.
- [ ] **Keep export intact.** `ApplicationViewModel.open/generate`, the one-page gate, and the
      `.fileExporter` flow are unchanged — only the container changes from sheet to window.

**Tests.** The window plumbing is largely untestable in unit tests (scene wiring), so cover the **pure**
pieces: `AppSession` state/revision-token behaviour (profile/grounding read-through, bump increments); a
use case (or thin loader) that resolves a `RankedJob` from a job id (found / missing); and keep the
existing `TrackerViewModel` / `ResultsViewModel` reload tests, adapting them to trigger on the revision
signal instead of sheet dismissal. Window-open behaviour itself is a **manual (device) check** — note it in
"Awaiting device checks."

**On-device.** Yes — pure local reads + existing engines; no network, no new persistence.

---

## Milestone C — Remove the "Mark as applied" button (the status menu covers it)

**What's wrong.** `JobDetailView`'s Application-status section shows a prominent **"Mark as applied"**
button whenever a job is untracked (`JobDetailView.swift:125`, only rendered when `status == nil`), *next
to* a **"Set status"** menu. The menu already lists every settable stage — `ApplicationStage.settable` is
`allCases.filter { $0 != .saved }` (`ApplicationStatus.swift:37`), so it **includes `.applied`** via the
same auto-date-stamping `mark(.applied)` path. The dedicated button is redundant with the dropdown.

**Wanted.** Remove the "Mark as applied" button in **all** views. (It lives in one place — `JobDetailView`
— which is presented from both the Results and Tracker contexts, so removing it there removes it
everywhere.) Applied stays reachable via **Set status → Applied**, with the identical auto-stamp.

**Seam + files.** **Presentation only, single file** — `lib/src/Presentation/Results/View/JobDetailView.swift`,
the `statusSection` (`:115`). Delete the `if status == nil { Button("Mark as applied") … }` block
(`:124–128`); keep the `StatusBadge` / "Not tracked yet" text and the "Set status" `Menu` unchanged. No
ViewModel, use-case, or lower-layer change; `MarkStatusUseCase` and the `.applied` stamping are untouched.

**Sub-tasks.**
- [ ] Remove the `Button("Mark as applied")` and its enclosing `if status == nil` guard from `statusSection`.
- [ ] Confirm the "Set status" menu stays always-visible (it currently is) so an untracked job can still be
      moved to Applied (and any other stage) in one step.
- [ ] (optional) If the untracked row now looks bare, consider whether "Set status" wants a subtle prominent
      style — leave as-is unless it reads oddly at build time.

**Tests.** No logic change to test (pure view edit). The existing status-marking coverage
(`StatusUseCaseTests` auto-stamp on `.applied`; `JobDetailView` `#Preview`) stands. If a footer/status pure
helper is extracted during Milestone A/B, ensure it doesn't reintroduce the button.

**On-device.** N/a (UI only).

---

## Milestone D — Generation controls: fidelity scale, tailored aspects, and presets

**What's wanted.** Give the user control over how the tailored application is generated, from a controls
panel shown before generating:
1. **Rename the generate button** from "Generate résumé & cover letter" (`JobDetailView.swift:221`) to
   **"Generate application"** *(Taylor asked for "Generate portfolio"; we picked a non-colliding label
   because "Portfolio" already names the input area / nav section — the output is an `ApplicationKit`.
   Final wording is Taylor's; "Generate application" matches the existing `Application*` naming.)*
2. **A generation-fidelity scale** (analogous to LLM temperature), a slider `0.0…1.0`: **0 = authentic**
   (verbatim real experience), **~0.5 = curated** (reorder / rephrase / emphasize — today's grounded
   behaviour), **→1.0 = embellished**, and at the very top **invented** content is permitted. Per Taylor's
   call ("allow fabrication, clearly flagged"), anything beyond the real profile is **disclosed** — see D-E.
3. **Tailored-aspect checkboxes** — Summary/Headline, Work Experience, Projects, Skills, Education, Cover
   Letter. **None checked = tailor all**; checking a subset tailors only those, leaving the rest authentic.
4. **Presets** — save a (fidelity + aspects) configuration under a name and reuse it on the current job or
   any other job.

**⚠️ Integrity note (drives D-E and the principle edits).** Generation is **grounded by default** — the
existing "never fabricate" hard rule holds at fidelity 0. The upper scale is an **explicit opt-in**, and
invented content must be **surfaced, never silent**. The **desired rank-match target (D-F) is the most
aggressive mode** — it overrides fidelity *and* aspects and auto-climbs to full fabrication to hit a score —
so its D-E disclosure (list every invention + a prominent "draft — verify before sending" warning + the
achieved score) is **mandatory, not optional**. This planning pass revises SPEC → "Grounded generation" and
CLAUDE.md → "Hard rules for generated content" to the *grounded-by-default + opt-in + disclosed* model. Keep
the default path byte-for-byte unchanged.

**Seam + files (touches Presentation + Business + Data; optional Infrastructure — NOT Presentation-only).**
- **Data/Models (new):** `GenerationSettings` (`fidelity: Double` + `aspects: Set<TailoredAspect>` +
  `desiredRankMatch: Int?`; `.default` = fidelity 0 / empty aspects / nil target = grounded, tailor-all),
  `TailoredAspect` enum, `GenerationPreset` (id + name + `GenerationSettings`). All `Codable`/`Sendable`,
  `@Model`-free. **Control hierarchy:** `desiredRankMatch` (master) **overrides** `fidelity` **and**
  `aspects` when set (D-F); with no target, `fidelity` + `aspects` apply (D-B/D-C).
- **Data/LLM:** `LLMProvider.generateApplication(...)` grows a `settings: GenerationSettings` param **with a
  forwarding default** (mirrors how `grounding` was added — stubs/engines untouched, default = today's
  prompt). `Prompts.generateApplication(...)` grows `settings` and scales latitude + restricts aspects.
  `LLMRouter` + `FoundationModelsProvider` + `ClaudeCodeProvider` thread it through.
- **Data/Persistence (new):** `GenerationPresetsRepository` on the existing `PersistentRecordStore`
  (`kind` "generationPreset"), mirroring `SavedSearchesRepository`.
- **Business/UseCases:** `GenerateApplicationUseCase` accepts `settings` and forwards it; new
  `SaveGenerationPresetUseCase` / `LoadGenerationPresetsUseCase` / `DeleteGenerationPresetUseCase`.
- **Presentation:** the button rename + a **generation-controls panel** (slider + checkboxes + preset
  save/pick) on the Application view (`ApplicationSheet.swift` / its window from Milestone B) driven by
  `ApplicationViewModel`; `generate(...)` passes the current `GenerationSettings`.
- **Infrastructure (optional):** if fidelity should also nudge sampling temperature, `FoundationModelsClient.respond`
  gains a `GenerationOptions(temperature:)` — see D-B open call (Claude CLI can't set it, so this stays
  secondary to prompt latitude).

### D-A — Button rename + controls panel scaffold

- [ ] Rename the footer button to **"Generate application"** (`JobDetailView.swift:221`); keep Milestone A's
      **View** button label consistent ("View application").
- [ ] Add a `GenerationSettings` `@State`/VM property and a controls panel surfaced before generation
      (inline on the Application view, or a small "Options" disclosure). Panel hosts D-B/D-C/D-D controls.
- [ ] `ApplicationViewModel.generate(...)` and `open(...)` thread `settings` into `GenerateApplicationUseCase`.

### D-B — Generation-fidelity scale

- [ ] Add `GenerationSettings.fidelity: Double` (0…1) + a labelled `Slider` (tick labels: Authentic /
      Curated / Embellished). Default **0**.
- [ ] `Prompts.generateApplication` scales latitude by band: **0** = "reorder/rephrase real experience only,
      never invent" (today's text verbatim); **mid** = "curate, emphasize, infer reasonable adjacent skills,
      still no invented employers/titles/dates/credentials"; **top** = permit plausible additions, each of
      which MUST be reported (feeds D-E disclosure). Default band = the current prompt **byte-for-byte**.
- [ ] **(open call)** Also set LLM **sampling** temperature from fidelity? Recommend **no** for now — map
      fidelity to *prompt latitude* only (engine-agnostic; the Claude `-p` path can't set temperature). If
      yes, add `GenerationOptions(temperature:)` to `FoundationModelsClient.respond` (on-device only).
- [ ] **(open call)** Exact band thresholds + labels (e.g. 0.0–0.15 authentic / 0.15–0.75 curated /
      0.75–1.0 embellished). Recommend the implementer tune against real output.

### D-C — Tailored-aspect checkboxes

- [ ] `TailoredAspect` enum: `summary`, `experience`, `projects`, `skills`, `education`, `coverLetter`
      (each with a `label`). `GenerationSettings.aspects: Set<TailoredAspect>` — **empty = all**.
- [ ] Checkbox group in the panel (toggles the set). Prompt: when non-empty, instruct the model to tailor
      **only** the named sections and reproduce the rest authentically; when empty, tailor everything
      (today's behaviour). Since `resumeMarkdown` is freeform, this is instruction-driven — name the sections.
- [ ] **(open call)** "Education" tailoring at fidelity 0 is effectively verbatim (facts only) — confirm the
      aspect list; drop any that never make sense to "tailor."

### D-D — Presets (save + reuse across jobs)

- [ ] `GenerationPreset` (id + name + `GenerationSettings` — incl. `desiredRankMatch`) +
      `GenerationPresetsRepository` (`kind` "generationPreset", upsert, newest-first) on
      `PersistentRecordStore`, mirroring `SavedSearchesRepository`.
- [ ] `SaveGenerationPresetUseCase` / `LoadGenerationPresetsUseCase` / `DeleteGenerationPresetUseCase`; wire
      through `Composition`.
- [ ] Panel UI: **Save as preset…** (names the current fidelity+aspects), a **preset picker** that applies a
      saved preset to the current job, and delete. Presets are **global** — reusable on any job.

### D-E — Disclosure of embellished / invented content (integrity safeguard)

- [ ] When `fidelity` is in the embellishing band, the prompt must **list every addition not supported by
      the profile** — extend `ApplicationKit.gapNote` (or add a dedicated `disclosures` field) to carry them.
- [ ] UI: show a prominent **warning banner** on the generated output ("Contains embellished/unverified
      content — verify before sending") and a **"draft — verify"** marker; list the disclosed additions.
- [ ] **Docs (this pass):** revise SPEC "Grounded generation" + CLAUDE.md "Hard rules for generated
      content" to *grounded-by-default + opt-in + disclosed* (done during planning; keep prompt/UI in sync
      when built).
- [ ] **(open call)** Whether to also stamp exported PDF/DOCX with a visible "draft" watermark when
      fidelity is high. Recommend a small footer line in the export rather than a full watermark.

### D-F — Desired rank-match target (outcome-driven generation loop; the master control)

The **hierarchical top** of the generation controls: instead of setting *how much* to embellish (fidelity)
or *where* (aspects), the user sets a **target fit score** and the app fabricates as needed to reach it.
Per Taylor's calls: **when a target is set it overrides BOTH the fidelity slider AND the aspect
checkboxes** — it tailors/fabricates across all areas and climbs latitude up to full fabrication until the
score is met. This is the app's **most aggressive** mode; D-E disclosure is non-negotiable here.

- [ ] **Model.** `GenerationSettings.desiredRankMatch: Int?` (0–100, `nil` = off). When non-nil, `fidelity`
      and `aspects` are ignored by generation (and disabled/greyed in the UI, D-A panel).
- [ ] **Scoring the generated output.** Fit scores today come from `provider.rank(jobs:against:) → [JobMatch]`
      (`JobMatch.score` 0–100), which scores a `JobListing` against a `CandidateProfile` — not against a
      generated `ApplicationKit`. **(open call)** how to score the tailored output: **(a)** add a dedicated
      `LLMProvider.scoreApplication(job:brief:kit:) → JobMatch` step (one call per iteration — **recommended**,
      cheaper, no profile rebuild), or **(b)** distil a throwaway `CandidateProfile` from the tailored résumé
      (`buildProfile`) and reuse `JobRanker`/`rank` (heavier: 2 calls/iteration). Keep both engines in lockstep
      via shared `Prompts`.
- [ ] **The loop (Business).** A `GenerateToTargetUseCase` (or an extended `GenerateApplicationUseCase`):
      generate → score → if `< desiredRankMatch`, escalate latitude (foreground more must-have keywords,
      convert gaps into claims) and regenerate → repeat. **Hard iteration/cost cap** (e.g. ≤ 4 rounds — even
      with fidelity overridden, cost/on-device latency must be bounded). If the target isn't reached within
      the cap, return the **best-scoring** attempt with a note ("reached 78 of your 85 target"). Accumulate
      D-E disclosures across all rounds.
- [ ] **UI.** A **rank slider** (0–100) with an on/off affordance in the controls panel, sitting **above**
      the fidelity slider + checkboxes (visually the master control); when engaged, grey out fidelity +
      aspects and show a prominent notice that the app will **fabricate as needed to hit the target** +
      the D-E "draft — verify before sending" warning. Surface the **achieved score** on the result.
- [ ] **(open call)** Minimum sensible target / step (e.g. slider snaps to 5s; a very high target like 100
      may be unreachable — the "best achieved + note" path covers it).

**Tests.**
- `PromptsTests`: default settings ⇒ the generation prompt is **unchanged byte-for-byte** (mirrors the
  grounding "profile-only unchanged" test); a mid/high fidelity changes latitude wording; a non-empty
  aspect set restricts the "tailor only these" instruction; high fidelity requires the disclosure clause.
- `GenerationPresetsRepositoryTests` (round-trip newest-first, upsert, delete) + preset use-case tests
  (mirror `SavedSearchesRepositoryTests`).
- `ClaudeCodeProviderTests` / `LLMRouterTests`: `settings` reaches the prompt; forwarding default keeps
  old call sites compiling.
- `ApplicationViewModel`: `generate` forwards settings; the disclosure banner shows when fidelity is high.
- **D-F loop** (`GenerateToTargetUseCase`): with a stub provider whose scores rise per round, the loop stops
  once `score ≥ target`; it stops at the **iteration cap** and returns the best attempt + a shortfall note
  when the target is unreachable; a set `desiredRankMatch` makes generation **ignore** `fidelity`/`aspects`;
  disclosures accumulate across rounds.

**On-device.** Yes — presets are a local store; generation uses the current `.application` engine. If D-B's
optional sampling-temperature is adopted, it applies to the **on-device** path only (the `claude -p` CLI
can't set temperature), so fidelity stays primarily prompt-driven to keep the two engines in lockstep.
