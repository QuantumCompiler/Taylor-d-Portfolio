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

> **One entry below** — **v0.7.1 (bug fixes)**, a patch on the shipped v0.7.0. The **customizable LaTeX styles** entry
> (`Target: v0.7.0`) was scheduled into **v0.7.0** as **Milestones A–F** (2026-07-28) and now lives in `TODO.md` /
> `ROADMAP.md`. Two known candidates are **unspecced** and need an entry here with a `Target:` before they can be
> scheduled: the **ATS-friendly export mode** noted alongside v0.6.1, and the **chunked full tidy** noted as v0.6.2
> Milestone E's follow-on (tidy a long document in segments so its readable copy is complete *and* formatted
> throughout, rather than tidied-then-raw). The five **`v0.6.2`** entries — **discoverable
> remove-from-Tracker**, **multi-select bulk actions**, **Results sort + Tracker filter**, **hide imported-doc raw
> preview**, and **full source-document preview** — were scheduled into **v0.6.2** as **Milestones A–E**
> (2026-07-28) and now live in `TODO.md` / `ROADMAP.md`. The **keyword-match / ATS coverage**
> entry was scheduled into **v0.6.1** as **Milestones A–D** (2026-07-28) and now lives in `TODO.md` /
> `ROADMAP.md`; its noted companion, an **ATS-friendly export mode**, was left **unscheduled and unspecced** —
> add it here with its own `Target:` if Taylor wants it. The **supporting profile documents** entry was
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

## Bug fixes — 18 verified defects found by a codebase audit

**Target:** **v0.7.1** (a patch on the shipped v0.7.0). A **bug-fix release**, not a feature theme — per `CLAUDE.md`
→ Versioning, a batch of fixes on top of a shipped `.0` is exactly the `v0.x.y` case. Milestones restart at **A**.

**Why.** v0.7.0 shipped with the suite green (904 cases, no warnings) and no `TODO`/`FIXME` markers anywhere in
`lib/src` — so the remaining defects are the ones tests and markers don't catch: **stale-async writes, unstable
identity, silent fail-soft swallowing, and unreachable UI wiring**. A structured audit (2026-08-04) swept five
subsystems — concurrency/isolation, persistence/`Codable`, the LLM layer, the search pipeline, and
Presentation — and every candidate was then **adversarially re-verified against the source** by a second pass
instructed to refute it. 20 findings survived; **two pairs were the same defect found from two angles**
(the pasted-posting id, and the subprocess pipe deadlock), leaving **18 unique bugs: 4 high, 9 medium, 5 low**.

**⚠️ Provenance / how to treat this list.** These are **audit findings, not user-reported bugs** — each cites a real
file:line and a concrete failure scenario, and each survived a refutation pass, but a verifier can still be wrong.
**Reproduce each one before fixing it**, and treat the "suggested fix" as a starting point, not a prescription. Some
(the two `Int` overflow traps, the subprocess deadlock) are edge cases that may never have bitten in practice;
they're included because they're **crashes/hangs**, which are cheap to guard and expensive to hit.

### The defects

**High — visible corruption or a feature that silently doesn't work**

1. **In-flight generation writes another job's kit into the shared `ApplicationViewModel`** —
   `Presentation/Application/ViewModel/ApplicationViewModel.swift:438`. `ApplicationWindow` holds **one** view model
   (`:26`) and re-targets via `.onChange(of: requestID)`, while `generate(...)` runs as an **unstructured `Task`**
   that assigns `kit = produced` / `brief = producedBrief` with **no staleness check**. Generate for job A → open
   job B while it runs → A's result overwrites B's state. The window then shows **B's header with A's résumé**, and
   Export writes a file **named for B containing A's content**. `loadSaved(for:)` also clears `isGenerating`, so the
   Generate button re-enables mid-flight and a second run can be clobbered by the older one. *(Persistence itself is
   safe — line 443 saves under the correct per-job id; the corruption is on-screen and in the export.)*
   **Fix:** a generation token (or the target `JobListing.id`) captured at start, cancel-and-replace in
   `loadSaved(for:)`, and `guard` the token still matches before assigning.
2. **Pasted-posting id uses `String.hashValue`, which is not stable across launches** —
   `Data/Models/ExtractedPosting.swift:47`: `id: sourceURL?.absoluteString ?? "pasted-posting-\(description.hashValue)"`.
   Swift seeds `Hasher` **per process**, so the same pasted posting gets a **different id every launch** — and that
   id is the persistence key everywhere (`RankedJob.id`, `SavedJobsRepository` upsert, `SavedStatusRepository`,
   `SavedApplicationsRepository`). Relaunch → the saved kit and application status are **orphaned**, `contains(jobID:)`
   never matches, and the store gains a **duplicate row per launch**. Reachable via
   `SearchViewModel.generateFromPastedText()` when the URL field is empty.
   **Fix:** derive the fallback id deterministically — reuse the `JobListing.fingerprint` normalization, or a SHA-256
   digest of the description.
3. **Desired-result-count is silently capped at 20 by the ranker's shortlist, and the shortfall note never fires** —
   `Business/UseCases/SearchAndRankUseCase.swift:138`. Ask for 50, get exactly 20, with **no explanation** — the U-D
   shortfall note that exists to warn about a short set stays silent because it's computed from `merged.count`, not
   the ranked count.
   **Fix:** give `JobRanker.rank` an explicit `limit:` and pass `max(shortlistLimit, goal)`, **or** compute the
   shortfall from `ranked.count` so the user is at least told "Found 20 of a desired 50".
4. **Document Styles pane never loads the saved library — `reloadStyles()` has no caller** —
   `Presentation/Settings/View/DocumentStylesView.swift:25`. Every launch shows "No saved styles yet" **even though
   styles are persisted**; the default style is never opened; Save re-creates the style as a new row, so the library
   **fills with duplicates**. This makes the headline v0.7.0 feature look broken on relaunch.
   **Fix:** `.task { await viewModel.reloadStyles() }` on the view body — the pattern `PortfolioView` (`:35`) and
   `SearchView` (`:31`) already use.

**Medium**

5. **Subprocess pipe deadlock — stdout drained to EOF before stderr is read** —
   `Infrastructure/LLM/ClaudeProcessClient.swift:169`. If the child fills the **stderr** pipe buffer while we're
   still reading stdout, both sides block: the LLM call **hangs forever**, with no timeout and no cancellation path.
   **Fix:** drain both pipes concurrently (`readabilityHandler`s, or stderr on a second queue joined before
   `waitUntilExit()`). **Apply the same fix to `LaTeXProcessClient.runProcess`.**
6. **`llmSourceAvailable` is a launch-time snapshot** — `Presentation/Settings/ViewModel/SettingsViewModel.swift:38`.
   Change the AI-job-search engine and the source's Configured status + Search-screen availability stay wrong **until
   relaunch** — including a search that silently returns zero results with no error.
   **Fix:** inject a live `@Sendable () -> Bool` instead of a `Bool`; `refreshCredentialState()` already re-runs after
   every save.
7. **Clearing an imported cover letter then saving leaves the text persisted — and still used for generation** —
   `Presentation/Portfolio/ViewModel/PortfolioViewModel.swift:192`. The ✕ Clear hides the file in the UI, but the
   captured text stays in the saved record and **every later generation still feeds it as the voice exemplar**. A
   silent no-op for content.
   **Fix:** `clearCoverLetter()` must also clear `coverLetterSourceText` / `coverLetterReadableText` (or `saveProfile()`
   must honour the cleared slot — one of the two has to change).
8. **`searchJobs` prompt never names the `leads` wrapper key the decoder requires** — `Data/LLM/Prompts.swift:699`.
   AI job search intermittently returns nothing on the **Claude engine (the default for every task)**; because
   `CompositeJobSource` is fail-soft, the decode error is **swallowed** whenever another provider succeeds, so the
   user sees zero AI leads and **no error at all**.
   **Fix:** name the wrapper key the way `Prompts.rank` does ("Produce a `leads` array — one element per opening…").
9. **Generated résumé truncated to the job-description cap (2 000 chars) before scoring** — `Data/LLM/Prompts.swift:414`.
   "Generate to target match score" **under-scores its own output**: the scorer sees only ~half the résumé, so tail
   skills are reported as `missingSkills`. The loop burns all 4 rounds and **escalates fidelity to 1.0 (the
   embellished band)** — producing an invented-content draft the user never asked for.
   **Fix:** use `maxPortfolioCharacters` (6 000) or a dedicated `maxResumeCharacters`.
10. **Paging toward the goal never starts when a provider returns fewer listings than the requested page size** —
    `SearchAndRankUseCase.swift:105`. A goal-driven JSearch search only ever fetches page 1 (~10) and reports "that's
    all that's available" though pages 2–5 exist.
    **Fix:** don't infer exhaustion from a post-dedup count against a page size the source may not honour — keep a
    title active while it returned *any* listings, bounded by `maxPagesPerTitle`.
11. **Cross-source duplicates leak in — the use case de-dupes by source-specific `id` while the composite de-dupes by
    `fingerprint`** — `SearchAndRankUseCase.swift:104`. The same posting appears twice (Adzuna + JSearch/AI), saves
    twice, and burns two of the 20 shortlist slots.
    **Fix:** key the merge on `job.fingerprint` (falling back to `id`), matching the composite; each listing keeps its
    own `id` for persistence.
12. **Background description-digest yanks the user back to Results, repeatedly** — `Presentation/App/RootView.swift:60`.
    While "Standardizing descriptions…" runs, navigating anywhere throws you back to Results — **once per digested
    posting** (25–50 times over a minute), also resetting that area's sub-tab.
    **Fix:** drive the jump off a one-shot signal from `performSearch`/`fetchFromLink` (or an id-set change), not off
    every `search.results` mutation.
13. **Digest updates overwrite the Results list, resurrecting deleted rows** — `RootView.swift:59`. Delete a result
    while descriptions are standardizing and the row **pops back seconds later** — and is re-written to the store.
    **Fix:** merge by id rather than wholesale replacement (mirroring `ResultsViewModel.applyRefreshed(_:)`), or prune
    deleted ids before `persistResults()`.

**Low**

14. **`fetchFromLink` and `search` race for `results`** — `Presentation/Search/ViewModel/SearchViewModel.swift:421`. A
    link-fetched job appears, then silently vanishes when an earlier search lands.
    **Fix:** cross-gate the two entry points (`!isSearching` in `canFetchLink`, `!isFetchingLink` in `canSearch`).
15. **`select()` restores a profile's file names but not its slot text** — `PortfolioViewModel.swift:364`. A loaded
    profile shows "resume.pdf — 0 characters" and **Build stays disabled**, so you can't rebuild without re-importing.
    **Fix:** seed the slots from `saved.readableText`/`sourceText` (and the cover-letter equivalents).
16. **`Int(salaryMin)` traps on a large typed salary floor** — `Data/Jobs/AdzunaJobSource.swift:61`. **Crashes the app**
    during URL construction. **Fix:** clamp before converting, or use `Int(exactly:)`.
17. **Results sidebar badge counts tracked jobs the list deliberately hides** — `RootView.swift:121`. Sidebar says
    "Results 10" while the pane says "All results are in your Tracker"; saved jobs counted twice.
    **Fix:** badge from `results.untrackedResults.count`.
18. **Min-salary filter field traps on a very large number** — `Presentation/Components/ListFilterBar.swift:55`. A 19+
    digit paste **crashes the app** (Results or Tracker). **Fix:** clamp / avoid the `Double`→`Int` round-trip.

### Suggested milestone decomposition (at kickoff)

Grouped by shared root cause / file so each milestone is one coherent change:

- **A — Stale-async writes corrupt visible state** (1, 14) — the generation token + cross-gating; the highest-impact fix.
- **B — Results/search handoff in `RootView`** (12, 13, 17) — all three live in the same `onChange` + badge block.
- **C — Stable posting identity** (2) — small, but it touches every persistence key; do it early and consider a
  migration note for already-orphaned records.
- **D — Search goal & de-duplication** (3, 10, 11) — all in `SearchAndRankUseCase`.
- **E — LLM layer correctness** (5, 8, 9) — process deadlock, prompt wrapper key, résumé budget.
- **F — Settings wiring** (4, 6) — the unreachable `reloadStyles()` and the stale availability snapshot.
- **G — Portfolio document state** (7, 15) — clear-vs-persist and load-vs-slot symmetry.
- **H — Crash guards** (16, 18) — both `Double`→`Int` overflow traps; trivial, ship together.

**Tests.** Each fix should land with a regression test — these are exactly the cases the current 904 didn't cover:
a stale generation completing after a re-target must **not** mutate the new job's state; the pasted-posting id must be
**equal across two independently constructed instances**; a goal of 50 must not silently yield 20; `clearCoverLetter()`
must leave nothing behind for `saveProfile()`; the two `Int` traps need out-of-range inputs; the digest merge must not
resurrect a deleted id.

**On-device / risk.** No new seams and no model-behaviour changes — these are correctness fixes inside existing
paths. Two carry mild behavioural risk worth calling out at build time: **(3)** raising the shortlist limit means
**ranking more jobs per search** (more LLM work — the shortlist cap was also a cost guard), and **(9)** a larger
résumé budget means **more tokens per scoring round**.

**Scope.** Patch-sized in kind (no new features) but **broad in surface** — 18 fixes across all four layers, ~8
milestones. Fits **v0.7.1**; commit as `v0.7.1 : Milestone X Completed`.

---
