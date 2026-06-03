# Production-Readiness Sprint — Work Log

A record of the engineering work that took VitalSync from "functional" to
production-grade. Each item below was delivered as its own commit with
`flutter analyze` at **0 issues** and the test suite green as the completion
gate. (Commit hashes are intentionally omitted — git history was later
sanitized to remove leaked infrastructure identifiers, which rewrote hashes;
the work and its ordering are unchanged.)

---

## 1. Crash reporting & global error handling
- Added `sentry_flutter`; app bootstrap runs inside `SentryFlutter.init`'s
  guarded zone (`appRunner`).
- Synchronous (`FlutterError.onError`) and uncaught async
  (`PlatformDispatcher.onError`) errors are forwarded to Sentry.
- DSN read from `--dart-define=SENTRY_DSN`; empty → Sentry skipped (no local
  noise). The existing init-error/splash flow and graceful degradation were
  preserved, not replaced.
- **Why:** health data + a silent crash is the worst-case risk; observability
  comes first.

## 2. Build-time dev/prod environment switch
- Introduced `lib/core/config/app_environment.dart` driven by
  `--dart-define=ENV=dev|prod`; selects the Amplify config and the Sentry DSN.
- Defaults to `dev`; an unknown/missing value falls back to `dev` (never prod).
- Real backend configs stay git-ignored; only `.example` templates are
  committed. Documented in `docs/ENVIRONMENTS.md`.
- **Why:** removes the "hand-edit a file to switch environments" footgun.

## 3. Secret hygiene (git)
- Stopped tracking `amplify/team-provider-info.json` (kept on disk) and added
  it to `.gitignore`; it carried infra identifiers (account id via ARNs, IAM
  role ARNs, deployment bucket, CloudFormation stack id, Amplify App id).
- Decision recorded transparently in the README.
- **Why:** keep an infra recon surface out of a public repo.

## 4. Test coverage
- Auth flows (sign-in / sign-up / Apple / sign-out / reset) — happy + failure
  paths via `ProviderContainer` + mocked `AuthRepository`.
- Sync failure paths — offline / consent / unauthenticated guards, timestamp
  conflict resolution, and retry-on-failure marking.
- Critical-screen widget tests — Login, Register, GDPR consent gate.
- Fixed a pre-existing flaky InsightEngine test (argument-based stubbing) and
  replaced the stale counter template; **production logic untouched**.
- Result: **84 tests passing**, `flutter analyze` 0.

## 5. AWS backend hardening (live)
Applied directly to the live backend and recorded with apply/verify/rollback in
`docs/AWS_HARDENING.md`:
- **DynamoDB** — Point-in-Time Recovery enabled; deletion protection enabled.
- **API Gateway** — `dev` stage throttling (50 rps / 100 burst); CloudWatch
  metrics + ERROR-level execution logging (no payload tracing → no PHI in logs).
- **Lambda** — 30-day CloudWatch log retention.
- **Cognito Threat Protection** — deferred (requires the paid `PLUS` tier);
  documented as a roadmap item.
- **Why:** data durability + abuse protection + server-side visibility, scoped
  only to VitalSync resources.

## 6. README aligned with reality
- Added an Observability section, backend-hardening notes, the `--dart-define`
  build commands, the real test tree, and an updated roadmap.
- Every technical claim is verifiable in the repo. Screenshot placeholders
  under `docs/images/`.

---

## Post-sprint: history sanitization
Before open-sourcing, git history was rewritten (`git filter-repo`) to remove
the previously-tracked `team-provider-info.json` and to redact infrastructure
identifiers from earlier commits. No credentials were ever committed (verified
by a full-history scan: no access keys, private keys, tokens, or DSNs); the
removed values were identifiers only. The real contribution timeline (author
dates) was preserved.
