# Insights UI — what exists, what ships, what was removed

Written 2026-08-26, while cutting 1.1.0. This is the record for anyone who
comes back to the insight feature and wonders why half of it is missing from
the repo and the other half never appears in the app.

---

## The short version

The insight **engine** ships and runs. The insight **UI** was built three times
and connected once.

| Piece | State before 1.1.0 | State after |
|---|---|---|
| `InsightEngine` + daily background task | live | unchanged |
| `_LatestInsightCard` on `DashboardPage` | live — one non-tappable card | unchanged |
| `InsightBadge` in `GlassmorphicAppBar` | live, and **broken**: pushed `/insights`, which is not a route | removed |
| `InsightsListScreen` (360 lines) | never reachable | removed |
| `InsightDetailScreen` (507 lines) | never reachable | removed |
| `InsightCarouselCard` (282 lines) | only used by `DashboardScreen`, itself dead | left in place — see below |

Nothing a user can see changed, except that a badge which opened an error page
no longer appears.

---

## What still ships

`InsightEngine` runs as a WorkManager task every day at 06:00
(`AppConstants.taskGenerateInsights`, built in `background_service.dart` and
registered in `injection_container.dart`). It writes rows to
`generated_insights`.

Those rows surface in exactly one place: `_LatestInsightCard` in
`lib/presentation/pages/dashboard_page.dart`. It renders the most recent
insight's title and message. It is a plain `Card` — no tap target, no detail,
no list, no dismiss.

So the feature today is "one sentence on the dashboard", and that is the whole
of it.

### The engine's language is a live consideration

`InsightStrings` is hardcoded English, so that dashboard card renders English in
the Turkish and German builds. It is also interpretive by nature. The strongest
example, `insight_strings.dart`:

> Your `<symptom>` severity has increased from `<x>` to `<y>` over the past week
> — you may want to discuss this with your doctor.

That has shipped since 1.0.0. It is not new and it is not a regression, but it
is the reason the removed screens were not simply wired up: see below.

---

## Why the unreachable screens were removed rather than connected

`CONTEXT-2.0.md` draws the 2.0 boundary at **VitalSync measures and shows,
Kalibra interprets**, and gives the reason plainly: a Guideline 1.4.1 health-claim
rejection on a live app blocks *every* update, and a feature that has shipped
cannot be taken back.

Connecting `InsightsListScreen` and `InsightDetailScreen` would have turned the
current one-sentence surface into a browsable feature built entirely out of that
interpretive language — and done so as pre-release cleanup, days before a
submission, with:

- no screen tests on either file,
- no tri-lingual pass (and `InsightStrings` English-only, so tr/de would show
  English throughout),
- two route shapes that disagree with each other, proving neither was ever
  wired: the badge pushed `/insights`, the carousel pushed `/insights/<id>`, and
  the list screen pushed `/insights/detail/<id>`.

That is a product decision with review exposure, not a cleanup. It should be
made deliberately, for a release that has room to validate it.

### What it would take to bring them back

`git revert` the removal commit, then:

1. Add the routes. Pick **one** shape and make all callers agree —
   `/insights` for the list and `/insights/<id>` for the detail is the obvious
   pair; the list screen's `/insights/detail/<id>` needs changing either way.
2. Restore `InsightBadge` and its `/insights` push.
3. Localize `InsightStrings`. It is the message layer, not the rule layer, so
   translating it does not touch `InsightEngine` itself — but read
   `CONTEXT-2.0.md` first, because the strings are where health-claim language
   lives and the boundary is about the wording, not the plumbing.
4. Write screen tests for both. Neither has ever run.
5. Re-read the 1.4.1 question with the actual final wording in front of you.

---

## Two corrections to earlier notes

**1. The `/insights/weekly-report` route was added for the right reason, but the
reason given in commit `c7e968f` was wrong.**

That commit says the route was missing while "the dashboard greeting card and
quick-actions card have pushed that exact path since before 1.0.0", implying two
live broken taps. They are not live: `GreetingCard` and `QuickActionsCard` are
used only by `DashboardScreen`, which has zero usages. The route is still
needed — the weekly-report notification is live (`background_service.dart`
fires `showWeeklyReportReady`) and now routes there — but no user-reachable
button was broken.

**2. There were two dashboards. The superseded one has been removed.**

`app_router.dart` routes `/dashboard` to `DashboardPage`
(`lib/presentation/pages/dashboard_page.dart`), which came later as a
simplification. The older, richer `DashboardScreen` and its seven cards were
referenced by nothing and were deleted in 1.1.0 — 1,898 lines across ten files,
including two orphaned providers and a **second `DashboardSummary` class with
its own `dashboardSummaryProvider`**, a duplicate of the one the live page uses.

It had never been run in the app, and the code proves it:

- `QuickActionsCard` pushed `/health/medication/add`, `/health/symptom/add` and
  `/fitness/workout/start`. The real routes are `/health/add-medication`,
  `/health/add-symptom` and `/fitness/active-workout`. Three of its four
  buttons could never have worked, and nobody noticed.
- `InsightCarouselCard` pushed `/insights/<id>`, a route that never existed.
- Its pull-to-refresh called `insightEngine.generateAllInsights()` directly,
  moving the interpretive engine off its daily background task and onto a user
  gesture — the wrong direction for the 2.0 boundary.
- Edit mode was entered by long-pressing anywhere, and the banner explaining
  that ("long press to reorder") only appeared *after* you had long-pressed.

## The dashboard ideas worth keeping

Deleting that code was about the code, not the design. `DashboardScreen`
answered a real question that `DashboardPage` does not: what belongs on the home
screen of a health app. Recover from git (`git log -- lib/presentation/screens/dashboard`)
if the pixels are useful, but the ideas are these:

- **A weekly chart.** Bars plus a line overlay, seven days.
- **An activity feed.** One timeline merging medications, symptoms and
  workouts, which is the only place the app ever showed them together.
- **Quick actions.** Four shortcuts to the add-forms — with correct paths.
- **A tablet layout.** A masonry grid at two columns on phones, four above
  600pt. `DashboardPage` is a single column at every size.
- **Reorderable cards**, persisted per user. Genuinely nice; genuinely optional.

### The gap neither dashboard filled

**Neither showed glucose or meals.** The measurement layer is 1.1.0's headline
feature and it is invisible on the home screen — no reading, no meal, no
coverage count, nothing. Whichever direction the dashboard goes, that is the
user-facing gap to close first, and it is a better use of the effort than
reviving 1,898 lines that never executed.
