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

> These entries are **not** v0.5.1 work. v0.5.1's milestones live in `TODO.md`. Items here are candidates for a
> future version (likely a feature `.0`, given their scope).

---

## Richer job postings — capture & surface full posting detail

**What / why.** A search result currently keeps very little about a job: `JobListing`
(`Data/Models/JobListing.swift`) is only `id, title, company, location, description, url, salary`, plus the
`JobMatch` (score / reason / matched / missing skills). The **description** is the sole free-text field, and
from Adzuna it's frequently a **truncated snippet**, not the full posting. We want to keep **much more** of the
posting so ranking and — especially — résumé/cover-letter tailoring have real material to work from:

- **Job type** — full-time / part-time / contract / permanent (relates to the existing `PositionType`, which
  today is only a *search filter*, not stored per result).
- **Work type** — on-site / remote / hybrid.
- **Structured posting sections** — qualifications / requirements, "about the role" / responsibilities, "about
  the company", nice-to-haves, benefits, and posted date.

Keeping this makes the two-stage generation (`buildTargetBrief` → `generateApplication`) far better grounded —
more true signal to map the candidate's real experience against, and a fuller `TargetBrief`.

**The core constraint (read before designing).** These fields come from **two different places**, and neither
is free today:
1. **Adzuna structured fields we don't yet decode.** Adzuna *does* return `contract_type`
   (permanent/contract) and `contract_time` (full_time/part_time), plus `category` and `created` — but
   `AdzunaJobSource.Job` (`Data/Jobs/AdzunaJobSource.swift:80`) decodes none of them. **Job type** and
   **posted date** are a cheap win: just decode the fields already in the response.
2. **Everything else is buried in free text** — **work type** (remote/hybrid), **qualifications**, **about the
   role/company** — Adzuna gives no structured field for these, and its `description` is often a **snippet**.
   Getting them reliably needs either an **LLM extraction pass** over the posting text or the **full posting
   page**, not the snippet.

**Seam + files.**
- **Data model.** Extend the domain with the richer fields. Two shapes to weigh (open call):
  - Add optional fields to `JobListing` (`jobType`, `workType`, `postedDate`, `category`) that Adzuna can fill
    directly — plain `Codable`, back-compatible (all optional, decode-with-defaults like `SavedProfile` does).
  - Add a separate **`@Generable`** `PostingDetails` (workType, qualifications, aboutRole, aboutCompany,
    responsibilities, benefits) for the **LLM-extracted** structure, attached to a listing by `id`. Keeping the
    LLM-produced structure `@Generable` (like `ExtractedPosting`) while `JobListing` stays plain-`Codable`
    matches the existing "API data isn't `Generable`" rule (`JobListing` doc comment).
  - A `WorkType` enum (`onSite` / `remote` / `hybrid`) + reuse/relate `PositionType` for job type.
- **Adzuna decode (cheap win).** `AdzunaJobSource.Job`: decode `contract_type`, `contract_time`, `category`,
  `created`; map into the new `JobListing` fields. Source-agnostic mapping stays in the source.
- **LLM enrichment (the richer win).** Extend the existing extraction seam rather than invent a new one:
  `ExtractedPosting` (`Data/Models/ExtractedPosting.swift`) already LLM-structures a posting for the URL/paste
  path — grow it (or add a sibling `enrichPosting`) with the new fields + a `Prompts` entry, routed through the
  `.extraction` `LLMTask`. **Open call:** enrich **every** Adzuna result (costs an LLM call per result — heavy
  on a big search) vs. **on demand** when the user opens a result's detail (lazy, cheap) vs. only for **saved**
  jobs (enrich at save time, since only saved jobs get tailored). *Recommended:* **enrich on save / on detail
  open**, not for the whole ranked set.
- **Full text vs. snippet (open call).** To fill qualifications/about-company well, prefer the **full posting
  page** over Adzuna's snippet: reuse `LinkJobPostingSource` / `JobPostingSource` (already fetches + strips a
  posting URL) against `JobListing.url` before the enrichment pass. Falls back to the snippet when the page
  can't be fetched (JS-gated/paywalled — the same failure mode that path already handles).
- **Persistence.** The new fields must survive relaunch — thread through `SavedJobsRepository` /
  `PersistentRecordStore` mapping (decode-with-defaults so existing saved jobs still load).
- **Generation grounding.** Feed the richer fields into `buildTargetBrief` / `generateApplication` +
  `Prompts` so tailoring uses qualifications / about-the-company / work-type signal. This is the payoff.
- **Presentation.** `Results/View/JobDetailView` shows the new fields verbosely (job type + work type badges,
  collapsible Qualifications / About the role / About the company sections); a compact `RankedRow` may surface
  job-type / work-type chips.

**Rough sub-parts (letter them when scheduled into a version).**
- Decode Adzuna `contract_type` / `contract_time` / `category` / `created` → `JobListing` job type + posted
  date (no LLM). *(Smallest slice; ships value on its own.)*
- `WorkType` enum + `PostingDetails` (`@Generable`) + the `enrichPosting` LLM step + `Prompts`.
- Full-page fetch (reuse `LinkJobPostingSource`) feeding enrichment; snippet fallback.
- Persist the enriched fields (repository + record-store mapping, back-compatible).
- Thread enriched fields into `TargetBrief` / generation `Prompts`.
- `JobDetailView` verbose layout + row chips.

**Guardrail.** Enrichment **extracts and organizes** what the posting actually says — it must not invent
requirements or company facts (same "never fabricate" discipline as `ExtractedPosting`, which returns empty
when a page has no real posting). It structures the posting; it doesn't embellish the *candidate*.

**On-device.** The Adzuna-decode slice is pure/local (no model). The enrichment pass is LLM work routed
through the `.extraction` task (on-device-friendly; Claude when chosen); the optional full-page fetch needs
network (same as the existing URL path). Mind the on-device context window — bound the posting text before
extraction, as elsewhere.

**Scope note.** This is **feature-sized** (Data + Jobs + LLM + Business + Presentation + persistence) — a
future `.0`, not a patch. Not part of v0.5.1.

---

## Select a profile at generation time and ground on its source documents

**What / why.** When the user generates an application, curation should be grounded in a **chosen profile's
actual source documents** (the real résumé/portfolio text + optional cover letter), not just the distilled
`CandidateProfile` summary — and the user should be able to **pick which profile** to generate against right
on the generation screen. Comparing the full source documents against everything in the job result yields a
much better-tailored résumé + cover letter.

**What already exists (extend this, don't reinvent).** The grounding mechanism is already built (ROADMAP
Milestone T):
- `PortfolioGrounding` (`Data/Models/PortfolioGrounding.swift`) carries `resumeText` (**factual grounding** —
  the model reorders/rephrases it but adds no facts absent from it) + optional `coverLetterText` (a **voice /
  tone exemplar**). It's injected into `generateApplication(…grounding:)` and bounded in `Prompts`.
- `SavedProfile` already stores the source documents: `sourceText` / `readableText` and
  `coverLetterReadableText` (the LLM-tidied forms).
- `PortfolioViewModel.grounding` already builds a `PortfolioGrounding` from those fields
  (`PortfolioViewModel.swift:94`).

**The actual gap.** Grounding today is tied to the **single currently-loaded/default profile**: it flows
`PortfolioViewModel.grounding` → `AppSession.grounding` (`App/AppSession.swift:34`) → `ApplicationWindow`
(`App/ApplicationWindow.swift:36`) → `JobDetailView.grounding` (`Results/View/JobDetailView.swift:22`) →
`ApplicationSheet`. There is **no profile picker on the generation screen** and no per-application choice — you
generate against whatever profile happens to be loaded in the Portfolio tab, and if grounding wasn't set up
you silently fall back to profile-summary-only. This feature adds **explicit per-generation profile
selection** and guarantees the chosen profile's **source documents** are what's grounded.

**Seam + files.**
- **`SavedProfile` → grounding mapper (Data).** Lift the `PortfolioViewModel.grounding` logic into a reusable
  `SavedProfile.grounding` (or a small mapper) so **any** saved profile yields its `PortfolioGrounding`
  (`readableText` ?? `sourceText` for résumé; `coverLetterReadableText` for the exemplar). Each `SavedProfile`
  also carries its `CandidateProfile`, so a selection supplies **both** `profile:` and `grounding:`.
- **Profile picker (Presentation).** Add a saved-profile selector to the generation screen — the
  `ApplicationSheet` "Generation options" panel and/or `JobDetailView` — populated via the existing
  `LoadProfilesUseCase` (already composed; injected into `PortfolioViewModel` today), defaulting to the current
  default/loaded profile (`DefaultProfileStore`). Selecting a profile drives what generation grounds against.
- **Wiring (Presentation).** Thread the chosen profile through generation: `ApplicationViewModel.generate(...)`
  (`Application/ViewModel/ApplicationViewModel.swift:169`) takes the selected profile + its grounding rather
  than only the ambient `AppSession.profile`/`grounding`. Inject `LoadProfilesUseCase` into
  `ApplicationViewModel` via `Composition` (`makeApplicationViewModel`), and have the picker load the saved
  profiles. Keep `AppSession`'s current profile as the **default** selection so existing behaviour is
  unchanged when the user doesn't touch the picker.
- **Prompt depth (Data/LLM).** The curation prompt already receives `resumeText`; make sure it **compares the
  source documents against the full job result** (description — and the richer posting fields if the "Richer
  job postings" entry lands), and that both résumé + cover-letter source are bounded for the on-device context
  window (`Prompts` already bounds grounding — verify the limits are generous enough to carry a real résumé).

**Open calls (recommendations to settle when scheduled).**
- **Per-application persistence.** Should the chosen profile be **remembered per job** (persist the selection
  with the saved job/`ApplicationKit`) or **session-only**, defaulting to the default profile each open?
  *Recommended:* session-only first (default = the default profile), with per-job persistence a later refinement.
- **Where the picker lives.** In the `ApplicationSheet` options panel (nearest the Generate button) vs. on
  `JobDetailView` before opening the app view. *Recommended:* the options panel, beside fidelity/aspects, so
  it's part of the same "how to generate" controls (Milestone D family) and applies on Generate/Regenerate.
- **Unsaved just-built profile.** Only **saved** profiles have stored source documents. *Recommended:* the
  picker lists saved profiles; a just-built unsaved profile is available only after Save (consistent with
  v0.4.1 Milestone F's Source Documents rule).

**Guardrail.** Grounding on the source documents strengthens factual fidelity — it does **not** loosen the
never-fabricate rule. The résumé source grounds facts; the cover-letter source stays a voice/tone exemplar
only (no facts/metrics/dates imported), exactly as `PortfolioGrounding` already specifies.

**On-device.** Yes — profile load + grounding are local; generation runs on the chosen engine. Mind the
context window: bound the injected source-document text (as `Prompts` already does for grounding).

**Scope note.** Moderate — mostly **Presentation** (picker + wiring) plus a small **Data** mapper, reusing the
existing `PortfolioGrounding` seam; no new generation seam. Sized like a milestone or two; could ride a future
`.0` or a patch. Not part of v0.5.1. Composes with the "Richer job postings" entry above (better result data =
more for the source documents to be tailored against).
