# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** v0.1.0 (A–J + document import), v0.2.0 (K, M, N, O, P), and nearly all of v0.3.0 are
> **complete** — see `MILESTONES.md` for the full record (Hotfix, Q, R, S-D/S-E, T, U, V, W, plus
> the ad-hoc QoL work). **What's left in v0.3.0:** the broad **polish pass** — **S-A** (in-app markdown
> rendering), **S-B** (empty / loading / error states), **S-C** (results / saved-jobs / Tracker
> cohesion) — and the **stretch, X** (export templates + one-page gate). **Next: S-A.**
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

## Milestone S — Polish pass  ⬜ not started  (mostly Presentation; small Data/use-case touches)

Goal: make the six-tab app feel finished. Three independent parts — ship in any order.

### S-A — In-app markdown rendering  ⬜

- [ ] **Render the generated résumé + cover letter as styled text** (SwiftUI
      `Text(AttributedString(markdown:))` or an equivalent renderer) instead of raw markdown,
      on `ApplicationSheet` / `JobDetailView`.
- [ ] **Copy buttons** per document (résumé, cover letter) — composes with Q-A's clipboard export.
- [ ] **Tests / previews.** Renderer helper unit-tested (markdown → attributed); previews for
      both documents.

### S-B — Empty / loading / error states  ⬜

- [ ] **Consistent states across all six tabs** — no profile (Portfolio/Search gated), no
      results, no saved/tracked jobs, and clear fetch/generation **failure** messaging (reuse
      the existing warning/unavailable copy patterns). No silent blank screens.
- [ ] **Loading affordances** for the async steps (build profile, search, fetch posting,
      generate, export) — a consistent spinner / disabled-state convention.
- [ ] **Tests.** VM state flags (`isLoading`, empty vs populated, error message) per screen.

### S-C — Results / saved-jobs / Tracker cohesion  ⬜

- [ ] **One history story.** Make "already seen" (saved listing), "already generated" (saved
      `ApplicationKit`), and "applied" (`ApplicationStatus`) legible together — badges on
      `RankedRow` and a coherent path between Results, saved jobs, and the Tracker.
- [ ] **Reconcile loads.** Results/Tracker read the same persisted sources without clobbering a
      fresh search (extends O/P load behaviour).
- [ ] **Tests.** Badge/state assembly (seen / generated / applied) on a `RankedJob`; no-clobber
      on a fresh search.

> **Note:** S-D (scrollable screens) and S-E (saved-profile tile gestures) already shipped — see `MILESTONES.md`.

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
