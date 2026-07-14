# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding & job detail — Milestone C (Regenerate result).** All of
> v0.1.0–v0.5.1 are done; **v0.6.0 Milestones A and B are complete** (write-ups in `MILESTONES.md`): A —
> richer job postings (Adzuna fields + `PostingDetails` enrichment + enrich-on-save + into-generation + UI);
> B — per-generation **profile picker** grounding on the chosen saved profile's source documents
> (`SavedProfile.grounding` + `ApplicationViewModel.resolvedTarget`). Next is the **last milestone, C** —
> **regenerate result**: a single-job re-rank (with optional additional-context) against a chosen profile,
> reusing B's picker and A's `enrichPosting`, persisted latest-wins. `MARKETING_VERSION` is at `0.6.0`.
>
> **⚠️ Awaiting device checks (v0.5.0 + v0.5.1)** — verify on a real run: **(v0.5.0)** job detail + Application
> open as **separate windows**; marking status / saving / generating in a window refreshes the main-window
> Results/Tracker lists; **explicit Generate** with the options panel; **fidelity** + **aspect** checkboxes
> shift the output; **presets** save/apply/delete; **embellished** mode shows the disclosures; the
> **rank-target** loop converges; swipe-to-save/delete on Results and remove-from-Tracker; and no spurious
> Photos/Music privacy prompts. **(v0.5.1)** the Export menu's **"PDF — Portfolio (LaTeX)"** and **"LaTeX
> source (.tex)"** items produce a correct awesome-cv PDF / `.tex` on a machine with `lualatex` installed
> (matching the hand-built layout), the LaTeX PDF item is absent when TeX isn't found, résumé & cover letter
> export as **separate** files, the Tracker **sort** bar reorders rows, the additional-context box steers a
> regeneration, and Settings → About shows LaTeX availability + reads **0.5.1**.
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone A)** — with a live engine: saving a searched job **enriches** it,
> and its Tracker detail shows work-type / employment / posted-date / category **badges** plus a collapsible
> **Posting details** section (About the role/company, Qualifications, Responsibilities, Nice-to-have, Benefits);
> enriched jobs show work/employment **chips** in the Tracker list (`RankedRow`) while un-enriched jobs look
> unchanged; a blocked/paywalled posting falls back to the snippet without error; and the enriched detail visibly
> improves a generated résumé/cover letter (it flows into the target brief). Settings → About reads **0.6.0**.
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone B)** — with saved profiles present, the Application view's
> **Generation options** panel shows a **Profile** picker defaulting to "Current profile"; picking another
> profile grounds the generated résumé/cover letter on **that** profile's source documents (visibly different
> output); the picker is absent when there are no saved profiles; and "Current profile" reproduces the prior
> behaviour.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.0 — richer grounding & job detail  (in progress)

**Milestones restart at A** (see the versioning note in `CLAUDE.md`); commit as `v0.6.0 : Milestone X
Completed`. The three milestones are drawn from `PLANNED.md` (now removed from there) and **build in order** —
B introduces the shared profile picker that C reuses, and C's re-enrich half depends on A's enrichment. Each
respects the layer dependency rule (Presentation → Business → Data → Infrastructure).

**Release hygiene (do at kickoff):**

- [x] Bump every `MARKETING_VERSION` (4 copies in `project.pbxproj`, Debug/Release × app/test) to `0.6.0` so
      Settings → About reports the real version.

**✅ Milestone A — Richer job postings — complete** (A-A…A-F). Write-up moved to `MILESTONES.md`.

---

## Milestone C — Regenerate result (re-rank & re-enrich a saved job against a chosen profile)

**What / why.** Mirror the **regenerate application** flow (Generate/Regenerate on the Application view) with a
**regenerate result** action on a saved job. It re-runs the fit assessment — and, where available, the posting
**enrichment** (Milestone A) — for an existing result against a **chosen profile**, so the user can refresh a
stale result. The motivating case: **legacy entries** carried over from the old version of the app were ranked
against a different/older profile and lack the richer posting fields; "regenerate result" lets the user re-rank
them against a current profile and **fill out more info about the job posting**. Like the profile-summary
regeneration (`refineSummary`) and the application generation (v0.5.1 Milestone I), it also takes an
**additional-context** field to steer the re-assessment (e.g. "weight my Go backend experience", "read this
role as platform-focused").

**What a "result" is.** A `RankedJob` (`Data/Models/RankedJob.swift`) = a `JobListing` + its `JobMatch`.
"Regenerate result" refreshes the **`JobMatch`** (re-rank) and optionally the **`JobListing`** (re-enrich —
Milestone A), then persists the updated `RankedJob`.

**Seam + files.**
- **Business — a `RegenerateResultUseCase`.** Re-rank one saved job against the chosen profile and persist.
  Ranking today is **batch + context-free**: `JobRanker.rank(_:for:)` (`Business/Ranking/JobRanker.swift:44`)
  → `LLMProvider.rank(jobs:against:)` (`Data/LLM/LLMProvider.swift:21`) → `[JobMatch]`. Add a **single-job
  re-rank that accepts an optional instruction**: a new `rank(job:against:instruction:)`-style `LLMProvider`
  overload (forwarding default, exactly how `generateApplication` grew `grounding:` / `settings:`) + a
  `Prompts` "additional guidance" block, or reuse the batch `rank` with a one-element array when no context is
  given.
- **Data/LLM — enrichment (optional, composes with A).** If Milestone A has landed, regenerate also runs the
  `enrichPosting` pass to backfill job type / work type / qualifications / about-role/company on the legacy
  `JobListing`. If A hasn't shipped yet, regenerate is **re-rank only** — the two are independent slices.
- **Persistence — latest-wins upsert.** Save the refreshed `RankedJob` via `SavedJobsRepository.save([RankedJob])`
  (`Data/Persistence/SavedJobsRepository.swift:26`, upsert by `JobListing.id`) — reusing `SaveResultsUseCase`.
  Overwrites the old match/enrichment in place.
- **Presentation — the action.** A **"Regenerate result"** button on `JobDetailView`
  (`Results/View/JobDetailView.swift`, shown from Results **and** Tracker), with a **profile picker** (shared
  with Milestone B) + an **additional-context** text box (shared UI pattern with v0.5.1 Milestone I and
  `refineSummary`). On completion the row's score/reason/skills badges and the detail view refresh via the
  existing cross-window refresh signal (`AppSession.dataChanged()` / `revision`). Wire `RegenerateResultUseCase`
  into `Composition` and the relevant ViewModel (`ResultsViewModel` / `TrackerViewModel` / a small detail VM).

**Sub-tasks:**
- [ ] Single-job re-rank overload on `LLMProvider` (`rank(job:against:instruction:)`, forwarding default) +
      `Prompts` guidance block; real engines override, stubs inherit.
- [ ] `RegenerateResultUseCase` (Business) — re-rank one job against the chosen profile, persist via
      `SaveResultsUseCase` / `SavedJobsRepository`.
- [ ] Optional re-enrich (gated on Milestone A's `enrichPosting`).
- [ ] "Regenerate result" action on `JobDetailView` with the shared profile picker + additional-context box;
      wire into `Composition` + the relevant ViewModel; refresh via `AppSession`.
- [ ] **(open call) What it refreshes.** Re-rank only, or re-rank **and** re-enrich? *Recommended:* re-rank
      always; re-enrich when A's fields exist (gate on A). Ship re-rank first if A hasn't landed.
- [ ] **(open call) Per-result vs. bulk.** Per-result manual (this milestone) vs. bulk "re-rank all legacy
      entries against profile X". *Recommended:* per-result first; bulk backfill a later convenience (mind
      Adzuna/LLM cost + context window).
- [ ] **(open call) History vs. overwrite.** *Recommended:* latest-wins overwrite of the saved `RankedJob`
      (consistent with how `ApplicationKit` persists), not a match history.
- [ ] **(open call) Legacy detection.** Optionally flag results predating the richer schema (a "needs refresh"
      hint). *Recommended:* decode-with-defaults means legacy jobs load with empty richer fields — surface a
      subtle "re-rank to update" affordance rather than auto-regenerating.

**Tests.** Single-job re-rank via a stub `LLMProvider` (with and without an instruction); `RegenerateResultUseCase`
persists a latest-wins upsert (`SavedJobsRepository` shows the refreshed `JobMatch` for the same id); the
additional-context threads into the `Prompts` guidance block (empty = byte-for-byte the base rank prompt).

**On-device.** Yes — re-rank + enrich are LLM work on the chosen engine (on-device-friendly; Claude when
selected); persistence is local. Bound the posting + profile text for the context window, as ranking/grounding
already do. No network beyond the normal model call (plus the optional full-page fetch if enrichment pulls the
full posting).

**Guardrail.** Re-ranking **re-assesses fit honestly** against the real profile (it may raise *or lower* the
score); enrichment **structures what the posting says**, never invents requirements or company facts. The
additional-context steers **emphasis / interpretation**, not fabrication.
