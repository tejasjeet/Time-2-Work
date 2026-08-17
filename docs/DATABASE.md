# Database

MongoDB database: `time2work` (from `MONGO_URI`).  
Mongoose `strictQuery` is on. Indexes are synced on API boot (`connectDb`) and at the end of `npm run seed`.

Geo fields are GeoJSON **Point** with `[lng, lat]` coordinates. Queries use `$geoNear` / `$near` with `2dsphere`.

All documents get `createdAt` / `updatedAt` unless noted.

---

## `users`

Model: `User`

| Field | Type | Notes |
| --- | --- | --- |
| `phone` | String | Unique, sparse. Normalized 10-digit IN mobile. |
| `name`, `photoUrl`, `about`, `address` | String | |
| `role` | `worker` \| `business` \| `null` | |
| `location` | GeoJSON Point | |
| `status` | `active` \| `suspended` \| `blocked` | Default `active` |
| `verified` | Boolean | Admin flag |
| `fcmTokens` | [String] | |
| `blockedUsers` | [ObjectId → User] | |
| `avgRating`, `ratingCount` | Number | Recalculated on rate |
| `refreshTokenHash` | String | SHA-256 of current refresh JWT |
| `firebaseUid` | String | |
| `isSeed` | Boolean | |

**Indexes**

- `phone` unique sparse
- `status`
- `location` **2dsphere**
- `createdAt` desc
- `{ role: 1, status: 1 }`

---

## `worker_profiles`

| Field | Type |
| --- | --- |
| `userId` | ObjectId → User, **unique**, required |
| `skills` | [String] |
| `experienceYears` | Number |
| `availableNow` | Boolean (default true) |
| `hourlyRate` | Number |
| `bio` | String |
| `languages` | [String] default `["hi","en"]` |

**Indexes:** `userId` unique; `skills`; `availableNow`.

---

## `business_profiles`

| Field | Type |
| --- | --- |
| `userId` | ObjectId → User, **unique**, required |
| `businessName`, `category`, `description`, `address`, `gstin` | String |

**Indexes:** `userId` unique; `category`.

---

## `jobs`

| Field | Type | Notes |
| --- | --- | --- |
| `posterId` | ObjectId → User | Indexed |
| `title` | String | Required |
| `description` | String | |
| `category` | String | Slug, indexed |
| `pay` | Number | ≥ 0 |
| `payType` | `fixed` \| `hourly` \| `daily` | |
| `workersRequired` | Number | Default 1 |
| `date` | Date | |
| `timeSlot` | String | |
| `location` | GeoJSON Point | Required to publish |
| `address` | String | |
| `status` | `draft` \| `open` \| `accepted` \| `started` \| `in_progress` \| `completed` \| `cancelled` | |
| `feePaid` | Boolean | |
| `feePaymentId` | ObjectId → Payment | |
| `postingFee` | Number | Snapshot of settings (default 19) |
| `posterRating` | Number | Copied from poster at create |
| `isSeed` | Boolean | Seed deletes `{ isSeed: true }` |

**Indexes**

- `posterId`
- `category`
- `status`
- `location` **2dsphere**
- `{ status: 1, category: 1, createdAt: -1 }`
- `{ posterId: 1, createdAt: -1 }`

---

## `job_applications`

| Field | Type |
| --- | --- |
| `jobId` | ObjectId → Job |
| `workerId` | ObjectId → User |
| `status` | `applied` \| `shortlisted` \| `accepted` \| `rejected` \| `cancelled` |
| `message` | String |

**Indexes**

- `{ jobId: 1, workerId: 1 }` **unique**
- `{ workerId: 1, createdAt: -1 }`
- `{ jobId: 1, status: 1 }`
- `status`

---

## `categories`

| Field | Type |
| --- | --- |
| `slug` | String, **unique**, required |
| `name` | String, required |
| `nameHi`, `icon` | String |
| `active` | Boolean |
| `sortOrder` | Number |

**Indexes:** `slug` unique; `{ active: 1, sortOrder: 1 }`.

Seeded slugs are listed in [API.md](API.md#categories--apicategories).

---

## `chats`

| Field | Type |
| --- | --- |
| `jobId` | ObjectId → Job, required |
| `applicationId` | ObjectId → JobApplication |
| `participants` | [ObjectId → User] |
| `lastMessage` | String |
| `lastMessageAt` | Date |

**Indexes:** `participants`; `{ jobId: 1, applicationId: 1 }`; `lastMessageAt` desc.

---

## `messages`

| Field | Type |
| --- | --- |
| `chatId` | ObjectId → Chat, indexed |
| `senderId` | ObjectId → User |
| `text`, `imageUrl` | String |

**Indexes:** `chatId`; `{ chatId: 1, createdAt: -1 }`.

---

## `transactions`

| Field | Type |
| --- | --- |
| `uniqueTxnId` | String, **unique** (`T2W` + timestamp + hex) |
| `jobId` | ObjectId → Job |
| `fromUserId`, `toUserId` | ObjectId → User |
| `type` | `job_payout` \| `job_fee` \| `refund` |
| `gross`, `commission`, `net` | Number |
| `paymentStatus` | `pending` \| `completed` \| `failed` |

**Indexes:** `uniqueTxnId` unique; `toUserId`; `paymentStatus`; `{ toUserId: 1, createdAt: -1 }`; `{ jobId: 1, type: 1 }`; `createdAt` desc.

On job complete: one `job_payout` per accepted worker. Example: pay ₹600 × 2 helpers → two rows of `gross` 600, `commission` 10% (60), `net` 540.

---

## `payments`

Checkout orders (posting fee / payout intent).

| Field | Type |
| --- | --- |
| `orderId` | String, **unique** (`ORD` + timestamp + hex) |
| `userId` | ObjectId → User |
| `jobId` | ObjectId → Job |
| `type` | `job_fee` \| `job_payout` |
| `method` | `mock` \| `razorpay` |
| `amount` | Number |
| `status` | `created` \| `paid` \| `failed` |
| `razorpayOrderId`, `razorpayPaymentId` | String |
| `raw` | Mixed | Razorpay order payload |

**Indexes:** `orderId` unique; `userId`; `status`; `createdAt` desc; `{ jobId: 1, type: 1 }`.

---

## `ratings`

| Field | Type |
| --- | --- |
| `jobId` | ObjectId → Job |
| `fromUserId`, `toUserId` | ObjectId → User |
| `stars` | 1–5 |

**Indexes:** `{ jobId: 1, fromUserId: 1, toUserId: 1 }` **unique**; `toUserId`; `{ toUserId: 1, createdAt: -1 }`.

---

## `reviews`

| Field | Type |
| --- | --- |
| `jobId` | ObjectId → Job |
| `ratingId` | ObjectId → Rating |
| `fromUserId`, `toUserId` | ObjectId → User |
| `stars` | 1–5 |
| `review` | String |

**Indexes:** `toUserId`; `{ toUserId: 1, createdAt: -1 }`; `jobId`.

---

## `notifications`

| Field | Type |
| --- | --- |
| `userId` | ObjectId → User |
| `title` | String |
| `body` | String |
| `type` | String (default `general`) |
| `data` | Mixed |
| `read` | Boolean |

**Indexes:** `userId`; `{ userId: 1, createdAt: -1 }`; `{ userId: 1, read: 1 }`.

---

## `reports`

| Field | Type |
| --- | --- |
| `reporterId` | ObjectId → User |
| `targetType` | `user` \| `job` \| `sos` |
| `targetId` | ObjectId (optional; SOS may omit) |
| `reason`, `details`, `adminNote` | String |
| `status` | `open` \| `reviewed` \| `resolved` \| `dismissed` |

SOS stores `{ lat, lng, contactName, contactPhone }` as JSON in `details`.

**Indexes:** `status`; `createdAt` desc; `{ targetType: 1, targetId: 1 }`.

---

## `referrals` (schema only — no HTTP routes)

| Field | Type |
| --- | --- |
| `referrerId` | ObjectId → User |
| `referredId` | ObjectId → User |
| `code` | String, **unique** |
| `status` | `pending` \| `completed` \| `paid` |
| `reward` | Number |

**Indexes:** `code` unique; `referrerId`.

---

## `services` (Phase 2 stub)

| Field | Type |
| --- | --- |
| `providerId` | ObjectId → User |
| `title` | String |
| `category`, `description`, `address` | String |
| `price` | Number |
| `location` | GeoJSON Point |
| `active` | Boolean |

**Indexes:** `providerId`; `location` **2dsphere**; `{ category: 1, createdAt: -1 }`.

---

## `marketplace_listings` (Phase 2 stub)

| Field | Type |
| --- | --- |
| `sellerId` | ObjectId → User |
| `title`, `description`, `category`, `address` | String |
| `price` | Number |
| `images` | [String] |
| `location` | GeoJSON Point |
| `status` | `active` \| `sold` \| `hidden` |

**Indexes:** `sellerId`; `status`; `location` **2dsphere**; `{ category: 1, createdAt: -1 }`.

---

## `admin_users`

| Field | Type |
| --- | --- |
| `email` | String, **unique**, lowercase |
| `passwordHash` | String (bcrypt) |
| `name` | String |
| `role` | String (default `admin`) |

**Indexes:** `email` unique.

Seed: `admin@time2work.com` / `Admin@123`.

---

## `settings`

Single document (API uses `findOne`). Defaults from `SETTINGS_DEFAULTS`:

| Field | Default |
| --- | --- |
| `jobPostingFee` | 19 |
| `commissionPercent` | 10 |
| `referralReward` | 0 |
| `primaryRadiusKm` | 5 |
| `secondaryRadiusKm` | 10 |

No extra indexes beyond `_id`. Cached in process for 15 seconds.

---

## `otps`

| Field | Type |
| --- | --- |
| `phone` | String, indexed |
| `codeHash` | String (bcrypt) |
| `expiresAt` | Date |
| `attempts` | Number |

**Indexes:** `phone`; TTL `{ expiresAt: 1 }` with `expireAfterSeconds: 0` (Mongo drops the row at `expiresAt`). Codes live 10 minutes at insert time.

---

## Seed snapshot

`npm run seed` upserts settings + categories + admin + demo users, then recreates seed jobs.

| Account | Key |
| --- | --- |
| Worker Ravi Kumar | phone `9999990001`, Andheri East (~19.1136, 72.8697) |
| Business Amit Sharma / Sharma Contractors | phone `9999990002`, Bandra West (~19.0596, 72.8295) |
| Admin | `admin@time2work.com` |

Open sample jobs sit around **19.0760, 72.8777** (Dadar / Sion / Kurla / Chembur / Andheri). One completed electrician job + payout + chat + rating is included for earnings demo.
