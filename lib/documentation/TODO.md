# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.4.0 — Milestone C (Polish + About).** Milestones A (navigation shell) and B
> (sub-view routing per area) are **done** — see `MILESTONES.md`. v0.1.0–v0.3.0 are all complete.
> v0.4.0 is the **navigation & shell** rework — a **Presentation-only** re-home of the existing screens
> behind a left sidebar + segmented inner nav (full spec:
> [`design/UI-Navigation-Redesign-v0.4.0.md`](design/UI-Navigation-Redesign-v0.4.0.md); interactive
> mockup: [`design/Refined-UI-mockup-v0.4.0.html`](design/Refined-UI-mockup-v0.4.0.html)). Start at
> Milestone C below.
>
> **⚠️ Awaiting device checks** (verify on a real run): the **sidebar shell + inner nav** — sidebar
> rows + accent selection, Results/Tracker count badges, each area's segmented sub-views (Portfolio /
> Search / Tracker stage filters / Settings), the `Area / Sub-view` header, and the split empty states —
> look/feel right; the Search **Fetch** button (now under *From a Link*) is reachable; exported
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

## Milestone C — Polish + About

- [ ] **Sidebar collapse/restore.** Confirm/refine the `NavigationSplitView` collapsible-sidebar
      behaviour (it comes free with the shell — verify the toggle + restored state feel right).
- [ ] **Keyboard navigation.** Move between areas / sub-views from the keyboard.
- [ ] **Pointer-cursor + swipe polish.** Final pass that the carried-over cursor and swipe affordances
      feel right in the shell.
- [ ] **About sub-view polish.** Milestone B added a functional Settings **About** stub (app name,
      version, one-liner). Polish it here — layout, an app icon/identity treatment, and any links.
- [ ] **Docs.** Refresh `CLAUDE.md`'s Presentation prose if needed (the App-layer entry already
      covers the shell + section taxonomy) and the root `README.md` (add the shipped v0.4.0 summary),
      then move this milestone's write-up into `MILESTONES.md`.
- [ ] **Nuke the design scaffolding.** When v0.4.0 is done, **delete the
      [`design/`](design/) subdirectory** (the UI spec + HTML mockup were build-time references only)
      and remove the now-dangling `design/…` links from `ROADMAP.md`, `TODO.md`, and `CLAUDE.md`.
