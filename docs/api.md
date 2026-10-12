# Field CRM — Backend API Specification

This document describes the HTTP API the mobile app expects. It is derived one-to-one from the
repository interfaces in `lib/features/*/domain/*_repository.dart` and the entity shapes in
`lib/features/*/domain/*.dart`. The app today runs against an in-memory mock that implements exactly
these rules (`lib/features/*/data/mock_*_repository.dart`); a real backend that follows this
document can replace it by editing only `lib/app/providers.dart`.

Contents

1. Conventions
2. Errors
3. Entities (JSON schemas)
4. Endpoints
   - Auth & profile
   - Users & team
   - Pipeline stages & activity types
   - Customers
   - Opportunities
   - Activities, follow-ups & notes
   - History
   - Dashboard & search
   - Products, quotations & invoices
   - Notifications
5. Offline queue & idempotency
6. Permissions matrix
7. Validation rules

---

## 1. Conventions

| Item | Rule |
|---|---|
| Base URL | `https://<host>/api/v1` (configured per flavor in `env/<flavor>.json`) |
| Transport | HTTPS, JSON request and response bodies, `Content-Type: application/json; charset=utf-8` |
| Auth | `Authorization: Bearer <token>` on every call except `POST /auth/login`, `POST /auth/password/forgot`, `POST /auth/password/reset` |
| IDs | Opaque strings. **Creates are client-generated UUID v4** (`id` is sent by the app) so retries are idempotent. |
| Timestamps | ISO-8601 in UTC with `Z`, e.g. `2026-10-12T09:15:00.000Z`. The app converts to the user's `timezone` for display. |
| Money | JSON numbers (double), currency implied by the deployment (`CURRENCY_CODE`, NPR today). No currency field. |
| Enums | Lower camel-case strings, exactly as listed in section 3. |
| Lists | Returned as plain JSON arrays. No pagination today; the app expects full lists (seed scale: tens to low hundreds). Add `?limit`/`?cursor` later without breaking clients if omitted. |
| Optimistic concurrency | Every update carries `expectedUpdatedAt`. The server compares it with the stored `updatedAt`; a mismatch is `409 conflict`. On success the server sets a new `updatedAt` and returns the full record. |
| Scope | "Visible" opportunities and activities are the caller's own, or the whole team's when `permissions.canViewTeam` is true. Customers, products and stages are visible to every active user. |
| Timezone-aware grouping | Dashboard and follow-up groups (today / upcoming / overdue) are computed in the user's `timezone`. |

Success responses return the resource(s) directly (no envelope):

```json
{ "id": "c-001", "name": "Himalayan Traders", "...": "..." }
```

---

## 2. Errors

Every non-2xx response has this body. The app maps `code` to its sealed `Failure` type; the two
transient codes are queued for retry, the others are final and shown to the user.

```json
{
  "error": {
    "code": "validation",
    "message": "Phone must be digits with optional +, spaces or dashes (e.g. +977 98XXXXXXXX)",
    "field": "phone"
  }
}
```

| HTTP | `code` | App behaviour | `field` |
|---|---|---|---|
| 400 / 422 | `validation` | Final. `message` is shown **verbatim**; when `field` is present it is shown under that form field (`name`, `email`, `phone`, `parentId`, `customerId`, `stageId`, `ownerId`, `summary`, `dueAt`, `relatedId`, `expectedRevenue`, `probability`, `items`, `current`, `next`, `code`). | optional |
| 401 | `permissionDenied` | Final. Session is invalid or expired → app returns to login. | — |
| 403 | `permissionDenied` | Final. Shown as "You don't have permission". | — |
| 404 | `unknown` | Final. `message` optional. | — |
| 409 | `conflict` | Final. App offers "Reload latest" / "Keep editing". | — |
| 408 / 5xx / network | `timeout` / `network` | **Transient.** Write is saved to the encrypted pending queue and retried (see section 5). | — |

Two auth-specific validation messages are matched by the app by exact `message` value:
`invalid_credentials` and `inactive_account` (login), and `invalid_code` (password reset).

---

## 3. Entities

Field tables list JSON key, type, and whether the client sends it on create. `R` = read-only (server sets).

### AppUser

| key | type | notes |
|---|---|---|
| `id` | string | |
| `name` | string | |
| `email` | string | unique, case-insensitive |
| `role` | `salesperson` \| `supervisor` | |
| `teamId` | string | |
| `permissions` | Permissions | computed by the server from role/policy; the app never checks roles directly |
| `timezone` | string | IANA zone, default `UTC` |
| `isActive` | bool | inactive users cannot log in |
| `phone` | string? | |
| `avatarPath` | string? | URL of the profile photo (the mock stores a device path) |

Permissions: `canCreateCustomer`, `canEditCustomer`, `canCreateOpportunity`, `canEditOpportunity`,
`canChangeStage`, `canReassign`, `canViewTeam`, `canLogActivity` — all bool, default false.

```json
{
  "id": "u-sita", "name": "Sita Gurung", "email": "sita@fieldcrm.test",
  "role": "salesperson", "teamId": "t-ktm", "timezone": "Asia/Kathmandu", "isActive": true,
  "phone": "+977 9841000000", "avatarPath": null,
  "permissions": { "canCreateCustomer": true, "canEditCustomer": true, "canCreateOpportunity": true,
    "canEditOpportunity": true, "canChangeStage": true, "canReassign": false,
    "canViewTeam": false, "canLogActivity": true }
}
```

### Session

```json
{ "token": "eyJ...", "user": { "...AppUser" } }
```

### Customer

| key | type | create |
|---|---|---|
| `id` | string | client UUID |
| `name` | string | required |
| `isCompany` | bool | default false |
| `parentId` | string? | must reference an existing company |
| `phone`, `email`, `address`, `city`, `country`, `taxId` | string? | optional |
| `updatedAt` | datetime | R |

### Opportunity

| key | type | create |
|---|---|---|
| `id` | string | client UUID |
| `title` | string | required |
| `customerId` | string | required, must exist |
| `stageId` | string | required, must exist; cannot be changed via update (use change-stage) |
| `ownerId` | string | server sets to caller on create; changed only via reassign |
| `teamId` | string | R, from owner |
| `expectedRevenue` | number | ≥ 0 |
| `probability` | int | 0–100 |
| `nextActionAt` | datetime? | |
| `nextActionSummary` | string? | |
| `updatedAt` | datetime | R |

### PipelineStage

```json
{ "id": "s-new", "name": "New", "sequence": 1, "isWon": false, "isFolded": false,
  "allowedNextStageIds": ["s-qualified", "s-lost"] }
```

A move from stage A to B is allowed only when `B ∈ A.allowedNextStageIds`. `isWon` marks the
terminal success stage (excluded from "open" totals). `isFolded` stages render collapsed on the kanban.

### Activity

| key | type | notes |
|---|---|---|
| `id` | string | client UUID |
| `type` | `call` \| `visit` \| `meeting` \| `note` \| `todo` | `todo` is the follow-up type |
| `relatedType` | `customer` \| `opportunity` | |
| `relatedId` | string | must exist and be visible |
| `summary` | string | required. Notes may contain `@Full Name` mentions |
| `ownerId` | string | server sets to caller when empty |
| `state` | `planned` \| `done` \| `overdue` | R, derived: follow-ups are `planned` until completed, `overdue` when `dueAt` has passed; interactions are `done` |
| `outcome` | string? | set on completion |
| `dueAt` | datetime? | required for follow-ups; interactions carry the time they were logged |
| `attachments` | string[] | URLs (the mock stores device paths) |
| `updatedAt` | datetime | R |

ActivityTypeDef (reference data): `{ "type": "call", "label": "Call", "isFollowUp": false }`.

### HistoryEntry

```json
{ "id": "h-1", "kind": "stageChange", "at": "2026-10-10T08:00:00.000Z", "actorName": "Sita Gurung",
  "from": "New", "to": "Qualified", "text": null }
```

`kind` ∈ `activity` | `note` | `stageChange` | `ownerChange`. `from`/`to` are used by the two change
kinds; `text` by `activity` and `note` (summary, plus " — outcome" when present).

### Product

```json
{ "id": "p-001", "name": "Water purifier 10L", "unitPrice": 18500, "unit": "unit", "isActive": true }
```

### Quotation & QuotationItem

| key | type | create |
|---|---|---|
| `id` | string | client UUID |
| `number` | string | R, server-assigned, e.g. `Q-0001` |
| `customerId` | string | required |
| `opportunityId` | string? | optional link |
| `ownerId` | string | R, caller |
| `items` | QuotationItem[] | ≥ 1 |
| `notes` | string? | |
| `status` | `draft` \| `confirmed` | R |
| `createdAt`, `updatedAt` | datetime | R |

QuotationItem: `description` (string, required), `productId` (string?, must exist when present),
`quantity` (number > 0, default 1), `unitPrice` (number ≥ 0). Line total = `quantity × unitPrice`;
quotation total = sum of line totals (computed client-side; the server may also return `total`).

### Invoice

```json
{ "id": "inv-1", "number": "INV-0001", "quotationId": "q-1", "customerId": "c-001",
  "amount": 37000, "status": "pending", "dueAt": "2026-11-11T09:15:00.000Z",
  "createdAt": "2026-10-12T09:15:00.000Z", "paidAt": null }
```

`status` ∈ `pending` | `paid`. Default due date is creation + 30 days.

### AppNotification

```json
{ "id": "n-1", "userId": "u-ram", "kind": "mention", "title": "Sita Gurung mentioned you",
  "body": "@Ram Thapa please call them back", "createdAt": "2026-10-12T09:15:00.000Z",
  "relatedType": "customer", "relatedId": "c-001", "readAt": null }
```

`kind` ∈ `mention` | `assignment` | `invoice` | `reminder`.

### DashboardSummary, SearchResults, TeamOverview

```json
{ "today": [Activity], "upcoming": [Activity], "overdue": [Activity], "noFollowUp": [Opportunity] }
```
```json
{ "customers": [Customer], "contacts": [Customer], "opportunities": [Opportunity] }
```
```json
{ "team": { "id": "t-ktm", "name": "Kathmandu", "supervisorId": "u-maya" },
  "members": [ { "user": AppUser, "openOpportunities": [Opportunity], "overdueActivities": [Activity] } ] }
```

---

## 4. Endpoints

### Auth & profile

#### POST /auth/login
```json
{ "email": "sita@fieldcrm.test", "password": "password", "rememberMe": true }
```
200 → Session. Token lifetime is long when `rememberMe` is true (the app stores it in secure
storage), otherwise it should expire with the session.
Errors: `validation` with `message: "invalid_credentials"`; `validation` with `message: "inactive_account"`.

#### GET /auth/session
Restores a remembered token. 200 → Session. 200 with body `null` when the token is unknown or the user is now inactive (the app then clears the stored token). Never 401 here.

#### POST /auth/logout
Invalidates the bearer token. 200, empty body.

#### PATCH /auth/profile
```json
{ "name": "Sita Gurung", "phone": "+977 9841000000", "avatarPath": "https://…/avatars/u-sita.jpg" }
```
200 → AppUser. Validation: `name` required; `phone` format (section 7). A photo upload endpoint
(`POST /files` multipart → `{ "url": "…" }`) is expected to produce `avatarPath`; the app currently
sends a local path, so swap that for the uploaded URL in the data layer.

#### POST /auth/password/change
```json
{ "current": "password", "next": "n3w-password" }
```
200 empty. Errors: `validation` field `current` ("Current password is wrong"); field `next` ("Use at least 8 characters").

#### POST /auth/password/forgot
```json
{ "email": "sita@fieldcrm.test" }
```
200 → `{ "code": null }`. Always 200 regardless of whether the email exists. Send the one-time
code by email/SMS. (The mock returns the code in `code` so dev builds can display it.)

#### POST /auth/password/reset
```json
{ "email": "sita@fieldcrm.test", "code": "482913", "newPassword": "n3w-password" }
```
200 empty. Errors: `validation` field `code`, `message: "invalid_code"` (wrong or expired); field `next` for a short password.

### Users & team

#### GET /users
Users the caller may see (used for names in lists and @mention suggestions). 200 → AppUser[].

#### GET /users/assignable
Active users the caller may reassign records to (same team). 200 → AppUser[].

#### GET /team/overview
Requires `canViewTeam`, else 403. 200 → TeamOverview.

### Reference data

#### GET /pipeline/stages → PipelineStage[] ordered by `sequence`.
#### GET /activity-types → ActivityTypeDef[].
#### GET /products → Product[] where `isActive`, sorted by name.

### Customers

#### GET /customers?query=
`query` filters by name (case-insensitive contains). Sorted by name. 200 → Customer[].

#### GET /customers/{id} → Customer | 404.

#### POST /customers
Body: Customer (without `updatedAt`). If a record with the same `id` already exists, return it
with 200 (idempotent retry). Requires `canCreateCustomer`. Validation per section 7.
200 → Customer.

#### PUT /customers/{id}
```json
{ "customer": { "...Customer" }, "expectedUpdatedAt": "2026-10-01T10:00:00.000Z" }
```
Requires `canEditCustomer`. 409 on stale `expectedUpdatedAt`. 200 → Customer.

### Opportunities

#### GET /opportunities?customerId=
Visible opportunities (scope rule), optionally for one customer. 200 → Opportunity[].

#### GET /opportunities/{id} → Opportunity | 404 (also 404 when not visible).

#### POST /opportunities
Body: Opportunity. Server sets `ownerId` = caller, `teamId` = caller's team. Requires
`canCreateOpportunity`. Idempotent on `id`. 200 → Opportunity.

#### PUT /opportunities/{id}
```json
{ "opportunity": { "...Opportunity" }, "expectedUpdatedAt": "…" }
```
Requires `canEditOpportunity`. `stageId` and `ownerId` in the body are ignored. 409 on conflict.

#### POST /opportunities/{id}/stage
```json
{ "toStageId": "s-qualified", "expectedUpdatedAt": "…" }
```
Requires `canChangeStage`. Rejects with `validation` field `stageId`,
`message: "Cannot move from <From> to <To>"` when the transition is not in
`allowedNextStageIds`. Appends a `stageChange` history entry. 200 → Opportunity.

#### POST /opportunities/{id}/reassign
```json
{ "newOwnerId": "u-ram", "expectedUpdatedAt": "…" }
```
Requires `canReassign`. New owner must be an active member of the caller's team, else
`validation` field `ownerId`. Appends an `ownerChange` history entry and creates an
`assignment` notification for the new owner. 200 → Opportunity.

### Activities, follow-ups & notes

#### GET /activities?relatedType=&relatedId=&ownerId=&state=&followUpsOnly=&dueFrom=&dueTo=
All filters optional and AND-ed. `state` is derived at read time (planned/done/overdue). Visible
scope applies. 200 → Activity[] (oldest first).

#### GET /activities/{id} → Activity.

#### POST /activities
Body: Activity. Requires `canLogActivity`. Rules:
- `summary` required.
- Follow-up types (`isFollowUp`) need `dueAt`, else `validation` field `dueAt`
  ("Follow-ups need a due date and time"); state becomes `planned`.
- Interaction types become `done` and get an `activity` (or `note`) history entry.
- `relatedId` must exist and be visible, else `validation` field `relatedId`.
- For `type: note`, every `@Full Name` matching a user in `GET /users` (other than the author)
  gets a `mention` notification.
- `attachments` are URLs returned by `POST /files`.
Idempotent on `id`. 200 → Activity.

#### POST /activities/{id}/complete
```json
{ "outcome": "Agreed to a demo", "expectedUpdatedAt": "…" }
```
Sets `state: done`, stores `outcome`, appends history. 409 on conflict. 200 → Activity.

#### POST /activities/{id}/reschedule
```json
{ "dueAt": "2026-10-14T04:30:00.000Z", "expectedUpdatedAt": "…" }
```
Only for follow-ups. 200 → Activity.

### History

#### GET /history/{relatedType}/{id}
Newest first. 200 → HistoryEntry[].

### Dashboard & search

#### GET /dashboard/summary
Computed for the caller in their timezone:
- `today`: planned follow-ups due before end of today
- `upcoming`: planned follow-ups due later
- `overdue`: follow-ups past due and not done
- `noFollowUp`: visible open opportunities with no planned follow-up and no `nextActionAt`
200 → DashboardSummary.

#### GET /search?q=
Case-insensitive match on customer name, phone, email (companies → `customers`, people →
`contacts`) and opportunity title (visible scope). Empty `q` → empty result. 200 → SearchResults.

### Products, quotations & invoices

#### GET /quotations?customerId=&opportunityId= → Quotation[] newest first.
#### GET /quotations/{id} → Quotation.

#### POST /quotations
Body: Quotation with `items`. Requires `canCreateOpportunity`. Server assigns `number`
(`Q-0001`, sequential), `ownerId`, `status: draft`, timestamps. Validation: ≥ 1 item
(`field: items`, "Add at least one item"), each item description required, `quantity > 0`,
`unitPrice ≥ 0`, `productId` must exist when present, `customerId` must exist. Idempotent on `id`.
200 → Quotation.

#### POST /quotations/{id}/confirm
No body. Sets `status: confirmed`, creates an Invoice (`INV-0001` sequential, `amount` = total,
`dueAt` = now + 30 days). Confirming twice returns the same invoice (idempotent).
200 → Invoice.

#### GET /quotations/{id}/invoice → Invoice | 404 while still a draft.

#### GET /invoices?customerId=&pendingOnly=true|false → Invoice[] ordered by `dueAt`.

#### POST /invoices/{id}/paid
No body. Sets `status: paid`, `paidAt: now`. 200 → Invoice.

### Notifications

#### GET /notifications → AppNotification[] for the caller, newest first.
#### POST /notifications/{id}/read → 200 empty (no-op if already read or not the caller's).
#### POST /notifications/read-all → 200 empty.

Notification producers today: `mention` (note with `@Name`), `assignment` (reassign). `invoice`
and `reminder` kinds are reserved for the backend (e.g. invoice overdue, follow-up due).

---

## 5. Offline queue & idempotency

When a write fails with a transient error (`network`, `timeout`), the app stores it in an encrypted
local queue and replays it later, unchanged, with the **same client-generated `id`**. The backend
must therefore make these operations idempotent:

| Operation | Idempotency rule |
|---|---|
| `POST /customers`, `/opportunities`, `/activities`, `/quotations` | Same `id` already exists → return the existing record with 200, do not create a duplicate. |
| `PUT …` / `POST …/stage` / `…/reassign` / `…/complete` / `…/reschedule` | Guarded by `expectedUpdatedAt`; a replay after the first success yields `409`, which the app treats as final (the user reloads). |

Queued operations (`WriteOperation`): `customerCreate`, `customerUpdate`, `opportunityCreate`,
`opportunityUpdate`, `opportunityStageChange`, `opportunityReassign`, `activityCreate`,
`activityComplete`, `activityReschedule`. Items older than `PENDING_MAX_AGE_DAYS` (7) are marked
failed client-side and never replayed. Quotation and notification writes are online-only today.

Only after the server has acknowledged a write does the app say "Saved"; it never shows local
state as confirmed.

---

## 6. Permissions matrix

| Action | Permission flag |
|---|---|
| Create customer | `canCreateCustomer` |
| Edit customer | `canEditCustomer` |
| Create opportunity, create/confirm quotation, mark invoice paid | `canCreateOpportunity` |
| Edit opportunity | `canEditOpportunity` |
| Change stage | `canChangeStage` |
| Reassign (handover) | `canReassign` |
| View team overview, see team-wide opportunities/activities | `canViewTeam` |
| Log interactions, follow-ups, notes | `canLogActivity` |

Seed roles: salesperson has everything except `canReassign` and `canViewTeam`; supervisor has all.
The server is the source of truth: the app only reads the flags from `AppUser.permissions`.

---

## 7. Validation rules (messages shown verbatim)

| Field | Rule | Message |
|---|---|---|
| any required | non-blank | `<Label> is required` |
| `email` | `^[\w.+-]+@[\w-]+\.[\w.-]+$` | `Email must look like name@example.com` |
| `phone` | `^\+?[0-9][0-9 -]{6,17}[0-9]$` | `Phone must be digits with optional +, spaces or dashes (e.g. +977 98XXXXXXXX)` |
| `parentId` | existing company | `Parent company does not exist` |
| `customerId` | existing customer | `Customer does not exist` |
| `probability` | 0–100 | `Probability must be between 0 and 100` |
| `expectedRevenue` | ≥ 0 | `Expected revenue must be between 0 and …` |
| `ownerId` (reassign) | active, same team | `Owner must be an active member of your team` |
| `stageId` (stage) | allowed transition | `Cannot move from <A> to <B>` |
| `dueAt` (follow-up) | present | `Follow-ups need a due date and time` |
| `items` (quotation) | ≥ 1 | `Add at least one item` |
| `next` (password) | ≥ 8 chars | `Use at least 8 characters` |
| `current` (password) | matches | `Current password is wrong` |
| `code` (reset) | valid, unexpired | message `invalid_code` |
| login | | message `invalid_credentials` / `inactive_account` |

The app also validates `name`, `email`, phone length and numeric fields inline before calling the
API, but treats the server as authoritative and displays any `validation` error it returns.
