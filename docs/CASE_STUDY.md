# VitalSync — Case Study

> Offline-first health & fitness companion. Flutter (iOS) + AWS serverless backend.
> Built and shipped solo, end to end: mobile app, cloud backend, security hardening,
> observability, and App Store submission prep.

---

## Elevator pitch (30 seconds)

VitalSync lets people track medications, symptoms, and workouts **offline-first** —
every action works with no network and syncs to an AWS backend when connectivity
returns, with timestamp-based conflict resolution. It handles real health data, so
the project is built around **data integrity, privacy (GDPR), and observability**:
encrypted local storage, crash reporting with deobfuscated release stacks, in-app
account deletion, and a hardened AWS backend.

---

## The problem & context

Health apps have two hard constraints most demo apps ignore:
1. **Connectivity can't be assumed.** A medication reminder or symptom log must work
   on a subway with no signal — and never lose data.
2. **The data is sensitive.** Health data is a GDPR "special category" (Art. 9). A
   crash that corrupts data, or a leak, is the worst-case outcome — and *not being
   able to see it happen* is the bigger risk.

So the engineering bar isn't "does the feature work" — it's "does it work offline,
does it stay consistent, and can I observe it in production."

---

## Architecture (high level)

```
┌──────────────────────── Flutter app (iOS) ────────────────────────┐
│  UI (Material 3, 3 languages)                                      │
│  State: Riverpod        Routing: go_router                        │
│  ── offline-first core ──                                          │
│  Drift (SQLite + SQLCipher, encrypted at rest)  ◄── source of truth│
│  Sync queue ─► SyncService (retry, conflict resolution)           │
│  Secure storage: Keychain   Crash: Sentry (obfuscated→symbolicated)│
└───────────────┬───────────────────────────────────────────────────┘
                │ HTTPS, AWS SigV4 (IAM auth)
                ▼
┌──────────────────────── AWS (eu-central-1) ───────────────────────┐
│  API Gateway (REST, IAM auth, throttling, WAF)                     │
│      └─► Lambda (sync handler, conditional writes)                 │
│              └─► DynamoDB (single-table, PK/SK, PITR + backups)    │
│  Cognito User Pool + Identity Pool (email + Sign in with Apple)    │
└────────────────────────────────────────────────────────────────────┘
```

Data flows **local-first**: writes hit the encrypted Drift DB immediately and enqueue
a sync job; the cloud is a backup/replication target, not the critical path.

---

## The hard parts (what's worth talking about)

### 1. Offline-first sync + conflict resolution
The sync engine drains a local queue against DynamoDB. Conflicts are resolved with
**last-write-wins by `lastModifiedAt`**, enforced server-side via **conditional
writes** (optimistic concurrency): the client pushes only when its timestamp is
newer; otherwise it pulls and overwrites locally. Per-item failures mark the item
for retry (bounded retries) and **never abort the batch or drop data**. Covered by
unit tests for push/pull, both conflict directions, retry exhaustion, and
re-entrancy.

### 2. Right to erasure that actually erases
In-app account deletion runs a deliberate order: delete cloud (DynamoDB) data first
(while the auth token is valid) → clear the local DB → clear preferences → delete the
Cognito account last. If the cloud delete fails it **aborts** rather than orphan
server-side health data, and requires connectivity up front. Failures surface to the
user *and* to Sentry.

### 3. Observability for release builds
Release builds are obfuscated, so raw Sentry stacks are unreadable. Wired up
`--split-debug-info` symbol upload (sentry_dart_plugin) so crash traces
**deobfuscate** in production, tagged by environment and release/dist.

### 4. AWS hardening (verified live, not just claimed)
DynamoDB PITR + deletion protection, API Gateway throttling + error-only logging
(health payloads excluded from logs), 30-day Lambda log retention, least-privilege
IAM (auth role scoped to `/sync` only), private deployment bucket, and a **WAF in
Block mode** (CommonRuleSet, KnownBadInputs, IpReputation). Each was confirmed via
the AWS CLI, with apply/verify/rollback documented.

### 5. Release-candidate (RC) verification — a build that ships ≠ a build that compiles
The launch bug that started this work (a **white screen after splash**) only appeared
in a **release build on a physical device**: debug paints a red error overlay, release
paints a blank `ErrorWidget` and hides the exception. That shaped an RC discipline —
*freeze the shippable artifact, then try to break it.*
- **Automated gate (no device needed):** `flutter analyze` clean, 100+ tests green, and
  the **actual shippable artifact compiles** — `flutter build ios --release
  --obfuscate --split-debug-info --dart-define=ENV=prod` produces `Runner.app` **and**
  emits the Dart symbol file for Sentry. Export-compliance flag
  (`ITSAppUsesNonExemptEncryption`) present.
- **Manual gate (inherently physical):** real-device smoke of the critical journeys
  (onboarding → Sign in with Apple → dashboard → account deletion), an
  **offline→reconnect→conflict matrix** for data integrity, a TestFlight install to
  exercise the *signed distribution* path, and confirming Sentry receives a
  **deobfuscated** crash. A bug here means a narrow fix and a **fresh RC**, not a patch
  on top of an already-verified build.

The point: green CI proves the code is correct; RC proves *the thing you upload* runs.

---

## Results / status (honest framing)

- **Functional, hardened, and submission-ready.** Real-device + offline regression
  matrices written; `flutter analyze` clean; 100+ tests green.
- **Solo project.** No production user scale yet — this demonstrates engineering
  breadth and ownership, not operating a service at scale.
- **Single-backend launch (documented trade-off).** `ENV=prod` currently ships the
  existing backend because a full env split would have reset the manually configured
  Sign in with Apple IdP; mitigated by hardening the live resources. A true dev/prod
  split is tracked as post-launch debt.
- **App Store:** prepared for submission (privacy nutrition label, Sign in with
  Apple, account deletion, export compliance).

---

## Tech stack

**Mobile:** Flutter, Dart, Riverpod, go_router, Drift (SQLite), SQLCipher,
flutter_secure_storage, local_auth (Face ID), flutter_local_notifications,
workmanager, sign_in_with_apple, Sentry.
**Backend:** AWS Cognito, API Gateway (REST), Lambda, DynamoDB, WAF, IAM, CloudWatch.
**Tooling:** Codemagic CI/CD, dart obfuscation + symbolication, i18n (en/tr/de).

