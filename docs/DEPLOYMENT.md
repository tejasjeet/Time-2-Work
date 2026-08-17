# Deployment

Monorepo layout:

```
App creation/
  backend/     Express + Socket.io (port 4000)
  admin/       Next.js 15 admin (port 3000)
  mobile/      Flutter app
  docs/
  docker-compose.yml
```

---

## 1. MongoDB

### Docker (recommended)

From the repo root:

```bash
docker compose up -d mongo
```

This starts `mongo:7` on host `27017`, volume `t2w_mongo`, with a ping healthcheck.

Then in `backend/.env`:

```
MONGO_URI=mongodb://127.0.0.1:27017/time2work
```

### Compose API + Mongo together

```bash
docker compose up -d
```

The `api` service builds `backend/Dockerfile` (Node 20 Alpine, `node src/server.js`), waits until Mongo is healthy, and publishes `4000`. Uploads mount to `./backend/uploads`.

Seed is **not** run by Compose. After Mongo is up:

```bash
cd backend
cp .env.example .env
# set MONGO_URI=mongodb://127.0.0.1:27017/time2work  (or mongodb://mongo:27017/time2work inside the api container)
npm install
npm run seed
```

### Local Mongo without Docker

Install MongoDB 6/7, create database `time2work`, and use the same `MONGO_URI`.

On the machine that wrote these docs, the Docker CLI was **not** on `PATH`. The API was verified against an already-running local Mongo at `127.0.0.1:27017` (`GET /health` → `{ "ok": true, "service": "time2work-api", "env": "development" }`).

### Production Mongo

Use Atlas or a managed replica set. Set `MONGO_URI` to the `mongodb+srv://` string. The API calls `syncIndexes()` on every model at connect time.

---

## 2. API

Requirements: Node 18+.

```bash
cd backend
cp .env.example .env
npm install
npm run seed
npm run dev          # nodemon src/server.js
# or
npm start            # node src/server.js
```

Listen: `Time2Work API listening on :4000`.

Health: `GET http://localhost:4000/health` → `{ "ok": true, "service": "time2work-api", "env": "development" }`.

Production process manager (example):

```bash
NODE_ENV=production PORT=4000 node src/server.js
```

Put a reverse proxy (nginx / Caddy) in front for TLS. Forward WebSocket upgrades for Socket.io. Point `PUBLIC_URL` and `CORS_ORIGIN` at the public origins.

See [ENV.md](ENV.md) for mock vs Firebase/Razorpay/FCM.

---

## 3. Admin panel

```bash
cd admin
cp .env.example .env.local
# NEXT_PUBLIC_API_URL=http://localhost:4000/api
npm install
npm run dev          # http://localhost:3000
```

Production:

```bash
npm run build
npm start            # next start, default :3000
```

Set `NEXT_PUBLIC_API_URL` to the public API (`https://api.example.com/api`) **before** `next build` — it is inlined.

Login: `admin@time2work.com` / `Admin@123` (created by seed). Change that password in Mongo (`admin_users`) before any public deploy.

Pages: Dashboard, Users, Jobs, Categories, Payments, Reports, Settings.

---

## 4. Flutter app (APK / AAB)

The `mobile/` tree has Dart sources and a partial Android folder. Gradle wrapper, launcher icons, and the iOS Xcode project are completed by Flutter tooling.

### One-time project files

Install [Flutter 3.22+](https://docs.flutter.dev/get-started/install) (SDK `>=3.3.0 <4.0.0` in `pubspec.yaml`) and:

```bash
cd mobile
flutter create . --project-name time2work --org com.time2work
flutter pub get
```

`flutter create .` does **not** overwrite `lib/`. Android application id is `com.time2work.app`.

### Run against local API

1. Start Mongo + API on `:4000`.
2. Android emulator uses `http://10.0.2.2:4000/api`.
3. iOS simulator / desktop uses `http://localhost:4000/api`.
4. Physical device: Settings → API base URL, or:

```bash
flutter run --dart-define=API_BASE=http://192.168.1.10:4000/api
```

### Release artifacts

```bash
cd mobile
flutter build apk --release
flutter build appbundle --release
```

Outputs:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

Optional flavor/API:

```bash
flutter build appbundle --release --dart-define=API_BASE=https://api.example.com/api
```

---

## 5. Android signing (Play upload)

`mobile/android/app/build.gradle` currently signs **release with the debug keystore**:

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.debug
    }
}
```

That is enough for local `flutter build apk` / sideload. **Google Play will not accept a debug-signed AAB for production.**

To ship:

1. Create a keystore (`keytool -genkey -v -keystore time2work-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`).
2. Add `android/key.properties` (do not commit it) with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
3. Load that file in `app/build.gradle` and set `signingConfig signingConfigs.release` for the release build type.
4. Keep the JKS and passwords offline. Losing them means you cannot update the Play listing.

Until that is done, use `flutter build apk` for testers only.

---

## 6. First-run checklist (no paid keys)

1. `docker compose up -d mongo` (or local Mongo).
2. `cd backend && npm install && npm run seed && npm run dev` → `:4000`.
3. `cd admin && npm install && npm run dev` → `:3000`.
4. `cd mobile && flutter create . && flutter pub get && flutter run`.
5. Worker `9999990001` / OTP `123456`, business `9999990002` / OTP `123456`, admin `admin@time2work.com` / `Admin@123`.
6. Sample jobs are near **lat 19.0760, lng 72.8777** (Mumbai). Use a 5 or 10 KM radius in the jobs feed.

Switch to Firebase + Razorpay by filling `.env` — see [ENV.md](ENV.md) and [FIREBASE.md](FIREBASE.md). No API rewrite required.
