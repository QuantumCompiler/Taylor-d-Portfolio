# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding, job detail & sources — Milestone K (standardized result descriptions); next K-A.**
> A–J are done (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`): **A** richer job postings; **B**
> per-generation profile picker; **C** regenerate result; **D** user-editable API credentials; **E** full
> job-posting text; **F** multi-source search; **G** per-provider credential-setup help — which also delivered
> **H-A**, the enumerable **provider registry** (`JobProviderRegistry`); **H** the Search **provider selector**;
> **I** supporting profile documents (extra career docs baked into a profile as factual grounding); **J** the
> **LLM job source** (AI-suggested leads from your résumé, no API key). **Remaining: Milestone K**
> (**standardized result descriptions** — scheduled 2026-07-15; see the **v0.6.0 — remaining milestone (K)**
> section below), then the small **merge-ready wrap** (`README.md` Version-history is already updated for A–F;
> refresh it for G–K) and the **device checks** below.
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
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone I)** — on the **Portfolio → Profile** tab, a **Supporting
> documents (optional)** slot lets you **Add** several files (each shows its name + size, with a per-file remove);
> **Build Profile** tidies them and bakes them into the profile; **Source Documents** lists each saved profile's
> supporting docs (readable form) under its disclosure; the docs **survive save + relaunch** (and a legacy profile
> with none still loads); and a job generated against a profile with a rich supporting portfolio visibly draws on
> the extra signal (both the ranking and the tailored résumé/cover letter). *(Import real documents — the agent
> never does.)*
>
> **⚠️ Awaiting device checks (v0.6.0 Milestone J)** — with an AI engine available (on-device ready, or `claude`
> installed): **Settings → Engines** shows an **"AI job search"** task (pick its engine/model); **Settings →
> Sources** shows an **"AI job search"** section with **Configured** status and **no key fields / no sign-up link**;
> **Search → New Search** lists **AI job search** as a selectable source (disabled with an "engine" hint if no
> engine is available). Running a search with it (a profile loaded) returns **AI-suggested** leads that carry a
> purple **"AI-suggested"** chip in Results and a prominent **"not a verified posting — confirm before applying"**
> banner in the detail, whose link opens a **web search** for the role (not a posting URL); an AI lead that
> duplicates a real Adzuna/JSearch posting appears **once** (the API posting wins); and with **no** API keys but an
> available engine, search still works (AI-only). *(The suggestions are the model's — verify before applying.)*

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.0 — remaining milestone (K)

One feature still to build in the current release: **K** — **standardized result descriptions** (LLM-digest
*every* posting into one canonical `PostingDetails` format so results read the same whatever the source, and
generation grounds on a uniform structure). (Milestone letters are per-version.) *(Milestones **I** — supporting
profile documents — and **J** — LLM job source — shipped; their write-ups are in `MILESTONES.md`.)*

## Milestone K — Standardized result descriptions (digest every posting into one format)

**What / why.** Two problems with descriptions today: **(1)** a result shows the **raw source** `description` —
Adzuna's ~500-char snippet ("…"), JSearch's full text, or a page-fetch of varying quality — so descriptions are
**inconsistent** and often thin; and **(2)** enrichment runs **only on save-to-Tracker**
([`ResultsViewModel.enrichSavedJob`](../src/Presentation/Results/ViewModel/ResultsViewModel.swift:139)), so the
list / detail / grounding never get it automatically. **Fix:** as part of search, **LLM-digest every result into one
canonical format** — the existing [`PostingDetails`](../src/Data/Models/PostingDetails.swift) sections — and render a
**standardized description** from it, so every result reads the same *regardless of source* and generation always
grounds on a uniform structure. **Decisions (2026-07-15):** reuse `PostingDetails` + a fixed renderer; **always
digest every result** (even already-full JSearch text); and when the fetch is thin/blocked, **digest from whatever we
have anyway** (snippet + Adzuna fields + title/company).

**Seam + files.**
- **Digest into the search pipeline.** Inject
  [`EnrichPostingUseCase`](../src/Business/UseCases/EnrichPostingUseCase.swift) into
  [`SearchAndRankUseCase`](../src/Business/UseCases/SearchAndRankUseCase.swift) and, **after ranking**, digest the
  `[RankedJob]` with **bounded concurrency** (reuse the `withTaskGroup` window in `SearchAndRankUseCase.searchAll`
  `:161`). Digestion becomes part of the search output, not a save-time afterthought.
- **Always structure, even from thin input.** Change `EnrichPostingUseCase` so it **always** runs `enrichPosting`
  (LLM) into `PostingDetails` using the best available text — the fetched full page (Milestone E) when it works,
  **else the snippet + structured Adzuna fields** (`contract_type`/`contract_time`/`category`) + title/company.
  **Drop** today's "no-op when the page can't be fetched / `hasContent` is false → keep the snippet" gating: we
  always attach the digest (some sections may be empty). And **always digest even already-full JSearch text**, so
  every result shares one format (this removes the old skip-already-full cost saving — see cost note).
- **Standard rendered description (pure).** Add a deterministic renderer — `PostingDetails.standardDescription` (or
  a `StandardPostingRenderer`, Infrastructure/Text) — that renders the sections into a **fixed template** (role
  summary → About the role → Responsibilities → Qualifications → Nice-to-haves → About the company → Benefits →
  work type). Unit-testable, identical shape for every result. It becomes the **displayed** description
  (`JobDetailView` / results); the raw source text stays as a fallback when the digest is empty.
- **Feeds generation consistently (the payoff).** `PostingDetails` already flows into `buildTargetBrief` via
  `Prompts.postingDetailSection` (A-E). Now that **every** job carries a populated `PostingDetails`, generation
  grounds on a uniform structure — the "standard format for creating applications" this milestone is really about.
- **⚠️ Cost (heavier than a plain enrich).** "Always digest" = **one LLM call per result** (+ a page-fetch
  attempt), *including* JSearch results that were previously free — so the skip-already-full saving is gone. Guards:
  the **bounded-concurrency window**, **caching** (never re-digest a job already carrying `details`), and
  **progressive display** — show ranked rows immediately (raw snippet), swap each to the standardized description as
  it completes. A 25–50-result search is a real token/latency cost; surface it.

**Sub-tasks (K-A…):**
- [ ] **K-A** — Inject `EnrichPostingUseCase` into `SearchAndRankUseCase`; digest **every** ranked result into
      `PostingDetails` with bounded concurrency (reuse `searchAll`'s window).
- [ ] **K-B** — Make `EnrichPostingUseCase` **always** structure (even from snippet + Adzuna fields); drop the
      "keep snippet when empty / skip already-full" no-op — always attach the digest.
- [ ] **K-C** — `PostingDetails.standardDescription` (pure fixed-template renderer) → the displayed description; raw
      source kept as fallback.
- [ ] **K-D** — Progressive display (`SearchViewModel` / Results): raw snippet first, swap to standardized as each
      completes; persist the standardized set (`persistResults` / `SaveResultsUseCase`).
- [ ] **K-E** — Cost guard: bounded window + **cache** (skip re-digesting a job already carrying `details`); reuse
      the rate-limit posture.
- [ ] **(open call) Fixed-template section order/labels for `standardDescription`.** *Recommended:* role summary →
      about role → responsibilities → qualifications → nice-to-haves → about company → benefits → work type.
- [ ] **(open call) Soft per-search cap / digest the tail on-demand for very large searches?** *Recommended:*
      bounded window first; add a cap only if huge searches prove too slow/costly.
- [ ] **(open call) Extend `PostingDetails` (one-line role summary, comp/logistics)?** *Recommended:* ship with the
      current fields; extend only if the standard description needs them.

**Tests.** Every result gets a `PostingDetails` (bounded) — a JSearch-style full-text listing **is still digested**,
and a thin Adzuna snippet is digested from snippet + fields; `standardDescription` renders a consistent template from
both populated and sparse details; a digest failure falls back to the raw description without failing the search; the
standardized set persists; a job already carrying `details` is not re-digested (cache).
**On-device.** One `.extraction`-task LLM call per result + a page-fetch — **cost scales with result count** (no
skip-already-full now); bounded window + caching + progressive display are the guards. The digest **normalizes** the
posting into the standard format; where the source is thin it summarizes what's there (a **normalized digest, not
verbatim** — surfaced as such, consistent with the transparency stance).

---

# Next version — (unstarted; number + theme TBD)

**v0.6.0 (richer grounding, job detail & sources)** is **not yet feature-complete**: A–J are in `MILESTONES.md` /
ticked in `ROADMAP.md`, but **Milestone K remains to build** (standardized result descriptions — see the
**v0.6.0 — remaining milestone (K)** section above). Remaining before merge: build **K**, then the small
**merge-ready wrap** (refresh the `README.md` Version-history summary for G–K) and the **device checks** above.

**Milestones restart at Milestone A** for the next version (see the versioning note in `CLAUDE.md`). Its number
and theme aren't chosen until development starts (see `CLAUDE.md` → "Never pre-name the next version"). At
kickoff, pick a theme from `ROADMAP.md`'s Backlog (native `LanguageModel` provider seam, on-device embedding RAG,
optional MCP tools) or a `PLANNED.md` entry (customizable LaTeX styles — v0.7.0; supporting profile documents was
scheduled into v0.6.0 as Milestone I), assign the version number, bump `MARKETING_VERSION`, and break it into
Milestone A, B, C… here.
