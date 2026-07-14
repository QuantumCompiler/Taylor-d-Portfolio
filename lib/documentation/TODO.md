# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding, job detail & sources — Milestone E (Full job-posting text).**
> Milestones **A–D are done** (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`): **A** richer job postings;
> **B** per-generation **profile picker**; **C** **regenerate result**; **D** **user-editable API credentials**
> (keychain-backed `JobSourceCredentialsStore`, Settings fields, live availability). Two milestones remain —
> **E** full job-posting text, then **F** multi-source search (F depends on D's credential seam).
> `MARKETING_VERSION` is `0.6.0`. Device checks below still stand.
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
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone C)** — in a job's detail (from the Tracker), the **Regenerate
> result** control re-scores the job against the chosen profile (score/reason/skills update in place, may rise
> or fall), the optional context box steers the re-assessment, a legacy job gains posting detail after
> regenerating, and the main-window Results/Tracker rows refresh to the new score.
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone D)** — in **Settings → Adzuna**: entering your own App ID + App
> Key and pressing **Save** flips Status to **Configured**, turns each field into an **immutable, greyed masked
> indicator** (the key is never shown), and (the key check) **lifts the Search "unavailable" banner / enables
> Generate without a relaunch**; **Clear saved credentials** appears only after you've saved keys, **unlocks the
> fields** for re-entry, and reverts to Not-configured (or to build-time keys, if this build baked them); the
> **"How to get an Adzuna API key"** link opens the browser; a build with baked keys and no user entry shows
> Configured **with the fields still editable** (nothing to mask); and the keys **survive relaunch** (stored in
> the Keychain, not the plist). *(Enter your own real key — the agent never does.)*

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.0 — richer grounding, job detail & sources  (remaining: E, F)

Milestones **A–D are complete** (write-ups in `MILESTONES.md`). The two below extend the release — pulled
from `PLANNED.md` (now removed from there): **E** full job-posting text (composes with A's enrichment), then
**F** multi-source search (depends on **D**'s user-editable credential seam for per-provider keys). Each
respects the layer dependency rule (Presentation → Business → Data → Infrastructure).

> **Safety note (F, credential UI):** building the Settings *field* where the user types a provider's API key is
> fine; the agent must **never** enter or paste real API keys — the user fills these in.

---

## Milestone E — Full job-posting text (capture the whole posting, not Adzuna's truncated snippet)

**What / why.** A search result shows only a **truncated snippet** of the job description, and that thin text is
all generation ever sees. The trailing `…` on an Adzuna description is the tell: **Adzuna truncates
`description` at the API level** (~500 chars) — the full body is **not in the `/search` response**, so no decode
(Milestone A-A) recovers it. Capture the **entire posting** (the level of detail on the source board: about the
role / company, qualifications, tech stack, benefits, pay, work location) — to *read* in `JobDetailView` and,
the real payoff, as **grounding for generation**, so tailoring maps real experience against the posting's
actual requirements instead of a 500-char teaser.

**Relationship to Milestone A (sharpens, doesn't duplicate).** A structures a posting into `@Generable`
`PostingDetails` via an LLM pass but under-specifies **capturing the full raw text itself** — the input that
structuring needs, and worth showing verbatim. E adds that first-class capture; the two compose (E's full text
feeds A's structuring). Left separate per Taylor's call (A stays as shipped).

**Seam + files.**
- **Data model.** Add `fullDescription: String?` to `JobListing` (`Data/Models/JobListing.swift`) alongside the
  snippet `description` — plain `Codable`, back-compatible (optional / decode-with-defaults, like
  `SavedProfile.init(from:)`).
- **Fetch.** `JobListing.url` is Adzuna's `redirect_url`; reuse `JobPostingSource.readableText(from:)` /
  `fetchPosting(from:)` (`Data/Jobs/LinkJobPostingSource.swift`, the "generate from a link" path) against it to
  recover the full text. **Best-effort:** JS-gated / paywalled / blocking boards throw `.unreadable` → fall back
  to the snippet (the failure mode that path already handles).
- **Persistence.** Thread `fullDescription` through `SavedJobsRepository` (`Data/Persistence/SavedJobsRepository.swift`)
  / `PersistentRecordStore` (decode-with-defaults so existing saved jobs still load).
- **Generation grounding — the payoff.** Feed the full posting into `buildTargetBrief` / `generateApplication` +
  `Prompts` (bound for the on-device context window, as grounding already is).
- **Presentation.** `Results/View/JobDetailView` shows the full description; the snippet stays fine for the
  compact `RankedRow`.

**Sub-tasks (letter as E-A…E-D):**
- [ ] **E-A — `JobListing.fullDescription`** field + Codable back-compat.
- [ ] **E-B — Full-page fetch** via `JobPostingSource.readableText(from:)` against `JobListing.url`; snippet
      fallback on `.unreadable`.
- [ ] **E-C — Persist** `fullDescription` (repository + record-store mapping, back-compatible).
- [ ] **E-D — Thread into generation** (`buildTargetBrief` / `Prompts`) + show in `JobDetailView`.
- [ ] **(open call) When to fetch.** Every result (an HTTP fetch each — heavy on a big search) vs. **on save /
      on detail-open** vs. saved-only. *Recommended:* **on save / on detail-open** (matches A's enrichment
      timing, so one fetch serves both full text and structuring).
- [ ] **(open call) Replace `description` vs. add `fullDescription`.** *Recommended:* **add** — the snippet is a
      fine list preview and the fallback when a page can't be fetched.
- [ ] **(open call) Store vs. re-fetch.** *Recommended:* **store** it (survives relaunch, grounds generation
      offline); re-fetch only on an explicit refresh (composes with Milestone C's regenerate).

**Tests.** `JobListing` Codable round-trip with and without `fullDescription` (legacy blob decodes with the
field absent); the fetch step swaps the full text in via a stub `JobPostingSource` and falls back to the snippet
on `.unreadable`; `SavedJobsRepository` persists/loads the field; a `Prompts`/brief snapshot showing the full
text injected when present.

**On-device.** The page-fetch needs **network** (same as the link path); storage + display are local. Bound the
posting text before it hits the model. **Guardrail:** full text is captured **verbatim** — any structuring
(with A) organizes, never invents requirements or company facts.

---

## Milestone F — Multi-source job search (aggregate more providers behind `JobSource`)

**What / why.** Searches sometimes return too few results. `SearchAndRankUseCase` already pages toward a
desired-result-count goal (round-robin pages, 50/page, `maxPagesPerTitle` cap — `SearchAndRankUseCase.swift`),
so a shortfall means we've hit **Adzuna's index ceiling for that query**, not a paging bug. The fix is **more
sources**, not more tuning. The `JobSource` protocol (`Data/Jobs/JobSource.swift`,
`search(_:) async throws -> [JobListing]`) is already the swappable seam — CLAUDE.md names "Adzuna, JSearch,
USAJOBS…" as the intended set; only Adzuna conforms today.

**Seam + files.**
- **New provider conformers in `Data/Jobs/`**, one per provider, each keeping its API request/response types
  **private** to the struct (the Adzuna pattern — `AdzunaJobSource.swift`): translate `JobQuery` → the
  provider's API, map the response → `[JobListing]`, leak nothing past the protocol. Each needs its own query
  translation (Adzuna maps `PositionType.rawValue` straight to its boolean flag names,
  `AdzunaJobSource.swift:65`; other APIs express employment type / remote differently).
- **A new `CompositeJobSource: JobSource`** (Data/Jobs) holding `[any JobSource]`, running them with bounded
  concurrency (mirror the `withTaskGroup` window in `SearchAndRankUseCase.searchAll`, `:161`) and merging — so
  the fan-out over *providers* sits below the seam and `SearchAndRankUseCase`'s fan-out over *titles* stays
  unchanged.
- **Wire it in the composition root** at `SettingsBackedJobSource` (`Composition.swift:303`): assemble the
  configured providers and wrap them in `CompositeJobSource` instead of a bare `AdzunaJobSource`. Per-provider
  credentials come from **Milestone D's `JobSourceCredentialsStore`**; a provider with no key is omitted
  (fail-soft, like today's `hasAdzunaCredentials` guard).
- **Cross-source de-dup (the one real wrinkle).** The merge key today is `seen.insert(job.id)`
  (`SearchAndRankUseCase.swift:98`), but `JobListing.id` is **source-specific** — the same posting from Adzuna
  and JSearch has different ids, so a naïve union double-lists it. Add a **normalized fingerprint** (lowercased
  `title + company + location`, or redirect host+path) for cross-source dedup while keeping the source id for
  persistence. *Recommended:* a `JobListing.fingerprint` computed property consumed by `CompositeJobSource`
  (keeps `SearchAndRankUseCase` untouched) over changing the use case's `seen` key.

**Providers to add (ranked by payoff):**
- **JSearch (via RapidAPI)** — *the primary add.* A Google-for-Jobs aggregator (LinkedIn, Indeed, Glassdoor,
  ZipRecruiter…), the single biggest coverage gain. Its rich structured response (`employment_type`, `is_remote`,
  qualifications, responsibilities, benefits) **also feeds Milestones A and E** — read fields from the source
  instead of an LLM pass / page-fetch where present. (Don't chase Indeed/LinkedIn directly — Indeed's Publisher
  API is effectively closed to indie use and LinkedIn needs a partner agreement; JSearch reaches both legally.)
- **The Muse** — free, clean structured data, strong company info + level/remote flags. Small but high quality.
- **Remotive / Remote OK / Arbeitnow** — free, mostly keyless remote feeds; cheap breadth, remote-only (supplement).
- *(Deferred: USAJOBS — only if US federal roles enter scope; Reed — only if UK is a target market.)*

**Sub-tasks (letter as F-A…F-D):**
- [ ] **F-A — `CompositeJobSource: JobSource`** (bounded-concurrency fan-out + merge) + tests.
- [ ] **F-B — `JobListing.fingerprint`** + cross-source dedup in the composite (source id kept for persistence).
- [ ] **F-C — JSearch provider gateway** (private API types; `JobQuery` → RapidAPI; response → `[JobListing]`,
      populating A/E fields where the response carries them), credential via D's store.
- [ ] **F-D — Composition wiring** at `SettingsBackedJobSource`: assemble configured providers → `CompositeJobSource`;
      omit keyless providers.
- [ ] **(open call) Which providers first.** *Recommended:* **JSearch only** in the first cut (biggest gain,
      advances A/E); build `CompositeJobSource` to hold N so The Muse / remote feeds drop in later.
- [ ] **(open call) Per-provider result balancing.** *Recommended:* **none initially** — merge all, dedup, let
      `JobRanker` sort by fit; revisit if one provider floods the set.
- [ ] **(open call) Surface each result's source.** *Recommended:* **capture** it (optional `JobListing.source`
      label), defer showing it in `JobDetailView`; cheap to store now.
- [ ] **(open call) Rate-limit / cost guard** (RapidAPI is metered). *Recommended:* keep the bounded-concurrency
      window + a conservative per-run page cap; note the free-tier ceiling in About alongside the Adzuna/LaTeX lines.

**Tests.** `CompositeJobSource` fans out to two stub sources and merges; `JobListing.fingerprint` dedups the same
posting arriving from two sources (different ids, same fingerprint) while keeping distinct postings; the JSearch
gateway maps a fixture response → `[JobListing]` with A/E fields populated; a keyless provider is omitted from the
composite. Pure URL/response mapping stays unit-testable off the network (fixtures), like `AdzunaJobSource`.

**On-device.** Search needs **network**; the composite + dedup are pure/local. Mind the **metered RapidAPI free
tier** when paging (keep the page cap). No model calls beyond the normal ranking pass. **Guardrail:** n/a — data
plumbing (the never-fabricate rules bind ranking/generation downstream, unchanged).
