# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** v0.1.0 (A–J + document import), v0.2.0 (K, M, N, O, P), and all of v0.3.0's
> **planned** milestones are **complete** — see `MILESTONES.md` for the full record (Hotfix, Q, R,
> **S** (all of A–E), T, U, V, W, plus the ad-hoc QoL work). **What's left in v0.3.0:** only the
> **stretch, X** (export templates + one-page gate) — parked; promote it into v0.3.0 or let it seed
> v0.4.0. **Next: decide on X (stretch) or cut v0.3.0.**
>
> **⚠️ Awaiting device checks** (verify on a real run, unrelated to the code below): the Search
> **Fetch** button is reachable/clickable after the scroll fix; exported **PDF/DOCX** files open
> correctly in Preview / Word; the new **filter bar**, **swipe card**, and **custom tab bar** look
> and feel right.
>
> Larger backlog beyond v0.3.0 (see `ROADMAP.md`): native `LanguageModel` provider seam; on-device
> embedding RAG; optional MCP tools.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.3.0 — output & polish (remaining)

## Milestone S — Polish pass  ✅ complete (A–E — see `MILESTONES.md`)

Made the six-tab app feel finished: S-A in-app markdown rendering, S-B empty/loading/error states,
S-C results/saved-jobs/Tracker cohesion, S-D scrollable screens, S-E saved-profile tile gestures.

## Milestone X — Export templates + one-page gate  ⬜ stretch (v0.3.0 stretch / v0.4.0 seed)

Goal (only if Q-B lands with room to spare): 1–2 selectable résumé templates and AGENT.md's
**one-page length gate**. Depends on the Q-B renderer choice — the HTML-template path makes both
realistic; the AttributedString path makes them harder (revisit if that was chosen).

- [ ] **Template selection.** A small set of styled templates the exporter can target; the user
      picks one at export time. Seam: extend `DocumentExporter` / `ExportFormat` with a template
      parameter (don't add a new port).
- [ ] **One-page gate.** Measure rendered length; warn (or offer a tightened variant) when the
      résumé overflows one page — AGENT.md discipline, surfaced, **never** silently truncating
      content.
- [ ] **Tests.** Template selection routes to the right layout; the length check flags an
      over-long kit.

Note: parked as a stretch — promote into v0.3.0 proper only if Q completes early; otherwise it seeds v0.4.0.
