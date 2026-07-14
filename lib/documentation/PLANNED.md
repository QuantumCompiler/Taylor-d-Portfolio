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

> The three entries that once lived here — **richer job postings**, **select a profile at generation time**,
> and **regenerate result** — were scheduled into **v0.6.0 (richer grounding & job detail)** on 2026-07-13 and
> now live as Milestones A, B, C in `TODO.md` (and `ROADMAP.md`). The entries below are still unscheduled; add
> new specced-but-unscheduled work as it comes up in chat.

**Ordering note.** The entries below are in **intended build order** — do **User-editable API credentials** *first*.
It establishes the credential seam (Keychain store + per-provider credentials port) that the full-posting and
multi-source work both build on, so sequencing it first avoids re-plumbing those features later.

---

## User-editable API credentials — move keys from build-time secrets into in-app Settings

**Build this first.** It's the foundation the two entries below lean on: adding providers (multi-source) and
richer fetches all want a per-provider credential home, so standing this seam up first avoids reworking them.

**Why.** Adzuna's `app_id` / `app_key` are **baked in at build time** today: `Secrets.xcconfig` → Info.plist
(`AdzunaAppID` / `AdzunaAppKey`) → [`BundleAppConfig`](../src/Infrastructure/Config/BundleAppConfig.swift) →
[`AppConfig`](../src/Infrastructure/Config/AppConfig.swift). That means only a build with the secret file can
search — a downloaded/shared binary can't, and there's no way to fix it from inside the app. Re-integrate the
credentials as **user-entered settings** so anyone can paste their own keys. This also unblocks the multi-source
entry below (each added provider — JSearch/RapidAPI, etc. — needs a key field).

**The seam + files.** Deliberately *inverts* the "credentials are build-time, not settings" decision recorded in
`AppSettings.swift:14` and `AppConfig.swift` — update those doc comments as part of the change.
- **Storage — use the Keychain, not `UserDefaults`.** The [`KeyValueStore`](../src/Infrastructure/Store/KeyValueStore.swift)
  protocol comment already anticipates "UserDefaults, the keychain, or an in-memory stub" — add a
  **`KeychainStore: KeyValueStore`** (Infrastructure/Store) so secrets never sit in the `UserDefaults` plist. Keep
  the non-secret `adzunaCountry` where it is (plain `SettingsStore`); route only the id/key through the keychain.
- **A credentials port keyed by provider.** Generalise, don't special-case Adzuna. Introduce a small
  `JobSourceCredentialsStore` (Data/Settings) exposing get/set for a `(provider, field)` — so Adzuna's id/key and
  a future JSearch key share one mechanism. `AppConfig` stays as an **optional build-time seed / fallback** (dev
  builds keep working); the resolution order becomes **user-entered value → build-time `AppConfig` → absent**.
- **Live read at search time.** [`SettingsBackedJobSource`](../src/Presentation/App/Composition.swift:303) already
  reads country live on every `search`; change it to pull id/key from the credentials store first, falling back to
  `config.adzunaAppID/Key`. `hasAdzunaCredentials` (`AppConfig.swift:27`) generalises to "resolved from either
  source".
- **Settings UI.** [`SettingsViewModel`](../src/Presentation/Settings/ViewModel/SettingsViewModel.swift) exposes
  `adzunaConfigured` as a **read-only status** today (`:24`); replace it with editable `SecureField`-backed
  properties (id + key) that persist to the credentials store, and derive the "configured / search available"
  banner from whether they now resolve. Mirror the existing country-field save flow (`SettingsViewModel.swift:66`).

**Migration.** A build that still ships baked keys should keep working with no user action: on first launch, if the
keychain has no Adzuna entry but `AppConfig` does, that's simply the fallback path (no copy needed) — or, optionally,
seed the keychain once from `AppConfig` (mirrors `LegacyKeyMigration`'s one-time-copy pattern). Recommended: **no
seeding, pure fallback** — simpler, and it keeps the secret out of the keychain unless the user actually enters one.

**Open calls (recommended defaults).**
- **Keychain vs. `UserDefaults` for the keys.** *Recommended:* Keychain — they're secrets, and it's the reason the
  `KeyValueStore` comment names it. (If Keychain proves fiddly under the unsandboxed target, a clearly-labelled
  `UserDefaults` fallback is acceptable but should be noted in About.)
- **Drop the build-time path entirely, or keep it as fallback?** *Recommended:* keep `AppConfig`/`BundleAppConfig`
  as an optional fallback so existing dev builds and CI keep searching without re-entering keys; user entry simply
  takes precedence.
- **Validate keys on entry (test call) vs. save-and-see?** *Recommended:* save-and-see for the first cut (a bad key
  surfaces as the existing search-failure path); a "Test credentials" button is a nice later add.
- **One flat key list vs. a per-provider section.** *Recommended:* a per-provider Settings section, so this scales to
  the multi-source providers without a redesign.

**Scope.** Moderate — one new Infrastructure store (`KeychainStore`), a Data credentials port, a composition-root
rewire, and a Settings screen edit; plus flipping the two "secrets are build-time" doc comments. **Not part of
v0.6.0.** **Prerequisite for the multi-source entry below** — build it first so every provider added there has a
credential field and no re-plumbing is needed. Respects the layer rule (Infrastructure store ← Data port ←
Presentation field, wired in the composition root).

> **Note (safety):** building the *field* where the user types their own key is fine; the agent must never enter or
> paste real API keys itself — the user fills these in.

---

## Full job-posting text — capture the whole posting, not Adzuna's truncated snippet

**Why.** A search result today shows only a **truncated snippet** of the job description, and that same thin
text is all the tailored résumé/cover-letter generation ever sees. Real example of what we *get*:

> …working across the stack to ship features, improve reliability, and support a fast-moving product and
> engineering team … When that data flows correctly, operators can ac**…**

That trailing `…` is the tell: **Adzuna truncates `description` at the API level** (roughly the first ~500
characters). The full text is **not in the API response at all**, so no amount of decoding extra fields
(v0.6.0 Milestone A-A) recovers it — Milestone A's `contract_type` / `contract_time` / `category` / `created`
decode gets job-type + posted-date, but the **body of the posting stays a snippet**. What we *want* is the
entire posting — the level of detail you'd see on the source board:

> **Who Are We? … What Will I Do in This Position? … What Are We Looking For?** (6+ years…, modern back-end
> languages…) **Our Technology Stack** (React, TypeScript, MobX; C# .Net 10, EFCore; PostgreSQL, Redis,
> ClickHouse; …) **Benefits** (401k matching, insurance, PTO…) **Pay** ($140k–$190k) **Experience**
> (C#: 1yr, React: 1yr) **Work Location** (Hybrid, North Salt Lake, UT)

That richness matters **twice**: to *read* in `JobDetailView`, and — the real payoff — as **grounding for
generation**, so tailoring maps the candidate's real experience against the posting's actual requirements /
stack / responsibilities instead of a 500-char teaser.

**The core constraint (read before designing).** The full body has to come from **somewhere other than the
Adzuna `/search` response**. Two routes, in ascending reliability:
1. **Full-page fetch behind the redirect URL.** `JobListing.url` is Adzuna's `redirect_url`; the posting seam
   already fetches + strips a posting page — `JobPostingSource.readableText(from:)` / `fetchPosting(from:)`
   ([`Data/Jobs/LinkJobPostingSource.swift`](../src/Data/Jobs/LinkJobPostingSource.swift)) — the same code the
   "generate from a link" path uses. Point it at `JobListing.url` to recover the full text. **Best-effort:**
   JS-gated / paywalled / blocking boards (LinkedIn, some ATSes) throw `.unreadable`, and we fall back to the
   snippet — the failure mode that path already handles.
2. **A source that returns the full text natively.** JSearch (see the **Multi-source** entry below) returns the
   full description **and** structured `employment_type` / `is_remote` / qualifications / responsibilities /
   benefits directly — no fragile page-fetch, no LLM parse. This is the *reliable* way to get the example
   above; the trade-off is a new provider + key (that entry's scope).

**Relationship to already-planned work (important — this sharpens, it doesn't duplicate).**
- **v0.6.0 Milestone A (richer job postings)** as written leans on decoding Adzuna fields + an **LLM pass** that
  *structures* the posting into `PostingDetails`. This entry adds the piece A under-specifies: **capturing the
  full raw description text itself** as a first-class value (the input the LLM structuring needs, and worth
  showing verbatim on its own). If Milestone A is in flight, fold this in as "A also captures + persists +
  displays the full description, sourced via the page-fetch," rather than treating structure as the only output.
- **Multi-source / JSearch (below)** is the *reliable source* of this same full text. If both are scheduled
  together, prefer JSearch's native full text/structure and treat the Adzuna page-fetch as the fallback.

**Seam + files.**
- **Data model.** Give `JobListing` ([`Data/Models/JobListing.swift`](../src/Data/Models/JobListing.swift)) a
  first-class home for the full body — either replace `description` with the fetched full text once available,
  or add a `fullDescription: String?` alongside the snippet (open call). Plain `Codable`, back-compatible
  (optional / decode-with-defaults, like `SavedProfile.init(from:)`).
- **Fetch.** Reuse `JobPostingSource.readableText(from:)` against `JobListing.url`; snippet fallback on
  `.unreadable`. A `JobSource`-agnostic step, so it composes with any provider.
- **Persistence.** Thread the full text through `SavedJobsRepository`
  ([`Data/Persistence/SavedJobsRepository.swift`](../src/Data/Persistence/SavedJobsRepository.swift)) /
  `PersistentRecordStore` (decode-with-defaults so existing saved jobs still load).
- **Generation grounding — the payoff.** Feed the full posting into `buildTargetBrief` / `generateApplication`
  + `Prompts` so tailoring works from the whole posting, not the snippet (bound for the on-device context
  window, as grounding already is).
- **Presentation.** `Results/View/JobDetailView` shows the full description (and, with Milestone A, the
  collapsible structured sections); the snippet stays fine for the compact `RankedRow`.

**Open calls (recommended defaults).**
- **When to fetch the full page.** Every result (an HTTP fetch per result — heavy on a big search) vs. **on
  save / on detail-open** vs. only for **saved** jobs. *Recommended:* **on save / on detail-open** — matches
  Milestone A's enrichment-timing recommendation, so one fetch serves both the full text and the structuring.
- **Replace `description` vs. add `fullDescription`.** *Recommended:* add `fullDescription` and keep the
  snippet — the snippet is a fine list preview and the fallback when a page can't be fetched.
- **Store the full text vs. re-fetch on demand.** *Recommended:* store it (survives relaunch, grounds
  generation offline); re-fetch only on an explicit refresh (composes with the **Regenerate result** milestone).

**Guardrail.** Capturing the full posting is **verbatim** — we surface what the posting actually says. Any LLM
structuring on top (Milestone A) **organizes**, never invents requirements or company facts (same discipline as
`ExtractedPosting`, which returns empty when a page has no real posting). It enriches the *posting*, not the
*candidate*.

**On-device.** The page-fetch needs **network** (same as the existing link path); storage + display are local.
LLM structuring (if paired with Milestone A) is `.extraction` work — on-device-friendly, Claude when chosen.
Bound the posting text before it hits the model.

**Scope.** Small-to-moderate on its own (Data field + reuse the existing fetch seam + persistence + a
`JobDetailView`/`Prompts` touch), but it's really the **requirement behind v0.6.0 Milestone A** and is best
built *with* it (or with JSearch). Not a standalone version — schedule it by folding it into Milestone A's build
(or the multi-source entry), not as a separate release.

---

## Multi-source job search — aggregate more providers behind `JobSource`

**Why.** Searches sometimes return too few results. `SearchAndRankUseCase` already pages toward a
desired-result-count goal (round-robin pages, 50/page, `maxPagesPerTitle` cap — `SearchAndRankUseCase.swift:113`),
so a shortfall means we've hit **Adzuna's index ceiling for that query**, not a paging bug. The fix is **more
sources**, not more tuning. The [`JobSource`](../src/Data/Jobs/JobSource.swift) protocol
(`search(_ query: JobQuery) async throws -> [JobListing]`) is already the swappable seam for exactly this — CLAUDE.md
even names "Adzuna, JSearch, USAJOBS…" as the intended set. Only Adzuna conforms today.

**The seam + files.**
- New conformers in `Data/Jobs/`, one per provider, each keeping its API-specific request/response types
  **private** to the struct (the Adzuna pattern — `AdzunaJobSource.swift`): translate `JobQuery` → the
  provider's API, map the response → `[JobListing]`, leak nothing past the protocol. Each needs its own
  query translation (Adzuna maps `PositionType.rawValue` straight to its boolean flag names —
  `AdzunaJobSource.swift:65`; other APIs express employment type / remote differently).
- A new **`CompositeJobSource: JobSource`** (Data/Jobs) that holds `[any JobSource]`, runs them with bounded
  concurrency (mirror the `withTaskGroup` window in `SearchAndRankUseCase.searchAll`), and merges the results —
  so the fan-out over *providers* sits below the seam and `SearchAndRankUseCase`'s fan-out over *titles* stays
  unchanged.
- Wire it in the composition root at **`SettingsBackedJobSource`** (`Composition.swift:303`): assemble the
  configured providers and wrap them in `CompositeJobSource` instead of returning a bare `AdzunaJobSource`.
  Per-provider credentials follow the same build-time `AppConfig` path as the Adzuna keys
  (`BundleAppConfig` ← `lib/secrets/Secrets.xcconfig`); a provider with no key is simply omitted from the
  composite (fail-soft, like the current `hasAdzunaCredentials` guard).

**Providers to add (ranked by payoff).**
- **JSearch (via RapidAPI)** — *the primary add.* A Google-for-Jobs aggregator (pulls LinkedIn, Indeed,
  Glassdoor, ZipRecruiter et al. into one call), so it's the single biggest coverage gain. It also returns
  rich structured fields (`employment_type`, `is_remote`, qualifications, responsibilities, benefits) that
  **feed v0.6.0 Milestone A (richer job postings)** directly — the enrichment can read them from the source
  response instead of an LLM pass where present. (Don't chase Indeed/LinkedIn *directly* — Indeed's Publisher
  API is effectively closed to indie use and LinkedIn needs a partner agreement; JSearch reaches both legally.)
- **The Muse** — free, clean structured data, strong company info + explicit level/remote flags. Tech/startup
  leaning; small but high quality.
- **Remotive / Remote OK / Arbeitnow** — free, mostly keyless remote-job feeds; cheap breadth for distributed
  roles. Remote-only, so best as a supplement, not a primary.
- *(Deferred: USAJOBS — free & authoritative, but only if US federal roles enter scope; Reed — deep UK
  coverage, only if UK is a target market.)*

**The one real design wrinkle — cross-source de-dup.** Today the merge key is `seen.insert(job.id)`
(`SearchAndRankUseCase.swift:98`), but `JobListing.id` is **source-specific** — the same posting from Adzuna and
JSearch has different ids, so a naïve union double-lists it. Multi-source needs a **normalized fingerprint**
(e.g. lowercased `title + company + location`, or host+path of the redirect URL) used for cross-source dedup,
while keeping the source id for persistence. Decide where it lives: a `JobListing.fingerprint` computed property
consumed by `CompositeJobSource` (favoured — keeps `SearchAndRankUseCase` untouched) vs. changing the use case's
`seen` key. This is the only non-trivial piece; the rest is additive.

**Open calls (recommended defaults).**
- **Which providers ship first?** *Recommended:* JSearch only in the first cut (biggest gain, advances Milestone
  A), with `CompositeJobSource` built to hold N so The Muse / remote feeds are a later drop-in.
- **Per-provider result balancing?** *Recommended:* none initially — merge all, dedup, let `JobRanker` sort by
  fit. Revisit only if one provider floods the set.
- **Surface which source each result came from?** *Recommended:* capture it (optional `JobListing.source` label)
  and defer showing it in `JobDetailView` to the richer-detail work — cheap to store now, easy to render later.
- **Rate-limit / cost guard for paid tiers (JSearch/RapidAPI is metered).** *Recommended:* keep the existing
  bounded-concurrency window and a conservative per-run page cap; note the free-tier ceiling in About alongside
  the Adzuna/LaTeX availability lines.

**Scope.** Feature-sized (`.0`) — new seam type, ≥1 new provider gateway + credentials, the dedup fingerprint, and
composition wiring. **Not part of v0.6.0.** Strongly composes with **v0.6.0 Milestone A (richer job postings)**:
JSearch's structured response is a *source* of the very fields that milestone surfaces, so if both land in one
version, build A's `JobListing` fields first and have JSearch populate them. Respects the layer rule (all Data +
one composition-root line; no upward imports). **Depends on** the credentials entry above — new providers need
somewhere for the user to enter their keys.
