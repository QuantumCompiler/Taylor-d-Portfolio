# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.6.0 — richer grounding & job detail — complete and ready to merge.** All three
> milestones are done (write-ups in `MILESTONES.md`, ticked in `ROADMAP.md`): **A** richer job postings
> (Adzuna fields + `@Generable` `PostingDetails` enrichment + enrich-on-save + into-generation + UI badges/
> sections); **B** per-generation **profile picker** grounding on the chosen saved profile's source documents;
> **C** **regenerate result** — a single-job re-rank (optional steering context) + re-enrich against a chosen
> profile, persisted latest-wins. Full suite green; `MARKETING_VERSION` is `0.6.0`. The only open items are the
> **device checks** below. **The next version is unstarted** — its number/theme aren't decided until
> development on it begins (see `CLAUDE.md` → "Never pre-name the next version").
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

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# Next version — (unstarted; number + theme TBD)

**v0.6.0 (richer grounding & job detail) is complete and ready to merge** — all three milestones (A richer
job postings, B profile-at-generation, C regenerate result) are in `MILESTONES.md`, ticked in `ROADMAP.md`.
The full suite is green; the only open items are the **device checks** noted above.

**Milestones restart at Milestone A** for the next version (see the versioning note in `CLAUDE.md`). Its
**number and theme aren't chosen until development starts** — Taylor decides then, so don't pre-name it here
(see `CLAUDE.md` → "Never pre-name the next version"). At kickoff, pick a theme from `ROADMAP.md`'s Backlog
(native `LanguageModel` provider seam, on-device embedding RAG, optional MCP tools) or a v0.6.0 fast-follow
(full awesome-cv fidelity / bulk legacy re-rank), assign the version number, bump `MARKETING_VERSION`, and
break it into Milestone A, B, C… here before starting.
