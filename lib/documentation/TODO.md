# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.5.0 — document generation fixes — feature work complete; verify + wrap for merge.**
> All planned milestones are shipped: **A** ✅ (view generated materials), **B** ✅ (job detail + Application
> as real windows), **C** ✅ (removed the redundant "Mark as applied" button), **D** ✅ (generation controls —
> fidelity, tailored aspects, presets, disclosure, and the rank-target loop). Plus ad-hoc fixes:
> swipe-to-save/delete restored on Results, remove-from-Tracker (return to Results / delete), and
> **generation is now user-initiated** (explicit Generate button). See `MILESTONES.md` for all write-ups.
> **Remaining before merge:** a **manual device pass** on the new windows + generation controls (see the
> device-check note below), then the branch merge-ready wrap (README version-history entry + ROADMAP header
> → complete) per `CLAUDE.md` → "Making a branch merge-ready".
>
> **⚠️ Awaiting device checks (v0.5.0)** — verify on a real run: job detail + Application open as **separate
> windows** (B); marking status / saving / generating in a window refreshes the main-window lists (B-A
> revision); **explicit Generate** button (no auto-generate) with the options panel; **fidelity** + **aspect**
> checkboxes actually shift the output; **presets** save/apply/delete; **embellished** disclosures show +
> "verify before sending"; the **rank-target** loop converges and greys out fidelity/aspects; swipe
> save/delete on Results + remove-from-Tracker.
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

# v0.5.0 — document generation fixes

**Milestones restart at Milestone A** for v0.5.0 (see the versioning note in `CLAUDE.md`). Theme: fix
and round out the **document-generation experience** — the tailored résumé + cover letter produced for a
saved job, and the paths to view and regenerate them.

**Release-hygiene (kickoff):**
- [x] **Project version bumped to 0.5.0** — all four `MARKETING_VERSION` copies in
      `Taylor'd Portfolio.xcodeproj/project.pbxproj` (Debug/Release × app/test) set to `0.5.0`, so
      Settings → About reports it. *(Done as part of planning kickoff.)*

---

## Milestone A — View generated résumé & cover letter from the Tracker  ✅ done → `MILESTONES.md`

Shipped: a **View résumé & cover letter** button + **Regenerate** in the Tracker detail footer when a
generated kit exists, detected via `LoadApplicationUseCase` and routed by a new `ApplicationStartMode`
(view = load-only, no LLM; regenerate = fresh). Pure `JobDetailFooter.resolve` decides the footer, covered
by `JobDetailFooterTests`. Full write-up in `MILESTONES.md`.

> **Note for Milestone B (builds on shipped A).** A added the Tracker's **View / Regenerate / Generate**
> footer buttons via a `.sheet` (`JobDetailView` → `ApplicationSheet`, `startMode:`). When B converts the
> Application view to a real window, migrate those buttons to `openWindow` — same footer/presentation code.

---

## Milestone B — Present job detail (and its Application view) as real windows, not sheets  ✅ done → `MILESTONES.md`

Shipped (B-A + B-B + B-C): the job-detail and Application sheets are now detached single-instance `Window`
scenes driven by a shared `AppSession` (profile/grounding + selection + a revision token for list reloads).
The dead detail params on `ResultsView`/`TrackerView`/`RootView` were removed in the same pass. Full
write-up in `MILESTONES.md`.

---

## Milestone C — Remove the "Mark as applied" button (the status menu covers it)  ✅ done → `MILESTONES.md`

Shipped: removed the redundant "Mark as applied" button from `JobDetailView.statusSection`; Applied stays
reachable via **Set status → Applied** with the same auto-stamp. Write-up in `MILESTONES.md`.

---

## Milestone D — Generation controls: fidelity, tailored aspects, presets, disclosure & rank-target  ✅ done (D-A…D-F) → `MILESTONES.md`

Shipped: a Generation options panel — fidelity scale (D-B), tailored-section checkboxes (D-C, four résumé
sections + keyword-matching goal), saved **presets** (D-D), disclosed embellishment (D-E, `GapNoteParts`), and
a **desired rank-match target** (D-F) that overrides fidelity/aspects and runs the `GenerateToTargetUseCase`
loop (`scoreApplication` → escalate → regenerate to a target score). Grounded-by-default + opt-in +
disclosed. Full write-up in `MILESTONES.md`.
