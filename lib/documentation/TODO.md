# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding & job detail — Milestone B (Select a profile at generation
> time).** All of v0.1.0–v0.5.1 are done, and **v0.6.0 Milestone A (Richer job postings, A-A…A-F) is complete**
> (write-up in `MILESTONES.md`): Adzuna-decoded fields + `@Generable` `PostingDetails` enrichment + full-page
> fetch + enrich-on-save + into-generation + UI badges/sections. Next is **Milestone B** — a per-generation
> **profile picker** grounding on the chosen saved profile's source documents (a small `SavedProfile.grounding`
> mapper + wiring through `ApplicationViewModel`). Then **Milestone C** — regenerate result (reuses B's picker
> and A's enrichment). `MARKETING_VERSION` is at `0.6.0`.
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

## Milestone B — Select a profile at generation time and ground on its source documents

**What / why.** When the user generates an application, curation should be grounded in a **chosen profile's
actual source documents** (the real résumé/portfolio text + optional cover letter), not just the distilled
`CandidateProfile` summary — and the user should be able to **pick which profile** to generate against right on
the generation screen. Comparing the full source documents against everything in the job result yields a
much better-tailored résumé + cover letter.

**What already exists (extend, don't reinvent).** The grounding mechanism is already built (ROADMAP Milestone T):
- `PortfolioGrounding` (`Data/Models/PortfolioGrounding.swift`) carries `resumeText` (**factual grounding**) +
  optional `coverLetterText` (a **voice / tone exemplar**). It's injected into `generateApplication(…grounding:)`
  and bounded in `Prompts`.
- `SavedProfile` (`Data/Models/SavedProfile.swift`) already stores the source documents: `sourceText` /
  `readableText` and `coverLetterText` / `coverLetterReadableText` (the LLM-tidied forms).
- `PortfolioViewModel.grounding` already builds a `PortfolioGrounding` from those fields
  (`PortfolioViewModel.swift:94`).

**The actual gap.** Grounding today is tied to the **single currently-loaded/default profile**: it flows
`PortfolioViewModel.grounding` → `AppSession.grounding` (`App/AppSession.swift:34`) → `ApplicationWindow`
(`App/ApplicationWindow.swift`) → `JobDetailView.grounding` (`Results/View/JobDetailView.swift:22`) →
`ApplicationSheet`. There is **no profile picker on the generation screen** and no per-application choice — you
generate against whatever profile is loaded in the Portfolio tab, and if grounding wasn't set up you silently
fall back to profile-summary-only. This milestone adds **explicit per-generation profile selection** and
guarantees the chosen profile's **source documents** are what's grounded.

**Seam + files.**
- **`SavedProfile` → grounding mapper (Data).** Lift the `PortfolioViewModel.grounding` logic into a reusable
  `SavedProfile.grounding` (or a small mapper) so **any** saved profile yields its `PortfolioGrounding`
  (`readableText` ?? `sourceText` for résumé; `coverLetterReadableText` for the exemplar). Each `SavedProfile`
  also carries its `CandidateProfile`, so a selection supplies **both** `profile:` and `grounding:`.
- **Profile picker (Presentation).** Add a saved-profile selector to the generation screen — the
  `ApplicationSheet` "Generation options" panel (alongside fidelity/aspects/context) — populated via the
  existing `LoadProfilesUseCase`, defaulting to the current default/loaded profile (`DefaultProfileStore`).
- **Wiring (Presentation).** Thread the chosen profile through generation:
  `ApplicationViewModel.generate(for:profile:grounding:)` (`Application/ViewModel/ApplicationViewModel.swift:265`)
  takes the selected profile + its grounding rather than only the ambient `AppSession.profile` / `grounding`.
  Inject `LoadProfilesUseCase` into `ApplicationViewModel` via `Composition` (`makeApplicationViewModel`), and
  have the picker load the saved profiles. Keep `AppSession`'s current profile as the **default** selection so
  behaviour is unchanged when the user doesn't touch the picker.
- **Prompt depth (Data/LLM).** The curation prompt already receives `resumeText`; make sure it **compares the
  source documents against the full job result** (description — and A's richer posting fields when they land),
  and that both résumé + cover-letter source are bounded for the on-device context window (verify `Prompts`'
  grounding limits are generous enough to carry a real résumé).

**Sub-tasks:**
- [ ] `SavedProfile.grounding` mapper (Data) + tests.
- [ ] Profile picker in the `ApplicationSheet` options panel, populated via `LoadProfilesUseCase`, defaulting
      to the `DefaultProfileStore` profile.
- [ ] Thread selected profile + grounding through `ApplicationViewModel.generate(...)`; inject
      `LoadProfilesUseCase` in `Composition.makeApplicationViewModel`.
- [ ] Verify `Prompts` grounding bounds carry a full résumé; compare source docs against the full job result.
- [ ] **(open call) Persistence.** Remember the chosen profile **per job** (persist with the saved
      job/`ApplicationKit`) vs. **session-only** (default = the default profile each open). *Recommended:*
      session-only first; per-job persistence a later refinement.
- [ ] **(open call) Picker location.** `ApplicationSheet` options panel vs. `JobDetailView` before opening.
      *Recommended:* the options panel, beside fidelity/aspects (part of the same Milestone-D "how to generate"
      controls).
- [ ] **(open call) Unsaved just-built profile.** Only **saved** profiles have stored source documents.
      *Recommended:* the picker lists saved profiles only; a just-built unsaved profile appears after Save
      (consistent with v0.4.1 Milestone F's Source Documents rule).

**Tests.** `SavedProfile.grounding` maps `readableText`/`sourceText` + cover-letter fields correctly (incl. a
legacy single-document profile → résumé-only grounding); `ApplicationViewModel.generate` uses the selected
profile's grounding over the ambient one; default selection = the `DefaultProfileStore` profile when the user
doesn't pick.

**On-device.** Yes — profile load + grounding are local; generation runs on the chosen engine. **Bound the
injected source-document text** (as `Prompts` already does for grounding).

**Guardrail.** Grounding on the source documents strengthens factual fidelity — it does **not** loosen the
never-fabricate rule. The résumé source grounds facts; the cover-letter source stays a voice/tone exemplar only
(no facts/metrics/dates imported), exactly as `PortfolioGrounding` already specifies.

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
