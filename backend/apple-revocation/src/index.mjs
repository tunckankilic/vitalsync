/**
 * VitalSync — Sign in with Apple token revocation (App Store Guideline 5.1.1(v)).
 *
 * Receives a short-lived Apple authorization code from the app (the request is
 * authenticated with a Cognito ID token by the HTTP API JWT authorizer),
 * exchanges it for a refresh token, and revokes that token with Apple — which
 * releases the user's "Sign in with Apple" grant when they delete their account.
 *
 * Secrets never leave the backend: the Apple .p8 private key is read from
 * Secrets Manager; the Team ID / Key ID / client_id come from env config. The
 * app only ever sends the ephemeral, single-use authorization code.
 */
import crypto from 'node:crypto';
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from '@aws-sdk/client-secrets-manager';

const { APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_CLIENT_ID, APPLE_KEY_SECRET_ARN } =
  process.env;

const secretsManager = new SecretsManagerClient({});
let cachedPrivateKey;

async function applePrivateKey() {
  if (cachedPrivateKey) return cachedPrivateKey;
  const result = await secretsManager.send(
    new GetSecretValueCommand({ SecretId: APPLE_KEY_SECRET_ARN }),
  );
  cachedPrivateKey = result.SecretString;
  return cachedPrivateKey;
}

function base64url(input) {
  return Buffer.from(input).toString('base64url');
}

/**
 * Builds the ES256-signed JWT that Apple expects as `client_secret`.
 *
 * Uses Node's built-in crypto with `dsaEncoding: 'ieee-p1363'`, which produces
 * the raw R||S signature JOSE requires — so no third-party JWT dependency is
 * needed and the function ships with zero node_modules.
 */
function buildClientSecret(privateKey) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'ES256', kid: APPLE_KEY_ID, typ: 'JWT' };
  const payload = {
    iss: APPLE_TEAM_ID,
    iat: now,
    exp: now + 300, // short-lived; a single revoke round-trip needs seconds
    aud: 'https://appleid.apple.com',
    sub: APPLE_CLIENT_ID,
  };
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(
    JSON.stringify(payload),
  )}`;
  const signature = crypto
    .sign('SHA256', Buffer.from(signingInput), {
      key: privateKey,
      dsaEncoding: 'ieee-p1363',
    })
    .toString('base64url');
  return `${signingInput}.${signature}`;
}

function reply(statusCode, body) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

function applePost(path, params) {
  return fetch(`https://appleid.apple.com${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(params),
  });
}

export const handler = async (event) => {
  // Parse the authorization code from the request body.
  let authorizationCode;
  try {
    const raw = event.isBase64Encoded
      ? Buffer.from(event.body ?? '', 'base64').toString('utf8')
      : event.body ?? '';
    const parsed = JSON.parse(raw || '{}');
    authorizationCode = parsed.authorizationCode ?? parsed.code;
  } catch {
    return reply(400, { error: 'invalid JSON body' });
  }
  if (!authorizationCode) {
    return reply(400, { error: 'missing authorizationCode' });
  }

  let clientSecret;
  try {
    clientSecret = buildClientSecret(await applePrivateKey());
  } catch (error) {
    console.error('client_secret generation failed', error);
    return reply(500, { error: 'server misconfigured' });
  }

  // 1. Exchange the authorization code for tokens.
  const tokenResponse = await applePost('/auth/token', {
    grant_type: 'authorization_code',
    code: authorizationCode,
    client_id: APPLE_CLIENT_ID,
    client_secret: clientSecret,
  });
  if (!tokenResponse.ok) {
    const detail = await tokenResponse.text();
    console.error('apple /auth/token failed', tokenResponse.status, detail);
    return reply(502, {
      error: 'apple token exchange failed',
      status: tokenResponse.status,
    });
  }
  const tokens = await tokenResponse.json();

  // 2. Revoke the token — this releases the Sign in with Apple grant. Prefer the
  // refresh token; fall back to the access token if Apple returned no refresh.
  const token = tokens.refresh_token ?? tokens.access_token;
  const tokenTypeHint = tokens.refresh_token ? 'refresh_token' : 'access_token';
  if (!token) {
    return reply(502, { error: 'apple returned no revocable token' });
  }
  const revokeResponse = await applePost('/auth/revoke', {
    client_id: APPLE_CLIENT_ID,
    client_secret: clientSecret,
    token,
    token_type_hint: tokenTypeHint,
  });
  if (!revokeResponse.ok) {
    const detail = await revokeResponse.text();
    console.error('apple /auth/revoke failed', revokeResponse.status, detail);
    return reply(502, {
      error: 'apple revoke failed',
      status: revokeResponse.status,
    });
  }

  return reply(200, { revoked: true });
};
