# Spike SDK/API vs Open Wearables — Side-by-side Comparison

Date: 2026-04-20
Sources:
- Spike Flutter SDK docs: https://docs.spikeapi.com/sdk-docs/flutter/overview, /usage-guide, /background-delivery
- Open Wearables Flutter SDK README: https://github.com/the-momentum/open_wearables_health_sdk
- Open Wearables platform README: https://github.com/the-momentum/open-wearables

## Executive summary

| Dimension | Spike | Open Wearables |
|---|---|---|
| Product model | SaaS (Spike hosts everything) | Self-hosted open-source (you run the backend) |
| Cost model | Subscription, per active user | Infra cost only (servers + DB) |
| On-device sources (iOS/Android/Samsung) | ✅ Full (SDK) | ✅ Full (SDK) |
| Cloud provider coverage (OAuth) | ✅ Garmin, Fitbit, Oura, Whoop, Polar, Withings, many more | ⚠️ Garmin, Suunto, Polar only — "more coming soon" (Fitbit/Whoop/Oura not yet) |
| App-side local read of SDK data | ✅ `getStatistics`, `getRecords` | ❌ No — SDK is write-only (to backend) |
| Background sync | ✅ iOS HKObserverQuery + HKBackgroundDelivery; Android WorkManager | ✅ iOS BGTaskScheduler; Android WorkManager with foreground notification |
| Maturity | Production-grade, SaaS since 2022 | OSS, v0.0.15 Flutter SDK as of fetch; active but early |
| License | Commercial | MIT |

**TL;DR for Cureocity replacement:** Open Wearables covers the on-device half 1:1 and Garmin (you use Garmin today). It does **not** yet cover Fitbit (you use Fitbit today). The SDK is write-only, so the app architecture will shift from "app ↔ Spike-cloud via GraphQL digest on Cureocity backend" to "app pushes → your self-hosted Open Wearables backend → your Cureocity backend via webhook (or collapsed direct-to-Cureocity)".

---

## 1. Architecture

### Spike
```
Device sensors
   ↓ (Spike SDK: HealthKit / HealthConnect / Samsung)
Spike cloud (SaaS)         ← also OAuth ingress from Garmin/Fitbit/Oura/Whoop/Polar clouds
   ↓ (REST API + webhooks)
Your backend
   ↓ (GraphQL)
Your app (reads digests)
```
- Data flows both directions between SDK and Spike cloud: SDK pushes device data via "backfill"; `getStatistics`/`getRecords` also let the app read back aggregates.
- Cureocity consumes daily digests via GraphQL (`getSpikeDigest`) pulled from Cureocity backend, which in turn pulls from Spike REST.

### Open Wearables
```
Device sensors
   ↓ (Open Wearables SDK)
Self-hosted Open Wearables backend (FastAPI + Postgres + Redis + Celery)
   ↑ (OAuth ingress from Garmin/Suunto/Polar)         ← you run this
   ↓ (REST "unified API" + webhooks — "coming soon")
Your app / downstream systems
```
- Data flows **one way** from SDK to backend. The SDK has no read API; the app queries data from the backend.
- Self-hosted. Every deployment is single-tenant by design.
- Backend is FastAPI (Python) + PostgreSQL + Redis + Celery. Frontend is a React/TanStack admin/dev portal.

---

## 2. Authentication

| Aspect | Spike | Open Wearables |
|---|---|---|
| Per-app credentials | `applicationId` + server-signed `signature` per end user | API key OR (accessToken + refreshToken) per end user |
| Init call | `SpikeSDKV3.createConnection(applicationId, signature, endUserId)` | `OpenWearablesHealthSdk.configure({host, customSyncUrl?})` + `signIn({userId, accessToken, refreshToken, apiKey?})` |
| Credential storage | Spike SDK stores session internally | iOS Keychain / Android EncryptedSharedPreferences |
| Token refresh | Handled via Spike server | SDK hits `{host}/api/v1/token/refresh` automatically |
| Where signing/server secret lives | Cureocity backend generates signature | Cureocity backend (or Open Wearables backend) issues tokens |

Practical difference: **Spike needs a server-signed blob per user; Open Wearables needs an access/refresh pair or an API key per user.** Both require Cureocity backend to issue per-user credentials — no real asymmetry here.

---

## 3. SDK surface (Flutter)

### Spike key methods (`SpikeConnectionV3`)
- `SpikeSDKV3.createConnection({applicationId, signature, endUserId})`
- `requestPermissionsFromHealthKitAndBackfill(...)` (iOS) — permissions + historical backfill upload
- `requestPermissionsFromHealthConnectAndBackfill(...)` (Android)
- `requestHealthPermissions({statisticTypes, includeEnhancedPermissions})`
- `getStatistics({ofTypes, from, to, interval})` — hourly/daily aggregated reads
- `getRecords(...)` — raw event-level reads
- Samsung Health Data: separate usage guide (Android)
- Background delivery: `enableBackgroundDelivery(...)` on the connection; OS-specific hooks

### Open Wearables key methods (`OpenWearablesHealthSdk`)
- `configure({host, customSyncUrl?})`
- `signIn({userId, accessToken?, refreshToken?, apiKey?})`, `signOut()`, `updateTokens(...)`
- `requestAuthorization({types})`
- `syncNow()`, `startBackgroundSync()`, `stopBackgroundSync()`
- `getSyncStatus()`, `resetAnchors()`, `resumeSync()`, `clearSyncSession()`
- `getAvailableProviders()`, `setProvider(AndroidHealthProvider)` (Android: choose Samsung vs Health Connect)
- `getStoredCredentials()` (debug)

**Structural differences**:
- Spike exposes **read APIs** (`getStatistics`, `getRecords`); Open Wearables does **not** — no way to fetch data from the SDK.
- Open Wearables has an explicit **`syncNow()`** trigger; Spike uses "backfill" on permission grant + background delivery thereafter.
- Open Wearables has an **anchor-based incremental** model (`resetAnchors`, `resumeSync`), directly addressable; Spike abstracts this away.
- Open Wearables Android has a **first-class provider picker** (`getAvailableProviders`); Spike picks Samsung vs Health Connect based on install state.

---

## 4. Permissions model

| Aspect | Spike | Open Wearables |
|---|---|---|
| Requested as | Per-metric list on demand | Array of data types in `requestAuthorization` |
| Re-prompt needed after app restart | **Yes** — `requestHealthPermissions` must be called each restart (per docs) | No mention; SDK appears to persist |
| Granular revocation visible to app | Limited (OS-level) | OS-level (same) |
| Enhanced permissions concept | Yes (`includeEnhancedPermissions`) | No equivalent flag exposed |

---

## 5. Data types supported by each SDK

### Spike `StatisticsType` (observed from docs; not exhaustive)
`steps`, `distance`, and many more (Spike docs show `StatisticsType.steps` as the example; full enum lives in source). Spike platform also exposes derived metrics: **stress score**, **readiness score**, **sleep score**, **activity score**, **body composition** (via Garmin/Whoop/Oura).

### Open Wearables (explicit from README)
| Category | Types |
|---|---|
| Activity | steps, distanceWalkingRunning, flightsClimbed |
| Energy | activeEnergy, basalEnergy |
| Heart | heartRate, restingHeartRate, heartRateVariabilitySDNN, vo2Max, oxygenSaturation |
| Respiratory | respiratoryRate |
| Body | bodyMass, height, bodyFatPercentage, leanBodyMass, bodyTemperature |
| Blood | bloodGlucose, bloodPressure, bloodPressureSystolic, bloodPressureDiastolic |
| Nutrition | dietaryWater |
| Sleep | sleep |
| Workouts | workout |

### Mapping to Cureocity `HealthMetric` enum (from `packages/health_integration/lib/src/models/health_metric.dart`)
| Cureocity metric | Spike | Open Wearables | Gap? |
|---|---|---|---|
| steps | ✅ | ✅ | — |
| sleepDuration | ✅ | ✅ (`sleep`) | — |
| heartrate | ✅ | ✅ (`heartRate`) | — |
| bodyTemperature | ✅ | ✅ | — |
| bloodPressure | ✅ | ✅ (+systolic/diastolic) | — |
| hrv | ✅ | ✅ (`heartRateVariabilitySDNN`) | — |
| spo2 | ✅ | ✅ (`oxygenSaturation`) | — |
| breathingRate | ✅ | ✅ (`respiratoryRate`) | — |
| calories | ✅ | ⚠️ derive from `activeEnergy + basalEnergy` | minor |
| bodyComposition | ✅ (Spike normalizes from Garmin/Oura) | ⚠️ partial (`bodyFat + leanMass + bodyMass`) | medium |
| stressScore | ✅ (derived on Spike server) | ❌ not computed | **hard gap** |

---

## 6. Cloud provider coverage (OAuth ingress)

| Provider | Spike | Open Wearables | Cureocity uses today? |
|---|---|---|---|
| Garmin | ✅ | ✅ | **Yes** |
| Fitbit | ✅ | ❌ ("more coming soon") | **Yes** — **blocker** |
| Oura | ✅ | ❌ | — |
| Whoop | ✅ | ❌ | — |
| Polar | ✅ | ✅ | — |
| Suunto | ✅ | ✅ | — |
| Withings | ✅ | ❌ | — |
| Apple Health | SDK | SDK | Yes |
| Health Connect | SDK | SDK | Yes |
| Samsung Health | SDK | SDK | Yes |

**Implication:** Cureocity cannot drop Spike today without a Fitbit story — either implementing Fitbit OAuth in the Open Wearables fork (contribution back to upstream), building it in Cureocity backend, or keeping Spike alive for Fitbit-only users.

---

## 7. Background sync behavior

| Aspect | Spike | Open Wearables |
|---|---|---|
| iOS mechanism | HKObserverQuery + HKBackgroundDelivery (per data type) | BGTaskScheduler with identifiers `com.openwearables.healthsdk.task.refresh` / `task.process` |
| iOS frequency | Most data types: up to 1/hour; vo2Max faster; throttled | "Background sync" (frequency not specified in README; needs source read) |
| Android mechanism | WorkManager-based | WorkManager + **foreground service with user-visible notification** (`setSyncNotification` required) |
| Graceful resume on interrupt | Not documented | Explicit `resumeSync()` + `clearSyncSession()` + `getSyncStatus()` |
| Upload granularity | Delta since last backfill | Anchor-based incremental (`resetAnchors` resets) |

Open Wearables' Android **foreground-notification requirement** is a UX change from Spike — users will see a persistent "syncing health data" notification. Might be worth hiding/minimizing or batching.

---

## 8. Backend & data consumption

| Aspect | Spike | Open Wearables |
|---|---|---|
| Hosting | SaaS | Self-hosted (Docker Compose, or cloud-deployed) |
| Storage | Spike's DB | Your Postgres |
| API to consumers | REST + webhooks | REST "unified API" + webhooks (webhooks currently "coming soon" label) |
| Admin/dev UI | Spike dashboard | React + TanStack dev portal (open source) |
| Data normalization | Proprietary schema | Unified schema (documented in openwearables.io/docs) |
| Historical backfill | Via Spike REST (`/users/:id/data/...`) | Via your own Postgres query / REST |
| Privacy | Data lives on Spike servers | Data lives on your infra only |

---

## 9. What maps to Cureocity's current Spike usage (actionable)

### Already covered cleanly (Flutter SDK swap is straightforward)
- `SpikeSDKV3.createConnection` → `configure` + `signIn`
- `requestPermissionsFromHealthKitAndBackfill` / `HealthConnect` → `requestAuthorization` + `syncNow`
- Provider listing (Apple Health, Health Connect, Samsung) → `getAvailableProviders` + `setProvider`
- Background delivery → `startBackgroundSync` (note Android notification UX)
- Daily digest → NOT in SDK; the app must fetch from Cureocity backend, which reads from Open Wearables backend (REST) or your own DB

### Needs new code or workaround
1. **App-local reads** (`getStatistics`, `getRecords`): Cureocity doesn't appear to rely on these — data comes through GraphQL from backend. So this gap is **not** blocking for Cureocity specifically.
2. **`stressScore`**: Spike computes on server; Open Wearables does not. Either drop the metric, compute in Cureocity backend from HRV+sleep heuristics, or add to the Open Wearables fork as a derived metric (upstream contribution candidate).
3. **`calories`** unification: trivial backend-side math (`active + basal`).
4. **Fitbit OAuth**: Hard gap. Not provided. Candidate for a sub-project of its own — either contribute upstream to Open Wearables, or keep Spike for Fitbit users.

### Out of scope for the demo (address later)
- Backend ingestion into Cureocity from Open Wearables (webhook or direct sync protocol) — sub-project B/backend.
- GraphQL digest query rewrite in `workout-management/src/spike/` to read from Open Wearables DB/REST instead of Spike REST — sub-project B/backend.

---

## 10. Risk register (for demo + replacement plan)

| Risk | Severity | Mitigation |
|---|---|---|
| Fitbit not supported by Open Wearables | **High** | Plan Fitbit separately; keep Spike for Fitbit users temporarily; or build OAuth in fork |
| `stressScore` missing | Medium | Derive from HRV+sleep in Cureocity backend, or add to fork |
| SDK is write-only (no `getStatistics` equivalent) | Low for Cureocity (already uses backend digest), high for other consumers | Backend owns all read paths — Cureocity already does this |
| Android foreground notification UX regression | Low | Customize `setSyncNotification`; user education |
| Open Wearables SDK is young (v0.0.x) | Medium | Fork, pin version, test thoroughly; contribute fixes upstream |
| Self-hosting ops cost | Medium | Start with single-VM Docker Compose; scale later |
| Sync protocol changes upstream | Medium | Pin upstream version; review diffs on upgrade |

---

## 11. Recommendation for next step (demo scope)

1. Fork both repos (Flutter SDK + platform).
2. Stand up the Open Wearables backend locally (`docker compose up`).
3. Build the parity-probe Flutter demo inside `open_wearables_health_sdk/example/`, using a service class (`OpenWearablesHealthService`) that mirrors Cureocity's `HealthService` interface for easy sub-project C drop-in.
4. **Exit criterion for the demo**: on a seeded iOS simulator and Android emulator, each of the 8 cleanly-covered metrics (steps, sleep, HR, bodyTemp, BP, HRV, SpO2, respiratoryRate) flows device → SDK → backend → verified in DB.
5. Defer Fitbit, stressScore, and the Cureocity-backend webhook wiring to follow-up sub-projects.
