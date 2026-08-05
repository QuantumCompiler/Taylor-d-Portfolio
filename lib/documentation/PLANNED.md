# Taylor'd Portfolio — Planned (specced, not yet versioned)

A **staging area** for features and bug fixes that have been discussed and specced but are **not yet assigned
to a version**. It sits between `ROADMAP.md`'s loose Backlog (one-line ideas) and `TODO.md` (the lettered
milestones of the *in-progress* version): entries here are written up in enough detail — real seams, files,
open calls — that when Taylor schedules one into a version it can be lifted almost verbatim into that version's
`TODO.md` + `ROADMAP.md` as Milestone A, B, C…

**How to use it.** Add a specced item here when it's described in chat but isn't part of the current version.
When a version picks it up, move its write-up into that version's `TODO.md` (as lettered milestones), tick /
reference it in `ROADMAP.md`, and **remove it from here** (this file only holds *unscheduled* work). Each entry
still respects the layer dependency rule and names the real seam, per `CLAUDE.md` → "Working process →
Planning sessions".

**Every entry records a `Target:` line** — the release it's intended for (the in-progress version, a future
`v0.x.0`, or *backlog / unassigned*). **Ask Taylor which version an item goes into when you add it** — don't
guess. The target is the entry's *intended* release; it's distinct from being *scheduled* (an entry can read
`Target: v0.x.0` and still live here until that version's planning lifts it into `TODO.md`).

**Entries are ordered by ascending target version.** All `v0.6.0` entries come before `v0.6.1`, which come before
`v0.7.0`, and so on; *backlog / unassigned* entries sort last. When adding an entry, **insert it at its target's
position**, not at the end — e.g. a later-added `v0.6.1` item slots **between** the `v0.6.0` group and any `v0.7.0`
group (so the file always reads earliest-target → latest-target, top to bottom).

> **No entries right now — the file is empty of unscheduled work.** The **bug fixes** entry (`Target: v0.7.1`) was
> scheduled into **v0.7.1** as **Milestones A–H** (2026-08-04) and now lives in `TODO.md` / `ROADMAP.md` — 18
> verified defects grouped by shared root cause. The **customizable LaTeX styles** entry
> (`Target: v0.7.0`) was scheduled into **v0.7.0** as **Milestones A–F** (2026-07-28) and now lives in `TODO.md` /
> `ROADMAP.md`. Two known candidates are **unspecced** and need an entry here with a `Target:` before they can be
> scheduled: the **ATS-friendly export mode** noted alongside v0.6.1, and the **chunked full tidy** noted as v0.6.2
> Milestone E's follow-on (tidy a long document in segments so its readable copy is complete *and* formatted
> throughout, rather than tidied-then-raw). The five **`v0.6.2`** entries — **discoverable
> remove-from-Tracker**, **multi-select bulk actions**, **Results sort + Tracker filter**, **hide imported-doc raw
> preview**, and **full source-document preview** — were scheduled into **v0.6.2** as **Milestones A–E**
> (2026-07-28) and now live in `TODO.md` / `ROADMAP.md`. The **keyword-match / ATS coverage**
> entry was scheduled into **v0.6.1** as **Milestones A–D** (2026-07-28) and now lives in `TODO.md` /
> `ROADMAP.md`; its noted companion, an **ATS-friendly export mode**, was left **unscheduled and unspecced** —
> add it here with its own `Target:` if Taylor wants it. The **supporting profile documents** entry was
> scheduled into **v0.6.0** as **Milestone I** (2026-07-15) and now lives in `TODO.md` / `ROADMAP.md`. Prior specced
> entries were also scheduled into **v0.6.0 (richer grounding, job detail & sources)**:
> - **richer job postings**, **select a profile at generation time**, **regenerate result** → Milestones **A–C**.
> - **user-editable API credentials**, **full job-posting text**, **multi-source job search** → Milestones **D–F**.
> - **per-provider credential-setup help**, **provider selector in Search** → Milestones **G–H** (scheduled
>   2026-07-15; extend D and F respectively).
>
> Add new specced-but-unscheduled work below as it comes up in chat — each with its `Target:` release, in
> ascending target-version order.
