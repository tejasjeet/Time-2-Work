# Time2Work

**Kaam Bhi, Rojgar Bhi, Bazar Bhi** — a 5 KM hyperlocal job marketplace (Flutter + Express/Mongo + Next.js admin).

Docs: [API](docs/API.md) · [ENV](docs/ENV.md) · [Firebase](docs/FIREBASE.md) · [Deployment](docs/DEPLOYMENT.md) · [Database](docs/DATABASE.md)

---

## How to run

### 1. Mongo + API (`:4000`)

```bash
docker compose up -d mongo
cd backend
cp .env.example .env
npm install
npm run seed
npm run dev
```

If Docker is unavailable, run MongoDB locally and keep `MONGO_URI=mongodb://127.0.0.1:27017/time2work`.

Health: `GET http://localhost:4000/health`

### 2. Admin (`:3000`)

```bash
cd admin
cp .env.example .env.local
npm install
npm run dev
```

Open `http://localhost:3000`.

### 3. Mobile

```bash
cd mobile
flutter create . --project-name time2work --org com.time2work
flutter pub get
flutter run
```

Android emulator talks to `http://10.0.2.2:4000/api`. Physical device: set the LAN API URL in Settings, or `flutter run --dart-define=API_BASE=http://<pc-ip>:4000/api`.

---

## Seed credentials

| Role | Login | Secret |
| --- | --- | --- |
| Worker | `9999990001` | OTP `123456` |
| Business | `9999990002` | OTP `123456` |
| Admin | `admin@time2work.com` | `Admin@123` |

Sample jobs are around **lat 19.0760, lng 72.8777** (Mumbai). Use the 5 KM or 10 KM jobs filter.

Mock mode (default): no Firebase or Razorpay keys required. See `docs/ENV.md` to switch.
