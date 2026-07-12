# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.4.1 — Milestone G** next; **Milestones G → H** remain below. **A**–**F** are ✅
> **done** (A: profile preview / regenerate / save controls moved into Saved Profiles; B: content-pane
> header text removed app-wide, tabs-only; C: saved-to-Tracker jobs now leave the Results list; D: the
> Tracker has a tab per status, All + all 8 stages; E: Tracker (and Results) empty states now centered
> in the pane; F: Portfolio → Source Documents is now browsable by profile — see `MILESTONES.md`).
> **G:** in **Settings**, drop the background band around the **Save** button (just the
> button). **H:** clear the build **warnings** — the `ExportTemplate.style` main-actor-isolation batch
> (mark it `nonisolated`) and the unused `try?` in `SearchViewModel`. v0.4.1 is a
> **patch release** — bug fixes & small refinements on the
> v0.4.0 shell — and is this project's first `v0.x.y` point release (see the versioning note in
> `CLAUDE.md`). Its milestones still restart at **A** and commit as `v0.4.1 : Milestone X Completed`.
> When v0.4.1 ships, the next *feature* version is **v0.5.0** (also restarting at Milestone A; pick its
> theme from `ROADMAP.md`'s backlog — native `LanguageModel` provider seam, on-device embedding RAG, or
> optional MCP tools).
>
> **⚠️ Awaiting device checks** (verify on a real run, unrelated to the code below): the **sidebar
> shell + inner nav** — sidebar rows + accent selection, Results/Tracker count badges, each area's
> segmented sub-views (Portfolio / Search / Tracker stage filters / Settings), the `Area / Sub-view`
> header, split empty states, keyboard nav (⌘1–⌘5, ⌘⇧[ / ⌘⇧]), sidebar collapse, and the **About**
> pane (icon + version 0.4.0) all look/feel right; the Search **Fetch** button (now under *From a
> Link*) is reachable; exported **PDF/DOCX** files open correctly in Preview / Word; the **filter
> bar** and **swipe card** feel right.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.4.1 — fixes & refinements  (patch release, in progress)

This project's **first point release**: a small `v0.x.y` patch on top of the v0.4.0 shell,
gathering bug fixes and minor refinements rather than a new feature theme. Milestones still restart
at **A** and are committed as `v0.4.1 : Milestone X Completed`. Presentation-only unless a specific
milestone says otherwise. (See `CLAUDE.md` → Working process → Versioning for how patch releases fit
the numbering.)

**Milestones A–F are complete** — their write-ups moved to `MILESTONES.md`. Remaining: **G → H**.

## Milestone G — Settings Save button: drop the surrounding section background

In Settings (Engines / Adzuna), the **Save** button sits inside a grouped-form `Section` (`saveSection`),
so `.formStyle(.grouped)` draws an inset **background band** around it. It should be **just the button** —
no background container.

- [ ] **Present Save as a bare button.** Take the Save control out of the grouped `Form` section so it
      renders as a plain `borderedProminent` button with no inset row/background. Cleanest: move it **below
      the `Form`** in a small plain container (e.g. an `HStack { Button…; Spacer() }` footer) rather than
      as a `Form` `Section`. (Alternative if kept in-form: clear the row background with
      `.listRowBackground(Color.clear)` + zeroed insets — but out-of-form reads cleaner.)
- [ ] **Both editing panes.** Applies to **Engines** and **Adzuna** (the two panes that show Save); the
      **About** pane has no Save and is unaffected.
- [ ] **Preserve behaviour.** Same `viewModel.save()` action, `.borderedProminent` style, and
      `clickableCursor()` — only the surrounding background goes away.
- [ ] **Check.** Visual/device check (add to the v0.4.1 device checks): the Save button shows with no
      band behind it, still aligned sensibly under the settings rows on both panes.

Seam: **Presentation only** — `Settings/View/SettingsView.swift` (`saveSection` placement / the
`body`'s `Form` composition). No ViewModel or lower-layer change. On-device: n/a (UI only).

## Milestone H — Clear the concurrency & unused-result build warnings

A warnings-cleanup pass — **not** Presentation-only (touches Infrastructure + Presentation). Two kinds:

**1. `ExportTemplate.style` main-actor-isolation warnings ("a bunch").**
`Main actor-isolated property 'style' can not be referenced from a nonisolated context`
(`MarkdownAttributedRenderer.swift:26` and every other nonisolated caller). Root cause: the project
**defaults actor isolation to `MainActor`**, and `enum ExportTemplate` was never opted out — so its
computed `style` (and `displayName` / `summary`) are MainActor-isolated, while the code that reads them
(`nonisolated enum MarkdownAttributedRenderer`, the exporters) is nonisolated. The default argument
`style: TemplateStyle = ExportTemplate.classic.style` on the nonisolated renderer is the flagged site,
but the same warning fires at each nonisolated use.

- [ ] **Mark `ExportTemplate` `nonisolated`.** It's a pure value type (`String`-backed, `Sendable`, no UI
      state), like the already-`nonisolated MarkdownAttributedRenderer` and the plain `TemplateStyle`
      value — so `nonisolated enum ExportTemplate` is correct and clears the default-argument warning **and**
      every nonisolated call site at once. Mark `TemplateStyle` `nonisolated` too if any residual isolation
      warning remains.
- [ ] Seam: `Infrastructure/Export/ExportTemplate.swift` (+ confirm `MarkdownAttributedRenderer` and the
      exporters still compile clean).

**2. Unused `try?` result.** `Result of 'try?' is unused`
(`SearchViewModel.swift:151` — `try? await saveSearch(buildRequest())` in `saveCurrentSearch()` discards
a non-`Void` result).

- [ ] **Discard explicitly.** `_ = try? await saveSearch(buildRequest())` (or handle the returned value if
      it's meaningful). Sweep for the same pattern elsewhere (other unused `try?` / discardable results) and
      clear them the same way.
- [ ] Seam: `Presentation/Search/ViewModel/SearchViewModel.swift`.

- [ ] **Verify.** A full build reports **zero** of these warnings (check the whole project, not just the
      two named files — the isolation fix should silence all `'style'` occurrences); full test suite green.

Seam: **Infrastructure + Presentation** (explicitly not Presentation-only) —
`Infrastructure/Export/ExportTemplate.swift` + `Presentation/Search/ViewModel/SearchViewModel.swift`. No
behaviour change (compile-time hygiene only). On-device: n/a.

### v0.4.1 release hygiene (do before merging the patch)

- [x] **Bump the project version to `0.4.1`.** ✅ All **four** `MARKETING_VERSION` copies in
      `project.pbxproj` (Debug/Release × app/test) set to `0.4.1`. Still to verify on a real build: the
      running app's `CFBundleShortVersionString` reads `0.4.1` in Settings → About.
- [ ] **Docs to shipped state.** ROADMAP v0.4.1 header → **(complete)** with Milestone A ticked; move
      this write-up into `MILESTONES.md` under a `# v0.4.1 —` group; README gets a v0.4.1 summary and
      its **Next:** line points to v0.5.0; `TODO.md` carries no remaining v0.4.1 work.

# v0.5.0 — (theme TBD)

**Milestones restart at Milestone A** for v0.5.0 (see the versioning note in `CLAUDE.md`). Nothing is
scheduled yet — pick the next theme from `ROADMAP.md`'s backlog (native `LanguageModel` provider seam,
on-device embedding RAG, optional MCP tools) and break it into Milestone A, B, C… here before starting.
