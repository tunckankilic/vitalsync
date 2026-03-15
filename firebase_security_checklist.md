# Firebase API Key Security Checklist — VitalSync

## Required Restrictions

### Android API Key (`google-services.json`)
1. Go to **Google Cloud Console > APIs & Credentials**
2. Select the Android API key
3. Under **Application restrictions**, choose **Android apps**
4. Add your app's SHA-1 fingerprint and package name (`com.vitalsync.app`)
5. Under **API restrictions**, restrict to:
   - Firebase Installations API
   - Firebase Cloud Messaging API
   - Firebase Auth API
   - Cloud Firestore API

### iOS API Key (`GoogleService-Info.plist`)
1. Select the iOS API key
2. Under **Application restrictions**, choose **iOS apps**
3. Add your app's Bundle ID
4. Apply the same API restrictions as above

### Web API Key (if applicable)
1. Under **Application restrictions**, choose **HTTP referrers**
2. Add your web domain(s)
3. Restrict to required APIs only

## Firestore Security Rules
Ensure rules are **not** in test mode:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Firebase Auth Settings
- Enable only needed sign-in methods (Email/Password, Apple)
- Disable anonymous authentication unless needed
- Set up email enumeration protection

## Monitoring
- Enable Firebase App Check (recommended)
- Monitor usage in Firebase Console > Usage & Billing
- Set budget alerts for unexpected API usage spikes
