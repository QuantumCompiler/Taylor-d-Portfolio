# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus: v0.7.0 — customizable LaTeX document styles. Milestone F** (raw-LaTeX preamble override +
> graceful compile failure) — **the last milestone of the release**. **Milestones A–E are done**: the style model
> + registry, style-driven preambles, style-driven sections, the persisted library, and the manager UI + export
> picker (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`). F lands on a working style system, so it's the
> escape hatch plus its failure path — and `LaTeXStyle.customPreamble` has existed since A, unused, waiting for
> it. Six milestones **A–F**,
> scheduled out of `PLANNED.md`'s `Target: v0.7.0` entry (2026-07-28); see the v0.7.0 section at the bottom of
> this file. **v0.6.2 (list actions, sorting & document previews) is
> complete and merge-ready** — all five milestones
> **A–E** shipped (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`); docs and `README.md`
> are done, and the full suite is green (879 cases, no warnings). **v0.6.1 (keyword
> match & ATS coverage) is likewise complete.** Only the **device checks** below remain before the branch merges.
>
> **⚠️ Awaiting device checks** — everything automatable is done and green; these need a real run (each
> milestone's full write-up is in `MILESTONES.md`). These were written against a **0.6.2** build; the project
> version is now **0.7.0**, so Settings → About reads 0.7.0 in a current build.
> - **v0.6.2 A** — a Tracker row shows the **Return to Results + trash icons** without hovering, matching the
>   Results rows; **right-clicking** a row offers the same two; both **swipes** still work. **Delete confirms from
>   all three paths** (and the dialog names the job), Return to Results doesn't. With a job open, the footer's
>   **Remove** menu offers both and the window **dismisses** after either. Return to Results puts the job back in
>   Results with its listing intact; Delete removes it from both tabs and its generated materials are gone.
> - **v0.6.2 B** — **⚠️ the interaction change to check first: a single click now selects a row and opening the
>   detail is a double-click**, in **both** Results and the Tracker. Confirm ⌘-click / shift-click extend the
>   selection, the row **icons and swipes still work** while rows are selected, and the **action bar** appears with
>   the right count ("N selected"), disabling itself mid-batch. Bulk **Save to Tracker** moves them all out of
>   Results at once (and their enrichment fills in after, without freezing the list — try ~10 at once); bulk
>   **Delete** confirms with a count; the Tracker's bulk **Return to Results** puts them all back with listings
>   intact. Selecting under **All** then switching stage tabs must not let another tab act on those rows.
> - **v0.6.2 C** — Results now has a **sort bar** (match score / company / role title / salary / date posted, both
>   directions, Reset) and the Tracker a **filter bar** (min rank / keywords / location / company / min salary — no
>   "Tracked" facet). Untouched, the Results order must look **exactly as before**. Check the Tracker filter narrows
>   **within** the open stage tab and composes with its sort; that a filter hiding every row shows "No tracked
>   applications match your filters" **with the bar still visible** and Clear working (not the "No applied
>   applications" stage-empty message); and that both tabs' filter bars look and behave identically (they're now one
>   shared control). Listings with no salary / no posted date sort **last** either direction.
> - **v0.6.2 D** — on Portfolio → Profile, **importing** a résumé/cover letter shows only the file name + character
>   count (no "Show text", no raw editor), with **Clear** and **Replace…**; **Clear** brings the paste editor back
>   empty and pasting still builds. With **no** file imported the slot behaves exactly as before. After Build
>   Profile the tidied text still appears under **Source Documents**, and clearing the slot afterwards doesn't
>   disturb the built profile's copy.
> - **v0.6.2 E** — a saved profile's **Source Documents** entry expands to the **whole** document, not a ~220pt
>   box; check a **long** résumé (> 12 000 characters) reads tidied to the bound and then continues **as-extracted**
>   after the "too long to tidy" notice, with **nothing missing at the end**. A normal-length résumé (well under the
>   bound) must show **no** notice and be tidied throughout — and, being over the old 6 000 cap, is the case that
>   used to lose its tail silently.
> - **v0.6.1 C** — generate an application for a real posting: the **coverage panel** appears below the two
>   documents with the covered (green) / missing (amber) keyword capsules, the must-have headline count is right,
>   it updates on Regenerate, it **survives reopening** the saved result, and it's **absent** for a result
>   generated before this version (a legacy record with no stored brief) and for a thin posting with no keywords.
> - **v0.6.1 D** — the **"Match the posting's must-have keywords"** checkbox: off leaves output as before; on
>   visibly raises coverage on the next Generate **without inventing** — anything unclaimable shows up in **Gaps**,
>   and no keyword list is dumped into the résumé. It stays enabled (and still applies) under a rank target, saves
>   into a preset, and a preset saved before this version still loads with it off.
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

# v0.7.0 — customizable LaTeX document styles (in progress)

Scheduled out of `PLANNED.md`'s `Target: v0.7.0` entry (2026-07-28) — a **feature release**, so milestones
restart at **A** and commit as `v0.7.0 : Milestone X Completed`.

**Why.** The awesome-cv LaTeX route (v0.5.1) is a **single fixed template** mimicking Taylor's hand-authored
résumé: [`TexDocumentBuilder`](../src/Infrastructure/Tex/TexDocumentBuilder.swift) hardcodes every presentation
choice — `\documentclass[6pt]{Class/Resume}` + `\geometry{…}` in `resumePreamble`, `\fontdir[fonts/]`, the
section order (`canonicalOrder`) and per-section spacing (`sectionVSpace`), and a *separate*
`\documentclass[11pt, a4paper]{Class/CoverLetter}` for the letter. This release makes the look **user-owned**:
named, reusable styles chosen at export time, plus a raw-LaTeX escape hatch for power users.

**Decisions locked in planning (2026-07-15, carried from `PLANNED.md`).**
- **Both** multiple built-in templates **and** a user-editable raw-LaTeX preamble override — not just
  parameterizing the one template.
- Controls exposed: **font family & size**, **accent colour**, **margins + spacing + page size** (US Letter / A4),
  and **section order / visibility**.
- Granularity: **reusable named styles** in an app-wide library, **chosen at export time** (mirrors saved
  profiles / generation presets).
- **One shared style applies to both documents** (résumé + cover letter), unifying today's divergent hardcoded
  geometry; only doc-inherent bits (the letter's `\makeletterclosing`) stay per-type.

**⚠️ Naming — don't collide with the existing template type.** [`ExportTemplate`](../src/Infrastructure/Export/ExportTemplate.swift)
+ `TemplateStyle` (classic / compact / modern) already exist, but they theme the **native Core Text** PDF/DOCX
exports (v0.3.0 Milestone X), **not** LaTeX. The new type is LaTeX-specific — name it **`LaTeXStyle`** and keep
the two separate. Unifying them later is an explicit open call, not part of this release.

**Scoping constraint (applies to every milestone).** Styles theme **presentation only** — the raw-LaTeX override
changes layout, **never** content: the body stays app-generated and escaped (`escape` / `inlineLaTeX` /
`plainLaTeX` in `TexDocumentBuilder`), so a template can't smuggle in résumé content. This is a correctness
boundary for the template system, not a fabrication rule — the fidelity control still governs content latitude.

**Layer note.** Not Presentation-only: A–C + F are **Infrastructure/Tex**, D is **Data/Persistence**, E is
**Presentation** (+ `Composition` wiring). Dependencies still point down (Infra model/builder ← Data persistence
← Presentation manager/picker). Business's [`ExportApplicationUseCase`](../src/Business/UseCases/ExportApplicationUseCase.swift)
is the one call site that threads a style through (`texSource` / `latexPDF`).

**Release hygiene (do once, at kickoff).**
- [x] Bump every `MARKETING_VERSION` to `0.7.0` (4 copies in `project.pbxproj` — Debug/Release × app/test) so
      Settings → About reports the real version.

---

## Milestone F — Raw-LaTeX preamble override + graceful compile failure

The power-user escape hatch, last so it lands on a working style system.

**Seam + files.** `Infrastructure/Tex/TexDocumentBuilder.swift` (honour `customPreamble`) +
[`LaTeXProcessClient`](../src/Infrastructure/Tex/LaTeXProcessClient.swift) / `ApplicationViewModel`'s existing
`LaTeXProcessError` handling (it already surfaces the real `lualatex` log rather than a generic failure), plus
an advanced editor in the E manager.

- [ ] When `customPreamble` is set, it replaces the **generated preamble verbatim**; the body stays
      app-generated + escaped (the scoping constraint above).
- [ ] A broken override fails **gracefully** — the compile already runs `\nonstopmode`, so surface the compile
      error and offer **revert to a built-in** (a one-click path back to a compiling style, so a user can't
      strand themselves).
- [ ] The `.tex` **source** export stays available even when the override won't compile (it needs no TeX install)
      — that's how a user debugs their preamble.
- [ ] Advanced editor in the manager, clearly marked as replacing the generated preamble.

**Tests.** Override present → generated preamble absent and the override verbatim, body unchanged; override
absent → identical to B/C output; the error path maps a compile failure to a user-facing message + revert
affordance (VM-level, with a stub compiler).

**On-device.** n/a — no model calls.
