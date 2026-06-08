# VitalSync — Privacy Policy (DRAFT)

> ⚠️ **DRAFT — NOT LEGAL ADVICE.** This text is an engineering-supplied starting
> point describing what the app *technically* does with data. It has **not** been
> reviewed by a lawyer. Before publishing it at
> `https://tunckankilic.github.io/vitalsync/privacy.html` (the URL the app links
> to via `AppConstants.privacyPolicyUrl`), it **must** be reviewed and approved by
> qualified legal counsel for GDPR, Apple App Store, and any applicable
> health-data regulations (e.g. HIPAA-adjacent expectations, national health-data
> laws). Verify every factual claim below against the actual deployed backend.

**Last updated:** _<fill in on publish>_
**Effective version:** corresponds to `AppConstants.gdprPolicyVersion` (currently `1.0.0`)

---

## 1. Who we are

VitalSync ("the app", "we") is a health & fitness companion application. For
privacy questions or to exercise your rights, contact us at:
**_<support email — fill in>_**.

> _Legal review: identify the actual data controller (individual/company name and
> address) as required by GDPR Art. 13(1)(a)._

## 2. What data we collect

The app is **offline-first**: your data is created and stored on your device
first, then optionally synchronized to the cloud.

**Health & fitness data you enter:**
- Medication names, schedules, and reminder/adherence logs
- Symptoms and symptom-tracking entries
- Workout and exercise logs
- Body metrics and progress data
- Cross-module insights derived from the above

**Account data:**
- Authentication identifiers managed by AWS Cognito (e.g. email address; or an
  Apple Relay address if you use Sign in with Apple)

**Consent records:**
- Your GDPR consent choices and the policy version you accepted (stored in an
  on-device consent log)

**Optional analytics (only if you enable it):**
- Usage/diagnostic data, collected **only** when you turn on the "Analytics"
  consent toggle. Off by default.

> _Verify against the codebase before publishing: confirm exactly which fields are
> stored and whether any device identifiers are collected._

## 3. Why we use it (purposes)

- To provide core features: reminders, tracking, logging, and insights
- To synchronize your data across your devices (only if cloud backup is enabled)
- To authenticate you and secure your account
- To improve the app (only with analytics consent)

We do **not** sell your personal data. We do **not** use your health data for
advertising.

## 4. Legal basis (GDPR)

- **Consent** (Art. 6(1)(a) and, for health data, Art. 9(2)(a)) for processing
  health/fitness data and for optional analytics.
- **Contract** (Art. 6(1)(b)) for providing the account and core service.

> _Legal review required: health data is a "special category" under GDPR Art. 9.
> Confirm the lawful basis and that explicit consent is correctly obtained and
> recorded._

## 5. Where your data is stored & third parties

- **On your device:** stored locally in an encrypted database (SQLCipher) and in
  secure storage for credentials.
- **In the cloud (only if you enable cloud backup/sync):** processed and stored on
  **Amazon Web Services (AWS)** infrastructure, including:
  - **AWS Cognito** — authentication
  - **AWS DynamoDB** — synchronized records
  - **AWS API Gateway** — API access
  - **AWS S3** — file/object storage (if used)

AWS acts as our **data processor**. Data may be processed in the AWS region the
backend is deployed to.

> _Fill in: the actual AWS region(s), and whether data leaves the EU/EEA. If it
> does, document the transfer safeguards (e.g. Standard Contractual Clauses).
> Confirm crash reports are sent to Sentry and list Sentry as a processor if so._

## 6. Crash reporting

If enabled for the build, uncaught errors are sent to **Sentry** for diagnostics.
These reports may include technical details (stack traces, device/OS info) and
should not contain your health entries.

> _Verify what the Sentry payload actually contains and whether it can include
> personal data; if so, disclose it and add Sentry to the processor list._

## 7. Data retention

- **On-device data** is kept until you delete it or uninstall the app.
- **Cloud data** is kept until you delete your account or request deletion.

> _Define concrete retention periods and backup-deletion timelines with legal._

## 8. Your rights

Under GDPR you have the right to: access, rectification, erasure ("right to be
forgotten"), restriction, data portability, and to withdraw consent at any time.

In the app:
- **Manage consents:** Settings → Privacy & Data → Manage Consents
- **Export your data:** Settings → Privacy & Data → Export Data
- **Delete your account/data:** Settings → Privacy & Data → Delete Account

Withdrawing consent does not affect processing done before withdrawal.

## 9. Deletion

When you request account deletion, we delete your cloud-stored personal data and
your account. Local data is removed when you delete it in-app or uninstall.

> _Document the actual deletion flow and timeline (including backups) once the
> server-side deletion path is confirmed._

## 10. Children

The app is not intended for children below the age required by your local law
without appropriate consent.

> _Set the minimum age and confirm compliance (e.g. GDPR Art. 8)._

## 11. Changes to this policy

We may update this policy. Material changes will be reflected by a new policy
version, and you may be asked to re-consent.

## 12. Contact

_<data controller name, address, and contact email — fill in>_

---

### Engineering notes (remove before publishing)

- The app links to this content at `AppConstants.privacyPolicyUrl`
  (`privacy.html`). `termsOfServiceUrl` (`terms.html`) and `supportUrl`
  (`support.html`) are also linked from **Settings → Privacy & Data** and must be
  published too, or those links will 404.
- Keep `AppConstants.gdprPolicyVersion` in sync with the "Effective version" here;
  bump it when the policy materially changes so re-consent can be triggered.
