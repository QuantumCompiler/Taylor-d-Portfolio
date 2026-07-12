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
> version is bumped to **0.5.0**. **Milestones A, B, and C are shipped** (see `MILESTONES.md`); **the next up
> is Milestone D below.** Planned: **A** ✅ (view generated materials from the Tracker), **B** ✅ (job detail +
> Application as real windows), **C** ✅ (removed the redundant "Mark as applied" button), **D**
> (generation controls — fidelity scale, tailored aspects, presets, and a desired rank-match target that
> fabricates to a target score; grounded-by-default + opt-in disclosed embellishment).
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

## Milestone A — View generated résumé & cover letter from the Tracker  ✅ done → `MILESTONES.md`

Shipped: a **View résumé & cover letter** button + **Regenerate** in the Tracker detail footer when a
generated kit exists, detected via `LoadApplicationUseCase` and routed by a new `ApplicationStartMode`
(view = load-only, no LLM; regenerate = fresh). Pure `JobDetailFooter.resolve` decides the footer, covered
by `JobDetailFooterTests`. Full write-up in `MILESTONES.md`.

> **Note for Milestone B (builds on shipped A).** A added the Tracker's **View / Regenerate / Generate**
> footer buttons via a `.sheet` (`JobDetailView` → `ApplicationSheet`, `startMode:`). When B converts the
> Application view to a real window, migrate those buttons to `openWindow` — same footer/presentation code.

---

## Milestone B — Present job detail (and its Application view) as real windows, not sheets  ✅ done → `MILESTONES.md`

Shipped (B-A + B-B + B-C): the job-detail and Application sheets are now detached single-instance `Window`
scenes driven by a shared `AppSession` (profile/grounding + selection + a revision token for list reloads).
The dead detail params on `ResultsView`/`TrackerView`/`RootView` were removed in the same pass. Full
write-up in `MILESTONES.md`.

---

## Milestone C — Remove the "Mark as applied" button (the status menu covers it)  ✅ done → `MILESTONES.md`

Shipped: removed the redundant "Mark as applied" button from `JobDetailView.statusSection`; Applied stays
reachable via **Set status → Applied** with the same auto-stamp. Write-up in `MILESTONES.md`.

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

> **Build status (v0.5.0).** **D-A + D-B + D-C are done** (compiles warning-free, full suite green):
> `GenerationSettings` / `TailoredAspect` / `FidelityBand` models; `settings` threaded
> `GenerateApplicationUseCase` → `LLMProvider.generateApplication(…settings:)` (new requirement + forwarding
> default) → `Prompts.generateApplication` (a `generationControls(_:)` addendum — **default is byte-for-byte
> unchanged**, non-default appends latitude + aspect scope + the embellished-band disclosure clause); both
> providers + router override; `ApplicationViewModel.generationSettings`; a "Generation options" panel
> (fidelity slider + aspect checkboxes) + an embellished-band warning banner on the Application view; button
> renamed **"Generate application"** / **"View application"**. Tests: `GenerationSettingsTests`, `PromptsTests`
> (default-unchanged / curated / embellished-disclosure / aspect-scope). **Remaining: the D-C revision
> (narrow `TailoredAspect` to the four résumé sections — drop `education`/`coverLetter` — + a keyword/
> description-matching goal), D-D (presets), D-E (fuller disclosure UI — prompt clause + warning banner
> already in), D-F (rank-target loop).**

### D-A — Button rename + controls panel scaffold  ✅ done

- [ ] Rename the footer button to **"Generate application"** (`JobDetailView.swift:221`); keep Milestone A's
      **View** button label consistent ("View application").
- [ ] Add a `GenerationSettings` `@State`/VM property and a controls panel surfaced before generation
      (inline on the Application view, or a small "Options" disclosure). Panel hosts D-B/D-C/D-D controls.
- [ ] `ApplicationViewModel.generate(...)` and `open(...)` thread `settings` into `GenerateApplicationUseCase`.

### D-B — Generation-fidelity scale  ✅ done  (open call resolved: prompt-latitude only, no sampling-temperature; bands 0.15 / 0.75)

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

### D-C — Tailored-aspect checkboxes (résumé sections only)  ✅ built, ⚠️ revision pending

> **Revision (post-build).** D-C shipped with a six-case `TailoredAspect`
> (`summary`/`experience`/`projects`/`skills`/`education`/`coverLetter`). Taylor has narrowed it to the four
> résumé sections and sharpened the tailoring goal — the checkboxes below capture the follow-up code change.

- [x] `TailoredAspect` enum + `GenerationSettings.aspects: Set<TailoredAspect>` (**empty = all**) + checkbox
      group + instruction-driven prompt scope. *(Built.)*
- [ ] **Drop `education` and `coverLetter` from `TailoredAspect`** → final set is `summary`, `experience`,
      `projects`, `skills`. **Why:** education is factual and **never embellished** (stays verbatim regardless
      of settings), and the cover letter is **not** independently tailorable (see below). Remove their
      checkboxes + any prompt handling. *(Low risk — presets/persistence for settings aren't built yet, so no
      stored enum values to migrate; if `GenerationSettings` is persisted by the time this lands, decode
      unknown cases leniently.)*
- [ ] **Sharpen the tailoring goal in the prompt.** Each selected section is tailored with **one explicit
      objective: match the job post's keywords and description** — surface the `TargetBrief` must-have /
      nice-to-have keywords and the JD language that are supported for this candidate under the current
      fidelity / rank settings. State this goal for the named sections.
- [ ] **Cover letter follows the curated résumé.** The cover letter is generated **from the curated/tailored
      résumé** (not tailored on its own), so it inherits the résumé's keyword alignment automatically — which
      is why it isn't a checkbox. Ensure the cover-letter step is grounded in the freshly-tailored
      `resumeMarkdown` (+ the cover-letter voice exemplar from `PortfolioGrounding`). *(open call: keep the
      single-shot `ApplicationKit` generation but instruct the prompt to derive the letter from the tailored
      résumé, vs. a two-step résumé→letter chain. Recommend the single-shot instruction first; split only if
      the letter drifts from the résumé.)*
- [ ] **Tests.** Update `PromptsTests` aspect-scope cases to the four-section set; assert the prompt names the
      keyword/description-matching goal for selected sections; assert `education`/`coverLetter` are gone.

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
