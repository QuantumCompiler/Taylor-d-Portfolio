# Taylor'd Portfolio — Planned (specced, not yet versioned)

A **staging area** for features and bug fixes that have been discussed and specced but are **not yet assigned
to a version**. It sits between `ROADMAP.md`'s loose Backlog (one-line ideas) and `TODO.md` (the lettered
milestones of the *in-progress* version): entries here are written up in enough detail — real seams, files,
open calls — that when Taylor schedules one into a version it can be lifted almost verbatim into that version's
`TODO.md` + `ROADMAP.md` as Milestone A, B, C…

**How to use it.** Add a specced item here when it's described in chat but isn't part of the current version.
When a version picks it up, move its write-up into that version's `TODO.md` (as lettered milestones), tick /
reference it in `ROADMAP.md`, and **remove it from here** (this file only holds *unscheduled* work). Each entry
still respects the layer dependency rule and names the real seam, per `CLAUDE.md` → "Working process →
Planning sessions".

**Every entry records a `Target:` line** — the release it's intended for (the in-progress version, a future
`v0.x.0`, or *backlog / unassigned*). **Ask Taylor which version an item goes into when you add it** — don't
guess. The target is the entry's *intended* release; it's distinct from being *scheduled* (an entry can read
`Target: v0.x.0` and still live here until that version's planning lifts it into `TODO.md`).

**Entries are ordered by ascending target version.** All `v0.6.0` entries come before `v0.6.1`, which come before
`v0.7.0`, and so on; *backlog / unassigned* entries sort last. When adding an entry, **insert it at its target's
position**, not at the end — e.g. a later-added `v0.6.1` item slots **between** the `v0.6.0` group and any `v0.7.0`
group (so the file always reads earliest-target → latest-target, top to bottom).

> **Two entries below**, in ascending target order: **keyword-match / ATS coverage** targets **`v0.6.1`** (a patch
> on v0.6.0); **customizable LaTeX styles** targets **`v0.7.0`**. The **supporting profile documents** entry was
> scheduled into **v0.6.0** as **Milestone I** (2026-07-15) and now lives in `TODO.md` / `ROADMAP.md`. Prior specced
> entries were also scheduled into **v0.6.0 (richer grounding, job detail & sources)**:
> - **richer job postings**, **select a profile at generation time**, **regenerate result** → Milestones **A–C**.
> - **user-editable API credentials**, **full job-posting text**, **multi-source job search** → Milestones **D–F**.
> - **per-provider credential-setup help**, **provider selector in Search** → Milestones **G–H** (scheduled
>   2026-07-15; extend D and F respectively).
>
> Add new specced-but-unscheduled work below as it comes up in chat — each with its `Target:` release, in
> ascending target-version order.

---

## Keyword match / ATS coverage at generation — visible keyword alignment, no hidden text

**Target:** **v0.6.1** (a patch on v0.6.0). Moderate.

**Why.** ATS / AI résumé screeners filter on the posting's keywords, and good candidates get auto-rejected for
missing a few. The honest, effective answer (explicitly **not** hidden "invisible-ink" white-text keyword stuffing,
which backfires — ATS parse to plain text, recruiters see it, LLM screeners flag it) is to surface how well the
generated résumé covers the posting's **real** keywords **in visible text**, so the user aligns truthfully with what
the screener looks for. Everything here is visible-text-only — that's the whole point.

**The seam + files (most of the data already exists).**
- **Coverage computation — a pure value type.** Add a `KeywordCoverage` (Data or Business, pure/`Sendable`,
  unit-testable): given the posting keywords from
  [`TargetBrief`](../src/Data/Models/TargetBrief.swift) (`mustHaveKeywords` + `niceToHaveKeywords` + `techStack`)
  and the generated visible résumé (`ApplicationKit.resumeMarkdown` → plain text via
  `MarkdownPlainText`), compute **covered vs. missing** per tier (case-insensitive, word-boundary match, light
  normalization). `JobMatch.matchedSkills` / `missingSkills` already exist from ranking and can seed/cross-check it,
  but coverage is specifically *posting-keyword vs. the actual résumé text*.
- **Generation option — a toggle.** Add a **keyword-match** option to
  [`GenerationSettings`](../src/Data/Models/GenerationSettings.swift) — either a new `TailoredAspect` case (fits the
  existing `aspects: Set<TailoredAspect>` checkboxes + presets) or a dedicated flag. When on, the `Prompts`
  generation block is told to **weave the posting's must-have keywords into the visible résumé where they truthfully
  apply**, and route keywords that don't fit into the `gapNote` — so the user sees what's missing and decides.
  Forwarding default so stubs/engines are unaffected.
- **UI — a coverage panel.** In the generation controls / result view (`ApplicationSheet` `generationControlsPanel`
  or the generated-result view): **"Posting keywords: X/Y covered,"** with the covered list (green) and missing list
  (amber), computed on the **visible** résumé and recomputed after generate/regenerate.

**Related (optional companion, could be its own entry).** An **ATS-friendly export mode** — standard section
headings, single-column, selectable text (no text-in-images) — is what actually determines whether an ATS can parse
the résumé at all. Natural pairing with keyword coverage; note it, don't fold it in unless scoped together.

**Open calls (recommended defaults).**
- **`TailoredAspect` case vs. dedicated flag?** *Recommended:* a `TailoredAspect` case — reuses the checkbox UI +
  preset save/apply.
- **Which keyword tiers count?** *Recommended:* weight **must-have**, but show all three tiers (must / nice /
  tech-stack) in the coverage view.
- **Match strictness (exact / stemmed / synonyms)?** *Recommended:* case-insensitive word-boundary + light
  normalization first; stemming/synonyms later.
- **Report-only vs. auto-emphasize?** *Recommended:* **report-only by default**, with the opt-in emphasis toggle —
  the user stays in control of what's claimed.

**Transparency.** Coverage reports **truthfully** what's in the visible résumé; the emphasis option weaves in
keywords that **genuinely apply** and routes the rest to the gap note (the user sees covered vs. missing and decides
what to claim). **No hidden text** — the deliberate opposite of the invisible-ink idea this replaces.

**On-device.** Coverage is pure/local string matching; the optional emphasis is `.application`-task LLM work on the
existing engine — no new engine or seam.

**Scope.** Moderate, patch-sized (`.1`) — a `KeywordCoverage` value type + a `GenerationSettings` toggle + a
`Prompts` block + a coverage panel. Composes with the already-extracted `TargetBrief` keywords and `JobMatch`
skills. Respects the layer rule (Data/Business coverage ← Presentation panel).

---

## Customizable LaTeX document styles — templates, typography, layout & a raw-LaTeX escape hatch

**Target:** **v0.7.0**. Large feature — will break into ~6 milestones at kickoff (decomposition suggested below).

**Why.** The awesome-cv LaTeX PDF route (v0.5.1) is a **single fixed template** that mimics Taylor's hand-authored
résumé. [`TexDocumentBuilder`](../src/Infrastructure/Tex/TexDocumentBuilder.swift) hardcodes every presentation
choice: the class + font size (`\documentclass[6pt]{Class/Resume}`, `TexDocumentBuilder.swift:244`), the margins
(`\geometry{…}`, `:245`), the bundled font dir (`\fontdir[fonts/]`), the **section order**
(`canonicalOrder`, `:213` → Education→Experience→Projects→Skills) and per-section spacing (`sectionVSpace`, `:223`),
and the cover letter's own `\documentclass[11pt, a4paper]` + `parskip`/`linespread` (`:280`, `:70`). The user wants
a **fully customizable LaTeX style** the user sets in the app instead of this one baked-in look.

**Decisions (locked in planning, 2026-07-15).**
- **Approach:** *both* **multiple built-in templates/themes** *and* a **user-editable raw-LaTeX escape hatch** for
  power users (not just parameterizing one template).
- **Controls exposed:** **font family & size**, **accent/theme color**, **margins + spacing + page size**
  (US Letter / A4), and **section order / layout** (reorder / show-hide).
- **Granularity:** **reusable *named* styles** in an app-wide library, **chosen at export time** (mirrors how
  saved profiles / generation presets already work).
- **Résumé vs. cover letter:** **one shared style** applied to **both** documents (unifies today's divergent
  hardcoded résumé/letter geometry; only doc-inherent bits like the letter's `\makeletterclosing` stay per-type).

**⚠️ Naming — don't collide with the existing template type.** There is **already** an
[`ExportTemplate`](../src/Infrastructure/Export/ExportTemplate.swift) + `TemplateStyle` (classic / compact / modern)
— but that themes the **native Core Text** PDF/DOCX exports (v0.3.0 Milestone X), **not** LaTeX. The new type is
LaTeX-specific; name it distinctly (e.g. **`LaTeXStyle`** / `SavedDocumentStyle`) and keep the two separate. (An
eventual unification is a later question — open call.)

**Seam + files.**
- **`LaTeXStyle` value type** (Infrastructure/Tex or Data; pure, `Sendable`, `Codable`): `template` (built-in
  template id), `fontFamily`, `fontSizePt`, `accentColor`, `pageSize`, margins/section/line spacing, `sectionOrder`
  + `hiddenSections`, and an optional **`customPreamble: String?`** (the raw-LaTeX override).
- **Built-in template registry** — an **enumerable source of truth** (mirror the `JobProviderRegistry` pattern from
  v0.6.0 H-A): each built-in template is a descriptor pairing a bundled class set (resolved via
  [`TexAssets`](../src/Infrastructure/Tex/TexAssets.swift)) with its default `LaTeXStyle`. **Adding a template =
  appending one descriptor + its `.cls` assets under `lib/tex/Class/`** — never hand-enumerated in a view.
- **Parameterize `TexDocumentBuilder`** (the core change): `resume(fromMarkdown:style:)` /
  `coverLetter(fromMarkdown:style:)` build the preamble **from the style** instead of the hardcoded literals —
  documentclass options + font size, `\geometry` from margins/page size, accent color via awesome-cv's colour
  mechanism, `\fontdir` for the chosen family, and **section order/visibility driving** what `canonicalOrder`
  (`:213`) / `sectionVSpace` (`:223`) hardcode today. **All content escaping stays intact** (`escape`,
  `inlineLaTeX`, `plainLaTeX`).
- **Raw-LaTeX escape hatch** — when `customPreamble` is set, use it verbatim in place of the *generated* preamble;
  the **body is still app-generated + escaped** (the override themes presentation, never injects content). A
  broken override must **fail gracefully**: the compile already runs `\nonstopmode` via
  [`LaTeXProcessClient`](../src/Infrastructure/Tex/LaTeXProcessClient.swift), so surface the compile failure and
  offer **revert to a built-in**.
- **Persistence + library** — a `SavedDocumentStyle` (id / name / `LaTeXStyle`) via `PersistentRecordStore` +
  a `SavedDocumentStylesRepository` (mirror `SavedProfilesRepository`), plus a **default-style pointer** via
  `KeyValueStore` (mirror `DefaultProfileStore`).
- **UI** — a **"Document styles" manager** (create / name / duplicate / edit / delete; the four control groups;
  an advanced raw-LaTeX editor) in Settings or its own area, and a **style picker at export time** on the
  LaTeX route (`ApplicationSheet` export menu), defaulting to the default style. **LaTeX-only:** the native
  exports keep `ExportTemplate`.
- **Fonts** — family choice is limited to **bundled** faces (today Roboto + Source Sans under `lib/tex/fonts/`);
  more families ⇒ more bundled fonts (**licensing + bundle-size** — open call to curate a small set).

**Suggested milestone decomposition (at kickoff).**
- **A** — `LaTeXStyle` model + built-in template registry (descriptors).
- **B** — Parameterize `TexDocumentBuilder` typography/geometry/colour/page-size from a style.
- **C** — Section order / visibility from the style (replace the hardcoded ordering + spacing).
- **D** — Persistence: `SavedDocumentStyle` + repository + default pointer.
- **E** — Style-manager UI + export-time picker.
- **F** — Raw-LaTeX preamble override + graceful compile-failure handling / revert.

**Open calls (recommended defaults).**
- **Live preview vs. a "Preview" button?** *Recommended:* a **Preview button** that compiles a sample — a live
  preview pays the `lualatex` compile latency on every keystroke.
- **Apply styles to the native Core Text exports too, or LaTeX-only?** *Recommended:* **LaTeX-only** now (the
  controls are LaTeX-specific); revisit unifying with `ExportTemplate` later.
- **Font families beyond the bundled set?** *Recommended:* curate a **small, licensed** set; document bundle-size.
- **Unknown / generated section names in a user-defined order?** *Recommended:* known sections follow the style's
  order; unknown ones append **stably** (today's fallback), never dropped.

**Scoping constraint.** Styles theme **presentation only** — the raw-LaTeX override changes layout, **not** résumé
content: body text stays app-generated + escaped, so a template can't smuggle in content. (This is a correctness
boundary for the template system, not a fabrication rule — the fidelity control still governs content latitude.)

**On-device.** n/a for styling — pure text/preamble generation. Compiling still needs a local `lualatex`
(the existing **optional** TeX dependency; the route is simply disabled when absent). No model calls.

**Scope.** Large (`.0`, ~6 milestones): new Infra/Tex `LaTeXStyle` + template registry + a `TexDocumentBuilder`
rewrite, Data persistence (styles library + default pointer), and Presentation (manager + export picker). Distinct
from the native `ExportTemplate`. Respects the layer rule (Infra/Tex model + builder ← Data persistence ←
Presentation manager/picker).
