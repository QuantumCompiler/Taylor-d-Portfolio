# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.7.1 — bug fixes — ALL MILESTONES (A–H) COMPLETE.** All 18 verified defects are fixed —
> write-ups in `MILESTONES.md`. What remains is **Release hygiene** (below): the `MARKETING_VERSION` bump is
> **still gated** on clearing the v0.7.0 device checks (they assert About reads 0.7.0), and the `README.md`
> version-history entry lands when the release wraps.


Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.7.1 — bug fixes

Scheduled out of `PLANNED.md` (2026-08-04). A **bug-fix release**, not a feature theme — per `CLAUDE.md` →
Versioning, a batch of fixes on top of a shipped `.0` is exactly the `v0.x.y` case. **Milestones restart at A**;
commit as `v0.7.1 : Milestone X Completed`. **Not Presentation-only** — the fixes span all four layers.

**Where these came from.** v0.7.0 shipped with the suite green (904 cases, no warnings) and **no `TODO`/`FIXME`
markers anywhere in `lib/src`** — so what's left are the defects tests and markers don't catch: **stale-async
writes, unstable identity, silent fail-soft swallowing, and unreachable UI wiring**. A structured audit
(2026-08-04) swept five subsystems — concurrency/isolation, persistence/`Codable`, the LLM layer, the search
pipeline, Presentation — and every candidate was **re-verified against the source by a second pass instructed to
refute it**. 20 findings survived; two pairs were the same defect found from two angles, leaving **18 unique: 4
high, 9 medium, 5 low**.

> **⚠️ Provenance — read before fixing.** These are **audit findings, not user-reported bugs**. Each cites a real
> `file:line` and a concrete failure scenario, and each survived a refutation pass — but **a verifier can still be
> wrong**. **Reproduce each defect before fixing it**, and treat the suggested fix as a starting point, not a
> prescription. Some (the two `Int` traps, the subprocess deadlock) are edge cases that may never have bitten in
> practice; they're in scope because they're **crashes/hangs**, cheap to guard and expensive to hit.

**Release hygiene**

- [ ] **Bump `MARKETING_VERSION` to `0.7.1`** (4 copies in `project.pbxproj` — Debug/Release × app/test).
      **⚠️ Deliberately not done at scheduling time:** v0.7.0 is merge-ready but **unmerged**, and its outstanding
      device checks assert **Settings → About reads 0.7.0**. Bumping now would invalidate them. **Clear the v0.7.0
      device checks first, then bump.**
- [ ] Add the v0.7.1 summary to `README.md`'s Version history when the release wraps.

---

# Next version — (unstarted; number + theme TBD)

**Nothing is scheduled beyond v0.7.1** — v0.7.0 is complete and **v0.7.1 (bug fixes) is scheduled above**; the
version after it is unstarted.

**Milestones restart at Milestone A** (see the versioning note in `CLAUDE.md`). The number and theme aren't chosen
until development starts (see `CLAUDE.md` → "Never pre-name the next version"). At kickoff, pick a theme from
`ROADMAP.md`'s Backlog (native `LanguageModel` provider seam, on-device embedding RAG, optional MCP tools) or spec
a `PLANNED.md` entry — that file is **empty again** now that v0.7.1 has been scheduled out of it. Four candidates
are known but unspecced and each needs a `PLANNED.md` entry with a `Target:` first:

- **ATS-friendly export mode** — noted alongside v0.6.1: standard headings, single-column, selectable text, which
  is what decides whether an ATS can *parse* a résumé at all.
- **Chunked full tidy** — v0.6.2 Milestone E's follow-on: tidy a long document in segments so its readable copy is
  complete *and* formatted throughout, rather than tidied-then-raw.
- **Custom accent colours in the manager UI** — v0.7.0 models `LaTeXAccent.custom(hex:)` and it survives a
  round-trip, but Milestone E's picker offers only the bundled palette.
- **Cross-window style refresh** — a style saved in Settings doesn't reach an already-open Application window
  until it reloads (v0.7.0 E, accepted deliberately; generation presets behave the same). An
  `AppSession.dataChanged()` bump would fix both.

Assign the version number, bump `MARKETING_VERSION`, and break it into Milestone A, B, C… here.
