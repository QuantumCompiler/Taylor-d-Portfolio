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
> **provider selector** — see the section below), then the small **merge-ready wrap** (`README.md` Version-history
> is already updated for A–F; refresh it for G–H) and the **device checks** below. `MARKETING_VERSION` is `0.6.0`.
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

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.6.0 — remaining milestone (H, H-B onward)

**Milestone G is complete** (write-up in `MILESTONES.md`) and, with it, **H-A** — the enumerable **provider
registry** (`JobProviderRegistry` in `Data/Jobs`). The registry is the data-driven source of truth for every
provider (id, displayName, credential-field spec + labels, `setupURL`/steps, and a `JobSource` factory); F's
composite and the Settings credential UI now read it, and **no provider is hand-enumerated** in the composition
root or any view. **What remains is Milestone H's H-B–H-E** — the Search-view provider selector.

## Milestone H — Provider selector in the Search view

**What / why.** **F** aggregates *every* configured provider on each search. Let the user **pick which API(s) to
query** from the Search view — and the picker must list **all registered providers, growing automatically** as new
ones are added (no hardcoded list). "Available" = **registered** *and* has **resolved credentials** (Milestone D);
registered-but-unconfigured providers show **disabled**, with a jump to Settings to add a key.

**Seam + files.**
- **Registry (the core requirement).** Formalise the per-provider descriptor as the **enumerable source of truth**
  (Data) — `id`, `displayName`, credential-field spec, `setupURL` (G), and a factory building the provider's
  `JobSource` from resolved credentials. `CompositeJobSource` (F), the Settings credential fields (D) + help (G),
  **and** this picker all read the same list. **Do not enumerate providers by hand in a view.**
- **Selection → request.** Add `sources: [String]?` to
  [`JobSearchRequest`](../src/Data/Models/JobSearchRequest.swift) (`Codable`; **nil ⇒ "all available"**,
  decode-with-defaults keeps existing `SavedSearch`es valid). Build it in `SearchViewModel.buildRequest()`
  ([`SearchViewModel.swift:433`](../src/Presentation/Search/ViewModel/SearchViewModel.swift:433)) from new
  selection state on the view model.
- **Honour it.** [`SearchAndRankUseCase`](../src/Business/UseCases/SearchAndRankUseCase.swift) filters the
  composite's children to the request's selection before fanning out (empty/nil ⇒ all).
- **UI.** A selector in [`SearchView`](../src/Presentation/Search/View/SearchView.swift) listing every registered
  provider; each row enabled only when configured (disabled + "Add a key in Settings" otherwise — composes with G).
  Reuse `.clickableCursor()`.
- **Availability gate.** Today `adzunaConfigured` gates search (`SearchViewModel.swift:290,296`; `search()` `:419`).
  Generalise to **"at least one *selected* provider is configured"**; the unavailable banner points at Settings.

**Sub-tasks (H-A…):**
- [x] **H-A** — Formalise the enumerable provider registry (Data). ✅ `JobProviderDescriptor` +
      `JobProviderRegistry.all` (`Data/Jobs`) — id/displayName/credential-field spec (+ labels)/`setupURL`+steps/
      `makeSource` factory; `Composition`'s `SettingsBackedJobSource` and `SettingsView` both read it (nothing
      hand-enumerated). Delivered with Milestone G.
- [ ] **H-B** — `JobSearchRequest.sources: [String]?` (Codable, nil = all) + assemble it in `buildRequest()`.
- [ ] **H-C** — `SearchAndRankUseCase` runs only the selected providers (nil/empty = all).
- [ ] **H-D** — `SearchView` selector + `SearchViewModel` selection state; unconfigured rows disabled + link to Settings.
- [ ] **H-E** — Generalise the availability gate to "≥1 *selected* provider configured".
- [ ] **(open call) Multi- or single-select?** *Recommended:* **multi-select**, default **"All available"**.
- [ ] **(open call) Persist the selection (incl. in `SavedSearch`)?** *Recommended:* persist; a saved search re-runs
      against the providers it was saved with.
- [ ] **(open call) A selected provider loses its key?** *Recommended:* skip it with a **soft note** (reuse the
      `Output.failedTitles` style), never a hard failure — mirrors F's per-source resilience.
- [ ] **(open call) Per-provider source labels?** *Recommended:* defer to F's `JobListing.source` open call.

**Tests.** `JobSearchRequest` encodes/decodes `sources` (absent ⇒ nil ⇒ back-compatible); `SearchAndRankUseCase`
fans out to only the selected stub providers; `canSearch` is true iff ≥1 selected provider is configured; the
registry enumerates all providers.
**On-device.** Search needs **network**; the registry + selection state are pure/local.

---

# Next version — (unstarted; number + theme TBD)

**v0.6.0 (richer grounding, job detail & sources)** has **two new milestones — G and H — added** (scheduled from
`PLANNED.md`), so it is **not yet feature-complete**: A–F are in `MILESTONES.md` / ticked in `ROADMAP.md`, but
**G–H remain to build** (see the **v0.6.0 — remaining milestones (G–H)** section above). Remaining before merge:
build **G–H**, then the small **merge-ready wrap** (the `README.md` Version-history summary + **Next** line) and
the **device checks** above.

**Milestones restart at Milestone A** for the next version (see the versioning note in `CLAUDE.md`). Its number
and theme aren't chosen until development starts (see `CLAUDE.md` → "Never pre-name the next version"). At
kickoff, pick a theme from `ROADMAP.md`'s Backlog (native `LanguageModel` provider seam, on-device embedding RAG,
optional MCP tools) or a `PLANNED.md` entry (currently empty — the provider-selector and credential-setup-help
entries were scheduled into v0.6.0 as Milestones G–H), assign the version number, bump `MARKETING_VERSION`, and
break it into Milestone A, B, C… here.
