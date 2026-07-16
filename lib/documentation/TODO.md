# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding, job detail & sources — Milestone J (LLM job source); next J-A.**
> A–I are done (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`): **A** richer job postings; **B**
> per-generation profile picker; **C** regenerate result; **D** user-editable API credentials; **E** full
> job-posting text; **F** multi-source search; **G** per-provider credential-setup help — which also delivered
> **H-A**, the enumerable **provider registry** (`JobProviderRegistry`); **H** the Search **provider selector**;
> **I** supporting profile documents (extra career docs baked into a profile as factual grounding). **Remaining:
> Milestone J** (the **LLM job source** — scheduled 2026-07-15; see the **v0.6.0 — remaining milestone (J)** section
> below), then the small **merge-ready wrap** (`README.md` Version-history is already updated for A–F; refresh it
> for G–J) and the **device checks** below.
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

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.0 — remaining milestone (J)

One feature scheduled (2026-07-15) still to build in the current release: **J** — an **LLM-backed job source**
that finds job leads from your résumé/portfolio, wired in alongside the API providers and given its own engine.
(Milestone letters are per-version; this is v0.6.0's J, unrelated to v0.5.1's Milestone J.) *(Milestone **I** —
supporting profile documents — shipped; its write-up is in `MILESTONES.md`.)*

## Milestone J — LLM job source (find jobs from your résumé, no API required)

**What / why.** Search needs an API key today (Adzuna / JSearch). But an LLM can surface roles straight from a
résumé/portfolio — the "paste your résumé into a fresh Claude session and it finds jobs for you" workflow. Wire an
**LLM-backed `JobSource`** in as a first-class search source (Settings → **Sources** + the Milestone H **provider
selector**) and give it its own **engine** in the engines menu — so search works even with **no API keys**.

**⚠️ The one rule that stays — transparency to the user.** An LLM asked to "find jobs" will surface roles that may
not be verified live postings — possibly invented companies or URLs. **Fabrication itself is fine in this app;
misleading the user isn't.** So LLM results are **AI-suggested leads**, clearly labelled, and shouldn't present an
unverified `redirect_url` as a confirmed live posting — the user should know these are AI suggestions, not confirmed
openings. This is the milestone's central design decision (open call below), not an afterthought.

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
- [ ] **J-F** — **AI-suggested labelling** in results/detail + lead-URL handling (don't present an unverified URL
      as a confirmed posting).
- [ ] **(open call) Lead-URL presentation.** *Recommended:* each lead links to a **search query** (LinkedIn/Google
      "title company location"), badged **"AI-suggested — verify before applying"**, rather than an unverified
      live-posting URL.
- [ ] **(open call) Does the `claude -p` provider have web-search tooling?** **Verify at build.** If not, leads are
      model-knowledge (staleness risk) and the labelling matters even more.
- [ ] **(open call) Count / dedup.** *Recommended:* cap the returned count; dedup against API results via F's
      `JobListing.fingerprint`.

**Tests.** `LLMJobSource` maps a stubbed `searchJobs` response → `[JobListing]` tagged AI; the `.llm` provider
reports available iff its **engine** stub is available (independent of credentials); LLM results dedup against an API
source by fingerprint.
**On-device.** `.jobSearch` runs on-device (or Claude when chosen) — **no API key needed**; a web-search-capable
engine needs network. **Transparency:** results are **AI-suggested leads**, labelled as such and not presented as
verified live postings — the user sees they're AI suggestions. (Fabrication is acceptable; the label is what keeps
the user informed.)

---

# Next version — (unstarted; number + theme TBD)

**v0.6.0 (richer grounding, job detail & sources)** is **not yet feature-complete**: A–I are in `MILESTONES.md` /
ticked in `ROADMAP.md`, but **Milestone J remains to build** (the LLM job source — see the **v0.6.0 — remaining
milestone (J)** section above). Remaining before merge: build **J**, then the small **merge-ready wrap** (refresh
the `README.md` Version-history summary for G–J) and the **device checks** above.

**Milestones restart at Milestone A** for the next version (see the versioning note in `CLAUDE.md`). Its number
and theme aren't chosen until development starts (see `CLAUDE.md` → "Never pre-name the next version"). At
kickoff, pick a theme from `ROADMAP.md`'s Backlog (native `LanguageModel` provider seam, on-device embedding RAG,
optional MCP tools) or a `PLANNED.md` entry (customizable LaTeX styles — v0.7.0; supporting profile documents was
scheduled into v0.6.0 as Milestone I), assign the version number, bump `MARKETING_VERSION`, and break it into
Milestone A, B, C… here.
