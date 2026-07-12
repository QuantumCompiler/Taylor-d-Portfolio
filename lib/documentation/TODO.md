# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus.** **v0.4.1 — Milestones A → H** (below). **A:** move the Portfolio **profile
> preview**, **regenerate-description**, and **save/update** controls from the **Profile** sub-view into
> **Saved Profiles**. **B:** app-wide, **remove the content-pane header text entirely** — both the
> in-content `Area / Sub-view` title ("Portfolio / Profile") and the window title bar; the segmented
> **tabs** are the only sub-view indicator and the sidebar names the area, so Results shows no header and
> no tabs. **C:** once a result
> is **saved to the Tracker**, drop it from the **Results** list — it
> lives in the Tracker (as "Saved") from then on. **D:** give the **Tracker a tab per status** (All +
> Saved / Applied / Interviewing / Offer / Accepted / Declined / Rejected / Withdrawn). **E:** **center**
> the Tracker empty-state icon & text in the sub-view (today it hugs the top). **F:** make Portfolio →
> **Source Documents** browsable **by profile** — list saved profiles, expand one to see its source
> documents. **G:** in **Settings**, drop the background band around the **Save** button (just the
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

## Milestone A — Move the profile preview & its controls to Saved Profiles

Today the Portfolio → **Profile** sub-view holds both the *inputs* (résumé / cover-letter slots +
Build Profile) **and**, once a profile exists, that profile's preview and edit controls. Move the
second group into the Portfolio → **Saved Profiles** sub-view, so **Profile** is purely "import &
build" and **Saved Profiles** owns the built profile and everything you do to it. Presentation-only —
the ViewModel API is unchanged; these subviews already call existing VM methods, so it's a re-home,
not a rewrite.

Three blocks move out of `profileTab` (the `if let profile = viewModel.profile { … }` group in
`Portfolio/View/PortfolioView.swift`) into the Saved Profiles sub-view:

- [ ] **Profile preview** — the `ProfileSummary(profile:isDefault:)` block (the summary /
      description preview shown after Build or Load).
- [ ] **Regenerate description** — the `regenerateSummaryControl` (prompt field + Submit →
      `viewModel.regenerateSummary()`), gated on `supportsSummaryRegeneration`.
- [ ] **Update / Save profile** — the `saveRow` (profile-name field + Save Profile / Update Profile →
      `viewModel.saveProfile()`), gated on `supportsSavedProfiles`.

After the move:

- [ ] **Profile sub-view** = résumé slot + optional cover-letter slot + **Build Profile** (with its
      busy/error affordances) **only** — nothing rendered from `viewModel.profile`.
- [ ] **Saved Profiles sub-view** = the current built/loaded profile's **preview + regenerate + save**
      controls at the top, then the existing saved-profiles **library** (load / set default / delete)
      below.
- [ ] **Empty-state gate.** `savedProfilesTab` currently shows the "No saved profiles" empty state
      whenever the library is empty. It must now also host a *just-built, unsaved* profile: render the
      preview/regenerate/save block whenever `viewModel.profile != nil`, and fall back to the empty
      state only when there is **no current profile and no saved profiles**. (Open UX call — resolve at
      build time: does the saved-profiles library's own "No saved profiles" note still show *beneath* an
      unsaved current profile, or only when the whole sub-view is empty?)
- [ ] **Copy touch-ups.** Reword now-misplaced copy: the empty-state message ("Build a profile on the
      **Profile** tab and Save it — …") and the regenerate helper ("… Save/Update to keep it") should
      read correctly now that preview/save live on Saved Profiles, not Profile.
- [ ] **Tests.** The VM API is untouched, so this is a view re-home — confirm the full suite stays
      green; add/adjust any `PortfolioView`-level coverage only if a moved subview's gating changes.

Seam: **Presentation only** — `Portfolio/View/PortfolioView.swift` (relocate the three subviews from
`profileTab` to `savedProfilesTab`; widen the `savedProfilesTab` gate to account for an unsaved current
profile). No ViewModel, use-case, or lower-layer change. On-device: n/a (UI only).

## Milestone B — Remove the content-pane header text entirely (tabs only)

App-wide. Today each content pane shows a text header reading **`Area / Sub-view`** ("Portfolio /
Profile", "Search / New Search") — both **above the segmented tabs** *and* in the **window title bar** —
via `ShellNavigation.breadcrumbTitle` (`Presentation/App/ShellNavigation.swift`). Drop that text
**everywhere**: the segmented **tabs are the only sub-view indicator**, and the **sidebar** already
names the area, so **no "Portfolio / Profile"-style header should appear in any capacity** — not over
the content, not in the title bar. Presentation-only.

- [ ] **Remove the in-content header text.** In `RootView.contentHeader`, delete the
      `Text(nav.breadcrumbTitle)` line (line ~119) so `contentHeader` renders **only** the segmented
      `innerNav`. Re-check the surrounding spacing/`Divider` — with the title gone, the tabs sit at the
      top of the pane; tighten the header padding so there's no empty gap where the text was.
- [ ] **Stop the window title bar showing the area/sub-view.** The pane's
      `.navigationTitle(nav.breadcrumbTitle)` (line ~113) is what puts "Portfolio / Profile" in the title
      bar — change it so the window **no longer shows the area/sub-view**. Prefer the app name
      (`.navigationTitle("Taylor'd Portfolio")`, matching the sidebar column's title) or an empty title;
      **not** the area or sub-view name.
- [ ] **Results (and any single-sub-view area) — no header, no tabs.** Results has no real sub-views, so
      it shows **no segmented control and no header text** — its content simply fills the pane, and the
      selected **sidebar** row ("Results") is what identifies it. Confirm that with the header text gone
      and no `innerNav`, the Results pane doesn't leave an empty header band or a stray `Divider`
      (conditionally omit the header area when there are ≤ 1 sub-views). The `MainArea.subViews` entry
      for `.results` (`["Ranked"]`) can collapse accordingly.
- [ ] **Retire `breadcrumbTitle`.** With nothing displaying it, remove `ShellNavigation.breadcrumbTitle`
      (and its `RootView` uses). If a string is still wanted purely for window-title/accessibility, keep a
      minimal one — but it must not surface the `Area / Sub-view` text in the UI.
- [ ] **Tests.** Remove/replace the `ShellNavigationTests` breadcrumb assertions (they currently expect
      `Area / Sub-view` for multi-sub-view areas and the bare area name for Results) — either delete them
      with the property or assert the new behaviour (no displayed header string). Full suite green.

Seam: **Presentation only** — `Presentation/App/RootView.swift` (drop the header `Text`, retitle the
window, tidy the header band) + `ShellNavigation.swift` (retire `breadcrumbTitle`) +
`ShellNavigationTests`. No ViewModel or lower-layer change. On-device: n/a (UI only).

## Milestone C — Saved-to-Tracker jobs leave the Results list

Right now saving a result to the Tracker (Milestone V-B: marks the job `.saved`) keeps the row in
**Results** with a "Saved" badge. Change that: once a job has **any** tracker status, it should **drop
out of the Results list** and live only in the **Tracker**. Results becomes strictly the *un-triaged*
ranked jobs; saving (or otherwise tracking) a job moves it out.

- [ ] **Exclude tracked jobs from the displayed results.** In `ResultsViewModel`, filter the shown
      `[RankedJob]` to those with **no persisted `ApplicationStatus`** (i.e. not in the Tracker). The
      tracked-status data already loads for badges (`LoadJobHistoryUseCase` / the status repository) — a
      job with any stage (`.saved` … `.withdrawn`) is excluded. This composes with the existing
      `ResultsFilter` (still applied over the already-un-tracked set).
- [ ] **Remove live on save.** After a Save-to-Tracker action (row button or right-swipe → `.saved`),
      refresh so the row disappears from Results immediately, rather than only on the next load.
- [ ] **"Saved" is a Tracker state, shown in the Tracker.** A job saved with no further status stays at
      `.saved` (label already "Saved") and appears under the Tracker's **Saved** tab (see Milestone D).
      Its status is set/advanced from the Tracker (or the detail view), not from Results.
- [ ] **Clean up the now-dead Results "Saved" badge.** With saved jobs no longer in Results, the
      "Saved" badge on `RankedRow` in the Results context is moot — remove or repurpose it (Delete/other
      badges stay). Confirm the swipe card's **left = dismiss** (no save) still just hides the row and
      the right-swipe save now also removes it.
- [ ] **Empty-state wording.** If filtering-out tracked jobs can empty the list, make sure the Results
      empty state reads sensibly ("nothing left to triage" vs. "no results found") — distinct from the
      filter-bar empty state (Milestone W).
- [ ] **Tests.** `ResultsViewModel` coverage: a tracked job is excluded; saving a job removes it from
      the shown results; the `ResultsFilter` still applies to the remaining un-tracked set. Full suite
      green.

Seam: **Presentation + a use-case read** — `Results/ViewModel/ResultsViewModel` (exclude tracked ids
using the already-loaded status/history data) + `Results/View` (badge cleanup, empty state). No new
persistence or domain type — reuses Milestone O/P status data and V's save/delete flow. On-device: yes
(all local).

## Milestone D — Tracker: one tab per application status

The Tracker's inner nav has only **All / Applied / Interviewing / Offers** (and `.offers` bundles
`offer` **+** `accepted`; `saved`, `rejected`, `declined`, `withdrawn` appear only under All). Give
**every** `ApplicationStage` its own tab so each status is directly reachable.

- [ ] **Expand `TrackerSection`.** Replace the four cases with **All + one case per `ApplicationStage`**:
      **All, Saved, Applied, Interviewing, Offer, Accepted, Declined, Rejected, Withdrawn**
      (`ShellNavigation.swift`). `title` per case matches the stage `label`; `rawValue` stays the segment
      index; `init(index:)` still clamps. `MainArea.subViews` for `.tracker` keeps deriving from
      `TrackerSection.allCases`, so the segmented labels update automatically.
- [ ] **Exact-stage filtering.** `TrackerSection.includes(_ stage:)` becomes All = every stage, and each
      other tab = its **exact** stage (drop the special-case where Offers also matched `accepted`).
      `TrackerViewModel.jobs(in:)` is unchanged in shape — it just sees the new cases.
- [ ] **Per-tab empty states.** Each stage tab needs its own "nothing at this stage yet" empty state
      (e.g. "No saved jobs", "No offers yet"), distinct from "no tracked jobs at all" under All.
- [ ] **Segmented-control width (open call).** All + 8 stages = **9 segments** — a segmented `Picker`
      may not fit the content width. Decide at build time: let it compress, switch this inner nav to a
      scrollable segmented control / menu, or group less-used terminal outcomes. Keep every status
      reachable regardless of the chosen control.
- [ ] **Tests.** Update `SectionRoutingTests` (labels/order vs. `TrackerSection.allCases`; `init(index:)`
      clamp; the full new `includes` policy — each tab matches exactly its stage, All matches all) and
      `TrackerViewModelTests.jobsInSectionFilterByStage` (Saved/Accepted/Declined/Rejected/Withdrawn now
      have their own tabs). Full suite green.

Seam: **Presentation only** — `Presentation/App/ShellNavigation.swift` (`TrackerSection` cases +
`includes`) + `Tracker/View` (per-tab empty states; possibly the inner-nav control) + the two test
files. Reuses the existing `ApplicationStage` / `ApplicationStatus` data — no domain or persistence
change. On-device: yes (all local).

## Milestone E — Center the Tracker empty-state icon & text in the sub-view

In the Tracker, the empty-state `ContentUnavailableView` (both "No tracked applications" and the
per-stage "No <stage> applications") **hugs the top** of the content pane, just under the tabs, instead
of sitting centered in the available space. Cause: those branches aren't stretched — the sibling
`ProgressView` (`TrackerView.swift` line ~30) has `.frame(maxWidth: .infinity, maxHeight: .infinity)`
but the `ContentUnavailableView` branches don't, so they render at their natural (top) position.

- [ ] **Stretch the empty-state branches.** Give the two `ContentUnavailableView` branches (line ~32 and
      ~38) — or the enclosing `Group` — `.frame(maxWidth: .infinity, maxHeight: .infinity)` so the icon +
      title + description **center vertically and horizontally** in the content pane, matching the
      `ProgressView` branch.
- [ ] **Consistency sweep (optional).** Check other list-based `ContentUnavailableView` empty states
      (e.g. Results) for the same top-hug and center them the same way. **Leave the scrolling
      Portfolio/Search sub-views alone** — they deliberately use the **left-aligned** `InlineEmptyState`,
      which is correct there; this is only about the centered `ContentUnavailableView` panes.
- [ ] **Composes with Milestone D.** D adds a per-stage tab (and empty state) for every status; those new
      empty states should be centered by the same fix — do E's centering on whatever set of tabs D lands.
- [ ] **Check.** Centering isn't unit-testable — it's a device/visual check (add to the v0.4.1 device
      checks): the empty state sits centered in the pane across window sizes.

Seam: **Presentation only** — `Tracker/View/TrackerView.swift` (+ any sibling `ContentUnavailableView`
that shares the top-hug). No ViewModel or lower-layer change. On-device: n/a (UI only).

## Milestone F — Source Documents browsable by profile

Today the Portfolio → **Source Documents** sub-view shows only the **currently-loaded** profile's
tidied documents (`viewModel.readableText` / `coverLetterReadableText`) as a flat list of disclosures.
Make it **keyed by profile**: list the saved profiles, and clicking/expanding one reveals **that
profile's** source documents. Each `SavedProfile` already carries its own `sourceFileName` /
`readableText` and `coverLetterFileName` / `coverLetterReadableText`, and `viewModel.savedProfiles`
already loads them — so this is a **view restructure over existing data**, not a data change.

- [ ] **List saved profiles.** Render one selectable/expandable row per `viewModel.savedProfiles` entry
      (by `name`), replacing the single loaded-profile view.
- [ ] **Expand to that profile's documents.** Expanding a profile reveals its documents in the existing
      collapsed, scrollable `documentDisclosure`: the **résumé** readable text (`readableText`, labelled
      with `sourceFileName`) and, if present, the **cover-letter** readable text (`coverLetterReadableText`
      / `coverLetterFileName`). Net result is a two-level disclosure — **profile → documents** (decide the
      exact control: nested `DisclosureGroup`, or a profile picker/`List` selection that swaps the shown
      documents; a nested disclosure keeps it simple and matches the current pattern).
- [ ] **Per-profile empty note.** A saved profile with no tidied source text (older/empty saves) shows an
      inline "no source documents saved for this profile" note when expanded.
- [ ] **Sub-view empty state + gate.** When there are **no saved profiles**, keep the `InlineEmptyState`
      (reworded for the per-profile framing). Change the `hasSourceDocuments` gate (line ~194) from "the
      loaded profile has readable text" to "there is at least one saved profile (with source docs)".
- [ ] **Unsaved current profile (open call).** Decide whether a just-built, **not-yet-saved** profile
      also appears here (e.g. a "Current (unsaved)" entry) or whether Source Documents lists **only saved**
      profiles. Recommended: **only saved profiles** — source docs are a property of a saved profile — with
      the empty/hint copy directing the user to build & save first. (Consistent with Milestone A moving the
      save controls into Saved Profiles.)
- [ ] **Tests.** A view restructure over existing `savedProfiles` data — confirm the suite stays green;
      add coverage only if a small `PortfolioViewModel` helper is introduced to vend a profile's documents.

Seam: **Presentation only** — `Portfolio/View/PortfolioView.swift` (`sourceDocumentsSection` +
`sourceDocumentsTab` gate; reuse `documentDisclosure`), reading `viewModel.savedProfiles`. Each
`SavedProfile` already carries its readable source + cover-letter text, so **no ViewModel/use-case/
persistence change** is required (an optional VM convenience aside). On-device: yes (all local).

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
