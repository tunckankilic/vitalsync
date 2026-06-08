# Apple Sign-In OIDC Setup (Cognito)

Bu doküman, AWS Cognito User Pool'da Apple Sign-In federated identity provider'ını kurmak için gerekli manuel adımları içerir. Kod tarafı `Amplify.Auth.signInWithWebUI(provider: AuthProvider.apple)` çağrısı ile hazırdır; backend konfigürasyonu yapılmadan çalışmaz.

> **Identifiers redacted.** Instance-specific values (`<USER_POOL_ID>`, `<APP_CLIENT_ID>`, `<COGNITO_DOMAIN_PREFIX>`) are placeholders — substitute your own from the AWS Cognito console / git-ignored `amplifyconfiguration.dart`. Public app identifiers (bundle id, URL schemes) are kept as-is.

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
  - Domains and Subdomains: `<COGNITO_DOMAIN_PREFIX>.auth.eu-central-1.amazoncognito.com`
  - Return URLs: `https://<COGNITO_DOMAIN_PREFIX>.auth.eu-central-1.amazoncognito.com/oauth2/idpresponse`

### 1.3 Sign In with Apple Key oluştur
- Keys → "+" → Sign in with Apple aktif et → Configure
  - Primary App ID seç
- Continue → Register
- `.p8` dosyasını indir (bir kez indirebilirsin, sakla)
- **Key ID**'yi not al
- **Team ID**'yi (sağ üstte) not al

## 2. AWS Cognito Console

### 2.1 Hosted UI Domain ayarla
- Cognito → User Pools → `<USER_POOL_ID>`
- App integration tab → Domain → Cognito domain
- Domain prefix: `<COGNITO_DOMAIN_PREFIX>`
- Save (tam adres: `https://<COGNITO_DOMAIN_PREFIX>.auth.eu-central-1.amazoncognito.com`)

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
- App integration → App clients → mevcut app client (`<APP_CLIENT_ID>`)
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
https://<COGNITO_DOMAIN_PREFIX>.auth.eu-central-1.amazoncognito.com/login?response_type=code&client_id=<APP_CLIENT_ID>&redirect_uri=site.tunckankilic.vitalsync://callback/&identity_provider=SignInWithApple
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

## 6. Profil "User" / "No email" gösteriyor — isim/e-posta doldurma

**Belirti:** Apple ile giriş çalışıyor ama profilde isim "User", e-posta "No email" görünüyor.

**Kök sebep:** §2.2'deki `name` → `name` eşlemesi yetersiz. Apple, Sign in with
Apple'da tek bir `name` claim'i göndermez; ismi **`firstName` / `lastName`**
olarak ve **yalnızca ilk yetkilendirmede** gönderir. Cognito bunları `name`'e
değil `given_name` / `family_name`'e map etmelidir.

> Client tarafı zaten doğru: `cognito_auth_repository_impl.dart` →
> `_fetchCurrentUser`, `name` boşsa `given_name + family_name`'den display
> name'i kurar. Yani bu bölüm tamamen Cognito/Apple + cihaz konfigürasyonudur;
> kod değişikliği gerekmez. `amplify push` gerekmez — hepsi mevcut kaynak
> üzerinde additive console ayarı.

### 6.1 Apple IdP attribute mapping'i düzelt
- Cognito → User Pools → `<USER_POOL_ID>` → Authentication → Social and external
  providers → **Sign in with Apple** → Map attributes:

  | Apple attribute | → User pool attribute |
  | --------------- | --------------------- |
  | `email`         | `email`               |
  | `firstName`     | `given_name`          |
  | `lastName`      | `family_name`         |

  (§2.2'deki `name` → `name` eşlemesini bununla değiştir/genişlet.)

### 6.2 Scope'ları doğrula
- Aynı ekranda **Authorized scopes** = `name email` olmalı. Yalnızca `email`
  varsa Apple ismi hiç göndermez.

### 6.3 App client okuma izinleri (sessiz sebep — mutlaka kontrol et)
- `fetchUserAttributes()` sadece app client'ın **read** izni olan attribute'ları
  döndürür. Mapping doğru olsa bile bu izin yoksa profil yine boş kalır.
- App integration → App clients → `<APP_CLIENT_ID>` → Attribute read and write
  permissions → **Read** sütununda şunlar işaretli olmalı: `email`,
  `email_verified`, `given_name`, `family_name`, `name`.

### 6.4 Mevcut federe test kullanıcısını sil
- Cognito mapping'i **yalnızca ilk federasyonda** uygular; zaten oluşmuş federe
  kullanıcıyı geri-güncellemez.
- User management → Users → Apple kullanıcısını (`SignInWithApple_…` ya da
  private relay e-postası) seç → **Delete user**.

### 6.5 Cihazda Apple yetkisini kaldır
- Apple ismi **yalnızca ilk yetkilendirmede** gelir; cihaz uygulamayı zaten
  yetkilendirdiyse bir daha isim gelmez.
- iPhone → Ayarlar → Apple ID → Sign in with Apple (veya Şifreler ve Güvenlik →
  Apple Kimliğinizi Kullanan Uygulamalar) → **VitalSync** → **Apple Kimliğini
  Kullanmayı Bırak**. Ardından uygulamada signOut yap.

> **Sıra:** önce 6.1 → 6.2 → 6.3 (config), sonra 6.4 (kullanıcıyı sil), sonra
> 6.5 (cihaz yetkisi), en son temiz giriş.

### 6.6 Temiz re-auth sonrası ne dolmalı
- **İsim:** `given_name` + `family_name` dolar → profil "Ad Soyad" gösterir.
- **E-posta — ikisi de normal:**
  - "E-postamı Paylaş" → gerçek e-posta `email`'e gelir.
  - "E-postamı Gizle" → `…@privaterelay.appleid.com` (private relay) gelir; bu
    beklenen davranıştır, `email` yine dolu olur.
- **emailVerified:** Apple e-postaları doğrulanmış kabul edilir (`email_verified=true`).

**Doğrulama:** Temiz girişten sonra Cognito → Users → (yeni kullanıcı) detayında
`given_name`, `family_name`, `email` dolu olmalı. Doluysa profil ekranı isim +
mail gösterir.

> **Test notu:** Apple ismi gerçekten yalnızca ilk authorization'da gelir. Her
> testte sıfırdan başlamak için **her seferinde 6.4 + 6.5'i** (kullanıcıyı sil +
> cihaz yetkisini kaldır) tekrarla; aksi halde Apple ismi tekrar göndermez.
