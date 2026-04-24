# Apple Sign-In OIDC Setup (Cognito)

Bu doküman, AWS Cognito User Pool'da Apple Sign-In federated identity provider'ını kurmak için gerekli manuel adımları içerir. Kod tarafı `Amplify.Auth.signInWithWebUI(provider: AuthProvider.apple)` çağrısı ile hazırdır; backend konfigürasyonu yapılmadan çalışmaz.

## 1. Apple Developer Portal

### 1.1 App ID kontrolü
- Apple Developer → Certificates, Identifiers & Profiles → Identifiers
- App ID `site.tunckankilic.vitalsync` üzerinde **Sign In with Apple** capability aktif olmalı
- "Configure" → "Enable as a primary App ID" seçili

### 1.2 Services ID oluştur
- Identifiers → "+" → Services IDs → Continue
- Description: `VitalSync Sign In`
- Identifier: `site.tunckankilic.vitalsync.signin` (App ID'den farklı olmak zorunda)
- Sign In with Apple aktif et → Configure
  - Primary App ID: `site.tunckankilic.vitalsync`
  - Domains and Subdomains: `***REDACTED***`
  - Return URLs: `https://***REDACTED***/oauth2/idpresponse`

### 1.3 Sign In with Apple Key oluştur
- Keys → "+" → Sign in with Apple aktif et → Configure
  - Primary App ID seç
- Continue → Register
- `.p8` dosyasını indir (bir kez indirebilirsin, sakla)
- **Key ID**'yi not al
- **Team ID**'yi (sağ üstte) not al

## 2. AWS Cognito Console

### 2.1 Hosted UI Domain ayarla
- Cognito → User Pools → `***REDACTED***`
- App integration tab → Domain → Cognito domain
- Domain prefix: `***REDACTED***`
- Save (tam adres: `https://***REDACTED***`)

### 2.2 Apple Identity Provider ekle
- Same User Pool → Sign-in experience → Federated identity provider sign-in → Add identity provider → **Sign in with Apple**
- Services ID: `site.tunckankilic.vitalsync.signin`
- Team ID: (1.3'te not alınan)
- Key ID: (1.3'te not alınan)
- Private key: (1.3'te indirilen `.p8` dosyasının içeriği — `BEGIN PRIVATE KEY` dahil tüm içerik)
- Authorize scopes: `email name`
- Map attributes:
  - `email` → `email`
  - `name` → `name`
- Create

### 2.3 App client güncelle
- App integration → App clients → mevcut app client (`***REDACTED***`)
- Edit Hosted UI:
  - Allowed callback URLs: `site.tunckankilic.vitalsync://callback/`
  - Allowed sign-out URLs: `site.tunckankilic.vitalsync://signout/`
  - Identity providers: **Cognito user pool** + **Sign in with Apple** (ikisi de işaretli)
  - OAuth 2.0 grant types: Authorization code grant
  - OpenID Connect scopes: `email`, `openid`, `profile`, `aws.cognito.signin.user.admin`
- Save

## 3. Doğrulama

Hosted UI test URL'inde manuel doğrulama:
```
https://***REDACTED***/login?response_type=code&client_id=***REDACTED***&redirect_uri=site.tunckankilic.vitalsync://callback/&identity_provider=SignInWithApple
```

Tarayıcıda açılınca Apple login ekranı görünmeli. Mobil uygulamada `Amplify.Auth.signInWithWebUI(provider: AuthProvider.apple)` çağrısı ASWebAuthenticationSession ile bu URL'i açar.

## 4. APNs Production Key (Push Notifications)

Bu Apple Sign-In ile ilgili değil ama TestFlight/App Store için gerekli:
- Apple Developer → Keys → Apple Push Notifications service (APNs) key oluştur
- `.p8` indir, Key ID + Team ID not al
- AWS Pinpoint console → Settings → Push notifications → APNs → Token (önerilen) seç → bilgileri gir
- `aps-environment` Runner.entitlements'ta `production` (zaten yapıldı)

## 5. Sorun Giderme

- "redirect_mismatch" → callback URL'in tam olarak Cognito + Apple Services ID + Info.plist URL scheme'inde aynı olduğunu doğrula
- "invalid_client" → Services ID yanlış yazılmış olabilir
- Apple loginden sonra "user not confirmed" → Cognito'da Apple IdP kullanıcılarının email_verified=true olması gerekir, IdP attribute mapping doğru mu kontrol et
