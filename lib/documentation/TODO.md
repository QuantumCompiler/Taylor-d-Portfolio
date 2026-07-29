# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.1 — keyword match & ATS coverage: code-complete → the merge-ready wrap.** All four
> milestones **A–D** are done (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`), the full suite is green, and
> `MARKETING_VERSION` is already `0.6.1`. **Nothing is left to build.** What remains is the shipping pass in
> `CLAUDE.md` → "Making a branch merge-ready": flip the `## v0.6.1 —` headers to **(complete)**, add the
> `README.md` version summary and point its **Next:** line forward *without* naming a version, and clear this
> file down to the next version's placeholder — plus the **device checks** below, which need a real run.
>
> **v0.6.0 (richer grounding, job detail & sources) shipped** — all eleven milestones **A–K** are written up
> in `MILESTONES.md` and ticked in `ROADMAP.md`.
>
> **⚠️ Awaiting device checks** — carried forward; everything automatable is done and green, but these need a
> real run (each milestone's full write-up is in `MILESTONES.md`). Settings → About should read **0.6.1**.
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

## Release hygiene (v0.6.1)

- [x] **`MARKETING_VERSION` → `0.6.1`** in all **4** copies in `project.pbxproj` (Debug/Release × app/test), so
      Settings → About reports the real version (`CLAUDE.md` → "Keep the project version in sync").
- [x] Each completed milestone's write-up moved into `MILESTONES.md` and ticked in `ROADMAP.md` (A–D).
- [ ] **The merge-ready wrap** (`CLAUDE.md` → "Making a branch merge-ready"): flip the `## v0.6.1 —` headers in
      `ROADMAP.md` / `MILESTONES.md` to **(complete)**, add v0.6.1's one-paragraph summary to `README.md` under
      "Version history" and point its **Next:** line forward **without naming** the next version, and clear this
      file down to the next version's un-numbered placeholder + the carried-forward device-checks note.
