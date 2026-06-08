# Environments (dev / prod)

VitalSync selects its backend configuration **at build time** via the
`--dart-define=ENV` flag. There is no longer any need to hand-edit
`amplifyconfiguration.dart` to switch environments, which used to risk shipping
a production build wired to development resources.

The switch is implemented in [`lib/core/config/app_environment.dart`](../lib/core/config/app_environment.dart).

## How it works

| `--dart-define=ENV` | Amplify config loaded | Source file |
| ------------------- | --------------------- | ----------- |
| `dev` (or omitted)  | `amplifyconfig`       | `lib/amplifyconfiguration.dart` |
| `prod`              | `amplifyconfigProd`   | `lib/amplifyconfiguration_prod.dart` |

- **Default is `dev`.** If `ENV` is absent or unrecognized, the app falls back
  to `dev` — never to prod. So a forgotten flag can never accidentally target
  production.
- The Sentry DSN is read from `--dart-define=SENTRY_DSN`. When empty, crash
  reporting is disabled (see `main.dart`). Pass the **prod** DSN for prod builds.

## Commands

### Development (default)
```bash
flutter run --dart-define=ENV=dev
# ENV may be omitted entirely — dev is the safe default:
flutter run
```

### Production
```bash
flutter run   --dart-define=ENV=prod --dart-define=SENTRY_DSN=<PROD_SENTRY_DSN>
flutter build apk      --dart-define=ENV=prod --dart-define=SENTRY_DSN=<PROD_SENTRY_DSN>
flutter build ipa      --dart-define=ENV=prod --dart-define=SENTRY_DSN=<PROD_SENTRY_DSN>
flutter build appbundle --dart-define=ENV=prod --dart-define=SENTRY_DSN=<PROD_SENTRY_DSN>
```

> Tip: keep the repeated defines in a `--dart-define-from-file=env.json` file
> (git-ignored) if you prefer not to type them each time.

> Release builds are obfuscated. To get readable crash stacks in Sentry you must
> also build with `--obfuscate --split-debug-info=build/symbols` and upload the
> symbols — see [`SENTRY_SYMBOLICATION.md`](./SENTRY_SYMBOLICATION.md).

## Configuration files & secrets

Real backend values **never** enter the repository. Only placeholder
`.example` templates are committed.

| File | Tracked in git? | Purpose |
| ---- | --------------- | ------- |
| `lib/amplifyconfiguration.dart`          | ❌ ignored (Amplify CLI-generated) | Real **dev** config |
| `lib/amplifyconfiguration.dart.example`  | ✅ committed | Dev placeholder template |
| `lib/amplifyconfiguration_prod.dart`         | ❌ ignored | Real **prod** config |
| `lib/amplifyconfiguration_prod.dart.example` | ✅ committed | Prod placeholder template |

### First-time setup on a fresh clone
1. **Dev:** run the Amplify CLI against the dev environment (`amplify pull`) to
   generate `lib/amplifyconfiguration.dart`, or copy
   `lib/amplifyconfiguration.dart.example` and fill in the real dev values.
2. **Prod:** copy `lib/amplifyconfiguration_prod.dart.example` to
   `lib/amplifyconfiguration_prod.dart` and fill in the real prod values
   (e.g. from `amplify pull --envName prod`).

Both files must exist for the project to compile, because
`app_environment.dart` references each environment's config constant.
