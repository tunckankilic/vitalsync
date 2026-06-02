# AWS Backend Hardening

Operational record of backend hardening applied directly to the live AWS
resources (region `eu-central-1`). These changes were made with the AWS CLI
rather than CloudFormation, so this file is the source of truth for what was
changed, why, how to verify it, and how to roll it back.

> **Identifiers are redacted.** Concrete account / API / user-pool ids are
> deliberately kept out of this committed (public) file — substitute your own.
> Get them from the AWS console or the git-ignored `lib/amplifyconfiguration.dart`:
> `<AWS_ACCOUNT_ID>`, `<REST_API_ID>`, `<USER_POOL_ID>`.

> Scope: only VitalSync resources were touched. This AWS account hosts other
> unrelated projects; none were affected.

| Resource | Identifier |
| -------- | ---------- |
| DynamoDB table | `vitalsynchDBtable-dev` |
| REST API (API Gateway) | `vitalsynchApi` — id `<REST_API_ID>`, stage `dev` |
| Cognito User Pool | `<USER_POOL_ID>` |

---

## 1. DynamoDB — Point-in-Time Recovery (PITR) ✅ ENABLED

Continuous backups protect health data against accidental writes/deletes and
allow restore to any second in the last 35 days.

**Applied**
```bash
aws dynamodb update-continuous-backups --region eu-central-1 \
  --table-name vitalsynchDBtable-dev \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

**Verify** → expect `ENABLED`
```bash
aws dynamodb describe-continuous-backups --region eu-central-1 \
  --table-name vitalsynchDBtable-dev \
  --query "ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus"
```

**Rollback**
```bash
aws dynamodb update-continuous-backups --region eu-central-1 \
  --table-name vitalsynchDBtable-dev \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=false
```

**Persistence:** the Amplify storage CloudFormation template does not declare a
`PointInTimeRecoverySpecification`, so `amplify push` will not overwrite this.

---

## 2. API Gateway — stage throttling ✅ APPLIED (rate 50 / burst 100)

The `dev` stage previously inherited the account default (10 000 rps / 5 000
burst). A modest cap protects the Lambda + DynamoDB backend from abuse/runaway
clients without throttling legitimate sync traffic (sync batches are ≤ 10
writes). Values are conservative and adjustable.

**Applied**
```bash
aws apigateway update-stage --region eu-central-1 \
  --rest-api-id <REST_API_ID> --stage-name dev \
  --patch-operations \
    'op=replace,path=/*/*/throttling/rateLimit,value=50' \
    'op=replace,path=/*/*/throttling/burstLimit,value=100'
```

**Verify** → expect `rate: 50.0`, `burst: 100`
```bash
aws apigateway get-stage --region eu-central-1 \
  --rest-api-id <REST_API_ID> --stage-name dev \
  --query 'methodSettings."*/*".{rate:throttlingRateLimit,burst:throttlingBurstLimit}'
```

**Rollback** (reverts to the account default)
```bash
aws apigateway update-stage --region eu-central-1 \
  --rest-api-id <REST_API_ID> --stage-name dev \
  --patch-operations \
    'op=remove,path=/*/*/throttling/rateLimit' \
    'op=remove,path=/*/*/throttling/burstLimit'
```

> ⚠️ **Caveat:** the stage is created by an `AWS::ApiGateway::Deployment`
> resource (not a managed `AWS::ApiGateway::Stage`). A future `amplify push`
> that creates a new deployment may reset these stage method settings. If that
> happens, re-run the command above, or make it permanent via an Amplify
> `override.ts` (CDK) that sets the stage `MethodSettings`.

---

## 3. Cognito — Threat Protection (Advanced Security) ⏭️ DEFERRED (roadmap)

Not applied yet. Two blockers:

1. **Cost** — Threat Protection requires upgrading the pool from the current
   `ESSENTIALS` tier to `PLUS` ($0.05 / MAU).
2. **Risk** — `aws cognito-idp update-user-pool` resets any pool attribute not
   re-specified in the call, which is unsafe to do blindly against a live pool.

**Recommended path when enabled:** an Amplify auth `override.ts` (CDK) that sets
`UserPoolAddOns.AdvancedSecurityMode` and the `PLUS` tier, deployed via
`amplify push` — persistent and safe, without the reset risk of a raw CLI call.

Current state: tier `ESSENTIALS`, `UserPoolAddOns = null`.

---

## IAM / resource-policy review (from the git cleanup in the secret-hygiene step)

The previously-tracked `team-provider-info.json` exposed IAM role ARNs and the
deployment S3 bucket. As ARNs are identifiers (not credentials), the real
boundary is policy, not secrecy. Still worth reviewing on the AWS side:

- Cognito **Auth/Unauth IAM roles** — confirm least-privilege (no broad `*`).
- **Deployment S3 bucket** — confirm Public Access Block is on and the bucket
  policy is not public.

These are review notes only; no IAM/bucket changes were made.
