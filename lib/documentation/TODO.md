# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.4.1 has shipped (feature-complete) — v0.5.0 is next.** All of v0.1.0–v0.4.1
> are done; see `MILESTONES.md` for the record (v0.4.1 = the profile/Saved-Profiles reorg, header
> removal, Results↔Tracker triage, a Tracker tab per status, centered empty states, per-profile Source
> Documents, the Settings Save button, and a build-warnings cleanup). **v0.5.0 restarts its milestones at
> Milestone A** (see the versioning note in `CLAUDE.md`) — pick the next theme from `ROADMAP.md`'s backlog
> (native `LanguageModel` provider seam, on-device embedding RAG, or optional MCP tools) and break it into
> Milestone A, B, C… below before starting.
>
> **⚠️ Awaiting device checks (v0.4.1)** — verify on a real run (carried across the merge): **A** the
> Portfolio Profile tab is inputs-only and the preview / regenerate / Save controls now sit on **Saved
> Profiles**; **B** no `Area / Sub-view` header anywhere (content or title bar), Results is a plain
> section with no tabs; **C** saving a result removes it from Results and it appears in the Tracker;
> **D** all 9 Tracker status tabs are reachable (the inner nav scrolls) and each filters correctly;
> **E** the Tracker / Results empty states are centered; **F** Source Documents lists saved profiles,
> each expanding to its docs, whole row clickable with a pointer cursor; **G** the Settings Save button
> has no background band and scrolls with the section; **H** exported **PDF/DOCX** still open correctly
> (the export renderer + zip writer were re-annotated in the concurrency cleanup — behaviour unchanged,
> but re-verify). Also confirm the running app's `CFBundleShortVersionString` reads **0.4.1** in
> Settings → About.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.5.0 — (theme TBD)

**Milestones restart at Milestone A** for v0.5.0 (see the versioning note in `CLAUDE.md`). Nothing is
scheduled yet — pick the next theme from `ROADMAP.md`'s backlog (native `LanguageModel` provider seam,
on-device embedding RAG, optional MCP tools) and break it into Milestone A, B, C… here before starting.
