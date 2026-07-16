# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding, job detail & sources — Milestone H (provider selector); next H-B.**
> A–G are done (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`): **A** richer job postings; **B**
> per-generation profile picker; **C** regenerate result; **D** user-editable API credentials; **E** full
> job-posting text; **F** multi-source search; **G** per-provider credential-setup help — which also delivered
> **H-A**, the enumerable **provider registry** (`JobProviderRegistry`) that now drives F's composite and the
> Settings credential UI (no provider hand-enumerated anywhere). **Remaining: Milestone H's H-B–H-E** (the Search
> **provider selector**) and **Milestones I–J** (supporting profile documents; **LLM job source** — scheduled
> 2026-07-15; see the **v0.6.0 — remaining milestones (I–J)** section below), then the small **merge-ready wrap**
> (`README.md` Version-history is already updated for A–F; refresh it for G–J) and the **device checks** below.
> `MARKETING_VERSION` is `0.6.0`.
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
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone F)** — with an Adzuna key **and** a JSearch (RapidAPI) key
> entered in **Settings → Sources**: a search returns results from **both** providers (more/different results
> than Adzuna alone), an obvious cross-source **duplicate** posting appears **once**, JSearch results show rich
> **Posting details** without a page-fetch, and removing the JSearch key falls back to Adzuna-only with no
> error. The JSearch field saves/locks/clears like the Adzuna fields. *(Enter your own RapidAPI key — the agent
> never does.)*
>
> **⚠️ Awaiting device checks (v0.6.0 Milestones G–H)** — **(G)** Settings → **Sources** shows one credential
> section **per registered provider** (Adzuna + JSearch) each with a working **"How to get a key"** link + a
> collapsible **Setup steps** disclosure; save/lock/mask/clear still work per field. **(H)** the New Search form
> shows a **"Search sources"** checkbox per provider — a provider with no key is **disabled** with an "add a key
> in Settings" hint; unchecking a provider drops it from the search; with **only** a JSearch key configured,
> search is available (JSearch-only) and Adzuna is disabled; a **saved search** re-runs against the providers it
> was saved with (pre-existing saved searches run all).

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.0 — remaining milestones (I–J)

Two features scheduled (2026-07-15) into the current release: **I** — profiles gain **additional supporting
documents** baked in as factual grounding; **J** — an **LLM-backed job source** that finds job leads from your
résumé/portfolio, wired in alongside the API providers and given its own engine. (Milestone letters are per-version;
this is v0.6.0's I/J, unrelated to v0.5.1's Milestone I.)

## Milestone I — Supporting profile documents

**What / why.** A `SavedProfile` carries only **two** documents today: the **résumé source** (distilled into the
`CandidateProfile` *and* used as factual grounding) and an **optional cover letter** (a voice/tone exemplar, **never**
distilled). Let a profile attach **additional file(s)** — e.g. a *complete career portfolio* of every role, skill,
and project — **baked into the profile** so both **ranking/search** and **application generation** draw on far more
real signal. Unlike the cover letter, these are **factual** grounding (their content may be used), like the résumé.

**Seam + files (generalises the existing résumé/cover-letter doc handling — the mechanics already exist).**
- **Data model.** Add `supportingDocuments: [SupportingDocument]` to
  [`SavedProfile`](../src/Data/Models/SavedProfile.swift) — `SupportingDocument = { id, fileName?, rawText,
  readableText }`, mirroring the résumé/cover-letter triples. `Codable`; extend `init(from:)`
  (`SavedProfile.swift:74`) to **decode-with-defaults** (empty array when absent) so existing profiles still load.
- **Import + tidy (reuse).** Per file, reuse [`ImportPortfolioUseCase`](../src/Business/UseCases/ImportPortfolioUseCase.swift)
  + [`TidyDocumentUseCase`](../src/Business/UseCases/TidyDocumentUseCase.swift) — exactly like
  `PortfolioViewModel.importDocument` / `importCoverLetter` (`PortfolioViewModel.swift:117,132`). Add
  `importSupportingDocument(from:)` (append) + a remove; tidy + store each in `build()` (`:157`).
- **Fidelity — two channels.** (1) **Generation grounding:** add `supportingText: String?` to
  [`PortfolioGrounding`](../src/Data/Models/PortfolioGrounding.swift) (concatenated, **bounded** readable texts),
  include it in `SavedProfile.grounding` (`:99`) + `PortfolioViewModel.grounding` (`:94`) and bound it in `Prompts`;
  it flows through **Milestone B's existing threading** — no new generation seam. (2) **Ranking/search
  (open call):** ranking is `JobRanker.rank(jobs:against:profile:)` against the *distilled* `CandidateProfile`,
  batched over many jobs — injecting a big portfolio per rank is costly. *Recommended:* **distil the supporting
  docs into a richer `CandidateProfile`** at build time (`buildProfile` over résumé + supporting text) so ranking
  benefits with no per-rank cost; keep raw grounding for generation.
- **UI.** The Portfolio tab ([`PortfolioView`](../src/Presentation/Portfolio/View/PortfolioView.swift)) gains a
  **multi-file supporting-docs slot** (add/remove list) beside the source + cover-letter slots, browsable like the
  existing source documents (v0.4.1 Milestone F).

**Sub-tasks (I-A…):**
- [ ] **I-A** — `SupportingDocument` model + `SavedProfile.supportingDocuments` (decode-with-defaults) + persistence.
- [ ] **I-B** — `PortfolioViewModel` multi-file import/remove + tidy + store in `build()`.
- [ ] **I-C** — `PortfolioGrounding.supportingText` (bounded) threaded through `SavedProfile.grounding` /
      `PortfolioViewModel.grounding` + `Prompts`.
- [ ] **I-D** — Distil supporting docs into the `CandidateProfile` at build (ranking fidelity).
- [ ] **I-E** — Portfolio UI: supporting-docs slot (add/remove/browse).
- [ ] **(open call) Distil + ground, or grounding-only?** *Recommended:* both; grounding-only if scope must shrink.
- [ ] **(open call) Bound/truncate vs. RAG for large docs?** *Recommended:* bound first cut; **RAG follow-on**
      (Backlog `Retriever`/`EmbeddingClient`) — this feature is its natural driver.
- [ ] **(open call) Per-doc "kind" tag?** *Recommended:* optional freeform label now.

**Tests.** `SavedProfile` decodes legacy blobs (no `supportingDocuments`) + round-trips with them;
`PortfolioGrounding.supportingText` is included when present and bounded; a profile built with supporting docs
yields a richer `CandidateProfile` (more skills/domains) than without.
**On-device.** Import + tidy are `.profile`-task LLM work (on-device-friendly; Claude when chosen) — **bound all
injected text**; the RAG follow-on needs the `EmbeddingClient`. **Guardrail:** factual grounding about the
candidate — never-fabricate still binds (nothing beyond these docs + the profile).

## Milestone J — LLM job source (find jobs from your résumé, no API required)

**What / why.** Search needs an API key today (Adzuna / JSearch). But an LLM can surface roles straight from a
résumé/portfolio — the "paste your résumé into a fresh Claude session and it finds jobs for you" workflow. Wire an
**LLM-backed `JobSource`** in as a first-class search source (Settings → **Sources** + the Milestone H **provider
selector**) and give it its own **engine** in the engines menu — so search works even with **no API keys**.

**⚠️ The core constraint — never-fabricate (hard rule).** An LLM asked to "find jobs" can **invent** companies,
postings, and URLs. Presenting that as real would violate the app's grounded-by-default / never-fabricate rule and
mislead the user. So LLM results are **AI-suggested leads**, clearly labelled, and must **not** present a fabricated
`redirect_url` as a live posting. This is the milestone's central design decision (open call below), not an
afterthought.

**Seam + files — two touch-points (this is why it's one milestone spanning both menus).**
1. **Engine — the `LLMTask` map.** Add an `LLMTask` case **`.jobSearch`** to
   [`LLMTask`](../src/Data/LLM/LLMTask.swift) (+ `displayName` / `detail`). Since the Settings engines section
   iterates `LLMTask.allCases`, the new task **auto-appears in the engines menu** with its own `TaskEngineConfig`
   (engine + Claude model) — "available in the engines menu" with no view change. Add
   `LLMProvider.searchJobs(query:grounding:) async throws -> [JobListing]`
   ([`LLMProvider`](../src/Data/LLM/LLMProvider.swift)) with a **forwarding default** (`[]`) so stubs/engines needn't
   all change; implement in `ClaudeCodeProvider` (JSON list) + `FoundationModelsProvider` (constrained `@Generable`
   list); route through the new task in `LLMRouter`. `Prompts` block grounded on the profile/résumé + query, with an
   explicit **"do not invent — only real, plausibly-current roles; return fewer if unsure."**
2. **Source — the `JobSource` registry.** Add a `JobProvider` case **`.llm`**
   ([`JobSourceCredentialsStore.swift:14`](../src/Data/Settings/JobSourceCredentialsStore.swift:14)) with
   **`requiredCredentials: []`** (no API key). Add **`LLMJobSource: JobSource`** (Data/Jobs) holding the
   `LLMProvider` + a **grounding closure** (the selected/default profile's `PortfolioGrounding`); its `search(_:)`
   calls `searchJobs(query:grounding:)` and tags each result's `source` = AI (reuses F's `JobListing.source` open
   call). Register it in [`JobProviderRegistry`](../src/Data/Jobs/JobProviderRegistry.swift) so it appears in
   **Settings → Sources** and the **H search selector** — no hand-enumeration.

**Three real wrinkles (name them, don't bury):**
- **The descriptor factory doesn't fit an LLM source.** `JobProviderDescriptor.makeSource` is
  `(resolve, http, country) -> JobSource?` — built for an API source from credentials + HTTP. The LLM source needs
  the `LLMProvider`/router + **profile grounding**, not http/credentials. Extend the descriptor (a richer dependency
  bundle, or a source `kind` the composition root special-cases) so it can build `LLMJobSource`.
- **"Configured / available" means something different for `.llm`.** For API providers, available = credentials
  resolve (`hasCredentials`); `.llm`'s `requiredCredentials` is empty, so that's trivially true. Instead,
  availability = the chosen **engine is available** (`claude` CLI installed, or on-device model ready). The Sources
  UI + the H selector's enable/disable must use **engine-availability** for `.llm`.
- **The source needs the profile, which lives above the `JobSource` seam.** `JobSource.search(query)` carries no
  profile, but `SearchAndRankUseCase(request:profile:)` has it. Inject a **grounding closure** into `LLMJobSource`
  that reads the selected/default profile at search time (mirroring how `SettingsBackedJobSource` reads country live).

**Sub-tasks (J-A…):**
- [ ] **J-A** — `LLMTask.jobSearch` (+ displayName/detail) → auto-appears in the engines menu.
- [ ] **J-B** — `LLMProvider.searchJobs(query:grounding:)` (forwarding default) + `ClaudeCodeProvider` /
      `FoundationModelsProvider` impls + `LLMRouter` routing + a **never-invent** `Prompts` block.
- [ ] **J-C** — `JobProvider.llm` (no required credentials) + `LLMJobSource: JobSource` (grounding closure; tags source=AI).
- [ ] **J-D** — Register `.llm` in `JobProviderRegistry` (extend the descriptor factory for an LLM source) → Sources + H selector.
- [ ] **J-E** — Availability = **engine-available** (not credential) for `.llm`, in the Sources UI + the H selector gate.
- [ ] **J-F** — **AI-suggested labelling** in results/detail + search-link handling (not a fabricated posting URL).
- [ ] **(open call) Fabricated-URL policy.** *Recommended:* each lead links to a **search query** (LinkedIn/Google
      "title company location"), badged **"AI-suggested — verify before applying"**; never a fake live-posting URL.
- [ ] **(open call) Does the `claude -p` provider have web-search tooling?** **Verify at build.** If not, leads are
      model-knowledge (staleness/fabrication risk) and the labelling matters even more.
- [ ] **(open call) Count / dedup.** *Recommended:* cap the returned count; dedup against API results via F's
      `JobListing.fingerprint`.

**Tests.** `LLMJobSource` maps a stubbed `searchJobs` response → `[JobListing]` tagged AI; the `.llm` provider
reports available iff its **engine** stub is available (independent of credentials); LLM results dedup against an API
source by fingerprint; the never-invent prompt is exercised against a stub.
**On-device.** `.jobSearch` runs on-device (or Claude when chosen) — **no API key needed**; a web-search-capable
engine needs network. **Guardrail (hard):** results are **AI-suggested leads**, labelled, **never** presented as
verified live postings; the model is told to surface only real, plausibly-current roles and to return fewer rather
than invent. This is the one source where never-fabricate is load-bearing at the **data-source** level.

---

# Next version — (unstarted; number + theme TBD)

**v0.6.0 (richer grounding, job detail & sources)** has a **ninth milestone — I — added** (supporting profile
documents, scheduled from `PLANNED.md`), so it is **not yet feature-complete**: A–H are in `MILESTONES.md` / ticked
in `ROADMAP.md`, but **Milestone I remains to build** (see the **v0.6.0 — remaining milestone (I)** section above).
Remaining before merge: build **I**, then the small **merge-ready wrap** (refresh the `README.md` Version-history
summary for G–I) and the **device checks** above.

**Milestones restart at Milestone A** for the next version (see the versioning note in `CLAUDE.md`). Its number
and theme aren't chosen until development starts (see `CLAUDE.md` → "Never pre-name the next version"). At
kickoff, pick a theme from `ROADMAP.md`'s Backlog (native `LanguageModel` provider seam, on-device embedding RAG,
optional MCP tools) or a `PLANNED.md` entry (customizable LaTeX styles — v0.7.0; supporting profile documents was
scheduled into v0.6.0 as Milestone I), assign the version number, bump `MARKETING_VERSION`, and break it into
Milestone A, B, C… here.
