# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.7.1 — bug fixes — scheduled, not yet started; next Milestone A.** Eighteen verified defects
> were scheduled out of `PLANNED.md` (2026-08-04) into the **v0.7.1 — bug fixes** section below, grouped into
> Milestones **A–H** by shared root cause. **Start with A** (stale-async writes — the highest-impact fix); **H**
> (two `Double`→`Int` overflow crashes) is nearly free if you want a quick win first. Every defect cites a real
> `file:line` — **reproduce each one before fixing it** (see the provenance note in that section).
>
> **v0.7.0 (customizable LaTeX document styles) is complete and merge-ready** — all six milestones **A–F**
> shipped (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`); docs and `README.md` are done, every
> `MARKETING_VERSION` reads `0.7.0`, and the full suite is green (904 cases, no warnings). Only the **device
> checks** below remain before that branch merges — **do those before bumping the version for v0.7.1** (they
> assert About reads **0.7.0**; see the release-hygiene checkbox in the v0.7.1 section).
>
> **⚠️ Awaiting device checks** — everything automatable is done and green; these need a real run (each
> milestone's full write-up is in `MILESTONES.md`). Settings → About should read **0.7.0**; the v0.6.x items were
> written against a 0.6.2 build and are carried forward unverified.
> - **v0.7.0 A–D** — Settings gains a **Document Styles** pane. Create a style, name it, Save; **star** it as the
>   default; **duplicate** it (the copy is named "… copy"); **delete** it — and confirm deleting the default
>   un-stars everything rather than leaving a pointer behind. Quit and relaunch: the library and the default
>   survive. With no styles saved, an export must look **exactly as it did in v0.6.2**.
> - **v0.7.0 E** — the four control groups: change the **body font**, **accent**, **page size**, **margins** and
>   the **section order / visibility / spacing**, then **Preview** (a few seconds; noticeably longer the first
>   time). Reorder so **Skills** comes first and confirm the sections after it aren't visibly compressed (the
>   `\arraystretch` fix). Hide **Other sections** and confirm the summary paragraph at the top **survives**. In a
>   job's Application window, the Export menu shows a **Style** picker under "Portfolio (LaTeX)" separate from
>   "PDF / Word template" — pick a saved style and confirm the exported PDF/`.tex` uses it; leave it on
>   **Default** and confirm it follows the starred style. Without MacTeX, Preview is **visible but disabled**
>   with an explanation.
> - **v0.7.0 F** — under **Advanced**, switch on **"Replace the generated preamble with my own LaTeX"**: the
>   editor seeds with the real generated block, and the Template/Typography/Accent/Page controls dim while the
>   cover-letter and section controls stay live. Add
>   `\renewcommand{\pageHeader}{\name{Your}{Name}\email{you@example.com}}` and Preview — **the header should
>   read your name** (this is the reason the escape hatch exists). Then break it deliberately (e.g.
>   `\thisIsNotACommand{}`): Preview shows the **real lualatex log** in the Preview section and keeps the last
>   good render; **"Use the generated preamble"** and **"Revert to a built-in…"** each fix it *and persist* —
>   re-export from the job window without re-saving to confirm. Export the same broken style from a job: the
>   banner names the custom preamble, **"Use the built-in style for this export"** unblocks it without changing
>   the saved style, and **"Export .tex source"** still works.
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

# v0.7.1 — bug fixes

Scheduled out of `PLANNED.md` (2026-08-04). A **bug-fix release**, not a feature theme — per `CLAUDE.md` →
Versioning, a batch of fixes on top of a shipped `.0` is exactly the `v0.x.y` case. **Milestones restart at A**;
commit as `v0.7.1 : Milestone X Completed`. **Not Presentation-only** — the fixes span all four layers.

**Where these came from.** v0.7.0 shipped with the suite green (904 cases, no warnings) and **no `TODO`/`FIXME`
markers anywhere in `lib/src`** — so what's left are the defects tests and markers don't catch: **stale-async
writes, unstable identity, silent fail-soft swallowing, and unreachable UI wiring**. A structured audit
(2026-08-04) swept five subsystems — concurrency/isolation, persistence/`Codable`, the LLM layer, the search
pipeline, Presentation — and every candidate was **re-verified against the source by a second pass instructed to
refute it**. 20 findings survived; two pairs were the same defect found from two angles, leaving **18 unique: 4
high, 9 medium, 5 low**.

> **⚠️ Provenance — read before fixing.** These are **audit findings, not user-reported bugs**. Each cites a real
> `file:line` and a concrete failure scenario, and each survived a refutation pass — but **a verifier can still be
> wrong**. **Reproduce each defect before fixing it**, and treat the suggested fix as a starting point, not a
> prescription. Some (the two `Int` traps, the subprocess deadlock) are edge cases that may never have bitten in
> practice; they're in scope because they're **crashes/hangs**, cheap to guard and expensive to hit.

**Release hygiene**

- [ ] **Bump `MARKETING_VERSION` to `0.7.1`** (4 copies in `project.pbxproj` — Debug/Release × app/test).
      **⚠️ Deliberately not done at scheduling time:** v0.7.0 is merge-ready but **unmerged**, and its outstanding
      device checks assert **Settings → About reads 0.7.0**. Bumping now would invalidate them. **Clear the v0.7.0
      device checks first, then bump.**
- [ ] Add the v0.7.1 summary to `README.md`'s Version history when the release wraps.

## Milestone A — Stale-async writes corrupt visible state  *(high + low)*

**What / why.** Two unstructured async flows assign into shared view state with **no staleness check**, so an older
operation can overwrite newer state.

**A-1 (high) — in-flight generation writes another job's kit into the shared `ApplicationViewModel`**
([`ApplicationViewModel.swift:438`](../src/Presentation/Application/ViewModel/ApplicationViewModel.swift:438)).
`ApplicationWindow` holds **one** view model (`ApplicationWindow.swift:26`) and re-targets purely via
`.onChange(of: requestID) { … loadSaved(for: job) }` (`ApplicationSheet.swift:151`); the sheet is **not** `.id`-keyed,
so the view identity is stable and nothing cancels prior work. `generate(...)` runs as an unstructured `Task`
(`ApplicationSheet.swift:396`) and assigns `kit = produced` / `brief = producedBrief` (`:438–439`) unconditionally.
Sequence: Generate for job A (tens of seconds) → open job B → `loadSaved(for: B)` sets `job = B` and clears
`isGenerating` → A's task completes and overwrites `kit`/`brief`. The window then shows **B's header with A's
résumé**, and `exportFilenameBase` (`:376`) yields B's name while `exportData` renders A's markdown — an export
**named for B containing A's content**. Clearing `isGenerating` in `loadSaved` also re-enables Generate mid-flight,
so a second run for B can be clobbered by A finishing last. *(Persistence is safe — `:443` uses the shadowing `job`
parameter, so A's kit is saved under A's id. The corruption is on-screen and in the export.)*

**A-2 (low) — `fetchFromLink` and `search` race for `results`**
([`SearchViewModel.swift:421`](../src/Presentation/Search/ViewModel/SearchViewModel.swift:421)). Neither guards on
the other's busy flag, so a link-fetched job appears in Results and then **silently vanishes** when an earlier
search lands.

**Sub-tasks:**
- [ ] **A-A** — Generation token in `ApplicationViewModel`: capture the target `JobListing.id` (or an incrementing
      `generationID`) when `generate` starts; `guard` it still matches before the `kit`/`brief` assignments.
- [ ] **A-B** — Store the in-flight `Task` and **cancel-and-replace** it in `loadSaved(for:)`, so re-targeting stops
      the old run rather than racing it.
- [ ] **A-C** — Don't let `loadSaved` clear `isGenerating` for a generation that's still running (or cancel first,
      then clear) — the button must not re-enable mid-flight.
- [ ] **A-D** — Cross-gate the Search entry points: `!isSearching` in `canFetchLink`, `!isFetchingLink` in
      `canSearch` (matches how the saved-search Run button is already disabled, `SearchView.swift:179`).

**Tests.** A stale generation completing **after** a re-target must not mutate the new job's state (assert `kit`
still belongs to B); a cancelled generation doesn't assign at all; `canFetchLink`/`canSearch` are false while the
other flow is busy.
**On-device.** n/a — pure state discipline, no model-behaviour change.

## Milestone B — Results/search handoff in `RootView`  *(medium ×2 + low)*

**What / why.** Three defects in the same `onChange` + badge block, all caused by the Results list being handed
**wholesale ownership** of `search.results` on every mutation — including the background digest's per-posting
updates (v0.6.0 K).

- **B-1 (medium) — the digest yanks the user back to Results, repeatedly**
  ([`RootView.swift:60`](../src/Presentation/App/RootView.swift:60)). While "Standardizing descriptions…" runs,
  navigating to any sidebar area throws you back to Results — **once per digested posting** (25–50 times over a
  minute), also resetting that area's inner sub-tab.
- **B-2 (medium) — digest updates resurrect deleted rows** ([`RootView.swift:59`](../src/Presentation/App/RootView.swift:59)).
  Delete a result while descriptions are standardizing and the row **pops back seconds later** — and is re-written
  to the saved-jobs store even though it was deleted.
- **B-3 (low) — the Results sidebar badge counts tracked jobs the list hides**
  ([`RootView.swift:121`](../src/Presentation/App/RootView.swift:121)). Sidebar reads "Results 10" while the pane
  says "All results are in your Tracker"; saved jobs are counted twice (Results **and** Tracker).

**Sub-tasks:**
- [ ] **B-A** — Auto-navigate on a **genuinely new result set** only: drive the jump off a one-shot signal from
      `performSearch`/`fetchFromLink` (a run id / `didFinishSearch`), or compare result **id sets**, not every mutation.
- [ ] **B-B** — Merge digest updates **by id** instead of replacing the list — never re-add an id the Results view
      model has dropped (mirror the targeted `ResultsViewModel.applyRefreshed(_:)` path), or prune deleted ids before
      `persistResults()`.
- [ ] **B-C** — Badge from `results.untrackedResults.count` so it matches what the list shows.

**Tests.** A digest update for an id the user deleted must not re-insert it (and must not persist it); the
auto-navigation fires **once** per search, not once per digest update; the badge equals the visible row count.
**On-device.** n/a.

## Milestone C — Stable posting identity  *(high)*

**What / why.** [`ExtractedPosting.swift:47`](../src/Data/Models/ExtractedPosting.swift:47) builds
`id: sourceURL?.absoluteString ?? "pasted-posting-\(description.hashValue)"`. Swift seeds `Hasher` with a
**per-process random value**, so the same pasted posting gets a **different id every launch** — and that id is the
persistence key everywhere: `RankedJob.id` (`RankedJob.swift:17`), `SavedJobsRepository.save` upsert
(`SavedJobsRepository.swift:30`), `SavedStatusRepository.save(_:forJobID:)`,
`SavedApplicationsRepository.save(_:brief:forJobID:)`. Relaunch → the saved kit and application status are
**orphaned**, `contains(jobID:)` never matches, and the store gains a **duplicate row per launch** instead of the
documented upsert. Reachable via `SearchViewModel.generateFromPastedText()` (`:456–481`) whenever the URL field is
empty. (`hashValue` is also often negative, producing ids like `pasted-posting--4471…`.)

**Sub-tasks:**
- [ ] **C-A** — Derive the fallback id **deterministically** from posting content — reuse the `JobListing.fingerprint`
      / `LLMJobSource.identifier(for:)` normalization, or a stable digest (SHA-256 hex) of the description.
- [ ] **C-B** — **(open call) Migrate existing orphans?** *Recommended:* **no migration** — old `pasted-posting-…`
      records are already unreachable and re-pasting now produces a stable id. If it matters, a one-time sweep could
      re-key them, but note the risk of colliding with a record the user re-created.

**Tests.** Two independently constructed `ExtractedPosting`s with the same description produce the **equal** id
(the launch-stability property, expressible in-process); a URL-backed posting still keys on its URL.
**On-device.** n/a. **Do this early** — it touches every persistence key.

## Milestone D — Search goal & de-duplication  *(high + medium ×2)*

**What / why.** Three defects in [`SearchAndRankUseCase`](../src/Business/UseCases/SearchAndRankUseCase.swift).

- **D-1 (high) — the desired-result-count goal is silently capped at 20 by the ranker's shortlist, and the shortfall
  note never fires** (`:138`). Ask for 50 → get exactly 20, with **no explanation**, because the U-D shortfall note
  is computed from `merged.count` rather than the ranked count.
- **D-2 (medium) — paging toward the goal never starts when a provider returns fewer listings than the requested
  page size** (`:105`). A goal-driven JSearch search fetches only page 1 (~10) and reports "that's all that's
  available" though pages 2–5 exist.
- **D-3 (medium) — cross-source duplicates leak in**: the use case de-dupes by source-specific `id` (`:104`) while
  `CompositeJobSource` de-dupes by `fingerprint`. The same posting appears twice (Adzuna + JSearch/AI), saves twice,
  and burns two of the 20 shortlist slots.

**Sub-tasks:**
- [ ] **D-A** — Make the shortlist respect the goal: give `JobRanker.rank` an explicit `limit:` and pass
      `max(shortlistLimit, goal ?? shortlistLimit)` — **and/or** compute the shortfall from `ranked.count` so the user
      is at least told "Found 20 of a desired 50".
- [ ] **D-B** — Stop inferring exhaustion from a post-dedup count against a page size the source may not honour: keep
      a title active while it returned **any** listings, bounded by `maxPagesPerTitle` + the `merged.count < goal`
      condition (or have JSearch request a page size and the composite report raw per-provider counts).
- [ ] **D-C** — Key the merge on `job.fingerprint` (falling back to `id` when empty), matching the composite; each
      listing keeps its own `id` for persistence.

**Tests.** A goal of 50 with 50 available yields >20 ranked (or reports the shortfall honestly); a provider returning
fewer than the page size still pages on; the same posting arriving from two sources with different ids collapses to
one row while each keeps its own id.
**On-device.** ⚠️ **D-A raises LLM cost** — the shortlist cap was also a cost guard, so ranking more jobs per search
means more model work. Consider a sane ceiling rather than an unbounded `goal`.

## Milestone E — LLM layer correctness  *(medium ×3)*

- **E-1 — subprocess pipe deadlock: stdout is drained to EOF before stderr is read**
  ([`ClaudeProcessClient.swift:169`](../src/Infrastructure/LLM/ClaudeProcessClient.swift:169)). If the child fills
  the **stderr** pipe buffer while we're still reading stdout, both sides block: the LLM call **hangs forever**, with
  no timeout and no cancellation path — neither `LLMRouter`'s fallback nor task cancellation can break out.
- **E-2 — the `searchJobs` prompt never names the `leads` wrapper key the decoder requires**
  ([`Prompts.swift:699`](../src/Data/LLM/Prompts.swift:699)). AI job search intermittently returns nothing on the
  **Claude engine — the default for every task**. Because `CompositeJobSource` is fail-soft, the decode error is
  **swallowed** whenever another provider succeeds, so the user sees zero AI leads and **no error at all**.
- **E-3 — the generated résumé is truncated to the job-description cap (2 000 chars) before scoring**
  ([`Prompts.swift:414`](../src/Data/LLM/Prompts.swift:414)). "Generate to target match score" **under-scores its own
  output**: the scorer sees ~half the résumé, so tail skills come back as `missingSkills`. The loop burns all 4
  rounds and **escalates fidelity to 1.0 (the embellished band)** — producing an invented-content draft the user
  never asked for.

**Sub-tasks:**
- [ ] **E-A** — Drain both pipes **concurrently** (`readabilityHandler`s into locally-owned buffers resumed from
      `terminationHandler`, or stderr on a second queue joined before `waitUntilExit()`). **Apply the same fix to
      `LaTeXProcessClient.runProcess`.** Consider a cancellation handler while there.
- [ ] **E-B** — Name the wrapper key the way `Prompts.rank` does: "Produce a `leads` array — one element per
      suggested opening — where each element has: …".
- [ ] **E-C** — Give the résumé a résumé-sized budget at `Prompts.swift:414`: `maxPortfolioCharacters` (6 000, matching
      the grounding injection) or a dedicated `maxResumeCharacters`.

**Tests.** A child process writing heavily to **stderr** completes rather than hanging (the regression test for E-A);
the `searchJobs` prompt text contains the `leads` key the decoder expects; a long résumé reaches the scorer untruncated.
**On-device.** ⚠️ **E-C increases tokens per scoring round.** E-A/E-B are correctness-only.

## Milestone F — Settings wiring  *(high + medium)*

- **F-1 (high) — the Document Styles pane never loads the saved library: `reloadStyles()` has no caller**
  ([`DocumentStylesView.swift:25`](../src/Presentation/Settings/View/DocumentStylesView.swift:25)). Every launch
  shows "No saved styles yet. Edit the controls below and choose Save." **even though styles are persisted**; the
  default style is never opened in the editor; and Save re-creates the style as a **new row**, so the library fills
  with duplicates. This makes v0.7.0's headline feature look broken on relaunch.
- **F-2 (medium) — `llmSourceAvailable` is a launch-time snapshot**
  ([`SettingsViewModel.swift:38`](../src/Presentation/Settings/ViewModel/SettingsViewModel.swift:38)). Change the AI
  job-search engine and the source's Configured status + Search-screen availability stay wrong **until relaunch** —
  including a search that silently returns zero results with no error.

**Sub-tasks:**
- [ ] **F-A** — `.task { await viewModel.reloadStyles() }` on `DocumentStylesView.body` — the pattern `PortfolioView`
      (`:35`) and `SearchView` (`:31`) already use.
- [ ] **F-B** — Confirm Save **updates** the loaded style rather than inserting a duplicate once the library loads
      (the duplicate-row symptom may be a consequence of F-A, or a second defect — verify).
- [ ] **F-C** — Make availability a **live check**: inject `let isLLMAvailable: @Sendable () -> Bool` (pointing at
      `Composition.isJobSearchEngineAvailable`) instead of a `Bool`, and call it from `isConfigured(_:)` /
      `resolvedProviderIDs(...)`. `refreshCredentialState()` already runs after every save.

**Tests.** The styles pane lists a persisted library on first appearance and Save updates rather than duplicates;
availability flips when the engine choice changes, with no relaunch.
**On-device.** n/a.

## Milestone G — Portfolio document state  *(medium + low)*

- **G-1 (medium) — clearing an imported cover letter then saving leaves the text persisted, and still used for
  generation** ([`PortfolioViewModel.swift:192`](../src/Presentation/Portfolio/ViewModel/PortfolioViewModel.swift:192)).
  The ✕ Clear hides the file in the UI, but the captured text stays in the saved record and **every later generation
  still feeds it to the LLM as the voice/tone exemplar**. A silent no-op for content.
- **G-2 (low) — `select()` restores a saved profile's file names but not its slot text**
  ([`PortfolioViewModel.swift:364`](../src/Presentation/Portfolio/ViewModel/PortfolioViewModel.swift:364)). A loaded
  profile shows "resume.pdf — 0 characters" and **Build stays disabled**, so the user can't rebuild from the
  profile's own document without re-importing it.

**Sub-tasks:**
- [ ] **G-A** — `clearCoverLetter()` must also clear `coverLetterSourceText` / `coverLetterReadableText` so the slot
      and the persisted record stay in sync. *(If keeping the captured text until the next build is genuinely
      intended, then `saveProfile()` must honour the cleared slot instead — **one of the two has to change**.)*
- [ ] **G-B** — In `select(_:)`, seed the slots from the saved record:
      `portfolioText = saved.readableText.isEmpty ? saved.sourceText : saved.readableText` (and the cover-letter
      equivalent), mirroring what `deselect()` already clears.

**Tests.** After `clearCoverLetter()` + `saveProfile()`, the persisted record carries **no** cover-letter text and
grounding omits the exemplar; `select(_:)` leaves the Build gate enabled with a non-zero character count.
**On-device.** n/a.

## Milestone H — Crash guards (`Double`→`Int` overflow traps)  *(low ×2)*

Both are hard **crashes**, trivially guarded — ship them together.

- **H-1** — `Int(salaryMin)` traps on a large typed salary floor
  ([`AdzunaJobSource.swift:61`](../src/Data/Jobs/AdzunaJobSource.swift:61)): "Double value cannot be converted to Int
  because the result would be greater than Int.max", during URL construction.
- **H-2** — the Min-salary **filter** field traps on a 19+ digit entry
  ([`ListFilterBar.swift:55`](../src/Presentation/Components/ListFilterBar.swift:55)) — in **both** Results and Tracker,
  since it's the shared control.

**Sub-tasks:**
- [ ] **H-A** — Clamp before converting (or use non-trapping `Int(exactly:)`) in `AdzunaJobSource.buildURL`; drop the
      parameter when out of range.
- [ ] **H-B** — Same in `ListFilterBar` — clamp, or avoid the `Double`→`Int` round-trip entirely.
- [ ] **H-C** — **(open call)** Bound `parsePositiveInt` / the salary fields to a sane maximum in the view model, so
      the guard lives in one place rather than at each conversion. *Recommended:* yes, in addition to the local clamps.

**Tests.** Out-of-range inputs (`1e19`, a 19-digit string) round-trip through both paths without trapping and are
either clamped or ignored.
**On-device.** n/a.

---

# Next version — (unstarted; number + theme TBD)

**Nothing is scheduled beyond v0.7.1** — v0.7.0 is complete and **v0.7.1 (bug fixes) is scheduled above**; the
version after it is unstarted.

**Milestones restart at Milestone A** (see the versioning note in `CLAUDE.md`). The number and theme aren't chosen
until development starts (see `CLAUDE.md` → "Never pre-name the next version"). At kickoff, pick a theme from
`ROADMAP.md`'s Backlog (native `LanguageModel` provider seam, on-device embedding RAG, optional MCP tools) or spec
a `PLANNED.md` entry — that file is **empty again** now that v0.7.1 has been scheduled out of it. Four candidates
are known but unspecced and each needs a `PLANNED.md` entry with a `Target:` first:

- **ATS-friendly export mode** — noted alongside v0.6.1: standard headings, single-column, selectable text, which
  is what decides whether an ATS can *parse* a résumé at all.
- **Chunked full tidy** — v0.6.2 Milestone E's follow-on: tidy a long document in segments so its readable copy is
  complete *and* formatted throughout, rather than tidied-then-raw.
- **Custom accent colours in the manager UI** — v0.7.0 models `LaTeXAccent.custom(hex:)` and it survives a
  round-trip, but Milestone E's picker offers only the bundled palette.
- **Cross-window style refresh** — a style saved in Settings doesn't reach an already-open Application window
  until it reloads (v0.7.0 E, accepted deliberately; generation presets behave the same). An
  `AppSession.dataChanged()` bump would fix both.

Assign the version number, bump `MARKETING_VERSION`, and break it into Milestone A, B, C… here.
