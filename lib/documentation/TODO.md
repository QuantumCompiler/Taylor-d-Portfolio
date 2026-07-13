# Taylor'd Portfolio — TODO (remaining work)

The **granular checklist of what's left to build**. Completed milestones live in `MILESTONES.md`;
the high-level plan and backlog are in `ROADMAP.md`; the product spec is `SPEC.md`. See `CLAUDE.md`
→ "Working process" for how these fit together.

**How to use it:** work top-down. When you finish an item, check it off; when a whole milestone (or
sub-part) is done, **move its write-up out of this file into `MILESTONES.md`** and tick the matching
line in `ROADMAP.md`, in the same change. This file should only ever contain work that still needs
doing.

> **Current focus. v0.5.1 — LaTeX résumé & cover letter output.** v0.1.0–v0.5.0 are all done and merged (see
> `MILESTONES.md`). v0.5.1 is a **patch release** on top of shipped v0.5.0 that gives the app a **second,
> high-fidelity PDF output path**: generate a `.tex` document from Taylor's own **awesome-cv LaTeX classes**
> and compile it with **`lualatex`** (shelled as an external process, exactly like the `claude -p` provider),
> producing résumé + cover letter PDFs that match the ones he builds by hand in his `Resume-And-Cover-Letter`
> repo. Milestones **restart at A**; commits are `v0.5.1 : Milestone X Completed`.
>
> **✅ Done so far (F, G, H, I — the independent refinements; see `MILESTONES.md`):** **F** — Markdown `---`
> now renders as a real rule (not literal dashes) in the PDF / DOCX / in-app preview; **G** — résumé & cover
> letter export as **separate** documents (per-document menu + filenames); **H** — a live **sort control** in
> the Tracker (mirroring the Results filter); **I** — an **additional-context** box on the generate/regenerate
> flow that steers emphasis/framing (rides `GenerationSettings`, excluded from presets). Full suite green
> (442 tests).
>
> **Remaining:** only **A–E** — the LaTeX output path (the release's core). Start at **Milestone A**. These
> are the larger effort and need a local TeX install (`lualatex`, already present on this machine) plus an
> Xcode resource-bundling step (Milestone A open call).
>
> **Release type (noted).** This is feature-sized work carried as a **patch (`v0.5.1`)** at Taylor's
> choice; the number and branch are fixed. Kickoff hygiene (below) is done: `MARKETING_VERSION` bumped to
> `0.5.1` (4 copies).
>
> **⚠️ Awaiting device checks (v0.5.0, carried forward)** — verify on a real run: job detail + Application
> open as **separate windows** (B); marking status / saving / generating in a window refreshes the
> main-window Results/Tracker lists (B-A revision token); **explicit Generate** button with the options panel
> (no auto-generate on open); **fidelity** + **aspect** checkboxes visibly shift the output; **presets** save
> / apply / delete; **embellished** mode shows the disclosures + "verify before sending"; the **rank-target**
> loop converges and greys out fidelity/aspects; swipe-to-save/delete on Results and remove-from-Tracker
> (return to Results / delete); and the Claude engine no longer triggers spurious Photos/Music privacy
> prompts. Also confirm Settings → About now reads **0.5.1**.

Layer dependency rule still applies (Presentation → Business → Data → Infrastructure, imports point
down only).

---

# v0.5.1 — LaTeX résumé & cover letter output  (in progress)

**The theme.** Taylor maintains a polished LaTeX pipeline (`~/…/Employment/Resume-And-Cover-Letter/`): a
custom **awesome-cv** derivative where `Class/*.cls` hold the presentation, curated `.tex` sections hold the
content, and a `PortfolioBuddy` script compiles them with **`lualatex`** (two passes) into dense, one-page
résumé + cover-letter PDFs. The app already ported that repo's *prompt discipline* (two-stage brief → tailored
generation) and does its own **native** export (Core Text PDF, hand-rolled OOXML DOCX — Milestones Q/X). What
it can't do is produce the **awesome-cv look**. v0.5.1 closes that gap by **path B**: render the generated
`ApplicationKit` into `.tex` against the bundled classes and shell `lualatex` to compile it — a second export
route beside the existing Core Text one, not a replacement.

**The new seam, end to end:** `ApplicationKit` (already generated) → **`TexDocumentBuilder`** (Markdown → `.tex`,
Milestone C) → **`LaTeXProcessClient`** behind a **`LaTeXCompiling`** port (shell `lualatex` twice in a temp
dir, Milestone B) → PDF `Data` surfaced through the export menu (Milestone D). The awesome-cv **assets** it
compiles against ship in the app bundle (Milestone A). `lualatex` becomes an **optional external dependency**,
exactly like the `claude` CLI: present → the awesome-cv PDF is offered; absent → the route is disabled with a
clear "TeX not found" note, and every existing export (native PDF / DOCX / Markdown) is untouched.

**Milestones restart at A.** Each is independently committable. A–E build the LaTeX output path; **Milestone
F** (Markdown `---` printing literally) and **Milestone G** (résumé & cover letter as separate export files)
are standalone fixes to the *existing* native export path; **Milestone H** adds a Tracker sort control
(Presentation-only, mirroring the Results filter); **Milestone I** adds a free-text additional-context box to
the generate/regenerate flow. **DOCX-from-LaTeX** (the repo's `tex2docx.py` → pandoc path) is **out of scope**
— the app already has native DOCX; a LaTeX-driven DOCX is a later idea.

## Milestone A — Bundle the awesome-cv LaTeX assets in the app

**What / why.** For `lualatex` to compile an app-generated `.tex`, the presentation assets it `\input`s /
references must be available on disk at build time: the three classes (`Resume.cls`, `CoverLetter.cls`,
`Portfolio.cls`), the `fonts/` (Roboto / Source Sans), `Images/` (`Signature.png`, `TJL Logo.png`), and the
`fontawesome.sty` / `fontawesome5.sty` shims. Ship them **inside the app bundle** so a scratch build directory
(Milestone B) can reference or stage them. Only **presentation** assets are bundled — never Taylor's curated
*content* sections; the app supplies content per job.

**Seam + files.**
- New asset tree under **`lib/src/Infrastructure/Tex/Resources/`** (`Class/`, `fonts/`, `Images/`, `*.sty`),
  copied from the `Resume-And-Cover-Letter` repo. (Placing it under the synced `lib/src` root is the
  file-system-synchronized-group way to get it into the app target — see the open call on how Xcode treats
  non-source files.)
- New `Infrastructure/Tex/TexAssets.swift` — a small accessor that resolves the bundled assets directory
  (`Bundle.main` resource URL) and exposes the class/fonts/images/sty paths for the process client to stage.

**Sub-tasks.**
- [ ] Copy `Class/{Resume,CoverLetter,Portfolio}.cls`, `fonts/`, `Images/`, `fontawesome.sty`,
      `fontawesome5.sty` into `lib/src/Infrastructure/Tex/Resources/`.
- [ ] Add `TexAssets` resolving the bundled resources dir + typed accessors (classes dir, fonts dir, images
      dir); return nil/throw cleanly if the resources are missing from the bundle.
- [ ] **(open call)** *How the non-Swift assets enter the app target.* The app target synchronizes `lib/src`
      via file-system-synchronized groups (`CLAUDE.md` → Xcode project structure), but `.cls`/`.sty`/`.tex`
      aren't Xcode-recognized resource types and fonts/images need to land in the bundle intact.
      **Recommended default:** keep them under `lib/src/Infrastructure/Tex/Resources/` and add an explicit
      **`PBXFileSystemSynchronizedBuildFileExceptionSet`** (or a folder-reference / `.copyFiles` phase) so the
      whole `Resources/` folder is copied as a bundle resource verbatim. Verify at build time that the files
      appear in `…/Taylor'd Portfolio.app/Contents/Resources/`. If synchronized groups fight it, fall back to
      a plain **blue folder reference** for `Resources/`. *(This is the one milestone that isn't purely
      additive Swift — it's an Xcode-integration step; confirm the bundle contents before moving on.)*
- [ ] **(open call)** *Header identity.* The classes' `\pageHeader` bakes Taylor's fixed contact block (name,
      phone, email, homepage, GitHub, LinkedIn). **Recommended default for v0.5.1:** keep the class
      `\pageHeader` identity as-is (single-user personal app) and let the app only supply the role headline
      (`\position{…}`) + content. Profile-driven identity (name/contact from `CandidateProfile`) is a later
      idea, not this patch.

**Tests.** Unit-test `TexAssets` resolves each expected path from a bundle whose resources are present, and
fails gracefully when they're absent. A build-time check (manual/CI) that the assets are in the built `.app`.

**On-device.** N/A — static asset packaging, no network, no model.

## Milestone B — `LaTeXCompiling` port + `LaTeXProcessClient` (shell `lualatex`)

**What / why.** The engine that turns `.tex` into PDF bytes. A new Infrastructure port + a process client that
**mirrors `ClaudeProcessClient`** almost exactly: it's the second external binary the (unsandboxed) app
shells out to. Stage the bundled assets (Milestone A) + the generated `.tex` into a temp build dir, run
`lualatex` **twice** (footers/refs settle — the same two-pass rule `PortfolioBuddy` uses), return the compiled
PDF `Data`, clean `*.aux/*.log/*.out`.

**Seam + files.**
- New `Infrastructure/Tex/LaTeXCompiling.swift` — the port: `func compile(tex: String, jobName: String) async throws -> Data`
  plus an availability probe (`var isAvailable: Bool` / `func locate() -> URL?`).
- New `Infrastructure/Tex/LaTeXProcessClient.swift` — the impl. Reuse the `ClaudeProcessClient` playbook:
  - **PATH widening** — copy `searchPATH(base:home:)` and add TeX bin dirs: `/Library/TeX/texbin` (MacTeX
    symlink), `/usr/local/texlive/*/bin/*`, `/opt/homebrew/bin`, `/usr/local/bin`. Extract the shared PATH
    helper if it's worth de-duplicating (open call below).
  - **Launcher** — `.env(binaryName: "lualatex")` / `.path(String)`, like `ClaudeProcessClient.Launcher`.
  - **Temp build dir** — create under Caches (app-owned, TCC-neutral, per `neutralWorkingDirectory()`), stage
    the class/fonts/images/sty (symlink or copy) so relative `\documentclass{Class/…}` + `\fontdir[fonts/]`
    resolve, write `Resume.tex` / `Cover Letter.tex`, `cd` in, run two passes with
    `-interaction=nonstopmode -halt-on-error`, read the produced PDF, tear the dir down.
  - **Errors** — a `LaTeXProcessError` enum (`launchFailed`, `nonZeroExit(code,message)`, `notInstalled`,
    `noOutput`), surfacing the real `lualatex` log tail like `ClaudeProcessError` does.

**Sub-tasks.**
- [ ] Define `LaTeXCompiling` (compile + availability).
- [ ] Implement `LaTeXProcessClient`: staging, two-pass run, PDF read, aux cleanup, error surfacing.
- [ ] Availability probe (resolve `lualatex` on the widened PATH) → drives the disabled state in D.
- [ ] **(open call)** *Share the PATH helper.* `ClaudeProcessClient.searchPATH` is exactly what's needed.
      **Recommended default:** lift it to a tiny `Infrastructure/ProcessSupport` helper (`searchPATH` +
      `neutralWorkingDirectory`) reused by both clients, rather than copy-paste. Keep it Infrastructure-only.
- [ ] **(open call)** *Stage assets by symlink vs copy.* **Recommended default:** symlink the bundled
      `Class/`/`fonts/`/`Images/` into the temp dir (fast, no duplication — how `PortfolioBuddy` scaffolds),
      copying only if a read-only bundle path can't be symlinked from Caches.

**Tests.** Unit-test the pure helpers (arg vector, PATH build, temp-dir layout, error mapping) without
launching a process (the `ClaudeProcessClient` test pattern). A real compile is an **integration/device check**
gated on `lualatex` being installed — add it to the awaiting-checks note, don't fail the suite when TeX is
absent.

**On-device.** N/A for the model; **needs a local TeX install** (MacTeX / TeX Live with `lualatex`) — a new
optional external dependency, documented like the `claude` CLI (Milestone E updates `CLAUDE.md` → Build & run).

## Milestone C — `TexDocumentBuilder`: `ApplicationKit` → awesome-cv `.tex`

**What / why.** The mapping piece — the inverse of the repo's `tex2docx.py`. Turn the generated résumé
(`ApplicationKit.resumeMarkdown`) and cover letter (`ApplicationKit.coverLetter`) into `.tex` that drives the
awesome-cv classes: résumé sections as `\cvsection` + `\cventry`/`\cvproject` + `\cvitems`/`\item` +
`\cvskills`/`\cvskill`; the cover letter as the `\begin{cvletter}` … `\lettersection{…}` … `\end{cvletter}`
rhythm with `\makeletterclosing`; the role headline as `\position{…}`.

**Seam + files.**
- New `Infrastructure/Tex/TexDocumentBuilder.swift` — pure, domain-agnostic (Markdown `String` in, `.tex`
  `String` out — same shape as `DocumentExporter`), so it's fully unit-testable and never imports upward.
  Reuse `Infrastructure/Text/MarkdownBlockParser` (already the exporters' parser) to lift headings/bullets.
- LaTeX escaping is mandatory: escape `& % $ # _ { } ~ ^ \` in all interpolated text, render em-dashes as
  `---`, and reuse **only** the safe FontAwesome icons already in the classes (`\faGithubSquare`, `\faApple`,
  `\faAtom`) — never introduce new ones (undefined-icon = compile failure; see AGENT.md §8).

**Sub-tasks.**
- [ ] Résumé builder: parse `resumeMarkdown` → emit `\cvsection` + entry/project/skill macros against the
      `Resume.cls` vocabulary; wrap in the `Resume.tex` driver preamble (`\documentclass[6pt]{Class/Resume}`,
      geometry, `\pageHeader`/`\pageFooter`, `\makecvheader`).
- [ ] Cover-letter builder: emit the `cvletter` body from `coverLetter` (one `\lettersection` per heading),
      wrap in the `Cover Letter.tex` driver (`\documentclass[11pt,a4paper]{Class/CoverLetter}`,
      `\makeletterclosing`).
- [ ] A robust LaTeX-escaper (unit-tested against the special-char set); the `gapNote` is **not** emitted
      (advisory only — matches `ExportApplicationUseCase.assembleMarkdown` excluding it).
- [ ] **(open call — the big one) Fidelity of the Markdown→LaTeX mapping.** `ApplicationKit.resumeMarkdown`
      is a loosely-structured Markdown blob — it has no explicit org / location / date / role fields, so a
      pure parse can't perfectly reconstruct `\cventry{title}{org}{loc}{date}{…}`.
      - **C-parse (recommended for v0.5.1):** best-effort map from Markdown structure — `##` → `\cvsection`,
        `**bold**` lead lines → entry titles, bullet lists → `\cvitems`, a "Skills" section → `\cvskills`.
        Keeps this milestone **Infrastructure/export-only** (no generation-seam change) and fits the patch
        scope. Accept that entry metadata (dates/locations) is only as rich as the Markdown carries.
      - **C-structured (deferred, flagged):** add a `@Generable` structured résumé type (sections → entries
        with title/org/location/date/bullets, projects, skill buckets) that generation emits, rendered
        faithfully to `.tex`. Higher fidelity but touches `LLMProvider` / `Prompts` / `ApplicationKit` —
        bigger than a patch. Recommend as the **v0.5.1 fast-follow** if C-parse fidelity proves too coarse.
      Write the milestone for **C-parse**; note C-structured as the upgrade path.

**Tests.** Unit-test the builder: known `ApplicationKit` → expected `.tex` (macro shapes, escaping, no
`gapNote`, safe icons only). A golden-file compile (does the emitted `.tex` actually build under `lualatex`)
is the Milestone B/D integration check.

**On-device.** Yes — pure local string transform, no network, no model.

## Milestone D — Wire the awesome-cv PDF route through export + the Application sheet

**What / why.** Expose the new path to the user beside the existing exports. Because `DocumentExporter` is a
**synchronous** `nonisolated` port and `lualatex` is an **async** external process, the LaTeX route can't ride
the existing sync `export(markdown:as:template:)`; it needs its own async path.

**Seam + files.**
- **`ExportApplicationUseCase`** (Business) gains an **async** overload, e.g.
  `func latex(_ kit:) async throws -> Data`, that calls `TexDocumentBuilder` → `LaTeXCompiling` (both injected).
- **`Composition`** (`Composition.swift:119`) wires a `LaTeXProcessClient` + `TexDocumentBuilder` into the use
  case; `makeApplicationViewModel()` (`Composition.swift:213`) passes an availability flag.
- **`ApplicationViewModel`** (`ApplicationViewModel.swift`) gets an async `exportLaTeXPDF() async -> Data?`
  beside the sync `exportData(_:)` (`:113`), plus `canExportLaTeX` (kit present **and** `lualatex` available).
- **`ApplicationSheet`** (`ApplicationSheet.swift:57`) adds a menu item — **"PDF — Portfolio (LaTeX)"** — to
  the existing Export `Menu`, routing through `.fileExporter` (`:107`) like the other formats; disabled with a
  "requires a TeX install (`lualatex`)" note when unavailable (mirror the Adzuna "unavailable in this build"
  fail-fast + `ApplicationViewModel.describe(error)` messaging).
- **Bonus (recommended):** also offer **"LaTeX source (.tex)"** as an export — writes `TexDocumentBuilder`'s
  output straight to a `.tex` file. Free once C exists, and it hands Taylor the exact source for his existing
  `PortfolioBuddy` pipeline (the path-C handoff) even on machines without TeX.
- **One-page gate.** For the LaTeX route, use the **compiled PDF's real page count** (PDFKit
  `PDFDocument(data:).pageCount`) rather than the Core Text estimate, so `resumeExceedsOnePage`
  (`ApplicationViewModel.swift:123`) reflects what `lualatex` actually produced. (Open call: gate the résumé
  only, as today.)

**Sub-tasks.**
- [ ] `ExportFormat` / routing: add a LaTeX-PDF option (new `ExportFormat` case **or** a VM-level route —
      **recommended:** a VM-level async route so the sync `RoutingDocumentExporter` stays untouched; revisit
      if a new `ExportFormat` case reads cleaner in the menu).
- [ ] Async `ExportApplicationUseCase.latex(_:)` + `.texSource(_:)`; inject builder + compiler in `Composition`.
- [ ] `ApplicationViewModel`: `exportLaTeXPDF()` / `exportTexSource()` + `canExportLaTeX`; async `.fileExporter` glue.
- [ ] `ApplicationSheet` menu items + disabled/unavailable state + error surface.
- [ ] LaTeX-route page-count via PDFKit; reconcile `refreshLengthGate()`.

**Tests.** VM unit tests for `canExportLaTeX` gating (kit × availability) and the `.tex` source export
(deterministic, no process). The end-to-end compile→PDF is the integration/device check.

**On-device.** Yes for the app logic; the compile step needs the local TeX install (Milestone B).

## Milestone E — Availability surfacing, docs, and release hygiene

**What / why.** Make the new dependency legible and bring the docs to a shipped state.

**Sub-tasks.**
- [ ] **Availability in the UI** — surface whether `lualatex` is detected (Settings → About note, or beside
      the export menu). Reuse the Milestone B probe; **(open call)** where it lives — **recommended:** a
      one-line status in **Settings → About** ("LaTeX output: available / install MacTeX to enable"), since
      About already reports environment/version.
- [ ] **`CLAUDE.md`** — document `lualatex` as a **second optional external binary** (Build & run, beside the
      `claude` CLI + PATH note), add `Infrastructure/Tex/` to the layer map + Suggested file layout, and note
      the bundled `Resources/` assets. *(Land with the code, per the working process.)*
- [ ] **`SPEC.md`** — note the awesome-cv LaTeX PDF as a second export path under the core flow's "export"
      step (Core-flow §4 / Milestone Q reference).
- [ ] **`README.md`** — add the v0.5.1 one-paragraph summary under Version history when shipping; the
      **Next:** line already points here (updated at kickoff).
- [ ] **Release hygiene (done at kickoff):** `MARKETING_VERSION` → `0.5.1` (4 copies) ✅. Confirm the built
      app's About reads **0.5.1**.

**Tests.** N/A beyond the availability probe (covered in B). Docs pass is non-code.

**On-device.** N/A (docs + a local availability read).
