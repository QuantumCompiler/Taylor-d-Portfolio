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

> **Seven entries below**, in ascending target order: **keyword-match / ATS coverage** → **`v0.6.1`**;
> **discoverable remove-from-Tracker**, **multi-select bulk actions**, **Results sort + Tracker filter**,
> **hide imported-doc raw preview**, and **full source-document preview** → **`v0.6.2`**; **customizable LaTeX
> styles** → **`v0.7.0`**. The **supporting profile documents** entry was
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

## Discoverable remove-from-Tracker — surface the existing untrack / delete actions

**Target:** **v0.6.2** (a patch on v0.6.0). Small.

**Why (read this — the logic already exists).** The Tracker *already* supports both removals; they're just
**undiscoverable**. Leading-swipe a Tracker row = **"To Results"** → `returnToResults` (clears the job's status so it
returns to the general Results list); trailing-swipe = **"Delete"** → `delete` (forgets the listing + status + any
generated materials). Both are wired. But they're **swipe-only**, and swipe-to-reveal-row-actions is an iOS pattern
that's **undiscoverable on macOS** (no visible affordance; Mac users right-click or expect visible controls) — so in
practice there's "no way to remove a result from the Tracker." **The gap is the affordance, not the behaviour.**

**The seam + files (almost entirely Presentation — reuse the existing methods).**
- **The actions exist, wired.** [`TrackerViewModel.returnToResults(_:)`](../src/Presentation/Tracker/ViewModel/TrackerViewModel.swift:54)
  (via `UntrackJobUseCase`) and `.delete(_:)` (`:63`, via `DeleteSavedJobUseCase`), gated by `supportsRowActions`
  and injected in `Composition.makeTrackerViewModel`. **No Business/Data change needed.**
- **Add a discoverable affordance** in [`TrackerView`](../src/Presentation/Tracker/View/TrackerView.swift:104),
  alongside the existing swipes (`.swipeActions` at `:106`/`:112`):
  - a right-click **`contextMenu`** on the row (the native macOS pattern) — **"Return to Results"** +
    **"Delete"** (destructive); and/or
  - **hover-revealed row buttons** (a `arrow.uturn.backward` + `trash` icon), mirroring the **Results tab's visible
    save/delete row icons** so the two tabs feel consistent.
  - Keep the swipe actions as a secondary path.

**Open calls (recommended defaults).**
- **Context menu, hover buttons, or both?** *Recommended:* **both** — `contextMenu` (native + discoverable) plus
  hover icons (mirrors Results). If only one, the context menu.
- **Confirm on Delete?** *Recommended:* **yes** for Delete (it also forgets generated materials); **none** for
  Return to Results (non-destructive — the job just moves back).
- **Expose the actions from the Tracker detail view too?** *Recommended:* yes — add both to the open job's
  detail/toolbar so they're reachable when a job is open, not only from the row.

**On-device.** n/a — pure Presentation over the existing persistence use cases.

**Scope.** Small (patch-sized, `.2`) — a `contextMenu` / hover buttons in `TrackerView` reusing the existing VM
methods; no new seam. Fits **v0.6.2**. (The behaviour is done; this is a discoverability fix.)

---

## Multi-select results — bulk save-to-Tracker / delete

**Target:** **v0.6.2** (a patch on v0.6.0). Moderate.

**Why.** Results row actions are **one-at-a-time** today — `saveToTracker` / `delete` per row (swipe or icon). After
a search returns many results, saving or clearing several is tedious. Add **multi-select** on the Results list plus
**bulk actions** (save selected to Tracker, delete selected, …).

**Seam + files (Presentation — reuse the existing per-item logic + batch repos).**
- **Selection state.** Add `selectedIDs: Set<String>` to
  [`ResultsViewModel`](../src/Presentation/Results/ViewModel/ResultsViewModel.swift) — distinct from `selectedJob`
  (`:19`), which is the single job open for detail.
- **Bulk methods.** `saveSelectedToTracker()` / `deleteSelected()` iterate `selectedIDs`, reusing the existing
  `saveToTracker` (`:125`) / `delete` (`:152`) paths. Batch is already available where it helps:
  `SaveResultsUseCase([RankedJob])` persists a batch; `MarkStatusUseCase` / `DeleteSavedJobUseCase` are per-id
  (loop, or add a batch-delete overload). Clear the selection afterward.
- **UI — the multi-select affordance (the main design fork).**
  [`ResultsView`](../src/Presentation/Results/View/ResultsView.swift:53) is a plain `List` with **tap-to-open-detail**
  (`onTapGesture`) + swipe row actions — so adding selection **conflicts with tap-to-open**. Options:
  - **Native `List(selection: $selectedIDs)`** — ⌘/shift-click multi-select (macOS-idiomatic); move open-detail to
    **double-click** (single-click now selects).
  - **A "Select" mode toggle** — shows per-row **checkboxes**; tap toggles selection while in mode; tap-to-open
    stays out of mode.
  - **Always-visible leading checkbox** — row tap opens detail, checkbox selects.
- **Bulk action bar.** When `!selectedIDs.isEmpty`, show a bar/toolbar: **"N selected" · Save to Tracker · Delete
  (destructive, confirm) · Clear**, wired to the bulk methods.

**⚠️ Cost note.** `saveToTracker` triggers per-job enrichment (`enrichSavedJob`), so **bulk-saving N** kicks off N
enrichments — bound it (reuse the concurrency posture; composes with **Milestone K**'s standardized-digest pipeline).
Bulk delete is cheap.

**Open calls (recommended defaults).**
- **Selection affordance?** *Recommended:* **native `List(selection:)`** (⌘/shift, macOS-idiomatic) with
  **double-click to open detail**; fall back to a Select-mode toggle if double-click feels off. This is the primary
  UX decision.
- **Confirm on bulk Delete?** *Recommended:* **yes** (destructive; removes materials), with a count in the prompt
  ("Delete 7 results?").
- **Multi-select in the Tracker too?** *Recommended:* yes, same pattern for bulk **Return to Results** / **Delete** —
  composes with the **discoverable remove-from-Tracker** entry above (both v0.6.2).
- **Bulk actions beyond save/delete?** *Recommended:* save + delete first; add bulk status-mark later if useful.

**On-device.** n/a for selection/UI; bulk-save enrichment is `.extraction` LLM work — bound it (see cost note).

**Scope.** Moderate (patch-sized, `.2`) — `ResultsViewModel` selection state + bulk methods, a `ResultsView`
selection affordance + action bar; reuses the existing per-item logic + batch repos. **Pairs with** the
discoverable-remove-from-Tracker entry (same row-actions theme) and **Milestone K** (bulk-save enrichment). Fits
**v0.6.2**.

---

## Results sort + Tracker filter — sort/filter parity across both tabs

**Target:** **v0.6.2** (a patch on v0.6.0). Small–moderate.

**Why.** The two list tabs each have **one** of the pair: Results has a live **filter**
([`ResultsFilter`](../src/Presentation/Results/View/ResultsFilter.swift)) but no sort; the Tracker has a live **sort**
([`TrackerSort`](../src/Presentation/Tracker/View/TrackerSort.swift) — built as "the Tracker analogue of
`ResultsFilter`") but no filter. Give each tab the capability the other already has, so **both** tabs can sort *and*
filter. Both existing types are pure, non-destructive, session-only — this is mostly lifting each pattern across.

**Seam + files (there's a useful asymmetry — one side reuses, the other parallels).**
- **Tracker filter — *reuse* `ResultsFilter`.** `ResultsFilter.matches(_ job: RankedJob, isTracked:)` is generic
  over a `RankedJob`, and a `TrackedJob` **wraps** one — so the Tracker can apply the existing filter directly to
  `tracked.job`. In [`TrackerViewModel.jobs(in:)`](../src/Presentation/Tracker/ViewModel/TrackerViewModel.swift:74),
  filter **before** the sort: `sort.apply(to: trackedJobs.filter { resultsFilter.matches($0.job, isTracked: { _ in
  true }) && section.includes($0.status.stage) })`. Add `var filter = ResultsFilter()` to `TrackerViewModel` and a
  filter bar in `TrackerView` mirroring the Results filter controls. **Hide the `trackedStatus` facet** in the
  Tracker (moot — everything there is tracked); expose minScore / keywords / location / company / salaryMin.
- **Results sort — a *new* `ResultsSort` mirroring `TrackerSort`.** `TrackerSort` sorts `[TrackedJob]` with
  **status-based keys** (recentActivity / dateApplied / stage) that **don't exist** for Results (`[RankedJob]`, no
  status). So add a parallel **`ResultsSort`** — same `Key` + `Direction` + `apply(to: [RankedJob])` shape, pure and
  unit-tested — with **RankedJob-appropriate keys**: **match score (default = the current ranking order)**, company,
  role title, salary, posted date (`JobListing.postedDate`). Add `var sort = ResultsSort.default` to
  [`ResultsViewModel`](../src/Presentation/Results/ViewModel/ResultsViewModel.swift) and apply it in
  `filteredResults` (`:75`) **after** the filter (`sort.apply(to: filter.apply(...))`); add a sort bar in
  `ResultsView` mirroring `TrackerView.sortBar` (`:61`).

**Open calls (recommended defaults).**
- **Share the types or keep parallel?** *Recommended:* **reuse `ResultsFilter`** for the Tracker (trivial — it's
  already `RankedJob`-generic) and **add a parallel `ResultsSort`** for Results (the Tracker's status keys don't
  fit). Optionally relocate both to `Presentation/Components/` as a shared list-filter / list-sort later (reusing a
  Results-folder type from the Tracker is legal — same layer — but crosses feature folders).
- **Results sort keys?** *Recommended:* match score (default) / company / role title / salary / posted date.
- **Tracker filter facets?** *Recommended:* minScore / keywords / location / company / salaryMin (drop
  `trackedStatus` — moot; the stage **tabs** already segment by stage).
- **Filter scope in the Tracker — within the stage tab or across all?** *Recommended:* **within the selected tab**
  (matches how `jobs(in:)` already applies the sort per section).

**On-device.** n/a — pure Presentation value types, session-only and non-destructive (no persistence, no re-load).

**Scope.** Small–moderate (patch-sized, `.2`) — reuse `ResultsFilter` in `TrackerViewModel` + a Tracker filter bar;
a new `ResultsSort` + a Results sort bar. **No Business/Data change** (both are pure view state). Pairs with the
other v0.6.2 entries (Results/Tracker actions). Fits **v0.6.2**.

---

## Hide the raw-text preview for imported source documents (keep paste)

**Target:** **v0.6.2** (a patch on v0.6.0). Small.

**Why.** On the Portfolio → Profile tab, each résumé/cover-letter upload slot
([`documentSlot`](../src/Presentation/Portfolio/View/PortfolioView.swift:152)) has a **"Show text"** toggle that
reveals a raw `TextEditor` (`:185`) of the document's extracted text. For an **imported file**, that raw extracted
text is noisy and not worth previewing — the user only cares about the **tidied** view (the Source Documents tab,
`readableText`) after **Build Profile**. So: **when a file is imported, drop the raw-text preview**; the nicely
formatted details after build stay. **Keep the paste path** — the same editor is how a user types/pastes text
instead of importing, so it must remain available when there's no imported file.

**Seam + files (Presentation-only).**
- **Gate the raw editor on import-vs-paste** in `documentSlot` (`PortfolioView.swift:152`). The slot already knows
  `fileName: String?` (set on import — `viewModel.sourceFileName` / `coverLetterFileName`):
  - **Imported (`fileName != nil`):** replace the "Show text" toggle + `TextEditor` with a compact **summary**
    (file name + character count — the existing `collapsedSummary` at `:247`) plus a **Clear/Remove** affordance.
    **No raw-text preview.**
  - **Paste (`fileName == nil`):** keep the `TextEditor` (type/paste) unchanged, so pasting still works.
- **Unchanged:** the **Source Documents** tab (`sourceDocumentsSection`, `:263`) still shows each saved profile's
  **`readableText`** (tidied form) after build — the "nicely formatted details" the user keeps.
- **Context:** the **Supporting-documents** slot is already import-only with no editor (Milestone I); this brings the
  résumé/cover-letter slots close to that, just retaining a paste editor when no file is imported.

**Open calls (recommended defaults).**
- **After import, a way to switch back to paste?** *Recommended:* **yes** — a small **Clear** on the imported
  summary drops `fileName` + text so the paste editor returns (otherwise an import can't be undone in-slot).
- **Show a tiny read-only snippet of the import, or nothing?** *Recommended:* **nothing** (name + char count only) —
  the raw preview is exactly what's being removed; the tidied post-build view is where it's read.

**On-device.** n/a — pure Presentation (conditional rendering in one view helper).

**Scope.** Small (patch-sized, `.2`) — a conditional in `documentSlot`; **no VM/Business/Data change** (the paste
binding + `sourceFileName` already exist). Fits **v0.6.2**.

---

## Full source-document preview — remove both truncations

**Target:** **v0.6.2** (a patch on v0.6.0). Small–moderate.

**Why.** The source-document preview appears to truncate. **Two** truncations are actually in play:
1. **UI cap.** [`documentDisclosure`](../src/Presentation/Portfolio/View/PortfolioView.swift:310) renders the text
   in a `ScrollView` capped at `.frame(maxHeight: 220)` — the full text is present but confined to a ~220pt box that
   reads as "cut off."
2. **Content truncation at tidy (the real one).** `readableText` is produced by `TidyDocumentUseCase` →
   `Prompts.tidyDocument(rawText:)`, which **truncates the input to `maxPortfolioCharacters`**
   ([`Prompts.swift:75`](../src/Data/LLM/Prompts.swift:75)) before tidying. So for a long document the stored tidied
   text is **genuinely shorter than the original** — dropping the UI cap alone still won't reveal what was never
   tidied. (The **full** extracted text does survive in `sourceText`; only the tidy *prompt* truncates.)

**Seam + files.**
- **UI cap (cheap).** In `documentDisclosure` (`:310`), raise or drop the `maxHeight: 220` — let the disclosure
  expand to the full text (the tab already scrolls), or add a **"View full document"** resizable window/sheet for
  very long docs. `Text` doesn't line-limit, so it renders fully once the height frees up.
- **Content (the substantive fix).** To truly show the **whole** document the preview must use untruncated text.
  `sourceText` holds the **full** extracted document; `readableText` is the tidied-but-bounded form. Options:
  - render the preview from **`sourceText`** (full, but un-tidied);
  - **raise `maxPortfolioCharacters`** for the tidy path so `readableText` covers typical full documents;
  - **chunked tidy** — tidy the document in segments so `readableText` is complete *and* formatted (larger scope);
  - **fallback** — show `readableText`, appending the remainder from `sourceText` when the tidy was truncated.

**Open calls (recommended defaults).**
- **How to get the full text into the preview?** *Recommended:* **raise the tidy bound** so typical
  résumés/portfolios tidy in full, and **fall back to the full `sourceText`** for anything longer, so the preview is
  never missing content. (A chunked full-tidy is the nicer-but-larger follow-on.)
- **Inline-expand vs. open in a window?** *Recommended:* **inline-expand** (drop the 220 cap) for the common case;
  add a "View full document" resizable window only if long docs feel unwieldy inline.

**On-device.** The UI change is free; a higher tidy bound / chunked tidy is more `.profile`-task LLM work (mind the
on-device context window). The raw-`sourceText` fallback needs **no** extra model work.

**Scope.** Small–moderate (patch-sized, `.2`) — a trivial UI cap change plus the content fix (raise bound / raw
fallback). Presentation (`documentDisclosure`) and, for the content fix, `Prompts` / `TidyDocumentUseCase` (or just
the preview's text source). Fits **v0.6.2**.

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
