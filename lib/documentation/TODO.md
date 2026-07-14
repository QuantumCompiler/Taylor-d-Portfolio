# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding, job detail & sources — Milestone F (Multi-source job search).**
> Milestones **A–E are done** (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`): **A** richer job postings;
> **B** per-generation **profile picker**; **C** **regenerate result**; **D** **user-editable API credentials**;
> **E** **full job-posting text** (recover the full posting behind the redirect URL, ground/display on it).
> **F is the last milestone** — multi-source search (aggregate providers behind `JobSource`), depending on D's
> per-provider credential seam. `MARKETING_VERSION` is `0.6.0`. Device checks below still stand.
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
> Configured **with the fields still editable** (nothing to mask); the keys **survive relaunch** and **no
> keychain-access prompt appears on launch** (stored locally in the app's preferences — the credentials store is
> wired to `UserDefaults`, not the keychain, because ad-hoc dev signing makes the legacy keychain re-prompt every
> rebuild; `KeychainStore` stays available behind the port). *(Enter your own real key — the agent never does.)*
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone E)** — with a live engine + network: saving a job whose Adzuna
> **redirect URL is fetchable** captures the **full posting, de-chromed** (the Tracker detail's Description
> shows a clean posting — overview, responsibilities, qualifications, pay, benefits — **not** the raw page with
> nav / "similar jobs" / footer, and not the ~500-char snippet); a **blocked/JS-gated** posting silently falls
> back to the snippet (no error); the collapsible **Posting details** section also populates now that
> enrichment actually reaches the engine (the composition-forwarding fix); the fuller text visibly improves the
> generated résumé/cover letter; and legacy saved jobs still load (full text simply absent). Also re-verify
> **Milestone C**'s "Regenerate result" now honours the steering **context** box (same forwarding fix).

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.0 — richer grounding, job detail & sources  (remaining: F)

Milestones **A–E are complete** (write-ups in `MILESTONES.md`). **F** is the last milestone — pulled from
`PLANNED.md` (now removed from there): multi-source search, depending on **D**'s user-editable credential seam
for per-provider keys. It respects the layer dependency rule (Presentation → Business → Data → Infrastructure).

> **Safety note (F, credential UI):** building the Settings *field* where the user types a provider's API key is
> fine; the agent must **never** enter or paste real API keys — the user fills these in.

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
