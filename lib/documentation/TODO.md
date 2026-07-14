# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding & job detail — Milestone A (Richer job postings).** All of
> v0.1.0–v0.5.1 are done (see `MILESTONES.md`). v0.6.0 is now in progress: three composed milestones pulled
> from `PLANNED.md` — **A** richer job postings, **B** select-a-profile-at-generation + ground on its source
> documents, **C** regenerate result (re-rank/re-enrich a saved job). Build in order (B adds the shared profile
> picker; C reuses it and A's enrichment). **A-A + A-B + A-C are done** (Adzuna-decoded posting fields on
> `JobListing`; the `WorkType` / `@Generable` `PostingDetails` enrichment model + `enrichPosting` LLM step; and
> `EnrichPostingUseCase` — full-page-fetch-preferred, snippet-fallback — plus the `JobPostingSource.readableText`
> seam; and **A-D** — enrich-on-save-to-Tracker wired through `Composition` → `ResultsViewModel`, re-persisting
> the enriched `RankedJob`). Next is **Milestone A-E** — thread the enriched `PostingDetails` into
> `buildTargetBrief` / `generateApplication` + `Prompts` so tailoring uses the richer signal (the payoff).
> `MARKETING_VERSION` bumped to `0.6.0`.
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

---

## Milestone A — Richer job postings (capture & surface full posting detail)

**What / why.** A search result keeps very little about a job: `JobListing`
(`Data/Models/JobListing.swift`) is only `id, title, company, location, description, url, salary`, plus the
`JobMatch` (`Data/Models/JobMatch.swift`: score / reason / matched / missing skills). The **description** is
the sole free-text field, and from Adzuna it's frequently a **truncated snippet**, not the full posting. Keep
**much more** — job type, work type, posted date, and structured posting sections — so ranking and (especially)
tailoring have real material: it makes the two-stage generation (`buildTargetBrief` → `generateApplication`)
far better grounded (more true signal to map real experience against, a fuller `TargetBrief`).

**The core constraint (read before designing).** The fields come from **two different places**, and neither is
free today:
1. **Adzuna structured fields we don't yet decode.** Adzuna *does* return `contract_type`
   (permanent/contract) and `contract_time` (full_time/part_time), plus `category` and `created` — but
   `AdzunaJobSource.Job` (`Data/Jobs/AdzunaJobSource.swift:80`) decodes none of them (it decodes only
   `id, title, company, location, description, redirect_url, salary_min, salary_max`). **Job type** and
   **posted date** are a cheap win: decode fields already in the response.
2. **Everything else is buried in free text** — **work type** (remote/hybrid), **qualifications**,
   **about the role/company** — Adzuna gives no structured field, and its `description` is often a snippet.
   Getting them reliably needs an **LLM extraction pass** and/or the **full posting page**, not the snippet.

**Seam + files.**
- **Data model.** Extend the domain with the richer fields. Two shapes (open call below):
  - Add optional fields to `JobListing` (`jobType`, `workType`, `postedDate`, `category`) that Adzuna fills
    directly — plain `Codable`, back-compatible (all optional, decode-with-defaults like `SavedProfile.init(from:)`).
  - A separate **`@Generable`** `PostingDetails` (workType, qualifications, aboutRole, aboutCompany,
    responsibilities, benefits) for the **LLM-extracted** structure, attached to a listing by `id`. Keeping the
    LLM-produced structure `@Generable` (like `ExtractedPosting`, `Data/Models/ExtractedPosting.swift`) while
    `JobListing` stays plain-`Codable` matches the existing "API data isn't `Generable`" rule (the `JobListing`
    doc comment states this explicitly).
  - A `WorkType` enum (`onSite` / `remote` / `hybrid`); reuse / relate the existing `PositionType` for job type.
- **Adzuna decode (cheap win).** `AdzunaJobSource.Job`: decode `contract_type`, `contract_time`, `category`,
  `created`; map into the new `JobListing` fields in `toDomain()`. Source-agnostic mapping stays in the source.
- **LLM enrichment (the richer win).** Extend the extraction seam rather than invent a new one: grow
  `ExtractedPosting` (or add a sibling `enrichPosting` step on `LLMProvider`, `Data/LLM/LLMProvider.swift`)
  with the new fields + a `Prompts` entry, routed through the `.extraction` `LLMTask`.
- **Full text vs. snippet (open call below).** To fill qualifications / about-company well, prefer the **full
  posting page** over Adzuna's snippet: reuse `LinkJobPostingSource` / `JobPostingSource` (already fetches +
  strips a posting URL) against `JobListing.url` before enrichment. Falls back to the snippet when the page
  can't be fetched (JS-gated / paywalled — the failure mode that path already handles).
- **Persistence.** Thread the new fields through `SavedJobsRepository` (`Data/Persistence/SavedJobsRepository.swift`)
  / `PersistentRecordStore` mapping (decode-with-defaults so existing saved jobs still load).
- **Generation grounding.** Feed the richer fields into `buildTargetBrief` / `generateApplication` + `Prompts`
  so tailoring uses qualifications / about-the-company / work-type signal. **This is the payoff.**
- **Presentation.** `Results/View/JobDetailView` shows the new fields (job-type + work-type badges, collapsible
  Qualifications / About the role / About the company sections); a compact `RankedRow` may surface chips.

**Sub-tasks (the sub-parts letter as A-A…A-F for commits):**
- [x] **A-A — Adzuna decode (no LLM).** ✅ **Done.** `JobListing` gained `positionTypes: [PositionType]` +
      `postedDate: Date?` + `category: String?` (custom `init(from:)` decodes-with-defaults so legacy
      `RankedJob` blobs still load). `AdzunaJobSource.Job` now decodes `contract_type` / `contract_time` /
      `category` / `created` and maps them in `toDomain()` (both contract fields → the `PositionType` flag
      list; ISO-8601 `created` → `postedDate`; category label). Tests: Adzuna decode of the richer fields +
      absent-fields default + a `JobListing` round-trip + a legacy-blob decode. Suites green.
- [x] **A-B — Enrichment model + step.** ✅ **Done.** New `WorkType` enum (`on_site`/`remote`/`hybrid`, with a
      lenient `init(loose:)`) and a `@Generable` `PostingDetails` (workTypeRaw + qualifications /
      responsibilities / niceToHaves / aboutRole / aboutCompany / benefits, with `workType`/`hasContent`
      accessors); `JobListing` gained `details: PostingDetails?` (decode-with-default nil, so it persists +
      threads with the listing). Added the `enrichPosting(fromPostingText:)` step across the whole seam:
      `LLMProvider` requirement + throwing default, `FoundationModelsProvider` (constrained decode),
      `ClaudeCodeProvider` (JSON), `LLMRouter` (routed through `.extraction`), and `Prompts.enrichPosting` +
      `enrichInstructions` (extract-only, "never invent"). Tests: `PostingDetails` round-trip + `WorkType`
      loose-parse + empty-has-no-content + `JobListing` carries details; provider JSON decode; router routing;
      prompt field/bounds/guardrail. Full suite green.
- [x] **A-C — Full-page fetch feeding enrichment.** ✅ **Done.** Extended the `JobPostingSource` seam with
      `readableText(from:)` (default throws `.unreadable`; `LinkJobPostingSource` implements it by refactoring
      the fetch→decode→strip→min-length half of `fetchPosting` into a shared method — behaviour of the URL path
      unchanged). New Business `EnrichPostingUseCase` prefers the **full posting page** (via `readableText`,
      when richer than the snippet) and **falls back to the description snippet** on any fetch failure / no url
      / no source; calls `LLMProvider.enrichPosting` and attaches `PostingDetails` only when `hasContent`
      (never overwrites with emptiness), returning the listing unchanged otherwise. Tests: `readableText`
      success + unreadable cases; use-case full-page-preferred, snippet-fallback, snippet-only, empty-unchanged,
      no-usable-text. Full suite green. **UI trigger + persistence deferred to A-D** (this slice is the
      mechanism + use case).
- [x] **A-D — Trigger enrichment + persist the enriched fields.** ✅ **Done.** Resolved the enrichment-timing
      open call as recommended: **enrich on save to Tracker** (only saved jobs get tailored). `EnrichPostingUseCase`
      wired in `Composition` (over the shared `jobPostingSource`) and injected into `ResultsViewModel`;
      `saveToTracker` now marks `.saved` + refreshes history **first** (the row drops out of Results immediately),
      then best-effort enriches and **re-persists** the `RankedJob` carrying its `PostingDetails` — a fetch/LLM
      failure leaves the plain saved job untouched, and an already-enriched job is skipped. Persistence needed
      **no repository change**: `details` rides along in the `RankedJob` JSON via `SavedJobsRepository`, and A-B's
      decode-with-default keeps legacy jobs loading (`details == nil`). Tests: saving enriches + persists +
      reflects in the in-memory list; saving without enrichment wiring still works and leaves `details` nil.
      Full suite green.
- [ ] **A-E — Thread enriched fields into `TargetBrief` / generation `Prompts`.**
- [ ] **A-F — `JobDetailView` verbose layout + `RankedRow` chips.**
- [ ] **(open call) Enrichment timing.** Enrich **every** Adzuna result (an LLM call per result — heavy on a
      big search) vs. **on demand** at detail-open vs. only for **saved** jobs. *Recommended:* **enrich on
      save / on detail open**, not for the whole ranked set. Settle at build time.
- [ ] **(open call) Data shape.** Optional fields on `JobListing` (Adzuna-fillable) **plus** a separate
      `@Generable` `PostingDetails` (LLM-extracted), vs. one merged type. *Recommended:* the split above —
      keeps `JobListing` plain-`Codable` and the LLM structure `@Generable`, per the existing rule.

**Tests.** Adzuna decode of the new fields (fixture JSON with `contract_type` / `contract_time` / `category` /
`created` → mapped `JobListing`); `PostingDetails` / `WorkType` Codable + Generable round-trip; enrichment
step via a stub `LLMProvider`; `SavedJobsRepository` round-trip with and without the new fields (legacy blob
decodes with empty defaults); a `Prompts` snapshot showing the richer fields injected. Guard the optional
full-page fetch behind the existing `LinkJobPostingSource` test seam.

**On-device.** Adzuna-decode slice is pure/local (no model). Enrichment is `.extraction` LLM work
(on-device-friendly; Claude when chosen); the optional full-page fetch needs network (same as the URL path).
**Bound the posting text before extraction** (small on-device context window), as elsewhere.

**Guardrail.** Enrichment **extracts and organizes** what the posting actually says — it must not invent
requirements or company facts (same discipline as `ExtractedPosting`, which returns empty when a page has no
real posting). It structures the posting; it does not embellish the *candidate*.

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
