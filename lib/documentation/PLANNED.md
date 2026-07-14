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

> **Prior entries scheduled.** These were moved into **v0.6.0 (richer grounding, job detail & sources)** and now
> live in `TODO.md` / `ROADMAP.md`:
> - **richer job postings**, **select a profile at generation time**, **regenerate result** → Milestones **A–C**
>   (scheduled 2026-07-13; A–C now complete).
> - **user-editable API credentials**, **full job-posting text**, **multi-source job search** → Milestones
>   **D–F** (scheduled 2026-07-13; build order D → E → F).
>
> The entries below are unscheduled but **target v0.6.0** (see each `Target:` line); add new specced work as it
> comes up in chat, each with its `Target:` release.

---

## Per-provider credential setup help — a link / instructions for getting each search engine's API key

**Target:** v0.6.0 — fold into **Milestone D** (the credential UI) if it hasn't shipped yet, else a small
standalone follow-up in the same version (see **Scope**).

> **Partially started (Milestone D-D shipped).** The Adzuna field already carries a **"How to get an Adzuna API
> key"** `Link`. What remains: generalise it to a **per-provider `setupURL` / `setupSteps` descriptor** (one
> source of truth driving both the field and its help) and add links/steps for the providers **Milestone F**
> introduces (JSearch/RapidAPI, The Muse, …).

**Why.** Once API keys are **user-entered** (v0.6.0 Milestone D) instead of baked in, a user faces an empty
`SecureField` with no idea *where* to get an Adzuna app id/key, a RapidAPI JSearch key, a The Muse token, etc.
Each field should carry a **"How to get a key" hyperlink** to that provider's signup/API-docs page — and, ideally,
a couple of inline setup steps so it still helps if the user is offline or the link rots.

**The seam + files.**
- **Where it renders.** The `adzunaSection` of [`SettingsView`](../src/Presentation/Settings/View/SettingsView.swift:54)
  — which Milestone D turns into editable credential fields, and Milestone F fans out into one sub-section per
  provider. Add, next to each provider's field(s), a SwiftUI **`Link("How to get a key", destination: …)`** (opens
  the provider's page in the default browser) plus an optional **help disclosure** (`DisclosureGroup` / small
  popover) holding 2–3 `Text` setup steps. Reuse the existing `.clickableCursor()` affordance already used on the
  Settings controls.
- **Where the URL + steps live — co-locate with the provider identity.** Don't scatter string literals in the
  view. These belong on the **per-provider descriptor** that Milestones D/F introduce (the credentials port is
  keyed by provider — `JobSourceCredentialsStore`; multi-source gives each provider an identity/enum). Add
  `setupURL: URL` + a short `setupSteps: [String]` (or a `credentialHelp` value) to that descriptor, so the
  provider list drives both the credential fields *and* their help — one source of truth, and a new provider
  automatically gets its help link. This keeps it in the **Data** layer (static provider metadata), read by the
  Presentation `Link`.
- **The URLs are static, known developer pages** (Adzuna developer portal, RapidAPI's JSearch listing, The Muse
  API docs) — hardcoded provider metadata, *not* anything fetched or derived from a job posting, so there's no
  untrusted-link concern. Verify each URL is current when the entry is scheduled.

**Open calls (recommended defaults).**
- **Hyperlink only, inline steps only, or both?** *Recommended:* **both** — a one-line `Link` for the happy path,
  plus a collapsed `DisclosureGroup` of terse steps as the offline/rot-proof fallback. If time is tight, ship the
  `Link` alone first (the steps are additive).
- **Per-field help vs. one "Set up providers" help screen.** *Recommended:* **per-provider, inline** in each
  Settings sub-section — closest to the empty field, no navigation. A dedicated help screen is overkill for a
  handful of providers.
- **Copy tone.** *Recommended:* neutral, factual ("Create a free Adzuna developer account, then copy your App ID
  and App Key here") — no marketing, and never pre-fill or transmit anything.

**Scope.** Small — Presentation `Link`/disclosure + a `setupURL`/`setupSteps` field on the provider descriptor.
Presentation-only apart from that Data metadata; no new seam. **Not part of v0.6.0 as its own milestone**, but it's
a natural **fold-in to Milestone D** (credential UI): if D hasn't shipped yet (check `TODO.md`), build the help
link *with* D's fields rather than as a separate pass; if D has already shipped, this is a small standalone
follow-up. Composes with Milestone F (each added provider brings its own `setupURL`, so its help link is free).

> **Note (safety):** the app links out to each provider's official signup page; the agent must never create
> accounts or enter/paste API keys — the user does that on the provider's site and pastes the key into the field.

---

## Choose which search providers to query — a provider selector in the Search view

**Target:** v0.6.0 — extends **Milestone F** (multi-source). Build it *with* F, or as the F-milestone's final
sub-part, so the selection UI lands together with the providers it selects.

**Why.** Milestone F aggregates **every** configured provider on every search. The user should instead be able to
**pick which API(s) to search** from the Search view — and the picker must list **all available providers, growing
automatically as new ones are added** (no hardcoded provider list to maintain). "Available" = a provider that's
**registered** *and* has **resolved credentials** (Milestone D); registered-but-unconfigured providers show
disabled, with a jump to Settings to add a key.

**The core requirement — one data-driven provider registry.** The single most important design point: the picker,
the Settings credential fields (Milestone D), and the Settings help links (the credential-setup-help entry above)
must all be driven by **one provider registry** — the per-provider descriptor D/F already introduce (identity/enum
+ credential fields + `setupURL`). Adding a new `JobSource` conformer + its descriptor entry should make it appear
in **all three** with no further wiring. Do **not** enumerate providers by hand in the view.

**The seam + files.**
- **Registry.** Formalise the provider descriptor as the enumerable source of truth (Data) — `id`, `displayName`,
  credential field spec, `setupURL`, and a factory that builds the provider's `JobSource` from resolved
  credentials. `CompositeJobSource` (Milestone F) is built from this list; the picker reads the same list.
- **Selection state + request.** Add the chosen provider ids to
  [`JobSearchRequest`](../src/Data/Models/JobSearchRequest.swift) (a `sources: [String]?` / `Set` — `Codable`, so
  a `SavedSearch` remembers the choice; decode-with-defaults ⇒ nil means "all available", keeping old saved
  searches valid). Build it in `SearchViewModel.buildRequest()`
  ([`SearchViewModel.swift:433`](../src/Presentation/Search/ViewModel/SearchViewModel.swift:433)) from new
  selection state on the view model.
- **Honour the selection.** [`SearchAndRankUseCase`](../src/Business/UseCases/SearchAndRankUseCase.swift) filters
  the composite's children to the request's selected providers before fanning out (or the composite takes the
  selection). Empty/nil selection ⇒ all available.
- **UI.** A selector in [`SearchView`](../src/Presentation/Search/View/SearchView.swift) listing every registered
  provider, each row enabled only when configured (disabled + "Add a key in Settings" otherwise — composes with
  the credential-setup-help entry). Reuse the `.clickableCursor()` affordance.
- **Availability gate.** Today `adzunaConfigured` gates search (`SearchViewModel.swift:290,296`,
  `search()` at `:419`). Generalise to **"at least one *selected* provider is configured"**; the unavailable
  banner points at Settings.

**Open calls (recommended defaults).**
- **Multi-select or single-select?** *Recommended:* **multi-select** (toggles/checkboxes) with **"All available"**
  as the default — multi-source is the whole point of F, and single-select is just the one-selected case of it.
- **Persist the last selection, or reset to "all" each search?** *Recommended:* persist (remember the user's last
  choice, and capture it in `SavedSearch` via the `JobSearchRequest` field); a saved search re-runs against the
  providers it was saved with.
- **What if a selected provider loses its key?** *Recommended:* skip it with a soft note (reuse
  `Output.failedTitles`-style messaging), never a hard failure — mirrors F's "one source failing is a soft note".
- **Show per-provider result counts / source labels?** *Recommended:* defer to the `JobListing.source` label
  already flagged as an open call in the multi-source entry; not required for the selector itself.

**Scope.** Moderate — a formalised provider registry (Data), a `JobSearchRequest` field, a `SearchAndRankUseCase`
filter, and a `SearchView` selector + `SearchViewModel` state. **Extends Milestone F**; best built as F's closing
sub-part so the picker ships with the providers. Depends on **Milestone D** for the "configured?" signal and the
registry it introduces. Respects the layer rule (Data registry ← Business filter ← Presentation picker, wired in
the composition root).
