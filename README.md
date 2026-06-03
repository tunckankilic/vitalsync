<div align="center">

# 🩺 VitalSync

### Health & Fitness Companion — with a cross-domain insight engine

A production-grade Flutter application that unifies **medication management**, **symptom tracking**, and **workout logging** into a single experience — then analyzes them *together* to surface personalized, actionable insights.

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![AWS Amplify](https://img.shields.io/badge/AWS-Amplify-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/amplify/)
[![Platform](https://img.shields.io/badge/Platform-iOS-000000?logo=apple&logoColor=white)](https://www.apple.com/ios/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-success)](#-architecture)
[![Analyzer](https://img.shields.io/badge/flutter%20analyze-0%20issues-brightgreen)](#)
[![Tests](https://img.shields.io/badge/tests-95%20passing-brightgreen)](#-testing)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [The Differentiator: InsightEngine](#-the-differentiator-insightengine)
- [Key Features](#-key-features)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Backend Architecture (AWS)](#-backend-architecture-aws)
- [Offline-First Sync](#-offline-first-sync)
- [Tech Stack & Rationale](#-tech-stack--rationale)
- [Data Model](#-data-model)
- [Security & Privacy](#-security--privacy)
- [Observability](#-observability)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Testing](#-testing)
- [Roadmap](#-roadmap)
- [License](#-license)

---

## 🎯 Overview

Most health apps treat *medication*, *symptoms*, and *fitness* as isolated silos. **VitalSync's premise is that the value lives in the correlations between them** — e.g. *"Your symptom severity drops on weeks where you maintain a workout streak"* or *"Medication adherence is 23% lower on weekends."*

VitalSync is built as a **real product**, not a tutorial demo:

- **Offline-first** — full functionality without a network; changes sync when connectivity returns.
- **Privacy by design** — local database is encrypted at rest (SQLCipher / AES-256); GDPR consent, data export, and a Privacy Manifest are first-class.
- **Cloud-backed** — AWS Cognito auth (incl. Sign in with Apple) and a serverless sync backend.
- **Observable** — global crash & async-error reporting via Sentry, wired so production failures are never silent.
- **Build-time environments** — a single `--dart-define=ENV=dev|prod` switch selects the backend; no file edits to ship a prod build.
- **Localized** — English, Turkish, and German out of the box.

> **Scale:** ~40K hand-written lines of Dart across 240+ files, 15 database tables, 34 screens, 3 feature modules, and a rule-based analytics engine — **with `flutter analyze` reporting 0 issues.**

---

## 💡 The Differentiator: InsightEngine

The heart of VitalSync is a **rule-based, cross-module analytics engine** written in pure Dart — no external ML dependencies, fully testable, and fully explainable.

It runs **10 correlation rules** across health and fitness data, each with minimum-sample-size guards and duplicate-prevention logic:

| Rule | What it detects |
|------|-----------------|
| `med_workout_correlation` | Relationship between medication adherence and workout activity |
| `symptom_exercise_pattern` | How exercise correlates with symptom occurrence |
| `compliance_streak_correlation` | Whether workout streaks track with medication compliance |
| `compliance_weekday_pattern` | Day-of-week dips in medication adherence |
| `symptom_trend` | Rising/falling symptom severity over time |
| `med_adherence_milestone` | Adherence achievement milestones |
| `volume_plateau` | Training-volume plateaus in fitness |
| `rest_day_suggestion` | Recovery recommendations based on load |
| `workout_consistency` | Consistency scoring and nudges |
| `pr_proximity` | Proximity to personal records |

**Why rule-based instead of ML?** Health recommendations must be *explainable* and *deterministic* — a user (and a regulator) should be able to understand exactly why a suggestion appeared. The architecture is intentionally pluggable, so an ML/LLM layer can be added later (see [Roadmap](#-roadmap)) without rewriting the domain.

> 📄 See [`lib/features/insights/domain/insight_engine.dart`](lib/features/insights/domain/insight_engine.dart) and its [test suite](test/features/insights/domain/insight_engine_test.dart).

---

## ✨ Key Features

### 🏥 Health
- **Medication management** — schedules, dosages, and reminders via local notifications.
- **Adherence logging** — taken / skipped / missed status tracking with history.
- **Symptom tracking** — severity logging and a unified health timeline.

### 💪 Fitness
- **Workout logging** — sessions, sets, reps, and weights with a live active-workout screen.
- **Exercise library** & **reusable templates**.
- **Progress analytics** — volume charts, personal records, streaks, and achievements.

### 📊 Insights
- **Cross-module insights** generated by the [InsightEngine](#-the-differentiator-insightengine).
- **Weekly reports** summarizing health + fitness in one view.
- Prioritized, categorized, and time-bounded insight cards.

### 🧩 Platform
- **Unified dashboard** with a context-aware Floating Action Button.
- **Glassmorphic UI** with Material You dynamic theming.
- **Real-time sync indicator** (Online / Offline / Syncing).
- **Biometric lock** (Face ID / Touch ID).
- **Onboarding** + **GDPR consent** flows.
- **Localization** — EN / TR / DE.

---

## 📸 Screenshots

> Drop the images at the paths below (suggested: `docs/images/`) and they will
> render automatically — no further README edits needed. Recommended set:
> Dashboard, an Insight card, Active Workout, and the Weekly Report.

| Dashboard | Insights | Active Workout | Weekly Report |
|:---:|:---:|:---:|:---:|
| ![Dashboard](docs/images/dashboard.png) | ![Insights](docs/images/insights.png) | ![Active Workout](docs/images/active_workout.png) | ![Weekly Report](docs/images/weekly_report.png) |

---

## 🏗 Architecture

VitalSync follows **Clean Architecture** with a **feature-first** organization. Each feature (`health`, `fitness`, `insights`) is split into `domain` and `presentation`, while cross-cutting concerns live in `core` and the data layer is shared.

```mermaid
flowchart TB
    subgraph Presentation["🎨 Presentation Layer"]
        UI["Screens & Widgets"]
        VM["Riverpod Providers / Notifiers"]
    end

    subgraph Domain["🧠 Domain Layer"]
        E["Entities"]
        RI["Repository Interfaces"]
        IE["InsightEngine (business rules)"]
    end

    subgraph Data["💾 Data Layer"]
        RImpl["Repository Implementations"]
        Local["Drift + SQLCipher (local)"]
        Remote["Amplify REST Client (remote)"]
        Queue["Sync Queue"]
    end

    UI --> VM
    VM --> RI
    IE --> RI
    RI -.implemented by.-> RImpl
    RImpl --> Local
    RImpl --> Queue
    Queue --> Remote

    classDef pres fill:#e3f2fd,stroke:#1976d2,color:#0d47a1
    classDef dom fill:#f3e5f5,stroke:#7b1fa2,color:#4a148c
    classDef dat fill:#e8f5e9,stroke:#388e3c,color:#1b5e20
    class UI,VM pres
    class E,RI,IE dom
    class RImpl,Local,Remote,Queue dat
```

**Principles applied**

- **Dependency Rule** — domain depends on nothing; data and presentation depend inward.
- **Dependency Injection** — `get_it` + `injectable` wire implementations to interfaces.
- **Single source of truth** — the local Drift database; the cloud is a sync target, not the primary read path (offline-first).
- **Testability** — repositories are mocked (`mocktail`) so domain logic is unit-tested in isolation.

---

## ☁️ Backend Architecture (AWS)

The backend is **serverless**, provisioned via **AWS Amplify**, and hosted in **`eu-central-1` (Frankfurt)** for EU data residency.

```mermaid
flowchart LR
    App["📱 VitalSync<br/>(Flutter / iOS)"]

    subgraph AWS["AWS — eu-central-1"]
        Cognito["🔐 Cognito<br/>User Pool + Identity Pool<br/>(Sign in with Apple)"]
        APIGW["🚪 API Gateway<br/>REST · AWS_IAM auth"]
        Lambda["⚡ Lambda<br/>Sync business logic"]
        Dynamo["🗄 DynamoDB<br/>Single-table design"]
        Pinpoint["📊 Pinpoint<br/>Analytics + Push"]
    end

    App -- "auth (SRP / OIDC)" --> Cognito
    App -- "IAM-signed requests" --> APIGW
    Cognito -. "temporary IAM creds" .-> App
    APIGW --> Lambda --> Dynamo
    App -- "events / push tokens" --> Pinpoint

    classDef aws fill:#fff3e0,stroke:#f57c00,color:#e65100
    class Cognito,APIGW,Lambda,Dynamo,Pinpoint aws
```

| Service | Role |
|---------|------|
| **Cognito** | Authentication (email/password via SRP, **Sign in with Apple** via OIDC federation) and temporary IAM credentials |
| **API Gateway** | REST entry point secured with `AWS_IAM` (requests are SigV4-signed with the user's Cognito credentials) |
| **Lambda** | Serverless sync/business logic |
| **DynamoDB** | Single-table design (`PK` / `SK`) for user-scoped records |
| **Pinpoint** | Product analytics and push-notification delivery |

> **Why IAM auth on the API?** Each request is signed with the authenticated user's short-lived AWS credentials, so authorization is enforced at the AWS layer — no bearer tokens to leak, and per-user data isolation can be expressed directly in IAM policies.

**Backend hardening** (see [`docs/AWS_HARDENING.md`](docs/AWS_HARDENING.md) for apply/verify/rollback commands):

- **DynamoDB Point-in-Time Recovery** — enabled on the data table (35-day restore window) to protect health data against accidental writes/deletes.
- **API Gateway throttling** — the `dev` stage is capped at 50 rps / 100 burst (down from the account default of 10 000 / 5 000), limiting abuse without affecting normal sync.
- **Cognito Threat Protection** — *planned* (see [Roadmap](#-roadmap)); deferred because it requires the paid `PLUS` user-pool tier.

---

## 🔄 Offline-First Sync

VitalSync is designed to be **fully usable with no connection**. The local encrypted database is the source of truth; the cloud is reconciled opportunistically.

```mermaid
sequenceDiagram
    participant U as User
    participant DB as Local DB (Drift)
    participant Q as Sync Queue
    participant N as Connectivity
    participant API as AWS (API Gateway → Lambda → DynamoDB)

    U->>DB: Create / update record
    DB-->>U: Instant UI update (optimistic)
    DB->>Q: Enqueue change
    N-->>Q: Connectivity restored
    Q->>API: Flush pending changes (IAM-signed)
    API-->>Q: Ack
    Q->>DB: Mark synced
    Note over U,API: A live indicator reflects Online / Offline / Syncing
```

- Writes apply **locally first** for an instant, optimistic UI.
- A dedicated **`sync_queue`** table durably tracks pending changes.
- `connectivity_plus` triggers a flush when the network returns.
- Background reconciliation runs via `workmanager`.

---

## 🛠 Tech Stack & Rationale

Every dependency was a deliberate choice — here's the *why*, not just the *what*.

| Concern | Choice | Why this one |
|---------|--------|--------------|
| **State management** | [Riverpod](https://riverpod.dev) | Compile-safe, testable, no `BuildContext` coupling; scales cleanly with code-gen. |
| **Navigation** | [GoRouter](https://pub.dev/packages/go_router) | Declarative, deep-link friendly, auth-redirect guards. |
| **Local DB** | [Drift](https://drift.simonbinder.eu) | Type-safe, compile-checked SQL with reactive streams — ideal for an offline-first source of truth. |
| **Encryption at rest** | [SQLCipher](https://pub.dev/packages/sqlcipher_flutter_libs) | Transparent AES-256 on the SQLite file — health data is never stored in plaintext. |
| **DI** | [get_it](https://pub.dev/packages/get_it) + [injectable](https://pub.dev/packages/injectable) | Decouples interfaces from implementations; keeps the domain layer pure. |
| **Backend** | [AWS Amplify](https://aws.amazon.com/amplify/) | Managed Cognito + serverless stack with EU data residency. |
| **Auth** | Cognito + [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) | Required for iOS social login; OIDC-federated into Cognito. |
| **Secure storage** | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | Keychain-backed storage for the DB key and secrets. |
| **Biometrics** | [local_auth](https://pub.dev/packages/local_auth) | Face ID / Touch ID app lock. |
| **Charts** | [fl_chart](https://pub.dev/packages/fl_chart) | Customizable progress and trend visualizations. |
| **Background work** | [workmanager](https://pub.dev/packages/workmanager) | Periodic sync + reminder scheduling. |
| **Notifications** | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | Timezone-aware medication reminders. |
| **Theming** | [dynamic_color](https://pub.dev/packages/dynamic_color) | Material You dynamic palettes. |

---

## 🗃 Data Model

A normalized local schema across 15 Drift tables, grouped by domain:

**Health**
`medications` · `medication_logs` · `symptoms`

**Fitness**
`exercises` · `workout_templates` · `template_exercises` · `workout_sessions` · `workout_sets` · `personal_records` · `achievements` · `user_stats`

**Insights**
`generated_insights`

**Shared / Platform**
`user_profiles` · `sync_queue` · `gdpr_consent_logs`

Repositories sit behind interfaces in `domain/repositories/`, keeping persistence details out of business logic.

---

## 🔒 Security & Privacy

Health data demands a higher bar — VitalSync treats privacy as a feature:

- **🔐 Encryption at rest** — SQLCipher (AES-256) on the entire local database.
- **🗝 Secret management** — DB key & tokens in the iOS Keychain via `flutter_secure_storage`.
- **👆 Biometric app lock** — Face ID / Touch ID gate.
- **🛡 IAM-authorized API** — SigV4-signed requests; no long-lived bearer tokens.
- **🌍 EU data residency** — all cloud resources in `eu-central-1`.
- **📜 GDPR** — explicit consent flow, consent audit log, and **data export** (Right to Data Portability, Art. 20).
- **🍎 Privacy Manifest** — `PrivacyInfo.xcprivacy` declares all collected data types and accessed-API reasons; `NSPrivacyTracking = false`.
- **🚫 No plaintext logging** — structured logging via `logger`; zero `print()` statements in the codebase.
- **🧹 Config hygiene** — backend configs (`amplifyconfiguration.dart`, prod variant, `team-provider-info.json`) are git-ignored; only placeholder `.example` templates are committed.

> **Note on `amplify/team-provider-info.json`.** This file was previously tracked
> in git. It carries no credentials — only infrastructure *identifiers* (AWS
> account id via ARNs, IAM role ARNs, the deployment S3 bucket, the
> CloudFormation stack id, the Amplify App id). It has been removed from
> tracking and added to `.gitignore`, and the file still lives on disk so local
> Amplify keeps working.
>
> Git history was **intentionally not rewritten.** The repo is public, so those
> identifiers were already exposed and likely mirrored/indexed — a rewrite
> cannot un-expose them, and force-rewriting public history would invalidate
> every clone, fork and open PR for little real gain. Since ARNs and account ids
> are identifiers rather than secrets, the actual security boundary is IAM
> least-privilege and resource (S3/bucket) policies, which are hardened on the
> AWS side rather than by hiding identifiers. The AWS account id itself cannot
> be rotated.

---

## 📡 Observability

For health data, an unseen crash is the biggest risk — it can corrupt user data
silently. VitalSync reports failures to **[Sentry](https://sentry.io)** so they
are never invisible in production:

- **Crash reporting** — `sentry_flutter` is initialized in `main.dart` and the
  app bootstrap runs inside its guarded zone (`appRunner`).
- **Global error handling** — both synchronous Flutter errors
  (`FlutterError.onError`) and uncaught asynchronous errors
  (`PlatformDispatcher.onError`) are forwarded to Sentry, while the existing
  init-error flow (splash error surfacing, graceful degradation of non-critical
  services) is preserved.
- **No secrets in source** — the DSN is supplied at build time via
  `--dart-define=SENTRY_DSN`. When empty (local/dev), Sentry is skipped so there
  is no noise and the app behaves exactly as before.

---

## 📁 Project Structure

```
lib/
├── core/                      # Cross-cutting concerns
│   ├── auth/                  # Auth state & guards
│   ├── di/                    # Dependency injection setup
│   ├── errors/                # Custom exception types
│   ├── gdpr/                  # Consent & data-export manager
│   ├── network/               # Connectivity & REST client
│   ├── notifications/         # Local notification service
│   ├── router/                # GoRouter configuration
│   ├── sync/                  # Sync orchestration
│   ├── theme/                 # Material You theming
│   └── l10n/                  # Localizations (EN/TR/DE)
│
├── domain/                    # Pure business layer
│   ├── entities/              # Domain models
│   └── repositories/          # Repository interfaces
│
├── data/                      # Implementation layer
│   ├── local/                 # Drift database, tables, seed data
│   ├── models/                # DTOs / mappers
│   └── repositories/          # Repository implementations
│
├── features/                  # Feature-first modules
│   ├── health/                # Medications & symptoms
│   ├── fitness/               # Workouts & progress
│   └── insights/              # InsightEngine + reports
│
└── presentation/              # App shell, auth, dashboard, profile, settings
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter **3.10.7+** / Dart **3.10.7+**
- Xcode (iOS) with a configured signing team
- An [AWS Amplify](https://docs.amplify.aws/) environment (for backend features)

### Installation

```bash
# 1. Clone
git clone <repository-url>
cd vitalsync

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift, Riverpod, injectable, JSON)
dart run build_runner build --delete-conflicting-outputs

# 4. Run (physical device recommended for biometrics & Material You)
#    ENV selects the backend at build time; it defaults to dev.
flutter run --dart-define=ENV=dev

# Production build (prod backend + Sentry crash reporting):
flutter run --dart-define=ENV=prod --dart-define=SENTRY_DSN=<your_sentry_dsn>
```

> **Environments:** the dev/prod backend is chosen at build time via
> `--dart-define=ENV` — no file edits required, and an omitted/unknown value
> safely falls back to `dev`. See [`docs/ENVIRONMENTS.md`](docs/ENVIRONMENTS.md)
> for the full command reference and config-file setup.
>
> **Backend note:** Amplify configs are environment-specific and git-ignored
> (only `.example` templates are committed). Provision your own Amplify
> environment (`amplify env add`) and push (`amplify push`) to generate a
> matching `lib/amplifyconfiguration.dart`.

---

## 🧪 Testing

```bash
flutter test
```

**95 tests passing.** The suite spans the highest-value logic — the
**InsightEngine**, repository implementations, **bidirectional sync**,
**authentication flows**, **sync failure & conflict paths**, and
**critical-screen widget tests** — using `mocktail` for dependency isolation
(no new test dependencies).

```
test/
├── core/auth/auth_notifier_test.dart                 # sign-in/up/Apple/out + failure paths
├── core/sync/sync_service_test.dart                  # guards, push/pull conflict, retry, batch limit, re-entrancy
├── features/insights/domain/insight_engine_test.dart
├── features/health/domain/services/medication_reminder_service_test.dart
├── features/fitness/presentation/providers/workout_notifier_test.dart
├── data/repositories/health/medication_log_repository_impl_test.dart
├── data/repositories/fitness/workout_session_repository_impl_test.dart
├── data/repositories/fitness/streak_repository_impl_test.dart
├── presentation/screens/auth/register_screen_test.dart          # widget: form + validation + failure
├── presentation/screens/auth/forgot_password_screen_test.dart   # widget: reset form + validation + failure
├── presentation/screens/gdpr/consent_screen_test.dart           # widget: GDPR consent gate
├── widget_test.dart                                              # widget: login screen
└── support/pump_app.dart                                         # shared widget-test harness
```

- **Auth flow** — sign-in / sign-up / Sign in with Apple / sign-out / reset, each with happy *and* failure paths.
- **Bidirectional sync** — offline / no-consent / unauthenticated guards; **conflict resolution** on both the push *and* pull sides (last-write-wins via `lastModifiedAt`); **retry** marking and partial-batch resilience on failure; batch rate-limiting; and a **re-entrancy guard** that skips overlapping syncs.
- **Critical-screen widget tests** — Login, Register, Forgot Password, and the GDPR consent gate (rendering, form validation, failure handling).

Static analysis is clean: **`flutter analyze` → 0 issues.**

---

## 🗺 Roadmap

- [x] **Crash & async-error observability** — Sentry crash reporting with global error handling (see [Observability](#-observability)).
- [x] **Auth, sync & widget test coverage** — auth flows, bidirectional sync (push/pull conflict, retry, batch limit, re-entrancy), and critical-screen widget tests.
- [ ] **Cognito Threat Protection** — compromised-credential / adaptive-auth detection; deferred pending the paid `PLUS` user-pool tier (see [`docs/AWS_HARDENING.md`](docs/AWS_HARDENING.md)).
- [ ] **AI-assisted insights** — pluggable LLM layer (AWS Bedrock / Claude) for natural-language data entry and visit summaries, layered on top of the existing rule engine.
- [ ] Performance tracing & release-health monitoring.
- [ ] Integration / end-to-end test coverage.
- [ ] Wearable / HealthKit data import.
- [ ] Android release.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with Flutter & AWS** — a demonstration of clean architecture, offline-first design, and privacy-conscious health data handling.

</div>
