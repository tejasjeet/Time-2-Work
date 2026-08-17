# Environment variables

Copy `backend/.env.example` → `backend/.env` and `admin/.env.example` → `admin/.env.local`.

Values below match `backend/src/config/env.js` and the example files. Defaults in parentheses are what the process uses when the variable is unset.

---

## Backend (`backend/.env`)

### Server

| Variable | Default | Notes |
| --- | --- | --- |
| `NODE_ENV` | `development` | `production` turns on combined logs, CORS allow-list, Razorpay-by-default payments, and hides 500 stacks. |
| `PORT` | `4000` | HTTP + Socket.io. |
| `CORS_ORIGIN` | `http://localhost:3000,http://localhost:4000` | Comma-separated. Used only when `NODE_ENV=production`. In development CORS is `origin: true`. |

### MongoDB

| Variable | Default | Notes |
| --- | --- | --- |
| `MONGO_URI` | `mongodb://127.0.0.1:27017/time2work` | Docker Compose API service uses `mongodb://mongo:27017/time2work`. |

### JWT

| Variable | Default | Notes |
| --- | --- | --- |
| `JWT_SECRET` | `dev-access-secret` | Access tokens. Change in any shared/prod deploy. |
| `JWT_REFRESH_SECRET` | `dev-refresh-secret` | Refresh tokens. |
| `JWT_EXPIRES_IN` | `7d` | Passed to `jsonwebtoken`. |
| `JWT_REFRESH_EXPIRES_IN` | `30d` | |

### Auth — mock vs Firebase

| Variable | Default | Notes |
| --- | --- | --- |
| `MOCK_OTP` | `true` when not production | `true`/`1` → OTP is always `123456`, logged as `[mock SMS]`, and `devOtp` is returned in non-prod. `false` generates a random 6-digit code (logged as queued; no SMS provider is wired). |
| `FIREBASE_ENABLED` | `false` | `true` enables `POST /api/auth/firebase` and firebase-admin (Auth verify + FCM multicast). |
| `FIREBASE_PROJECT_ID` | empty | Service-account cert fields. |
| `FIREBASE_CLIENT_EMAIL` | empty | |
| `FIREBASE_PRIVATE_KEY` | empty | Use `\n` for newlines in `.env`; they are unescaped at boot. |
| `GOOGLE_APPLICATION_CREDENTIALS` | unset | Optional path to a service-account JSON. If cert env vars are empty, `firebase-admin.initializeApp()` uses Application Default Credentials (this file). |

### Payments — mock vs Razorpay

| Variable | Default | Notes |
| --- | --- | --- |
| `PAYMENTS_MODE` | `mock` in non-prod, `razorpay` in production | `mock` → local checkout + `POST /api/payments/mock-confirm`. Job completion payouts are marked `completed`. `razorpay` requires keys; payouts stay `pending` until a real settlement path exists. |
| `RAZORPAY_KEY_ID` | empty | Returned to the client on Razorpay orders. |
| `RAZORPAY_KEY_SECRET` | empty | Server-side Orders API. |
| `RAZORPAY_WEBHOOK_SECRET` | empty | HMAC for `x-razorpay-signature`. Checked in production **or** whenever this value is set. |

### FCM / push

| Variable | Default | Notes |
| --- | --- | --- |
| `FCM_SERVER_KEY` | empty | Legacy hook. If firebase-admin is **not** initialized and this is set, the server **logs** that it would send (no HTTP send). |
| `FIREBASE_ENABLED` | `false` | When true and the user has `fcmTokens`, `notifyUser` calls `messaging().sendEachForMulticast`. |

If neither Firebase admin nor `FCM_SERVER_KEY` is set, notifications stay in-app (Mongo + Socket.io `notification` event) and are logged.

### Uploads

| Variable | Default | Notes |
| --- | --- | --- |
| `UPLOAD_DIR` | `uploads` | Created on boot; served at `/uploads`. |
| `PUBLIC_URL` | `http://localhost:4000` | Public origin for building file URLs. |

Boolean env values accept `true` / `1` (case-insensitive).

---

## Admin (`admin/.env.local`)

| Variable | Default | Notes |
| --- | --- | --- |
| `NEXT_PUBLIC_API_URL` | `http://localhost:4000/api` | Browser-visible. Must include the `/api` suffix. |

---

## Flutter

No `.env` file. Override the API at compile/run time:

```bash
flutter run --dart-define=API_BASE=http://192.168.1.10:4000/api
```

| Define | Default |
| --- | --- |
| `API_BASE` | Android emulator: `http://10.0.2.2:4000/api`. iOS/desktop: `http://localhost:4000/api`. |

The in-app Settings screen can also store a custom base URL. Socket.io is derived by stripping a trailing `/api`.

---

## Docker Compose

`docker-compose.yml` sets for the `api` service:

```
NODE_ENV=development
PORT=4000
MONGO_URI=mongodb://mongo:27017/time2work
JWT_SECRET=change-me-access-secret
JWT_REFRESH_SECRET=change-me-refresh-secret
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d
MOCK_OTP=true
PAYMENTS_MODE=mock
FIREBASE_ENABLED=false
CORS_ORIGIN=http://localhost:3000,http://localhost:4000
PUBLIC_URL=http://localhost:4000
```

---

## Recommended profiles

### Local mock (first run, no paid keys)

```
NODE_ENV=development
MOCK_OTP=true
FIREBASE_ENABLED=false
PAYMENTS_MODE=mock
```

OTP `123456`. Job fee via `method: "mock"` or `/payments/mock-confirm`. Push stays in-app.

### Production-shaped

```
NODE_ENV=production
MOCK_OTP=false
FIREBASE_ENABLED=true
FIREBASE_PROJECT_ID=…
FIREBASE_CLIENT_EMAIL=…
FIREBASE_PRIVATE_KEY=…
PAYMENTS_MODE=razorpay
RAZORPAY_KEY_ID=rzp_live_…
RAZORPAY_KEY_SECRET=…
RAZORPAY_WEBHOOK_SECRET=…
JWT_SECRET=<long random>
JWT_REFRESH_SECRET=<different long random>
CORS_ORIGIN=https://admin.example.com
PUBLIC_URL=https://api.example.com
MONGO_URI=mongodb+srv://…
```

Clients: Flutter Phone Auth → `POST /api/auth/firebase`. Checkout uses Razorpay order + webhook. FCM tokens via `POST /api/notifications/register-fcm`.
