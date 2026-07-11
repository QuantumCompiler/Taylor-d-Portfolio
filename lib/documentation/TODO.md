# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.4.0 — Milestone B (Sub-view routing per area).** Milestone A (the
> navigation shell) is **done** — see `MILESTONES.md`. v0.1.0–v0.3.0 are all complete. v0.4.0 is the
> **navigation & shell** rework — a **Presentation-only** re-home of the existing screens behind a
> left sidebar + segmented inner nav (full spec:
> [`design/UI-Navigation-Redesign-v0.4.0.md`](design/UI-Navigation-Redesign-v0.4.0.md); interactive
> mockup: [`design/Refined-UI-mockup-v0.4.0.html`](design/Refined-UI-mockup-v0.4.0.html)). Start at
> Milestone B below.
>
> **⚠️ Awaiting device checks** (verify on a real run): the new **sidebar shell** — sidebar rows +
> accent selection, Results/Tracker count badges, the segmented inner nav, and the `Area / Sub-view`
> header — looks/feels right; the Search **Fetch** button is reachable after the scroll fix; exported
> **PDF/DOCX** files open correctly in Preview / Word; the **filter bar** and **swipe card** feel right.
>
> Larger backlog beyond v0.4.0 (see `ROADMAP.md`): native `LanguageModel` provider seam; on-device
> embedding RAG; optional MCP tools.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.4.0 — navigation & shell

**Milestones restart at Milestone A** for v0.4.0 (see the versioning note in `CLAUDE.md`). The theme:
the app has outgrown its single top tab strip, so primary navigation moves to a **left sidebar** (the
five top-level areas) and each area's sub-screens become a **segmented inner nav** at the top of the
content pane (`NavigationSplitView`, native macOS throughout).

**Scope is Presentation-only.** No Business/Data/Infrastructure changes — every screen's content, view
models, and use cases are **preserved and only re-homed** under the new shell. Sheets (Job Detail,
Application) stay modal and unchanged; generation still lives in the Tracker; export/templates/one-page
gate are untouched. Full spec + interactive mockup:
[`design/UI-Navigation-Redesign-v0.4.0.md`](design/UI-Navigation-Redesign-v0.4.0.md) /
[`design/Refined-UI-mockup-v0.4.0.html`](design/Refined-UI-mockup-v0.4.0.html).

## Milestone B — Sub-view routing per area

Wire each area's sub-views behind the inner nav. Existing screen views are **reused verbatim**; only
their host changes. The agreed starting structure (see the spec's §3 table):

- [ ] **Portfolio → Profile / Saved Profiles / Source Documents.** Split the current Portfolio screen:
      **Profile** (two document slots + Build Profile + summary + Regenerate description + name +
      Save/Update), **Saved Profiles** (the saved-profile library — tap to load, long-press default,
      delete), **Source Documents** (the LLM-tidied résumé + cover-letter readable text, the current
      disclosures).
- [ ] **Search → New Search / Saved Searches / From a Link.** **New Search** (profile picker, role-title
      chips + common titles, optional filters, Search + Save Search), **Saved Searches** (list with Run /
      Delete), **From a Link** (URL fetch + paste-text fallback).
- [ ] **Results → Ranked.** The existing filter bar + ranked rows (score + history badges, per-row
      Save-to-Tracker + Delete, row → detail) as the single **Ranked** sub-view (one segment).
- [ ] **Tracker → All / Applied / Interviewing / Offers.** Stage filters over the tracked list (reuse
      the existing `ApplicationStatus` data — no new model); rows carry history badges; row → detail
      with Generate + Export unchanged.
- [ ] **Settings → Engines / Adzuna / About.** **Engines** (per-task engine + Claude-model pickers),
      **Adzuna** (country code + credentials status), **About** (stub here; filled in Milestone C).
- [ ] **Tests.** Per-area sub-view routing (each area exposes the right segments; the correct view
      hosts each segment). Reuse existing per-screen VM tests unchanged.

## Milestone C — Polish + About

- [ ] **Sidebar collapse/restore.** The `NavigationSplitView` collapsible-sidebar behaviour, native.
- [ ] **Keyboard navigation.** Move between areas / sub-views from the keyboard.
- [ ] **Pointer-cursor + swipe polish.** Final pass that the carried-over cursor and swipe affordances
      feel right in the shell.
- [ ] **About sub-view.** A small Settings **About** view — app identity, version, one-liner.
- [ ] **Docs.** Update `CLAUDE.md`'s Presentation section with the per-area sub-view structure
      (the shell itself is already documented from Milestone A) and the root `README.md` (add the
      shipped v0.4.0 summary), then move this milestone's write-up into `MILESTONES.md`.
- [ ] **Nuke the design scaffolding.** When v0.4.0 is done, **delete the
      [`design/`](design/) subdirectory** (the UI spec + HTML mockup were build-time references only)
      and remove the now-dangling `design/…` links from `ROADMAP.md`, `TODO.md`, and `CLAUDE.md`.
