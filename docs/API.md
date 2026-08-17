# Time2Work API

Base URL (dev): `http://localhost:4000`

JSON API prefix: `/api`  
Static uploads: `/uploads` (files from `UPLOAD_DIR`)

The Flutter app talks to `{host}/api` (Android emulator default `http://10.0.2.2:4000/api`).  
The admin panel uses `NEXT_PUBLIC_API_URL` (default `http://localhost:4000/api`).

---

## Auth headers

Protected routes expect:

```
Authorization: Bearer <access JWT>
```

The same token is also accepted as `?token=` (used by some clients).  
Socket.io accepts the token as `auth.token`, `query.token`, or the `Authorization` header.

| Token | How issued | Payload |
| --- | --- | --- |
| User access | `POST /api/auth/verify-otp`, `/firebase`, `/refresh` | `{ sub, role, kind: "user", typ: "access" }` |
| User refresh | same | `{ sub, role, kind: "user", typ: "refresh" }` — stored hashed on the user |
| Admin access | `POST /api/admin/login` | `{ sub, role: "admin", kind: "admin", typ: "access" }` |

`kind: "admin"` tokens work on user routes that call `requireAuth` (admins bypass role checks).  
`POST /api/auth/refresh` **rejects** admin refresh tokens.

Admins on `/api/admin/*` (except login) must use `requireAdmin` — user JWTs get `403 Admin only`.

Blocked or suspended users receive `403` with `code: "ACCOUNT_DISABLED"`.

---

## Errors

```json
{ "error": { "message": "…", "code": "UNAUTHORIZED" } }
```

| HTTP | Typical `code` |
| --- | --- |
| 400 | `VALIDATION_ERROR`, `ERROR` |
| 401 | `UNAUTHORIZED` |
| 402 | `FEE_REQUIRED` |
| 403 | `FORBIDDEN`, `ACCOUNT_DISABLED` |
| 404 | `NOT_FOUND` |
| 409 | `DUPLICATE`, `DUPLICATE_JOB` |
| 429 | `RATE_LIMIT` |
| 501 | `FIREBASE_DISABLED` |

Zod failures include `details`. Non-prod 500s may include `stack`.

---

## Pagination

Query: `page` (default 1), `limit` (default 20, max 50).

```json
{ "data": [], "meta": { "page": 1, "limit": 20, "total": 0 } }
```

---

## Rate limits

| Scope | Window | Max |
| --- | --- | --- |
| All `/api/*` | 15 min | 300 |
| `POST /api/auth/send-otp` | 15 min | 5 per phone |
| `POST /api/auth/verify-otp` | 15 min | 10 |

---

## Shared shapes

**Public user** (phone never included):

```json
{
  "id": "…",
  "name": "Ravi Kumar",
  "photoUrl": "",
  "role": "worker",
  "about": "",
  "avgRating": 4.6,
  "ratingCount": 8,
  "verified": true,
  "status": "active",
  "availableNow": null
}
```

**Me user** — public user plus `phone`, `address`, `location: { lat, lng } | null`, `createdAt`.

**Job**

```json
{
  "id": "…",
  "title": "House painting — 1 BHK",
  "description": "…",
  "category": "painter",
  "pay": 2500,
  "payType": "fixed",
  "workersRequired": 1,
  "date": "2026-08-15T00:00:00.000Z",
  "timeSlot": "09:00-18:00",
  "address": "Dadar East, Mumbai",
  "location": { "lat": 19.076, "lng": 72.8777 },
  "status": "open",
  "feePaid": true,
  "postingFee": 19,
  "poster": { "id": "…", "name": "Amit Sharma" },
  "posterRating": 4.4,
  "distanceMeters": 120,
  "createdAt": "…"
}
```

`payType`: `fixed` | `hourly` | `daily`.  
Job `status`: `draft` | `open` | `accepted` | `started` | `in_progress` | `completed` | `cancelled`.

**Application**

```json
{
  "id": "…",
  "jobId": "…" ,
  "worker": { "id": "…", "name": "Ravi Kumar" },
  "status": "applied",
  "message": "I Can Do It",
  "createdAt": "…"
}
```

When the job is populated (e.g. `GET /applications/mine`), `jobId` is a full **Job** object instead of a string.

Application `status`: `applied` | `shortlisted` | `accepted` | `rejected` | `cancelled`.

**Payment**

```json
{
  "id": "…",
  "orderId": "ORD…",
  "type": "job_fee",
  "method": "mock",
  "amount": 19,
  "status": "created",
  "jobId": "…",
  "razorpayOrderId": null,
  "createdAt": "…"
}
```

`type`: `job_fee` | `job_payout`. `method`: `mock` | `razorpay`. `status`: `created` | `paid` | `failed`.

**Transaction**

```json
{
  "id": "…",
  "uniqueTxnId": "T2W…",
  "jobId": "…",
  "fromUserId": "…",
  "toUserId": "…",
  "type": "job_payout",
  "gross": 800,
  "commission": 80,
  "net": 720,
  "paymentStatus": "completed",
  "createdAt": "…"
}
```

`type`: `job_payout` | `job_fee` | `refund`. `paymentStatus`: `pending` | `completed` | `failed`.

**Chat / message** — payloads never include phone numbers.

```json
{
  "id": "…",
  "jobId": "…",
  "applicationId": "…",
  "participants": [{ "id": "…", "name": "…" }],
  "lastMessage": "Thanks, work looks good.",
  "lastMessageAt": "…",
  "createdAt": "…"
}
```

```json
{
  "id": "…",
  "chatId": "…",
  "sender": { "id": "…", "name": "…" },
  "text": "On my way.",
  "imageUrl": "",
  "createdAt": "…"
}
```

---

## Health

### `GET /health` (no auth)

```json
{ "ok": true, "service": "time2work-api", "env": "development" }
```

---

## Auth — `/api/auth`

### `POST /api/auth/send-otp`

```json
{ "phone": "9999990001" }
```

Indian 10-digit numbers only (`6–9` + 9 digits; `91` / leading `0` stripped).

```json
{ "sent": true, "devOtp": "123456" }
```

`devOtp` is included only when `NODE_ENV !== production` and `MOCK_OTP=true`. In mock mode the code is always `123456`.

### `POST /api/auth/verify-otp`

```json
{ "phone": "9999990001", "otp": "123456", "name": "Optional" }
```

Creates the user on first verify. Response:

```json
{ "token": "…", "refreshToken": "…", "user": { "id": "…", "phone": "9999990001" } }
```

### `POST /api/auth/firebase`

Requires `FIREBASE_ENABLED=true`. Otherwise `501 FIREBASE_DISABLED`.

```json
{ "idToken": "<Firebase ID token>" }
```

Uses `phone_number` from the token. Same `{ token, refreshToken, user }` response.

### `POST /api/auth/refresh`

```json
{ "refreshToken": "…" }
```

Rotates tokens. User-only (admin refresh rejected). Same `{ token, refreshToken, user }` response.

### `GET /api/auth/me` (auth)

User:

```json
{
  "user": { "id": "…", "phone": "…", "role": "worker" },
  "workerProfile": { "skills": ["electrician"], "availableNow": true },
  "businessProfile": null
}
```

Admin token:

```json
{ "user": { "id": "…", "role": "admin", "email": "admin@time2work.com" } }
```

---

## Users — `/api/users`

### `PATCH /api/users/me` (auth)

```json
{
  "name": "Ravi",
  "photoUrl": "https://…",
  "role": "worker",
  "about": "…",
  "address": "Andheri East, Mumbai",
  "location": { "lat": 19.1136, "lng": 72.8697, "address": "optional" }
}
```

`role`: `worker` | `business`. Response: `{ "user": <meUser> }`.

### `POST /api/users/me/location` (auth)

```json
{ "lat": 19.076, "lng": 72.8777, "address": "Dadar" }
```

`{ "user": <meUser> }`

### `POST /api/users/me/role` (auth)

```json
{ "role": "worker" }
```

`{ "user": <meUser> }`

### `POST /api/users/:id/block` (auth)

`{ "blocked": true, "userId": "…" }`

### `POST /api/users/:id/report` (auth)

```json
{ "reason": "spam", "details": "optional" }
```

`201` `{ "id": "…", "status": "open" }`

### `GET /api/users/:id/reviews` (public, paginated)

Each item:

```json
{
  "id": "…",
  "jobId": "…",
  "fromUser": { "id": "…", "name": "…" },
  "stars": 5,
  "review": "On time and neat wiring.",
  "createdAt": "…"
}
```

---

## Profiles — `/api/profiles`

### `GET /api/profiles/worker` (auth)

`{ "profile": { "userId", "skills", "experienceYears", "availableNow", "hourlyRate", "bio", "languages" } | null }`

### `PUT /api/profiles/worker` (auth)

```json
{
  "skills": ["electrician", "labour"],
  "experienceYears": 5,
  "availableNow": true,
  "hourlyRate": 150,
  "bio": "…",
  "languages": ["hi", "en"]
}
```

Upserts. Sets `user.role = worker` if role was empty. `{ "profile": … }`

### `PATCH /api/profiles/worker/availability` (auth)

```json
{ "availableNow": true }
```

### `GET /api/profiles/business` (auth)

`{ "profile": { "userId", "businessName", "category", "description", "address", "gstin" } | null }`

### `PUT /api/profiles/business` (auth)

```json
{
  "businessName": "Sharma Contractors",
  "category": "labour",
  "description": "…",
  "address": "Bandra West",
  "gstin": ""
}
```

Sets `user.role = business` if role was empty.

### `GET /api/profiles/:userId` (public)

Exact coordinates are not returned. `location` is null; use `address` / `locationApprox`.

```json
{
  "user": { "id": "…", "name": "…", "address": "…", "locationApprox": "…", "location": null },
  "workerProfile": { "skills": [], "experienceYears": 5, "availableNow": true, "hourlyRate": 150, "bio": "", "languages": [] },
  "businessProfile": { "businessName": "…", "category": "…", "description": "…", "address": "…" }
}
```

Business public profile omits `gstin`.

---

## Jobs — `/api/jobs`

### `GET /api/jobs` (optional auth)

Query: `lat`, `lng`, `radiusKm` (`5` or `10`, from settings), `category`, `minPay`, `date` (YYYY-MM-DD), `page`, `limit`.

Only `status: open`. Blocked posters are excluded for the caller.

With `lat`+`lng`, uses `$geoNear` and ranks by distance, skill/category match, recency, pay, poster rating. Paginated job list.

### `GET /api/jobs/mine` (auth)

Jobs posted by the caller. Paginated.

### `GET /api/jobs/:id` (optional auth)

`{ "job": <Job> }`

### `GET /api/jobs/:id/applications` (auth, owner or admin)

Paginated applications with worker public profiles.

### `POST /api/jobs` (auth)

```json
{
  "title": "Need 2 helpers",
  "description": "optional",
  "category": "loader",
  "pay": 600,
  "payType": "fixed",
  "workersRequired": 2,
  "date": "2026-08-15",
  "timeSlot": "09:00-18:00",
  "lat": 19.119,
  "lng": 72.846,
  "location": { "lat": 19.119, "lng": 72.846 },
  "address": "Andheri West"
}
```

Creates `status: draft`, `feePaid: false`. Duplicate title + same poster + same calendar day → `409 DUPLICATE_JOB`.

`201` `{ "job": <Job>, "postingFee": 19 }`

### `POST /api/jobs/:id/pay-fee` (auth, owner)

```json
{ "method": "mock" }
```

`method` is required: `mock` | `razorpay`. Mock immediately marks the fee paid.

`{ "payment": <Payment>, "job": <Job>, "feePaid": true }`

### `POST /api/jobs/:id/publish` (auth, owner or admin)

Requires `feePaid` (`402 FEE_REQUIRED`) and a location. Sets `status: open`.

`{ "job": <Job> }`

### `PATCH /api/jobs/:id/status` (auth, owner or admin)

```json
{ "status": "completed" }
```

Allowed: `accepted` | `started` | `in_progress` | `completed` | `cancelled`.  
Cannot move backwards along `accepted → started → in_progress → completed`.  
On `completed`, one `job_payout` transaction is created per accepted worker (`gross = job.pay`, `commission` from settings %, `net = gross - commission`). In `PAYMENTS_MODE=mock`, payouts are `completed`; otherwise `pending`.

### `DELETE /api/jobs/:id` (auth, owner or admin)

Owners cannot delete after workers were accepted unless the job is `cancelled` or `draft`. `{ "deleted": true, "id": "…" }`

### `POST /api/jobs/:id/apply` (auth)

```json
{ "message": "Available after 2 PM" }
```

`201` `{ "application": <Application> }`. Duplicate apply → `409`. Own job / not open / blocked poster → `400`/`403`.

### `POST /api/jobs/:id/rate` (auth)

Job must be `completed`. Poster rates accepted workers; workers rate the poster.

```json
{ "toUserId": "…", "stars": 5, "review": "On time." }
```

`201`

```json
{
  "rating": { "id": "…", "stars": 5 },
  "review": { "id": "…", "stars": 5, "review": "On time." }
}
```

---

## Applications — `/api/applications`

### `GET /api/applications/mine` (auth)

Caller’s applications as worker. Paginated. `jobId` is a full Job.

### `PATCH /api/applications/:id` (auth)

```json
{ "status": "accepted" }
```

`cancelled` — worker, owner, or admin.  
`shortlisted` | `accepted` | `rejected` — owner or admin.

Accept is capped at `job.workersRequired` (`400 CAPACITY`). Accepting creates a chat and may set the job to `accepted` when the roster is full.

```json
{ "application": <Application>, "chat": <Chat> }
```

`chat` is present only on accept.

---

## Chats — `/api/chats`

### `GET /api/chats` (auth)

Paginated. Non-admins see chats they participate in.

### `GET /api/chats/:id/messages` (auth, participant or admin)

Paginated, chronological (`data` is oldest-first after an internal reverse).

### `POST /api/chats/:id/messages` (auth)

```json
{ "text": "On my way", "imageUrl": "https://…" }
```

At least one of `text` / `imageUrl`. Blocked participants → `403`.  
`201` `{ "message": <Message> }` and a Socket.io `message` emit to the room.

---

## Socket.io

Connect to the API host **without** `/api` (e.g. `http://localhost:4000`).

Auth: JWT as above. On connect the socket joins `user:{userId}` and receives `status: { userId, status: "online" }`.

| Client emit | Payload | Server emit |
| --- | --- | --- |
| `join` | `{ chatId }` | joins `chat:{chatId}` if participant |
| `message` | `{ chatId, text?, imageUrl? }` | `message` to room (same DTO as REST) |
| `typing` | `{ chatId, isTyping }` | `typing` to others in the room |
| `status` | `{ status }` | broadcast `status` |
| disconnect | | broadcast `status: offline` |

Server also emits `notification` to `user:{id}` and `error` `{ message }` on chat write failures.

---

## Payments — `/api/payments`

### `POST /api/payments/create-order` (auth)

```json
{ "type": "job_fee", "jobId": "…", "method": "mock" }
```

`type`: `job_fee` | `job_payout`. `method` optional — defaults from `PAYMENTS_MODE`.

`201` `{ "payment": <Payment>, "razorpayKeyId": "rzp_…" }`  
`razorpayKeyId` is set only when `method === "razorpay"`.

### `POST /api/payments/mock-confirm` (auth)

```json
{ "orderId": "ORD…" }
```

Marks the order paid (owner or admin). Rejected if the order is Razorpay and `PAYMENTS_MODE` is not `mock`.

### `POST /api/payments/razorpay/webhook` (raw JSON body)

Header: `x-razorpay-signature`.  
Signature is required in production **or** whenever `RAZORPAY_WEBHOOK_SECRET` is set.

Looks up `Payment` by `razorpayOrderId`. `payment.failed` → `failed`; otherwise `markPaid`.  
`{ "ok": true }` or `{ "ok": true, "ignored": true }`.

---

## Earnings — `/api/earnings`

### `GET /api/earnings` (auth)

Sums **net** of `job_payout` transactions where `toUserId` is the caller.

```json
{
  "today": 0,
  "week": 720,
  "month": 720,
  "total": 720,
  "pending": 0,
  "completedJobs": 1
}
```

---

## Transactions — `/api/transactions`

### `GET /api/transactions` (auth)

Paginated. Rows where the caller is `fromUserId` or `toUserId`.

---

## Notifications — `/api/notifications`

### `GET /api/notifications` (auth)

Paginated.

```json
{
  "id": "…",
  "title": "Welcome to Time2Work",
  "body": "…",
  "type": "system",
  "data": {},
  "read": false,
  "createdAt": "…"
}
```

`type` values used in code: `general`, `system`, `job`, `application`, `chat`, `payment`, `earnings`, `rating`, `sos`.

### `PATCH /api/notifications/:id/read` (auth)

`{ "notification": <Notification> }`

### `POST /api/notifications/register-fcm` (auth)

```json
{ "token": "<FCM device token>" }
```

`{ "registered": true }` — `$addToSet` on `users.fcmTokens`.

---

## Categories — `/api/categories`

### `GET /api/categories` (public)

Active categories only, sorted by `sortOrder`.

```json
{
  "data": [
    { "id": "…", "slug": "labour", "name": "Labour", "nameHi": "मजदूर", "icon": "construction" }
  ]
}
```

Seeded slugs: `labour`, `mason`, `painter`, `electrician`, `plumber`, `carpenter`, `welder`, `driver`, `delivery`, `cleaning`, `cook`, `security`, `gardener`, `ac-repair`, `loader`, `event-staff`, `tailor`, `beautician`, `tutor`, `shop-helper`, `warehouse`, `other`.

---

## Search — `/api/search`

### `GET /api/search` (optional auth)

Query: `q`, `type` (default `jobs`), `lat`, `lng`, `radiusKm`, `page`, `limit`.

| `type` | Result `data` items |
| --- | --- |
| `jobs` | Job DTOs (`status: open`) |
| `workers` | `{ user, profile }` |
| `businesses` | `{ user, profile }` |
| `services` | raw Service docs (`active: true`) |
| `products` | raw MarketplaceListing docs (`status: active`) |

---

## Services (Phase 2 stub) — `/api/services`

### `GET /api/services` (optional auth)

Query: `category`, `page`, `limit`. `{ data: [ { id, providerId, title, category, description, price, address, location, createdAt } ] }`

### `POST /api/services` (auth)

```json
{
  "title": "Home electrical visit",
  "category": "electrician",
  "description": "…",
  "price": 299,
  "lat": 19.11,
  "lng": 72.86,
  "address": "Andheri East"
}
```

`201` `{ "service": … }`

---

## Marketplace (Phase 2 stub) — `/api/marketplace`

### `GET /api/marketplace` (optional auth)

Query: `category`, `page`, `limit`. Active listings.

### `POST /api/marketplace` (auth)

```json
{
  "title": "Used drill machine",
  "description": "…",
  "price": 1500,
  "images": [],
  "category": "other",
  "lat": 19.05,
  "lng": 72.82,
  "address": "Bandra West"
}
```

`201` `{ "listing": { id, sellerId, title, description, price, images, category, address, location, status, createdAt } }`

---

## SOS — `/api/sos`

### `POST /api/sos` (auth)

```json
{
  "lat": 19.07,
  "lng": 72.87,
  "contactName": "Priya",
  "contactPhone": "9999990003"
}
```

Writes a `reports` row with `targetType: "sos"`.  
`201` `{ "ok": true, "id": "…", "message": "SOS recorded. Emergency contact will be notified." }`

---

## Admin — `/api/admin`

Admin panel pages: Dashboard, Users, Jobs, Categories, Payments, Reports, Settings.

### `POST /api/admin/login` (no auth)

```json
{ "email": "admin@time2work.com", "password": "Admin@123" }
```

```json
{
  "token": "…",
  "refreshToken": "…",
  "admin": { "id": "…", "email": "admin@time2work.com", "name": "Time2Work Admin", "role": "admin" }
}
```

There is no `/api/admin/refresh`. The issued refresh token cannot be used on `/api/auth/refresh`.

All routes below require an admin JWT.

### `GET /api/admin/analytics`

```json
{
  "users": 2,
  "activeUsers": 2,
  "jobsPosted": 6,
  "jobsCompleted": 1,
  "revenue": 95,
  "commission": 80
}
```

`revenue` = sum of completed `job_fee` transaction `gross`.  
`commission` = sum of `job_payout` `commission`.  
`jobsPosted` excludes `draft`.

### `GET /api/admin/users`

Query: `q` (name / phone / about), `page`, `limit`.  
Items are public users **plus** `phone` and `location` / `address`.

### `PATCH /api/admin/users/:id`

```json
{ "status": "suspended", "verified": true }
```

`status`: `active` | `suspended` | `blocked`. `{ "user": … }`

### `GET /api/admin/jobs`

Query: `status`, `page`, `limit`. Paginated Job DTOs.

### `DELETE /api/admin/jobs/:id`

`{ "deleted": true, "id": "…" }`

### `GET /api/admin/categories`

`{ "data": [ full Category documents ] }` (includes inactive).

### `POST /api/admin/categories`

```json
{ "slug": "mason", "name": "Mason", "nameHi": "राजमिस्त्री", "icon": "brick", "active": true, "sortOrder": 2 }
```

`201` `{ "category": <doc> }`

### `PATCH /api/admin/categories/:id` and `PUT /api/admin/categories/:id`

Same optional fields as create. `{ "category": <doc> }`

### `DELETE /api/admin/categories/:id`

`{ "deleted": true, "id": "…" }`

### `GET /api/admin/payments`

```json
{
  "payments": { "data": [<Payment>], "meta": { "page", "limit", "total" } },
  "transactions": { "data": [<Transaction>], "meta": { "page", "limit", "total" } }
}
```

### `GET /api/admin/reports`

Query: `status`, `page`, `limit`.

```json
{
  "id": "…",
  "reporter": { "id": "…", "name": "…" },
  "targetType": "user",
  "targetId": "…",
  "reason": "spam",
  "details": "",
  "status": "open",
  "adminNote": "",
  "createdAt": "…"
}
```

`targetType`: `user` | `job` | `sos`. `status`: `open` | `reviewed` | `resolved` | `dismissed`.

### `PATCH /api/admin/reports/:id`

```json
{ "status": "resolved", "adminNote": "Handled" }
```

`{ "report": { "id", "status", "adminNote" } }`

### `GET /api/admin/settings`

```json
{
  "settings": {
    "jobPostingFee": 19,
    "commissionPercent": 10,
    "referralReward": 0,
    "primaryRadiusKm": 5,
    "secondaryRadiusKm": 10
  }
}
```

### `PUT /api/admin/settings`

Any subset of the five numbers above. `{ "settings": … }`

---

## Not implemented as HTTP routes

These collections exist in Mongo but have **no** public CRUD in this API:

- `referrals` (schema only)
- KYC document vault
- Dedicated job-report endpoint (reports are user/SOS today; jobs can still be removed by admin)
