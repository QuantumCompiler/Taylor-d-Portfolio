# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.2 — list actions, sorting & document previews (in progress). Next: Milestone D.**
> See "v0.6.2" below: five milestones **A–E**, scheduled out of `PLANNED.md` (its five `Target: v0.6.2` entries)
> on 2026-07-28. **Milestones A (discoverable remove-from-Tracker), B (multi-select bulk actions) and C (sort /
> filter parity) are done** — write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`; **D–E remain**. **v0.6.1 (keyword match & ATS coverage) is complete and merge-ready** — all four milestones
> **A–D** shipped (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`); docs, `README.md`, and
> `MARKETING_VERSION = 0.6.1` are done. Only the **device checks** below remain before that branch merges.
>
> **⚠️ Awaiting device checks** — everything automatable is done and green; these need a real run (each
> milestone's full write-up is in `MILESTONES.md`). Settings → About should read **0.6.2**.
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

# v0.6.2 — list actions, sorting & document previews  (in progress)

A **patch release** on shipped v0.6.0/v0.6.1, scheduled out of `PLANNED.md` (all five of its `Target: v0.6.2`
entries) on 2026-07-28. The theme is **the two list tabs and the Portfolio document previews**: make the Tracker's
existing removals discoverable, add multi-select bulk actions to Results, give each list tab the sort/filter the
other already has, and fix the source-document previews (drop the noisy raw preview for imports; stop truncating
the tidied one). **Almost entirely Presentation** — the one exception is Milestone E's content fix, which touches
`Prompts` / `TidyDocumentUseCase`. Milestones restart at **A** and commit as `v0.6.2 : Milestone X Completed`.

**Release hygiene.**

- [x] **Every `MARKETING_VERSION` set to `0.6.2`** — all 4 copies in `Taylor'd Portfolio.xcodeproj/project.pbxproj`
      (Debug/Release × app/test), so Settings → About reports the real version. Done with Milestone A.
- [x] `# v0.6.2` release header added to `MILESTONES.md`.
- [ ] Update `README.md`'s **Next:** line (still says the next version's number and theme are undecided) and add
      v0.6.2's summary under "Version history" when the release wraps.

---

## Milestone D — Hide the raw-text preview for imported source documents (keep paste)

**What's wanted.** On the Portfolio → Profile tab, each résumé/cover-letter upload slot
([`documentSlot`](../src/Presentation/Portfolio/View/PortfolioView.swift:152)) has a **"Show text"** toggle that
reveals a raw `TextEditor` (`:186`) of the document's extracted text. For an **imported file** that raw extracted
text is noisy and not worth previewing — the user only cares about the **tidied** view (the Source Documents tab,
`readableText`) after **Build Profile**. So: **when a file is imported, drop the raw-text preview**; the nicely
formatted post-build details stay. **Keep the paste path** — the same editor is how a user types/pastes text
instead of importing, so it must remain available when there's no imported file.

**Seam + files (Presentation-only).** `documentSlot` already knows `fileName: String?` (set on import —
`viewModel.sourceFileName` at `:46` / `coverLetterFileName` at `:63`).

- [ ] **Imported (`fileName != nil`):** replace the "Show text" toggle + `TextEditor` with a compact **summary** —
      file name + character count, i.e. the existing `collapsedSummary` (`:247`) — plus a **Clear/Remove**
      affordance. **No raw-text preview.**
- [ ] **Paste (`fileName == nil`):** keep the `TextEditor` unchanged so typing/pasting still works.
- [ ] Wire **Clear** to drop `fileName` + text so the paste editor returns (otherwise an import can't be undone
      in-slot).
- [ ] Leave the **Source Documents** tab (`sourceDocumentsSection`, `:263`) untouched — it still shows each saved
      profile's tidied `readableText` after build.
- [ ] **(open call) Show a tiny read-only snippet of the import, or nothing?** *Recommended:* **nothing** (name +
      char count only) — the raw preview is exactly what's being removed; the tidied post-build view is where it's
      read.

**Tests.** Presentation conditional; assert at the VM level that Clear resets `sourceFileName` /
`coverLetterFileName` **and** the paired text, so the slot returns to the paste state. The rendering fork is a
device check.

**On-device.** n/a — pure Presentation (conditional rendering in one view helper). The **Supporting-documents**
slot is already import-only with no editor (v0.6.0 Milestone I); this brings the résumé/cover-letter slots close
to that, just retaining a paste editor when no file is imported.

---

## Milestone E — Full source-document preview (remove both truncations)

**What's wrong.** The source-document preview appears to truncate. **Two** truncations are actually in play:
1. **UI cap.** [`documentDisclosure`](../src/Presentation/Portfolio/View/PortfolioView.swift:310) renders the text
   in a `ScrollView` capped at `.frame(maxHeight: 220)` (`:321`) — the full text is present but confined to a
   ~220pt box that reads as "cut off."
2. **Content truncation at tidy (the real one).** `readableText` is produced by `TidyDocumentUseCase` →
   `Prompts.tidyDocument(rawText:)`, which **truncates the input to `maxPortfolioCharacters`** (6 000 —
   [`Prompts.swift:19`](../src/Data/LLM/Prompts.swift:19), applied at `:75`) before tidying. So for a long document
   the stored tidied text is **genuinely shorter than the original** — dropping the UI cap alone still won't reveal
   what was never tidied. (The **full** extracted text does survive in `sourceText`; only the tidy *prompt*
   truncates.)

**Seam + files.** Presentation (`documentDisclosure`) plus, for the content fix, `Prompts` / `TidyDocumentUseCase`
(or just the preview's text source).

- [ ] **UI cap (cheap).** Raise or drop `maxHeight: 220` in `documentDisclosure` (`:321`) — let the disclosure
      expand to the full text (the tab already scrolls). `Text` doesn't line-limit, so it renders fully once the
      height frees up.
- [ ] **Content fix (the substantive one).** *Recommended:* **raise the tidy bound** so typical
      résumés/portfolios tidy in full, **and fall back to the full `sourceText`** when the tidy was truncated, so
      the preview is never missing content.
- [ ] **(open call) Alternatives considered, if the recommendation doesn't hold up:** render the preview from
      **`sourceText`** (full but un-tidied); or a **chunked tidy** (tidy in segments so `readableText` is complete
      *and* formatted — nicer but a larger scope, likely a follow-on rather than this patch).
- [ ] **(open call) Inline-expand vs. open in a window?** *Recommended:* **inline-expand** (drop the 220 cap) for
      the common case; add a "View full document" resizable window only if long docs feel unwieldy inline.
- [ ] Don't raise `maxPortfolioCharacters` globally without checking its other call sites (`:49`, `:99`, `:620`,
      `:684` — profile build, generation grounding), which bound what's sent to the on-device model; scope the
      raise to the tidy path if a global raise would blow the context window.

**Tests.** Unit-test the fallback rule directly: a document under the bound tidies whole; one over it yields a
preview that ends with the untidied remainder rather than stopping short; an empty `sourceText` doesn't crash the
preview.

**On-device.** The UI change is free; a higher tidy bound / chunked tidy is more `.profile`-task LLM work (**mind
the on-device context window** — this is why the bound exists). The raw-`sourceText` fallback needs **no** extra
model work.

