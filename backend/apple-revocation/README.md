# Apple token revocation service

Backend for **App Store Guideline 5.1.1(v)**: an app offering *Sign in with
Apple* **and** account deletion must revoke the user's Apple token on deletion.

The app cannot revoke on its own — that requires Apple's private signing key,
which must never ship in the app bundle. So the app sends a short-lived,
single-use Apple **authorization code** to this endpoint, which:

1. builds an ES256 `client_secret` JWT (signed with the Apple `.p8` key),
2. exchanges the code for a refresh token at `POST /auth/token`,
3. revokes that token at `POST /auth/revoke`.

The endpoint is an **HTTP API** protected by a **Cognito JWT authorizer**, so
only signed-in app users can call it.

> **Security.** The Apple `.p8` private key lives **only** in AWS Secrets
> Manager and is read at runtime. Team ID / Key ID / client_id are Lambda env
> config. Nothing secret is committed to git or shipped in the app.

---

## Prerequisites

- **AWS CLI** configured for the account/region that hosts the Cognito pool.
- **AWS SAM CLI** — `brew install aws-sam-cli`.
- The **Sign in with Apple `.p8`** key file, its **Key ID**, your **Team ID**,
  the app **bundle identifier**, and the Cognito **User Pool ID** +
  **app client id**.

Deploy in the **same region as the Cognito user pool** (the JWT issuer is
derived from the stack region).

---

## Step 1 — store the `.p8` in Secrets Manager

Create the secret directly from the key file (handles the multi-line PEM
cleanly — no copy/paste):

```bash
aws secretsmanager create-secret \
  --name vitalsync/apple-siwa-key \
  --secret-string file:///absolute/path/to/AuthKey_XXXXXXXXXX.p8 \
  --region <AWS_REGION>
```

Copy the returned `ARN` — it is the `AppleKeySecretArn` parameter below.

## Step 2 — build & deploy

```bash
cd backend/apple-revocation
sam build
sam deploy --guided \
  --region <AWS_REGION> \
  --parameter-overrides \
    AppleTeamId=<APPLE_TEAM_ID> \
    AppleKeyId=<APPLE_KEY_ID> \
    AppleClientId=<APP_BUNDLE_ID> \
    AppleKeySecretArn=<SECRET_ARN_FROM_STEP_1> \
    CognitoUserPoolId=<COGNITO_USER_POOL_ID> \
    CognitoAppClientId=<COGNITO_APP_CLIENT_ID>
```

`sam deploy --guided` saves your answers to `samconfig.toml` (git-ignored), so
later deploys are just `sam deploy`.

## Step 3 — wire the endpoint into the app

The deploy prints an output **`RevokeEndpoint`** (e.g.
`https://abc123.execute-api.<region>.amazonaws.com/revoke`). Pass it to the app
build as a dart-define (add it in Codemagic alongside the other defines):

```
--dart-define=APPLE_REVOKE_ENDPOINT=https://abc123.execute-api.<region>.amazonaws.com/revoke
```

Without this define the app skips the revoke step entirely (deletion still
works) — so nothing breaks if the backend isn't deployed yet.

---

## Parameters — where each value comes from

| Parameter            | Source                                                              |
| -------------------- | ------------------------------------------------------------------ |
| `AppleTeamId`        | Apple Developer → Membership.                                      |
| `AppleKeyId`         | The Key ID shown for the Sign in with Apple `.p8` key.            |
| `AppleClientId`      | App **bundle identifier** (native code path).                     |
| `AppleKeySecretArn`  | ARN from Step 1.                                                   |
| `CognitoUserPoolId`  | `amplifyconfiguration*.dart` → `CognitoUserPool … PoolId`.        |
| `CognitoAppClientId` | `amplifyconfiguration*.dart` → `CognitoUserPool … AppClientId`.   |

---

## Testing (real device required)

Sign in with Apple is restricted on the simulator — use a physical device and a
real Apple ID.

1. Delete the account in-app. An Apple sheet appears (fresh code) — this is
   expected.
2. In CloudWatch, the Lambda logs a `revoked: true` (200) response.
3. On the device: **Settings → [Apple ID] → Sign in with Apple** — the app
   should no longer be listed.
4. Sign in with Apple again → a fresh consent screen appears and a new,
   empty account is provisioned (old data does not return).

> **client_id nuance.** A code obtained natively is issued to the app **bundle
> id**; the grant the user sees may have been created under a **Service ID**
> (web/Hosted-UI login). If step 3 still lists the app, the visible grant was
> issued to the Service ID — set `AppleClientId` to that Service ID (and use the
> Service ID's code path), or move login fully native so both share one
> client_id. Verify on a real device before release.

## Hardening (post-launch)

- Rotate the `.p8` if it was ever shared outside Secrets Manager.
- Consider tighter throttling on the HTTP API stage.
