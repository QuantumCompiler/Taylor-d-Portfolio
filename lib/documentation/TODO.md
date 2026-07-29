# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. The next version (unstarted) — number + theme TBD.** See "Next version" at the bottom of this
> file. **v0.6.2 (list actions, sorting & document previews) is complete and merge-ready** — all five milestones
> **A–E** shipped (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`); docs, `README.md`, and
> `MARKETING_VERSION = 0.6.2` are done, and the full suite is green (719 tests, no warnings). **v0.6.1 (keyword
> match & ATS coverage) is likewise complete.** Only the **device checks** below remain before the branch merges.
>
> **⚠️ Awaiting device checks** — everything automatable is done and green; these need a real run (each
> milestone's full write-up is in `MILESTONES.md`). Settings → About should read **0.6.2**.
> - **v0.6.2 A** — a Tracker row shows the **Return to Results + trash icons** without hovering, matching the
>   Results rows; **right-clicking** a row offers the same two; both **swipes** still work. **Delete confirms from
>   all three paths** (and the dialog names the job), Return to Results doesn't. With a job open, the footer's
>   **Remove** menu offers both and the window **dismisses** after either. Return to Results puts the job back in
>   Results with its listing intact; Delete removes it from both tabs and its generated materials are gone.
> - **v0.6.2 B** — **⚠️ the interaction change to check first: a single click now selects a row and opening the
>   detail is a double-click**, in **both** Results and the Tracker. Confirm ⌘-click / shift-click extend the
>   selection, the row **icons and swipes still work** while rows are selected, and the **action bar** appears with
>   the right count ("N selected"), disabling itself mid-batch. Bulk **Save to Tracker** moves them all out of
>   Results at once (and their enrichment fills in after, without freezing the list — try ~10 at once); bulk
>   **Delete** confirms with a count; the Tracker's bulk **Return to Results** puts them all back with listings
>   intact. Selecting under **All** then switching stage tabs must not let another tab act on those rows.
> - **v0.6.2 C** — Results now has a **sort bar** (match score / company / role title / salary / date posted, both
>   directions, Reset) and the Tracker a **filter bar** (min rank / keywords / location / company / min salary — no
>   "Tracked" facet). Untouched, the Results order must look **exactly as before**. Check the Tracker filter narrows
>   **within** the open stage tab and composes with its sort; that a filter hiding every row shows "No tracked
>   applications match your filters" **with the bar still visible** and Clear working (not the "No applied
>   applications" stage-empty message); and that both tabs' filter bars look and behave identically (they're now one
>   shared control). Listings with no salary / no posted date sort **last** either direction.
> - **v0.6.2 D** — on Portfolio → Profile, **importing** a résumé/cover letter shows only the file name + character
>   count (no "Show text", no raw editor), with **Clear** and **Replace…**; **Clear** brings the paste editor back
>   empty and pasting still builds. With **no** file imported the slot behaves exactly as before. After Build
>   Profile the tidied text still appears under **Source Documents**, and clearing the slot afterwards doesn't
>   disturb the built profile's copy.
> - **v0.6.2 E** — a saved profile's **Source Documents** entry expands to the **whole** document, not a ~220pt
>   box; check a **long** résumé (> 12 000 characters) reads tidied to the bound and then continues **as-extracted**
>   after the "too long to tidy" notice, with **nothing missing at the end**. A normal-length résumé (well under the
>   bound) must show **no** notice and be tidied throughout — and, being over the old 6 000 cap, is the case that
>   used to lose its tail silently.
> - **v0.6.1 C** — generate an application for a real posting: the **coverage panel** appears below the two
>   documents with the covered (green) / missing (amber) keyword capsules, the must-have headline count is right,
>   it updates on Regenerate, it **survives reopening** the saved result, and it's **absent** for a result
>   generated before this version (a legacy record with no stored brief) and for a thin posting with no keywords.
> - **v0.6.1 D** — the **"Match the posting's must-have keywords"** checkbox: off leaves output as before; on
>   visibly raises coverage on the next Generate **without inventing** — anything unclaimable shows up in **Gaps**,
>   and no keyword list is dumped into the résumé. It stays enabled (and still applies) under a rank target, saves
>   into a preset, and a preset saved before this version still loads with it off.
> - **v0.5.0** — detail + Application as separate windows; cross-window list refresh; explicit Generate + options
>   panel (fidelity / aspects / presets / embellished disclosures / rank-target loop); Results swipe + remove-from-Tracker; no spurious Photos/Music prompts.
> - **v0.5.1** — awesome-cv LaTeX **PDF / `.tex`** export (needs `lualatex`; item hidden when TeX is absent); résumé
>   & cover letter export separately; Tracker **sort**; additional-context steers a regeneration; About shows LaTeX availability.
> - **v0.6.0 A–E** — enrich-on-save (badges + structured detail); per-generation **profile picker** grounds on that
>   profile; **Regenerate result** re-scores + backfills + honours the context box; Settings → Sources credential save/lock/mask/clear + **no keychain prompt** + live banner lift; **full de-chromed** posting text vs. snippet fallback.
> - **v0.6.0 F–H** — Adzuna **and** JSearch both return (cross-source dupes collapse; JSearch-only works); per-provider
>   "How to get a key" + Setup steps; Search **"Search sources"** selector enable/disable + saved-search source restore.
> - **v0.6.0 I** — supporting-docs slot (add/remove, survives save + relaunch); Source Documents lists them; generation draws on the extra signal.
> - **v0.6.0 J** — **AI job search** in Engines / Sources / selector (engine-based availability, no key); **AI-suggested**
>   leads with chip + "not verified" banner + web-search link; AI/API dupe collapses; AI-only search works with no API keys.
> - **v0.6.0 K** — rows appear immediately, then **"Standardizing descriptions…"**; uniform **standardized Description**
>   across sources; empty digest keeps raw (no error); persisted + not re-digested; generation grounds on it.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# Next version — (unstarted; number + theme TBD)

**Nothing is scheduled yet** — v0.6.2 is complete (see "Current focus" above) and the next version is unstarted.

**Milestones restart at Milestone A** for the next version (see the versioning note in `CLAUDE.md`). Its number
and theme aren't chosen until development starts (see `CLAUDE.md` → "Never pre-name the next version"). At
kickoff, pick a theme from `ROADMAP.md`'s Backlog (native `LanguageModel` provider seam, on-device embedding RAG,
optional MCP tools) or a `PLANNED.md` entry — one remains, **customizable LaTeX styles** (`Target: v0.7.0`, a
large ~6-milestone feature). Two candidates are **unspecced** and need a `PLANNED.md` entry with a `Target:`
first: the **ATS-friendly export mode** noted alongside v0.6.1, and the **chunked full tidy** noted as v0.6.2
Milestone E's follow-on (tidy a long document in segments so its readable copy is complete *and* formatted
throughout, rather than tidied-then-raw). Assign the version number, bump `MARKETING_VERSION`, and break it into
Milestone A, B, C… here.
