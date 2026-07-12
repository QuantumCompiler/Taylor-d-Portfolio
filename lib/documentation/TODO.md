# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.4.1 is feature-complete — all milestones A–H are done** (A: profile preview /
> regenerate / save controls moved into Saved Profiles; B: content-pane header text removed app-wide,
> tabs-only; C: saved-to-Tracker jobs leave the Results list; D: the Tracker has a tab per status, All +
> all 8 stages; E: Tracker/Results empty states centered; F: Source Documents browsable by profile
> (whole-row-clickable disclosures via `ExpandableRow`); G: the Settings Save button lost its background
> band; H: all concurrency + unused-`try?` build warnings cleared — a clean build is warning-free). See
> `MILESTONES.md` for the write-ups. **Remaining before merge:** the v0.4.1 device checks (below) and the
> user's commit/merge. v0.4.1 is this project's first `v0.x.y` **patch release** (see the versioning note
> in `CLAUDE.md`); the next *feature* version is **v0.5.0** (restarts at Milestone A — pick its theme from
> `ROADMAP.md`'s backlog: native `LanguageModel` provider seam, on-device embedding RAG, or optional MCP
> tools).

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.4.1 — fixes & refinements  (patch release, feature-complete)

This project's **first point release**: a small `v0.x.y` patch on top of the v0.4.0 shell,
gathering bug fixes and minor refinements rather than a new feature theme. Milestones still restart
at **A** and are committed as `v0.4.1 : Milestone X Completed`. Presentation-only unless a specific
milestone says otherwise. (See `CLAUDE.md` → Working process → Versioning for how patch releases fit
the numbering.)

**All milestones A–H are complete** — write-ups in `MILESTONES.md`. v0.4.1 is **feature-complete**;
only the release-hygiene items below and the device checks remain before it's merge-ready.

### v0.4.1 release hygiene (do before merging the patch)

- [x] **Bump the project version to `0.4.1`.** ✅ All **four** `MARKETING_VERSION` copies in
      `project.pbxproj` (Debug/Release × app/test) set to `0.4.1`. Still to verify on a real build: the
      running app's `CFBundleShortVersionString` reads `0.4.1` in Settings → About.
- [x] **Docs to shipped state.** ✅ ROADMAP v0.4.1 header reads **(complete)** with every milestone
      ticked; all write-ups are in `MILESTONES.md` under the `# v0.4.1 —` group; README has a v0.4.1
      summary and its **Next:** line points to v0.5.0; `TODO.md` carries no remaining v0.4.1 work.

> **⚠️ Awaiting device checks (v0.4.1)** — verify on a real run: **A** Portfolio Profile tab is
> inputs-only and the preview / regenerate / Save controls now sit on **Saved Profiles**; **B** no
> `Area / Sub-view` header anywhere (content or title bar), Results is a plain section with no tabs;
> **C** saving a result removes it from Results and it appears in the Tracker; **D** all 9 Tracker
> status tabs are reachable (the inner nav scrolls) and each filters correctly; **E** the Tracker /
> Results empty states are centered; **F** Source Documents lists saved profiles, each expanding to its
> docs, whole row clickable with a pointer cursor; **G** the Settings Save button has no background band
> and scrolls with the section; **H** exported **PDF/DOCX** still open correctly (the export renderer +
> zip writer were touched by the concurrency-annotation cleanup — behaviour unchanged, but re-verify).

# v0.5.0 — (theme TBD)

**Milestones restart at Milestone A** for v0.5.0 (see the versioning note in `CLAUDE.md`). Nothing is
scheduled yet — pick the next theme from `ROADMAP.md`'s backlog (native `LanguageModel` provider seam,
on-device embedding RAG, optional MCP tools) and break it into Milestone A, B, C… here before starting.
