# v0.4.0 — Navigation & Shell Redesign (UI spec)

> Design decision captured from the product/design discussion for the v0.4.0 branch.
> **Scope: Presentation-layer navigation shell only.** No Business/Data/Infrastructure
> changes; every screen's existing content, view models, and use cases are preserved —
> they are only *re-homed* under a new navigation structure. Milestones for v0.4.0
> restart at Milestone A (per `CLAUDE.md` → Versioning).

Interactive mockup: **`design/Refined-UI-mockup-v0.4.0.html`** (self-contained, opens
in any browser). Source of truth for spacing/labels/states is the mockup + this doc.

---

## 1. Why

At v0.3.0 the app is six top-level areas, several of which now have real internal
depth (Search alone = role titles + optional filters + saved searches + link import;
Portfolio = profile + two source documents + saved profiles; the Tracker is becoming
the primary "work" surface now that generation lives there). The single native tab
strip (now a custom full-width bar) can't grow with this without crowding.

**Decision:** move primary navigation to a **left sidebar** listing only the
**top-level areas**, and demote the per-area sub-screens to a **segmented "tab" control
at the top of the content pane** (the "inner navigation"). This is macOS-standard for
an app of this shape and leaves room to add nested views per area over time.

Constraint agreed: **stay within native macOS conventions** — it should still read as a
Mac app (system materials, SF typography, accent-tinted selection, standard controls).

---

## 2. The shell

```
┌───────────────┬─────────────────────────────────────────────┐
│ ● ● ●         │  Portfolio / Profile                          │  ← title = Area / Sub-view
│               │  [ Profile ][ Saved Profiles ][ Source Docs ] │  ← inner segmented nav
│  ▸ Portfolio  │  ───────────────────────────────────────────  │
│    Search     │                                               │
│    Results  6 │             (sub-view content)                │
│    Tracker  2 │                                               │
│    Settings   │                                               │
└───────────────┴─────────────────────────────────────────────┘
```

- **Sidebar (primary nav):** one row per area — Portfolio, Search, Results, Tracker,
  Settings — each with its existing SF Symbol (`person.text.rectangle`,
  `magnifyingglass`, `list.number`, `briefcase`, `gearshape`). Selected row uses the
  standard accent-fill sidebar selection. Traffic lights sit in the sidebar header.
  Count badges on Results (loaded-result count) and Tracker (tracked-job count).
  - **Sidebar rows show top-level areas only** — no nested rows. (Explicit decision:
    an earlier variant nested sub-views under each row; rejected in favour of inner
    tabs so the sidebar stays a clean area switcher.)
- **Inner segmented nav:** the sub-views of the selected area, rendered as a segmented
  control at the top of the content pane. Selecting an area shows its first sub-view.
- **Content pane header:** `Area / Sub-view` breadcrumb-style title above the segmented
  control.

Implementation note: this replaces `RootView`'s `VStack { tabBar; Divider; selectedTab }`
with a `NavigationSplitView` (or an `HSplitView`/sidebar) driving area selection, plus a
per-area `Picker(.segmented)` (or equivalent) for the sub-view. The five screen views
are unchanged; only their host changes. Keep the pointer-cursor + swipe polish.

---

## 3. Nested views per area

The inner tabs below are the **agreed starting structure**. Areas with a single view
today still get the segmented control (one segment) so the pattern is consistent and
new views slot in without a layout change.

### Portfolio
| Sub-view | Content (existing) |
|---|---|
| **Profile** | Two document slots (résumé/portfolio required + optional cover letter, each Show text / Import), Build Profile, profile summary, **Regenerate description** control, name + Save/Update. |
| **Saved Profiles** | The saved-profile library (tap to load, long-press default, delete). |
| **Source Documents** | The LLM-tidied résumé + cover-letter readable text (the current disclosures). |

### Search
| Sub-view | Content (existing) |
|---|---|
| **New Search** | Profile picker, role-title chips + add + common titles, optional filters (position type; typeable+saveable location & salary with presets; desired-result goal; min-rank slider), Search + Save Search. |
| **Saved Searches** | Saved-search list with Run / Delete. |
| **From a Link** | URL fetch + paste-text fallback. |

### Results
| Sub-view | Content (existing) |
|---|---|
| **Ranked** | Filter bar (Showing X of Y + Clear), ranked rows with score badge + **history badges** (Seen / Generated / status·date), per-row Save-to-Tracker + Delete. Row → detail (read + Save to Tracker; swipe right = save). |

### Tracker
The Tracker is now the "work" surface (generation lives here). Sub-views are **stage
filters** over the tracked list; the detail sheet keeps Generate.
| Sub-view | Content |
|---|---|
| **All / Applied / Interviewing / Offers** | The tracked-jobs list filtered by stage; rows carry history badges; row → detail with Generate résumé & cover letter + Export. |

### Settings
| Sub-view | Content (existing) |
|---|---|
| **Engines** | Per-task engine + Claude-model pickers + footer. |
| **Adzuna** | Country code + credentials status. |
| **About** | App identity / version / one-liner (new, minor). |

---

## 4. What is explicitly preserved (not redesigned)

- All generation, ranking, persistence, export, and grounding behaviour.
- The **generation-in-Tracker** model from Milestone V (Results = read + save only).
- Export (PDF/DOCX/MD/TXT), templates, one-page gate — unchanged, still on the
  Application sheet.
- Sheets (Job Detail, Application) remain modal sheets, unchanged in content.

---

## 5. Open questions for build

1. `NavigationSplitView` (collapsible sidebar, native) vs. a fixed sidebar — recommend
   `NavigationSplitView` for the standard collapse/restore behaviour.
2. Inner nav as `Picker(.segmented)` vs. a custom segmented control — segmented Picker
   is the native default; use custom only if we want icons per sub-view.
3. Tracker stage filters as inner tabs (this doc) vs. a filter chip row inside one
   "All" view — decide during build; inner tabs chosen here for consistency and depth.
4. Room reserved for future areas/sub-views (e.g. Interview Prep area; Tracker
   Follow-ups view) — the shell supports adding either without layout change.
