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

> **Prior entries scheduled.** These were moved into **v0.6.0 (richer grounding, job detail & sources)** and now
> live in `TODO.md` / `ROADMAP.md`:
> - **richer job postings**, **select a profile at generation time**, **regenerate result** → Milestones **A–C**
>   (scheduled 2026-07-13; A–C now complete).
> - **user-editable API credentials**, **full job-posting text**, **multi-source job search** → Milestones
>   **D–F** (scheduled 2026-07-13; build order D → E → F).
>
> The entry below is still unscheduled; add new specced-but-unscheduled work as it comes up in chat.

---

## Per-provider credential setup help — a link / instructions for getting each search engine's API key

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
