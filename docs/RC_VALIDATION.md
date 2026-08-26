# VitalSync — Release-Candidate (RC) Validation Runbook

Operational checklist for the final pre-submission round: real-device validation →
beta → App Store submission. **No production code changes** belong in this round;
if a bug is found, report → propose a narrow fix → get approval → fix (then
`flutter analyze` 0 + `flutter test` green).

Routes/flows below are derived from `lib/core/router/app_router.dart` and
`lib/presentation/pages/splash_page.dart`.

> **Targets 1.1.0+4.** 1.1.0 adds the measurement layer: read-only Apple Health
> import, manual glucose entry, meal logging, the post-meal reminder, and opt-in
> calibration metrics. Sections marked *new in 1.1.0* have never been run on a
> device. When bumping the version, re-check §3.1, §4, §5.1 and the reviewer
> notes in §5.3 — all four name the version or the permission set.

---

## 0. Pre-flight (before any RC build)

- [ ] **Working tree is clean and merged to `main`.** Codemagic's `ios-release`
      workflow triggers on **push to `main`**, so anything not on `main` will NOT
      be in the TestFlight build. Commit + merge all completed work first.
- [ ] `flutter analyze` → **0 issues**.
- [ ] `flutter test` → **all green**.
- [ ] `flutter test integration_test -d <device-id>` → **all green**. Needs a
      booted simulator or a connected device; `flutter test` alone does **not**
      run `integration_test/`.
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

New in 1.1.0 — the measurement layer. These screens have never had a
tri-lingual pass:

- [ ] `/health/glucose` — glucose list (empty state, rows, delete confirm)
- [ ] `/health/glucose/add` — add-reading form (unit selector, validation errors)
- [ ] `/health/glucose/today` — today's curve (axis labels, meal markers, empty state)
- [ ] `/health/meals` — meal list (rows, **coverage badge**, delete confirm)
- [ ] `/health/meals/add` — add-meal form (name, tags, note)
- [ ] Settings → Privacy & Data → **Health Sources** — connect/import/disconnect
      buttons, the read-only notice, and the five type chips (glucose, steps,
      active energy, workouts, sleep). German chip labels are the longest here.
- [ ] Settings → Notifications → **post-meal reminder** row (title + subtitle);
      also check it in the disabled state (master notification switch off)
- [ ] Settings → Privacy & Data → **calibration metrics** row + its info dialog
- [ ] `/fitness/achievements` — the 22 achievement titles/descriptions were
      translated in 1.1.0 and have **never** been checked on a device. German
      descriptions are long; watch the cards and the category filter chips.

All three are LTR (no RTL). Expectation: text ellipsizes, no pixel overflow stripes.

> A missing translation key does **not** fail the build — it silently falls back
> to English. So a screen that renders English text in tr/de is a real finding,
> not a cosmetic one.

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

### 1E. Apple Health import (new in 1.1.0 — read-only)

> **Must be a physical device.** The simulator's Health app cannot serve most of
> these types, so a simulator pass proves nothing here.
>
> The app requests **read** access only. If any of these steps produces a
> HealthKit *write* prompt, or Health → Sources → VitalSync shows anything under
> "Allow VitalSync to Write Data", **stop and report it** — that contradicts the
> entitlement (`com.apple.developer.healthkit.access` is an empty array) and the
> reviewer notes in §5.3.

| # | Action | Expected |
|---|--------|----------|
| 1 | Fresh install, Settings → Privacy & Data → **Health Sources** | Apple Health shows **Not connected**; last import **Never** |
| 2 | Tap **Connect** | iOS HealthKit sheet lists exactly five read types: glucose, steps, active energy, workouts, sleep. **No write section** |
| 3 | Grant all → return to the screen | Shows **Connected** |
| 4 | **Deny** instead (repeat on a second install, or revoke in Health → Sources) | App keeps working — no crash, no error dialog; screen stays "Not connected" and the rest of the app is unaffected |
| 5 | Add a glucose value by hand in Apple **Health**, then tap **Import now** | Snackbar reports the imported count; the reading appears in `/health/glucose` with the *imported* trailing icon (heart, not pencil) |
| 6 | Tap **Import now** again immediately | "Nothing new" — no duplicate row (dedupe by external id) |
| 7 | Background the app, add another value in Health, foreground VitalSync | Imported automatically (foreground import, 15-min throttle) |
| 8 | Tap **Disconnect** | Screen returns to "Not connected"; imports stop |

### 1F. Glucose + meal logging (new in 1.1.0)

Entry points: Health tab → the icon row at the top of the medication list
(glucose and meal icons). There is no bottom-nav tab for these.

| # | Action | Expected |
|---|--------|----------|
| 1 | Health tab → glucose icon → **Add** | Form opens; measurement time defaults to now |
| 2 | Enter a value, switch the unit selector mg/dL ↔ mmol/L, save | Saved; the **list always shows mg/dL** (storage unit) regardless of the unit picked on the form |
| 3 | Enter an out-of-range / empty value | Inline validation error; nothing saved |
| 4 | Health tab → meal icon → **Add**: time, name, tags, note → save | Appears in the meal list. **No photo/camera control anywhere on the form** |
| 5 | Log 3+ readings across today plus a meal → `/health/glucose/today` | Curve renders with a vertical marker at the meal time. **No reference-range band, no colour coding, no "high/low" wording** |
| 6 | Swipe-delete a reading and a meal | Confirm dialog → removed. Deleting a meal also cancels its pending reminder (§1G) |
| 7 | Meal list: check the **coverage badge** on a meal | Neutral theme colours only — **not** green/red. It reports data completeness, never a judgement about the meal |

### 1G. Post-meal measurement reminder (new in 1.1.0)

> Same as §1D: pre-scheduled local notifications, so it must work with the app
> killed. Advance the device clock rather than waiting 2 real hours.

| # | Action | Expected |
|---|--------|----------|
| 1 | Settings → Notifications: master switch **on**, post-meal reminder **on** (default) | Both switches on |
| 2 | Log a meal at the current time; **kill the app**; advance the clock +2 h | Notification fires |
| 3 | Read the notification text on the **lock screen** | Generic time-based prompt only. It must **not** contain the meal name, any glucose value, or words like high / low / spike / normal / "you should" |
| 4 | Tap the notification | Opens `/health/glucose/add` with the measurement time **pre-filled** to the reminder's fire time |
| 5 | Log a meal **backdated** more than 2 h | **No** notification fires immediately (past-due reminders are never scheduled) |
| 6 | Edit a meal's time | Old reminder cancelled; a new one is scheduled for the new time + 2 h |
| 7 | Delete the meal | No reminder fires for it |
| 8 | Turn the post-meal reminder switch **off**, log a meal, advance the clock | Nothing fires |
| 9 | Turn the **master** notification switch off | The post-meal row goes disabled and reads off; no reminder is scheduled |
| 10 | Switch to tr/de, log a meal, let a reminder fire | Title/body localized |

### 1H. Calibration metrics telemetry (opt-in, new in 1.1.0)

| # | Action | Expected |
|---|--------|----------|
| 1 | Fresh install → Settings → Privacy & Data → **Calibration metrics** | Switch is **off** by default |
| 2 | Tap the row | Info dialog explains what is counted. It must **not** use the word "anonymous" (the data is tied to the user's own account) |
| 3 | Leave it off; log meals + readings; let the weekly task run | No `calibration_metrics` row is produced at all |
| 4 | Turn it on; log meals + readings; trigger the weekly report | A row is produced |
| 5 | Export data (Settings → Privacy & Data → data export) and read the calibration section | **Counts only.** No glucose value, no meal name, no note anywhere in it |
| 6 | Delete Account, then re-check the export/local DB | Calibration metrics, meals, glucose readings and imported health samples are all gone |

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

### 2E. Measurement-layer sync boundary (new in 1.1.0)

> This is the one place where "it synced" is the **wrong** result for some rows.
> HealthKit-sourced data must never leave the device: imported samples are
> re-derivable from the platform health store, and re-uploading them would put
> the user's Health app contents in the cloud without a separate consent.

| # | Action | Expected |
|---|--------|----------|
| 1 | Online, cloud-backup consent ON. Enter a glucose reading **by hand**, let sync run | Reaches the server (`GLUCOSE#` sort key) |
| 2 | Log a meal, let sync run | Reaches the server (`MEAL#`) |
| 3 | Import readings from Apple Health (§1E), let sync run | The imported readings are **NOT** on the server — only the manual one from step 1 |
| 4 | Check the server for step/energy/workout/sleep samples | Nothing: `health_samples` is local-only and is not in `tablesToSync` |
| 5 | With calibration metrics ON, let a weekly row be produced and sync | Row reaches the server (`CALMETRIC#`) and contains counts only (§1H step 5) |
| 6 | Sign out and back in on the same device (cloud restore) | Manual readings and meals come back. Imported samples do **not** — they are re-imported from Apple Health instead (§1E step 5) |

---

## 3. Build + beta

### 3.1 Version / build number
- `pubspec.yaml` → `version: 1.1.0+4`.
- **The marketing version lives in two places.** `pubspec.yaml` drives
  `CFBundleShortVersionString`, and `AppConstants.appVersion` (`1.1.0`) is
  stamped onto calibration metrics. Codemagic passes only `--build-number`,
  never `--build-name`, so nothing keeps them in step at build time —
  `test/core/constants/app_version_test.dart` fails the suite if they diverge.
  **Bump both.**
- There is no `AppConstants.buildNumber`; the real build number is CI's.
- TestFlight requires a **unique, increasing build number** per upload.
  - **CI (Codemagic):** auto-increments via `get-latest-testflight-build-number + 1` — no manual edit needed.
  - **Manual build:** bump the `+N` yourself (e.g. `1.1.0+5`) before each upload.
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

### 3.4 Manual upload via Transporter (first release)

Use this when uploading the **first build by hand** instead of via CI. The CI
path (§3.3) auto-increments the build number; **manual uploads do not — you must
bump `+N` in `pubspec.yaml` yourself before every upload** (ASC rejects a reused
build number).

**Pre-flight (manual-specific):**
- [ ] App record **exists in App Store Connect** for bundle id
      `site.tunckankilic.vitalsync` — *Transporter delivery fails without it.*
- [ ] Distribution certificate + App Store provisioning profile available
      (or Xcode "Automatically manage signing" on, with a Team selected).
- [ ] **Transporter** app installed (Mac App Store).
- [ ] Sentry vars exported in the shell: `SENTRY_DSN`, `SENTRY_ORG`,
      `SENTRY_PROJECT`, `SENTRY_AUTH_TOKEN`.

**Steps:**
1. Build the signed, obfuscated prod IPA + upload symbols (§3.2). If
   `flutter build ipa` needs an export method, check
   `flutter build ipa --help | grep export-method` (value is `app-store` or
   `app-store-connect` depending on Flutter version).
2. **CLI signing fails? → Xcode fallback:** `open ios/Runner.xcworkspace` →
   Signing & Capabilities: set Team → device target **Any iOS Device (arm64)** →
   Product → **Archive** → Organizer → **Distribute App → App Store Connect →
   Export** → save the `.ipa`. *(Organizer can also Upload directly, skipping
   Transporter.)*
3. Run the **Sentry symbol upload immediately after the build**, against the same
   binary (`dart run sentry_dart_plugin`) — so first-release crashes deobfuscate.
4. Open **Transporter** → sign in → drag the `.ipa` → it validates → **Deliver**.
5. App Store Connect → TestFlight shows **"Processing"** (~5–30 min).
6. When processed → **Internal Testing** first (no review, instant) → run the
   §1–§2 matrices on it → then attach to the App Store version and submit.

### 3.5 Beta plan
- **Internal testing first:** add App Store Connect users (≤100), no review,
  instant. Run the §1–§2 matrices here.
- **External testing:** up to 10k testers; the **first** build needs Beta App
  Review (~a day). Provide test notes, what to test, and a feedback email.

---

## 4. Monitoring during beta (Sentry)

- Sentry → **Releases** → select `…@1.1.0+<build>` (the marketing version comes
  from `pubspec.yaml`; see §3.1).
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
      - **HealthKit (new in 1.1.0):** the Health/Fitness categories now also cover
        glucose, steps, active energy, workouts and sleep read from Apple Health.
        Imported samples stay **on the device** (`health_samples` is not synced,
        and HealthKit-sourced glucose is not pushed) — but they are still stored
        and shown, so Health/Fitness remain "collected".
- [ ] **HealthKit capability** is on the App ID / provisioning profile used for
      the build. The entitlement (`com.apple.developer.healthkit`) was added in
      1.1.0; a profile generated before that will fail signing, not just at
      runtime. Read access only — `com.apple.developer.healthkit.access` is an
      empty array and there is no `NSHealthUpdateUsageDescription`.
- [ ] `NSHealthShareUsageDescription` is present and reads back **localized** in
      the built `.app` (`tr.lproj` / `de.lproj` are in the bundle).
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
| 5.1.3 HealthKit | HealthKit data used for advertising, or written back without cause | Read-only (no write entitlement, no `NSHealthUpdateUsageDescription`); imported data never leaves the device; state both in the notes (§5.3) |
| 1.4.1 Medical claims | App appears to diagnose or advise | It does not: no score, no reference ranges, no interpretation. Notifications are time-triggered only and say nothing about a measurement (§1G step 3) |

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
  Users track their own medications, symptoms, workouts, blood glucose
  measurements and meals. Data is stored for the user's own use only —
  encrypted locally (SQLCipher) and synced to the user's private AWS backend
  when cloud backup is enabled. It is never used for advertising or tracking
  and is not shared with third parties.

HealthKit (Guideline 5.1.3):
  The app reads five sample types from Apple Health: blood glucose, steps,
  active energy, workouts, and sleep.

  - Read-only. The app never requests write authorization. The
    com.apple.developer.healthkit.access entitlement is an empty array and
    Info.plist contains no NSHealthUpdateUsageDescription, so the app cannot
    write to Apple Health at all.
  - HealthKit-sourced data never leaves the device. Imported samples are stored
    in a local-only table that is excluded from cloud sync, and glucose
    readings imported from Apple Health are never uploaded. Only measurements
    the user typed in by hand are synced to their own private backend.
  - Reading Apple Health is entirely optional. The user connects it explicitly
    in Settings > Privacy & Data > Health Sources, can disconnect at any time,
    and the app works normally if permission is denied.
  - HealthKit data is used only to display the user's own measurements back to
    them. It is not used for advertising, marketing, or any use-based data
    mining, and it is not shared with third parties.

No diagnosis or medical advice:
  The app records and displays measurements. It does not compute a health
  score, does not draw reference ranges, and does not interpret any reading.
  The optional post-meal notification is triggered by elapsed time only and
  says nothing about the user's values.

Permissions:
  - Notifications: medication reminders and the optional post-meal
    measurement reminder.
  - Apple Health (HealthKit): read-only, optional, described above.
```

> **Do not ship a note that says the app does not use HealthKit.** That was true
> for 1.0.0 and is false from 1.1.0 on — the entitlement and the usage
> description are both in the binary, so the claim would contradict what the
> reviewer sees.

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
