# VitalSync — Release-Candidate (RC) Validation Runbook

Operational checklist for the final pre-submission round: real-device validation →
beta → App Store submission. **No production code changes** belong in this round;
if a bug is found, report → propose a narrow fix → get approval → fix (then
`flutter analyze` 0 + `flutter test` green).

Routes/flows below are derived from `lib/core/router/app_router.dart` and
`lib/presentation/pages/splash_page.dart`.

---

## 0. Pre-flight (before any RC build)

- [ ] **Working tree is clean and merged to `main`.** Codemagic's `ios-release`
      workflow triggers on **push to `main`**, so anything not on `main` will NOT
      be in the TestFlight build. Commit + merge all completed work first.
- [ ] `flutter analyze` → **0 issues**.
- [ ] `flutter test` → **all green**.
- [ ] `lib/amplifyconfiguration_prod.dart` exists and points at the **prod**
      backend (it is git-ignored; must exist locally / in CI).
- [ ] Privacy Policy + Support pages are **live** (`AppConstants.privacyPolicyUrl`,
      `AppConstants.supportUrl`) — required by App Store; metadata-rejected otherwise.
- [ ] Sentry env vars available for CI/local: `SENTRY_DSN`, `SENTRY_ORG`,
      `SENTRY_PROJECT`, `SENTRY_AUTH_TOKEN`.
- [ ] Hardware: a **physical iPhone** (not the simulator — biometrics, push,
      Apple Sign-In, and obfuscated release builds must be tested on device),
      cable, and an Apple Developer account with TestFlight access.

### Splash routing (expected app-open behavior)
`/splash` waits ~2s, then:
1. First launch → `/onboarding` (sets `keyFirstLaunch=false`).
2. Authenticated → `/dashboard` (auth is checked **before** onboarding).
3. Not authed + onboarding completed → `/auth/login`.
4. Not authed + onboarding not completed → `/onboarding`.
5. Critical init error → error dialog with "Continue anyway" → `/auth/login`.

---

## 1. Real-device smoke / regression matrix

Run on a physical device. Mark expected result at each step.

### 1A. Clean-install end-to-end

| # | Action | Expected |
|---|--------|----------|
| 1 | Delete app if present, install RC build, launch | Splash ~2s → **onboarding** (first launch) |
| 2 | Complete onboarding | Routes to **GDPR consent** (`?onboarding=true`) |
| 3 | Consent screen: Health + Fitness toggles ON (required), Analytics/Backup optional | Required toggles can't be turned off (snackbar); optional toggle freely |
| 4 | Tap "Read Full Privacy Policy" | Opens privacy URL in browser (graceful snackbar if offline/unreachable) |
| 5 | Tap "Accept & Continue" | Routes to **/auth/login** |
| 6 | Sign in with Apple | Apple sheet → success → **dashboard**. First-ever authorization maps given/family name (Apple→Cognito) → name shows, not blank "User" |
| 7 | Observe dashboard | Summary loads; spinner then real data |
| 8 | Health tab → add medication (name, dosage, schedule) → save | Appears in list; reminder notification scheduled |
| 9 | Fitness tab → start workout / template → add set → finish | Workout summary; session saved |
| 10 | Health → add symptom → save | Appears in health timeline |
| 11 | Settings/Profile → Logout | Routes to **/auth/login** |
| 12 | Login again (Apple or email) | **Dashboard**; previously created data still present (cloud sync restores) |
| 13 | Settings → Privacy & Data → **Delete Account** → confirm (online) | Progress dialog → returns to **login**; account + cloud + local data deleted |
| 14 | Try logging into the deleted account | Fails (account no longer exists) |

### 1B. Tri-lingual visual pass (en / tr / de)

Settings → Language → switch each. For each language inspect for **overflow /
truncation / clipping** (German strings are longest — watch buttons and cards):

- [ ] Onboarding screens
- [ ] Consent cards (titles, descriptions, "Required" tag)
- [ ] Dashboard summary tiles
- [ ] Settings list (incl. Privacy/Terms/Support rows)
- [ ] Delete-account dialog + the online-required / failed snackbars
- [ ] Medication / symptom / workout add forms
- [ ] Error/init dialogs

All three are LTR (no RTL). Expectation: text ellipsizes, no pixel overflow stripes.

### 1C. Restart behavior

- [ ] While **authenticated**, hot restart → splash → **dashboard** (login skipped).
- [ ] Cold start (kill + relaunch) while authenticated → **dashboard**.
- [ ] Logout, then cold start → **/auth/login** (onboarding not repeated).

### 1D. Medication follow-up notifications (dual-notification + cancel-on-log)

> All of this must work with the **app killed** — it's pre-scheduled local
> notifications, no background execution. Tip: instead of waiting 30 real
> minutes for the follow-up, advance the device clock past the follow-up time
> (Settings → General → Date & Time, Set Automatically OFF).

| # | Action | Expected |
|---|--------|----------|
| 1 | Add a medication with a dose time ~2 min from now; **kill the app** | Reminder notification fires at dose time (app killed) |
| 2 | Do **not** log the dose; wait/advance +30 min | Follow-up fires: "Did you take X? Don't forget to log it." |
| 3 | Next day's slot (or re-add): after the reminder fires, open app and **log the dose (taken)** before +30 min | Follow-up does **NOT** fire; the next day's reminder is still scheduled |
| 4 | Repeat with **skipped** instead of taken | Same: follow-up cancelled |
| 5 | **Delete** the medication while reminders are pending | No further reminders **or follow-ups** fire for it |
| 6 | **Edit** the medication's dose time | Old-time notifications stop; new-time reminder + follow-up fire |
| 7 | Settings → notifications **OFF**, then re-save a medication; turn clock past dose+30 | No follow-up is scheduled/fires |
| 8 | Switch app language to tr/de, re-save medication, let a follow-up fire | Follow-up title/body localized (tr: "Kaydetmeyi unutma…") |

---

## 2. Offline-first validation matrix (most critical)

> Do not touch sync/conflict code while testing. This validates existing behavior
> (retry, timestamp last-write-wins, conditional writes).

### 2A. Airplane-mode create → reconnect → sync (no data loss)

| # | Action | Expected |
|---|--------|----------|
| 1 | Login online (cloud-backup consent ON) | Authenticated |
| 2 | Enable Airplane Mode | Offline |
| 3 | Add medication + symptom + workout | Saved locally, visible in UI, queued (pending) |
| 4 | Kill + relaunch app (still offline) | Data persists (local encrypted DB) |
| 5 | Disable Airplane Mode | Auto-sync fires on connectivity return; queue drains; sync status → idle |
| 6 | Verify server copy (data export, or second device/login) | All records present — **no data loss** |

### 2B. Conflict — timestamp resolution (last-write-wins)

| # | Action | Expected |
|---|--------|----------|
| 1 | Device A online: create record, sync | Record on server |
| 2 | Device A offline: edit record (newer `lastModifiedAt`) | Local change queued |
| 3 | Change same record on server / Device B with a **different** timestamp | Two versions exist |
| 4a | Reconnect A, **local newer** | Local wins → push, server updated |
| 4b | Reconnect A, **remote newer** | Push skipped; local overwritten by remote on pull |
| 5 | Inspect both sides | Both converge on the newer-timestamp version |

### 2C. Sync failure preserves user data

| # | Action | Expected |
|---|--------|----------|
| 1 | Create data offline (pending queue) | Stored locally |
| 2 | Force a sync error (weak signal / server 5xx / precondition fail) | Item marked failed, retry count++, **local data NOT deleted** |
| 3 | Exhaust max retries | Item stays failed; data still present locally; no crash |
| 4 | Attempt Delete Account while **offline** | "You must be online…" message; **nothing deleted** (no orphaned server data) |

### 2D. Background flush on app close (lifecycle sync)

> Validates the `AppLifecycleState.paused` final flush: data entered right
> before closing the app should reach the cloud **without reopening it**.

| # | Action | Expected |
|---|--------|----------|
| 1 | Login online (cloud-backup consent ON); add a medication/symptom | Saved locally, queued |
| 2 | Immediately **swipe the app to background** (home gesture — do not kill); wait ~10 s | Flush sync runs in iOS's backgrounding window |
| 3 | **Without reopening the app**, verify the server copy (second device / data export) | Record is on the server |
| 4 | Repeat steps 1–2 while **offline** | No crash; nothing sent; data syncs normally on next launch/reconnect |
| 5 | Rapidly background→foreground→background a few times | No crash, no duplicate records server-side (sync is re-entrancy-guarded) |

---

## 3. Build + beta

### 3.1 Version / build number
- `pubspec.yaml` → `version: 1.0.0+1`. Marketing `1.0.0` is fine for first submission.
- TestFlight requires a **unique, increasing build number** per upload.
  - **CI (Codemagic):** auto-increments via `get-latest-testflight-build-number + 1` — no manual edit needed.
  - **Manual build:** bump the `+N` yourself (e.g. `1.0.0+2`) before each upload.
- `CFBundleShortVersionString`/`CFBundleVersion` flow from Flutter → these become
  the Sentry `release`/`dist`, so device events and uploaded symbols match.

### 3.2 Release build (manual) — obfuscated + symbols
```bash
flutter build ipa --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define=ENV=prod \
  --dart-define=SENTRY_DSN="$SENTRY_DSN"

# Upload Dart symbols + dSYMs to Sentry
export SENTRY_ORG=... SENTRY_PROJECT=... SENTRY_AUTH_TOKEN=...
dart run sentry_dart_plugin
```
(See `docs/SENTRY_SYMBOLICATION.md`.)

### 3.3 CI path (preferred)
Push to `main` → `ios-release` workflow runs: obfuscated build, build-number
bump, symbol upload, and `submit_to_testflight`. Watch the Codemagic build log.

### 3.4 Manual upload alternative
`build/ios/ipa/*.ipa` → upload via **Transporter** or Xcode Organizer →
App Store Connect → TestFlight → wait for processing.

### 3.5 Beta plan
- **Internal testing first:** add App Store Connect users (≤100), no review,
  instant. Run the §1–§2 matrices here.
- **External testing:** up to 10k testers; the **first** build needs Beta App
  Review (~a day). Provide test notes, what to test, and a feedback email.

---

## 4. Monitoring during beta (Sentry)

- Sentry → **Releases** → select `…@1.0.0+<build>`.
- [ ] **Crash-free sessions** — target **> 99.5%** for a health app. Investigate any regression.
- [ ] **Deobfuscation check:** open a real issue (or follow the test-crash steps
      in `docs/SENTRY_SYMBOLICATION.md`); the stack must show **readable Dart
      frames**, not hex/obfuscated symbols. If obfuscated → symbol upload failed
      for that build's debug-image UUID; re-run §3.2 upload against the same binary.
- [ ] Confirm `environment: prod` tag on events.
- [ ] Watch top issues; triage before widening to external testers.

---

## 5. App Store submission

### 5.1 Pre-submission checklist (App Store Connect)
- [ ] **App Privacy label** matches code reality:
      - Health, Fitness, Email, Name, User ID → collected, **Linked**, App Functionality, **not** tracking.
      - Crash Data (Sentry) → collected, **Not Linked**, App Functionality.
      - **Usage Data: do NOT mark** — `AnalyticsService` is a no-op (Pinpoint removed), client collects none.
      - "Data used to track you": empty (no ATT).
- [ ] **Age rating:** Medical/Treatment Information → "Infrequent/Mild" → ~12+.
- [ ] **Category:** Primary = Health & Fitness.
- [ ] Privacy Policy URL + Support URL live.
- [ ] Screenshots (required sizes), description, keywords.
- [ ] **Demo account** in App Review Information (login-gated app).
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption=false` (already in Info.plist; exemption applies).

### 5.2 Most common rejection causes — preparation
| Guideline | Risk | Mitigation |
|---|---|---|
| 2.1 Completeness | Reviewer can't log in | Provide a **working** demo account; or note Sign in with Apple |
| 5.1.1(v) Account deletion | Missing in-app deletion | Present: Settings → Privacy & Data → Delete Account — note the path |
| 5.1.1 Data & consent | Health data without consent/policy | GDPR consent screen + live privacy policy |
| 5.1.3 Health data use | Suspected ad/tracking use | State: health data is for the user's own use only, never ads/tracking/sharing |
| 4.8 Sign in with Apple | Missing when 3rd-party login present | Present (entitlement + flow) |
| Privacy label mismatch | Label ≠ actual collection | Label built from code (see §5.1); Usage Data unchecked |

### 5.3 Reviewer notes — draft (paste into App Review Information)
```
VitalSync is an offline-first health & fitness companion.

Demo account:
  Email: <REVIEWER_TEST_EMAIL>
  Password: <REVIEWER_TEST_PASSWORD>
(Sign in with Apple is also supported.)

Account deletion (Guideline 5.1.1(v)):
  Settings → Privacy & Data → Delete Account.
  This permanently deletes the user's cloud data (AWS DynamoDB), all local
  data, and the Cognito account. The app requires connectivity for deletion so
  server-side data is never orphaned.

Health data:
  Users track their own medications, symptoms, and workouts. Data is stored for
  the user's own use only — encrypted locally (SQLCipher) and synced to the
  user's private AWS backend when cloud backup is enabled. It is never used for
  advertising or tracking and is not shared with third parties.

Permissions:
  - Notifications: medication reminders.
  - Face ID: optional app lock.

The app does not use HealthKit.
```

### 5.4 Submit
- Select the processed TestFlight build → attach to the App Store version →
  **Submit for Review**. Answer export-compliance (already declared exempt).

---

## Bug-handling protocol (this round)
If validation surfaces a bug:
1. **Report** it here (repro steps, expected vs actual, severity).
2. **Propose** a narrow fix (no scope creep into sync/conflict internals).
3. **Wait for approval.**
4. Fix → `flutter analyze` 0 + `flutter test` green → re-verify the failing path.
