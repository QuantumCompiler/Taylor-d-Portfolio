# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.1 — keyword match & ATS coverage (in progress) → Milestone C.** A **patch release** on
> shipped v0.6.0, scheduled out of `PLANNED.md` (the *keyword match / ATS coverage at generation* entry, its sole
> `Target: v0.6.1`). Four milestones **A–D**, in build order: ~~**A** (pure `KeywordCoverage` value type)~~ and
> ~~**B** (surface the `TargetBrief`)~~ **✅ done — write-ups in `MILESTONES.md`** → **C** (the coverage panel) →
> **D** (the optional keyword-emphasis generation control). **Pick up at Milestone C** — `ApplicationViewModel`
> now exposes both `kit` and `brief`, which is everything the panel needs. Milestones restart at **A** and commit
> as `v0.6.1 : Milestone X Completed`.
>
> **v0.6.0 (richer grounding, job detail & sources) shipped** — all eleven milestones **A–K** are written up
> in `MILESTONES.md` and ticked in `ROADMAP.md`.
>
> **⚠️ Awaiting device checks** — carried forward; everything automatable is done and green, but these need a
> real run (each milestone's full write-up is in `MILESTONES.md`). Settings → About should read **0.6.1**.
> - **v0.5.0** — detail + Application as separate windows; cross-window list refresh; explicit Generate + options
>   panel (fidelity / aspects / presets / embellished disclosures / rank-target loop); Results swipe + remove-from-Tracker; no spurious Photos/Music prompts.
> - **v0.5.1** — awesome-cv LaTeX **PDF / `.tex`** export (needs `lualatex`; item hidden when TeX is absent); résumé
>   & cover letter export separately; Tracker **sort**; additional-context steers a regeneration; About shows LaTeX availability.
> - **v0.6.0 A–E** — enrich-on-save (badges + structured detail); per-generation **profile picker** grounds on that
>   profile; **Regenerate result** re-scores + backfills + honours the context box; Settings → Sources credential save/lock/mask/clear + **no keychain prompt** + live banner lift; **full de-chromed** posting text vs. snippet fallback.
> - **v0.6.0 F–H** — Adzuna **and** JSearch both return (cross-source dupes collapse; JSearch-only works); per-provider
>   "How to get a key" + Setup steps; Search **"Search sources"** selector enable/disable + saved-search source restore.
> - **v0.6.0 I** — supporting-docs slot (add/remove, survives save + relaunch); Source Documents lists them; generation draws on the extra signal.
> - **v0.6.0 J** — **AI job search** in Engines / Sources / selector (engine-based availability, no key); **AI-suggested**
>   leads with chip + "not verified" banner + web-search link; AI/API dupe collapses; AI-only search works with no API keys.
> - **v0.6.0 K** — rows appear immediately, then **"Standardizing descriptions…"**; uniform **standardized Description**
>   across sources; empty digest keeps raw (no error); persisted + not re-digested; generation grounds on it.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.1 — keyword match & ATS coverage

**The theme.** ATS / AI résumé screeners filter on a posting's keywords, and good candidates get
auto-rejected for missing a few. The honest, effective answer — explicitly **not** hidden "invisible-ink"
white-text keyword stuffing, which backfires (ATS parse to plain text, recruiters see it, LLM screeners flag
it) — is to surface how well the generated résumé covers the posting's **real** keywords **in visible text**,
so the user aligns truthfully with what the screener looks for. **Everything here is visible-text-only —
that's the whole point.** Most of the data already exists: the posting's keywords are distilled into
`TargetBrief` at generation stage 1, and the résumé is `ApplicationKit.resumeMarkdown`.

**Scope + layers.** Patch-sized (`.1`): a pure Data value type (A), a small Business/Presentation change to
carry the brief out of generation (B), a Presentation panel (C), and a `GenerationSettings` flag + `Prompts`
block (D). **No new seam and no `LLMProvider` change** — so nothing to forward in
`SettingsBackedLLMProvider` (`Composition.swift:366`+).

**Transparency.** Coverage reports **truthfully** what's in the visible résumé; D's emphasis option weaves in
keywords that **genuinely apply** and routes the rest to the gap note, so the user sees covered vs. missing and
decides what to claim. **No hidden text** — the deliberate opposite of the invisible-ink idea this replaces.

**Out of scope (noted, not folded in).** An **ATS-friendly export mode** — standard section headings,
single-column, selectable text (no text-in-images) — is what actually determines whether an ATS can *parse* the
résumé at all. Natural pairing with keyword coverage, but it's an export/template concern touching
`ExportTemplate` / `TexDocumentBuilder`, not this release. If Taylor wants it, spec it as its own `PLANNED.md`
entry with its own `Target:`.

## Milestone C — Coverage panel in the Application view

**What's wanted.** Show the user, on the generated result, **"Posting keywords: X/Y covered"** with the covered
list (green) and the missing list (amber), computed on the **visible** résumé and recomputed after every
generate/regenerate.

**Seam + files (Presentation only).**
- A `coverage` computed property on `ApplicationViewModel` (`kit` + `brief` → `KeywordCoverage`) — because both
  are `@Observable` state, it recomputes after generate/regenerate for free.
- A `coverageSection` in [`ApplicationSheet`](../src/Presentation/Application/View/ApplicationSheet.swift:429),
  rendered in `content` next to the existing result panels — `documentSection` (`:461`), `disclosuresSection`
  (`:482`), `gapsSection` (`:502`) — as a `GroupBox` in the same visual family.

**Sub-tasks.**
- [ ] `ApplicationViewModel.coverage` (nil when either `kit` or `brief` is missing).
- [ ] `coverageSection`: headline count + per-tier covered/missing chips (green / amber), matching the
      `disclosuresSection` / `gapsSection` styling so it reads as part of the result, not a new UI language.
- [ ] Place it in `content` (`:429`) — **(open call) above or below the two documents?** *Recommended:*
      **below the documents, above the disclosures/gaps**, so the user reads the output first, then the
      alignment report, then the honesty surfaces.
- [ ] Empty state: no brief — a saved kit whose record predates Milestone B, so `ApplicationViewModel.brief`
      comes back nil — → **hide** the panel rather than showing a misleading "0/0 covered".
- [ ] Zero-keyword posting (a thin brief) → hide the panel too; don't render an empty box.

**Tests.** `lib/tests/Presentation/Application/` — the VM's `coverage` is nil without a kit/brief and reflects
kit + brief when both are present; view rendering stays untested, consistent with the rest of the codebase.

**On-device.** n/a — pure local rendering over A's computation.

## Milestone D — Optional keyword-emphasis generation control

**What's wanted.** An **opt-in** control that tells generation to weave the posting's must-have keywords into
the **visible** résumé **where they truthfully apply**, and route the ones that don't fit into `gapNote` — so
the user sees what's missing and decides. **Report-only stays the default** (A–C alone change nothing about
what's generated).

**Seam + files (Data + Presentation).**
- [`GenerationSettings`](../src/Data/Models/GenerationSettings.swift) gains a dedicated
  `emphasizeKeywords: Bool = false`.
  **⚠️ Not a `TailoredAspect` case** — `PLANNED.md` recommended one, but the real code says otherwise:
  `TailoredAspect` is documented and *prompted* as a **résumé section** (`:10`–`:16`), and
  [`Prompts.generationControls`](../src/Data/LLM/Prompts.swift:546) renders the selection as
  *"tailor ONLY these résumé sections — …"* (`:553`). A non-section case would corrupt that sentence and the
  preset semantics. A flag costs one checkbox and keeps both clean.
- Add the flag to `CodingKeys` (`:77`) so it persists into a `GenerationPreset`, defaulting `false` so legacy
  preset blobs still decode; include it in `hasDefaultControls` (`:91`) so the default path stays
  **byte-for-byte** the base prompt.
- `Prompts.generationControls(_:)` (`:525`) appends the keyword clause when the flag is on. Note it **sharpens**
  the existing Objective line (`:557`), which already says to foreground the brief's keywords "wherever they are
  genuinely supported" — D turns that into an explicit *cover-it-or-declare-it* instruction rather than
  duplicating it.
- A checkbox in `generationControlsPanel`
  ([`ApplicationSheet.swift:143`](../src/Presentation/Application/View/ApplicationSheet.swift:143)), near the
  tailored-aspect checkboxes (`:167`–`:176`).

**Sub-tasks.**
- [ ] `GenerationSettings.emphasizeKeywords` + `CodingKeys` + `hasDefaultControls`; legacy-decode default.
- [ ] `Prompts.generationControls` keyword clause: weave the **must-have** keywords into the visible résumé
      **only where they're genuinely true** for this candidate; every keyword that can't be truthfully claimed
      goes into `gapNote`. Explicitly **no hidden/white text, no keyword lists appended for the parser** — the
      résumé stays a document a human reads.
- [ ] The checkbox in `generationControlsPanel`, with a one-line caption naming what it does.
- [ ] **(open call) Behaviour under a rank target?** `GenerateToTargetUseCase` builds its own
      `GenerationSettings` per round (`:55`), discarding the user's fidelity/aspects — so the flag is dropped
      unless threaded. *Recommended:* **thread it through**, exactly as `additionalContext` already rides along
      (`:56`), and leave the checkbox enabled under a rank target (it's an alignment/honesty control, not a
      latitude one) — unlike the fidelity slider and aspect checkboxes, which are correctly disabled by
      `rankTargetOn` (`:260`).
- [ ] **(open call) Which tiers does the prompt push?** *Recommended:* **must-have only** — nice-to-have and
      tech-stack keywords stay reported (C) but unpushed, so the résumé isn't stuffed with marginal terms.

**Tests.** `lib/tests/Data/LLM/` — with the flag off the prompt is **byte-for-byte** the current output; with it
on the keyword clause appears exactly once and the gap-note routing instruction is present. `lib/tests/Data/Models/`
— `GenerationSettings` Codable round-trip with the flag, and a legacy blob (no key) decoding to `false`;
`hasDefaultControls` / `isDefault` unaffected when the flag is off.

**On-device.** The optional emphasis is `.application`-task LLM work on the **existing** engine and prompt path —
no new engine, task, or seam.

## Release hygiene (v0.6.1)

- [x] **`MARKETING_VERSION` → `0.6.1`** in all **4** copies in `project.pbxproj` (Debug/Release × app/test), so
      Settings → About reports the real version (`CLAUDE.md` → "Keep the project version in sync").
- [ ] On wrap: move each completed milestone's write-up into `MILESTONES.md`, tick it in `ROADMAP.md`, flip the
      `## v0.6.1 —` header to **(complete)**, add the `README.md` version summary, and point the `README.md`
      **Next:** line forward **without naming** the next version.
