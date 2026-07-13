# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.5.1 — LaTeX résumé & cover letter output — complete and ready to merge.** All of
> v0.1.0–v0.5.1 are done (see `MILESTONES.md`). v0.5.1 added the awesome-cv **LaTeX PDF export** path (A–E:
> bundled assets → `lualatex` compile engine → `TexDocumentBuilder` → wired export menu → availability + docs)
> plus independent refinements (F: Markdown `---` renders as a rule; G: résumé & cover letter as separate
> documents; H: Tracker sort; I: additional-context box). Full suite green (479 tests). **The next version is
> unstarted** — its number and theme aren't decided until development on it begins (see `CLAUDE.md` → "Never
> pre-name the next version"). At the next planning session, pick a theme from `ROADMAP.md`'s Backlog (native
> `LanguageModel` provider seam, on-device embedding RAG, or optional MCP tools), assign the version number +
> bump the project version, and break it into Milestone A, B, C… below.
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

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# Next version — (unstarted; number + theme TBD)

**Milestones restart at Milestone A** for the next version (see the versioning note in `CLAUDE.md`). Its
**number and theme aren't chosen until development starts** — Taylor decides then, so don't pre-name it here
(see `CLAUDE.md` → "Never pre-name the next version"). At kickoff, pick a theme from `ROADMAP.md`'s Backlog
(native `LanguageModel` provider seam, on-device embedding RAG, optional MCP tools), assign the version
number, bump `MARKETING_VERSION`, and break it into Milestone A, B, C… here before starting.
