# Firebase Auth + FCM

Time2Work runs **without Firebase** by default (`FIREBASE_ENABLED=false`, `MOCK_OTP=true`). Phone login uses `POST /api/auth/send-otp` + `verify-otp` with OTP `123456`.

Enable Firebase when you want real phone tokens and (optionally) FCM multicast. The Express routes do not change.

---

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/) and create a project (e.g. `time2work`).
2. Add an **Android** app with package name `com.time2work.app` (see `mobile/android/app/build.gradle`).
3. Download `google-services.json` into `mobile/android/app/` after you run `flutter create .` (so the Android tree exists).
4. Add an **iOS** app if you ship iOS; place `GoogleService-Info.plist` in the Xcode Runner target.

---

## 2. Phone Authentication

1. Build → Authentication → Sign-in method → enable **Phone**.
2. Add test numbers in the console if you still want a fixed OTP during QA.
3. In the Flutter app, obtain a Firebase **ID token** after `PhoneAuthProvider` verification (the current mobile app still calls mock OTP; wire Firebase Auth on the client when you flip the backend).
4. Exchange that token with the API:

```http
POST /api/auth/firebase
Content-Type: application/json

{ "idToken": "<Firebase ID token>" }
```

The API calls `admin.auth().verifyIdToken`, reads `phone_number`, upserts `users.firebaseUid` + `phone`, and returns the same JWT pair as mock OTP.

If `FIREBASE_ENABLED` is false, this route returns `501` `{ "error": { "message": "Firebase auth is disabled", "code": "FIREBASE_DISABLED" } }`.

---

## 3. Service account on the API

Two equivalent ways (`backend/src/utils/firebase.js`):

**A. Cert env vars** (preferred in `.env`):

```
FIREBASE_ENABLED=true
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-…@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n…\n-----END PRIVATE KEY-----\n"
```

Create the key: Project settings → Service accounts → Generate new private key.

**B. Application Default Credentials**

```
FIREBASE_ENABLED=true
GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json
```

Leave `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` empty so `initializeApp()` uses ADC.

Restart the API after changing env. Init failures are logged as `Firebase admin init failed:` and Auth/FCM calls then fail closed.

---

## 4. FCM (push)

1. Enable **Cloud Messaging** on the Firebase project.
2. On the device, get an FCM token (FlutterFire `FirebaseMessaging.instance.getToken()`).
3. Register it (authenticated user JWT):

```http
POST /api/notifications/register-fcm
Authorization: Bearer <user JWT>
Content-Type: application/json

{ "token": "<FCM device token>" }
```

The token is `$addToSet` on `users.fcmTokens`.

### What actually sends

`notifyUser` (`backend/src/utils/notify.js`) always writes a Mongo notification and emits Socket.io `notification`. Then:

| Condition | Behavior |
| --- | --- |
| `FIREBASE_ENABLED=true` and admin initialized, user has tokens | `messaging().sendEachForMulticast` with `notification.title/body` and stringified `data` |
| Else `FCM_SERVER_KEY` set | Log only: `FCM (legacy key present) would send to N device(s)` |
| Else | Log: `In-app only notification: …` |

There is no HTTP send path for the legacy server key — it is a hook, not a working FCM HTTP v1 client.

---

## 5. Flutter client notes

- After `flutter create .`, add FlutterFire (`firebase_core`, `firebase_auth`, `firebase_messaging`) when you leave mock OTP.
- Android: apply the Google Services Gradle plugin once `google-services.json` is in place.
- Default API bases stay the same; only the login call switches from `/auth/send-otp` + `/auth/verify-otp` to `/auth/firebase`.
- Keep mock OTP available in development by leaving `FIREBASE_ENABLED=false`.

---

## 6. Local vs prod checklist

| | Local | Prod |
| --- | --- | --- |
| `MOCK_OTP` | `true` | `false` |
| `FIREBASE_ENABLED` | `false` | `true` |
| Login | OTP `123456` | Firebase Phone ID token |
| Push | In-app + logs | FCM multicast if tokens registered |
