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

> **One entry below**, targeting the **next feature release** (number assigned at its kickoff). Prior specced
> entries were all scheduled into **v0.6.0 (richer grounding, job detail & sources)** and now live in `TODO.md` /
> `ROADMAP.md`:
> - **richer job postings**, **select a profile at generation time**, **regenerate result** → Milestones **A–C**.
> - **user-editable API credentials**, **full job-posting text**, **multi-source job search** → Milestones **D–F**.
> - **per-provider credential-setup help**, **provider selector in Search** → Milestones **G–H** (scheduled
>   2026-07-15; extend D and F respectively).
>
> Add new specced-but-unscheduled work below as it comes up in chat — each with its `Target:` release, in
> ascending target-version order.

---

## Supporting profile documents — bake extra career docs into a profile for higher-fidelity search & generation

**Target:** next feature release (number assigned at that version's kickoff — not pre-named). Feature-sized (`.0`).

**Why.** A `SavedProfile` carries only **two** documents today: the **résumé source** (distilled into the
`CandidateProfile` *and* used as factual grounding) and an **optional cover letter** (a voice/tone exemplar that is
**never** distilled). The user wants to attach **additional file(s)** — e.g. a *complete career portfolio* listing
every role, skill, and project — that are **baked into the profile** so both **ranking/search** and **application
generation** draw on far more real signal. Unlike the cover letter, these are **factual** grounding (their content
may be used), like the résumé source.

**The seam + files.** This generalises the existing résumé/cover-letter document handling — the mechanics already
exist; the change is going from fixed slots to a collection.
- **Data model.** Add `supportingDocuments: [SupportingDocument]` to
  [`SavedProfile`](../src/Data/Models/SavedProfile.swift) — `SupportingDocument = { id, fileName?, rawText,
  readableText }`, mirroring the résumé/cover-letter triples. `Codable`; extend the custom `init(from:)`
  (`SavedProfile.swift:74`) to **decode-with-defaults** (empty array when absent) so existing profiles still load —
  the file already does exactly this for its current doc fields.
- **Import + tidy (reuse).** Per file, reuse [`ImportPortfolioUseCase`](../src/Business/UseCases/ImportPortfolioUseCase.swift)
  (file → text via `DocumentTextExtractor`) and [`TidyDocumentUseCase`](../src/Business/UseCases/TidyDocumentUseCase.swift)
  (raw → readable) — exactly how `PortfolioViewModel.importDocument` / `importCoverLetter`
  (`PortfolioViewModel.swift:117,132`) already work. Add `importSupportingDocument(from:)` (append) + a remove, and
  tidy + store each in `build()` (`PortfolioViewModel.swift:157`).
- **How they raise fidelity — two channels:**
  1. **Generation grounding (definitely).** Add `supportingText: String?` to
     [`PortfolioGrounding`](../src/Data/Models/PortfolioGrounding.swift) — the concatenated, **bounded** readable
     texts as *additional factual grounding*. Include it in `SavedProfile.grounding` (`SavedProfile.swift:99`) +
     `PortfolioViewModel.grounding` (`:94`), and bound it in `Prompts`. It then flows through the **existing
     Milestone B threading** into `buildTargetBrief` / `generateApplication` — **no new generation seam**.
  2. **Search / ranking fidelity (open call — the real design fork).** Ranking is
     `JobRanker.rank(jobs:against:profile:)` against the **distilled** `CandidateProfile`, **batched** over many
     jobs — injecting a big portfolio into every rank call is expensive. Route **(a):** distill the supporting docs
     into a **richer `CandidateProfile`** at build time (`buildProfile` over résumé + supporting text → more
     coreSkills / domains / experiences), so ranking benefits with **no per-rank cost**. Route **(b):** pass
     supporting grounding into ranking directly (costly). *Recommended:* **(a)** for ranking + channel **1** for
     generation.
- **UI.** The Portfolio tab ([`PortfolioView`](../src/Presentation/Portfolio/View/PortfolioView.swift)) gains a
  **multi-file supporting-docs slot** (add/remove list) beside the source + cover-letter slots, browsable like the
  existing source documents (v0.4.1 Milestone F made those viewable).

**Scale — the RAG angle (call out honestly).** A "complete portfolio" can be **large**: truncating loses detail,
and stuffing it all into every prompt burns the limited on-device context window. The scalable answer is the
roadmap **`Retriever` / `EmbeddingClient` RAG seam** — embed the supporting docs, retrieve only the chunks relevant
to a given job/generation. *Recommended:* ship a **bounded first cut** (distill + truncated grounding) and treat
**RAG as the follow-on** that makes it scale; this feature is a natural driver for that Backlog item.

**Open calls (recommended defaults).**
- **Distill into the profile *and* ground, or grounding-only?** *Recommended:* both (distill for ranking, ground
  raw for generation). If scope must shrink, **grounding-only first** (no profile-build change).
- **Bound/truncate vs. RAG for large docs?** *Recommended:* bound first cut; RAG follow-on.
- **A per-doc "kind" tag (portfolio / project list / transcript…)?** *Recommended:* optional freeform label now,
  structured taxonomy later — cheap to store, useful for prompt framing.
- **Re-distill on every upload or once at build/save?** *Recommended:* at **build/save** (matches today's
  `build()`), not per upload.

**Guardrail.** Supporting docs are **factual grounding about the candidate** (unlike the cover-letter voice
exemplar), so the model may use their facts — but **never-fabricate** still binds: nothing beyond these docs + the
profile. Grounded-by-default holds.

**On-device.** Import + tidy are `.profile`-task LLM work (on-device-friendly; Claude when chosen) — **bound all
injected text**. The RAG follow-on needs the `EmbeddingClient`.

**Scope.** Feature-sized (`.0`) — a new `SavedProfile` collection + `SupportingDocument`, a `PortfolioGrounding`
field, Portfolio UI, and (route a) a profile-build change. Composes with **v0.6.0 Milestone B** (grounding
threading, already shipped) and the **ROADMAP Backlog RAG** seam. Respects the layer rule (Data model ← Business
build/tidy ← Presentation upload).
