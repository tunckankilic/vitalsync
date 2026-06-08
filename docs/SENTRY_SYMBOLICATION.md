# Sentry Release Symbolication

Release builds are compiled with **Dart obfuscation**, so an uncaught crash
arrives in Sentry as meaningless symbols (`ce`, `a8`, hex offsets) instead of
real class/method names. To get readable stack traces we must:

1. build with `--obfuscate --split-debug-info=build/symbols`, and
2. upload the generated symbol files (plus the iOS dSYMs) to Sentry.

Sentry matches an obfuscated frame to its symbol file by the **debug-image
UUID** embedded in both the binary and the symbol file — *not* by release/dist.
So the only hard requirement for deobfuscation is "build with split-debug-info,
then upload those exact symbol files".

The upload is handled by [`sentry_dart_plugin`](https://pub.dev/packages/sentry_dart_plugin),
configured in the `sentry:` block of [`pubspec.yaml`](../pubspec.yaml).

---

## Secrets — never commit these

The plugin reads all credentials from the **environment**. Nothing below goes
into a tracked file.

| Variable | Purpose | Where it comes from |
| --- | --- | --- |
| `SENTRY_AUTH_TOKEN` | Auth token with `project:releases` + `org:read` scope | Sentry → Settings → Auth Tokens. Locally: shell/`.env` (git-ignored). CI: Codemagic `sentry_credentials` group (secret) |
| `SENTRY_ORG` | Organization slug | Sentry org settings |
| `SENTRY_PROJECT` | Project slug | Sentry project settings |
| `SENTRY_DSN` | Crash-reporting DSN (passed to the build via `--dart-define`) | Sentry project → Client Keys (DSN) |

`release` and `dist` are **auto-detected** by `sentry_flutter` from the native
build (`bundleId@CFBundleShortVersionString+CFBundleVersion` / `CFBundleVersion`),
so the value reported by the running app always matches the binary whose symbols
were uploaded. There is nothing to set by hand.

---

## Local build + upload

```bash
# 1. Build a release IPA with obfuscation and symbol output.
flutter build ipa \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define=ENV=prod \
  --dart-define=SENTRY_DSN="$SENTRY_DSN"

# 2. Provide the upload credentials (do NOT hardcode — export from your shell
#    profile or a git-ignored .env you `source`).
export SENTRY_ORG=<your-org-slug>
export SENTRY_PROJECT=<your-project-slug>
export SENTRY_AUTH_TOKEN=<token>

# 3. Upload obfuscation symbols (build/symbols) + iOS dSYMs to Sentry.
dart run sentry_dart_plugin
```

The same flags work for Android (`flutter build appbundle ...`); the plugin
picks up `build/symbols` for both platforms.

---

## CI (Codemagic)

The `ios-release` workflow in [`codemagic.yaml`](../codemagic.yaml) already does
both steps:

- the **Build iOS** step adds `--obfuscate --split-debug-info=build/symbols`
  and the `--dart-define`s;
- the **Upload symbols to Sentry** step runs `dart run sentry_dart_plugin`.

Define `SENTRY_DSN`, `SENTRY_ORG`, `SENTRY_PROJECT`, and `SENTRY_AUTH_TOKEN` as
**secret** variables in the Codemagic environment group `sentry_credentials`.
If `SENTRY_AUTH_TOKEN` is absent the upload step logs a skip and the build still
succeeds.

---

## Verifying deobfuscation on a real device

You need a genuine **release** build (debug builds aren't obfuscated, so they'd
"work" for the wrong reason).

1. **Add a deliberate test crash.** Temporarily wire a button (e.g. on the
   settings screen) to throw:

   ```dart
   onPressed: () => throw StateError('Sentry symbolication smoke test');
   ```

   An uncaught throw is routed through `PlatformDispatcher.onError` /
   `FlutterError.onError` → Sentry (see [`lib/main.dart`](../lib/main.dart)).

2. **Build + install the release build on a physical device** with the prod DSN:

   ```bash
   flutter build ipa \
     --release --obfuscate --split-debug-info=build/symbols \
     --dart-define=ENV=prod --dart-define=SENTRY_DSN="$SENTRY_DSN"
   ```

   Install the IPA (TestFlight, or `flutter install --release` for a tethered
   device).

3. **Upload the symbols** for that exact build:

   ```bash
   export SENTRY_ORG=... SENTRY_PROJECT=... SENTRY_AUTH_TOKEN=...
   dart run sentry_dart_plugin
   ```

   Confirm the log shows the iOS dSYM(s) and the Dart symbol file uploading
   without error. (You can also check Sentry → Settings → Debug Files.)

4. **Trigger the crash** by tapping the test button on the device.

5. **Open the event in Sentry.** Within a minute or two the issue should show:
   - the real exception type and message (`StateError: Sentry symbolication
     smoke test`);
   - a stack trace with **readable Dart frames** (real file/function names, not
     hex/obfuscated symbols);
   - `environment: prod` and a `release` of `…@1.0.0+<build>`.

   If frames are still obfuscated, the symbols for that build's debug-image UUID
   weren't uploaded — re-run step 3 against the same binary (a rebuild changes
   the UUID).

6. **Remove the test-crash code** before merging.
