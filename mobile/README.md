# Time2Work (Flutter)

**Kaam Bhi, Rojgar Bhi, Bazar Bhi** — 5 KM local work & opportunity network.

White + Black + Amber (`#F59E0B`). Bottom nav: Home | Jobs | Post | Chat | Profile.

## How to run

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.22+) and put `flutter` on your PATH.
2. Start the Time2Work API on port `4000`.
3. From this folder:

```bash
cd mobile
flutter create . --project-name time2work --org com.time2work
flutter pub get
flutter run
```

`flutter create .` fills in Gradle wrapper, launcher icons, and the iOS Xcode project if those files are missing. It will not overwrite `lib/`.

### Devices

| Target | API base (default) |
| --- | --- |
| Android emulator | `http://10.0.2.2:4000/api` |
| iOS simulator / desktop | `http://localhost:4000/api` |
| Physical device | Set your PC LAN IP in **Settings → API base URL** |

Override at launch:

```bash
flutter run --dart-define=API_BASE=http://192.168.1.10:4000/api
```

Socket.io uses the same host without `/api` (e.g. `http://10.0.2.2:4000`).

### Dev login

1. Enter any 10-digit phone.
2. OTP: **`123456`**.
3. Complete profile, choose **Find Work** or **Post Work**, allow location (or city default).

## Screens

Onboarding: Splash, Onboarding, Login, OTP, Profile Setup, Role Select, Location.

Main: Home feed, Jobs + filters (5/10 KM, category, pay, date), Job details + **I Can Do It / Main Kar Sakta Hoon**, Post + Preview + mock fee checkout, Applications (worker list + owner inbox accept/reject), Worker/Business profiles + Available Now, Chat list + chat (text + optional image URL), Notifications, Earnings + transactions, Rate after completion, Search, Settings (role, radius, API URL, logout), Help, Report/Block, SOS (double-confirm → `POST /sos`).

Phase 2 placeholders: Services (`GET /services`), Local Bazar (`GET /marketplace`), Map (approximate area only — no exact worker pins).

Other users’ phone numbers are never displayed, even if a payload includes them.

## Gaps

- Flutter SDK was **not installed** in this environment, so `flutter pub get` / analyzer were not run here.
- Android/iOS folders are starter files. Run `flutter create .` once to generate icons, Gradle wrapper, and `Runner.xcodeproj`.
- Image upload is an optional URL in chat; profile photo is a placeholder (no Cloudinary yet).
- Payments are mock (`/payments/create-order` + `/payments/mock-confirm`).
- No live E2E against the backend (it may still be in progress).
