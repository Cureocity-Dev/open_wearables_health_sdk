# Spike ⇄ Open Wearables — Provider Matrix + Cureocity Backend Migration Plan

**Date:** 2026-04-21
**Purpose:** (1) exact provider coverage gap; (2) concrete migration plan and effort estimate for replacing Cureocity's `workout-management/src/spike/*` with the Open Wearables backend.

---

## 1. Provider coverage — authoritative, today

### Open Wearables (live from the running backend's `GET /api/v1/oauth/providers`)

| Provider | Kind | Enabled |
|---|---|---|
| apple | SDK (HealthKit) | ✅ |
| samsung | SDK (Samsung Health) | ✅ |
| google | SDK (Health Connect) | ✅ |
| garmin | Cloud OAuth | ✅ |
| polar | Cloud OAuth | ✅ |
| suunto | Cloud OAuth | ✅ |
| whoop | Cloud OAuth | ✅ |
| strava | Cloud OAuth | ✅ |
| oura | Cloud OAuth | ✅ |
| fitbit | Cloud OAuth | ✅ |
| ultrahuman | Cloud OAuth | ✅ |

Schemas + workout-type mappings confirmed in source at `backend/app/schemas/providers/{apple,polar,whoop,strava,oura,mobile_sdk,garmin,suunto,fitbit,...}/` and `backend/app/constants/workout_types/*.py`.

### Spike API (per public docs + admin console, April 2026)

SDK-based (same three as OW):
- apple, samsung, google

Cloud / OAuth providers (Spike marketing list, widely advertised):
- garmin, fitbit, oura, whoop, polar, withings, suunto, strava, **peloton**, **zepp** (Amazfit/Huami), **ihealth**, **cronometer**, **lifesum**, **concept2**, **renpho**, **freestyle libre** (CGM), (and more — list grows each quarter)

Note: Spike doesn't publish a clean machine-readable provider list on its docs site; the above reflects their marketing and admin console options as of 2026-04. Treat as indicative, not exhaustive — add/remove one or two if Spike's console currently differs.

### The real gap (everything Spike covers that Open Wearables does NOT)

| Spike has | OW missing | Cureocity uses today? |
|---|---|---|
| Withings | ❌ | No (confirm with product) |
| Peloton | ❌ | No |
| Zepp (Amazfit/Huami) | ❌ | No |
| iHealth | ❌ | No |
| Cronometer | ❌ | No |
| Lifesum | ❌ | No |
| Concept2 | ❌ | No |
| Renpho | ❌ | No |
| FreeStyle Libre CGM | ❌ | **Relevant** — Cureocity has a CGM feature (see `features/cgm/`). Worth checking whether they pull it via Spike today. |
| Dexcom / Medtronic CGM | ❌ | — |

**Spike also bundles derived metrics** that Open Wearables does not expose:
- `stress_score`
- `readiness_score`
- Some vendor-specific summary endpoints

### The real advantage (OW has, Spike does not / does later)

- **Ultrahuman** — OW has, Spike does not (as of this writing).
- **Suunto native integration** — both have it.
- **Self-hosted** — obvious structural differentiator.
- **Open Wearables has cleaner unified summary endpoints** (`/summaries/activity`, `/summaries/sleep`, `/summaries/recovery`, `/summaries/body`) — Spike's equivalent is more per-provider + raw `/queries/statistics/*` and requires client-side aggregation.

### Verdict for Cureocity specifically

Cureocity today authenticates users against **Spike for Apple Health, Health Connect, Samsung, Garmin, and Fitbit** (per `spike_provider_extension.dart` and `workout-management/src/spike/*.spec.ts`). All 5 of those are **covered** by Open Wearables natively.

**No provider is a blocker for replacing Spike with Open Wearables in Cureocity**, unless CGM / Withings / Peloton comes up in a roadmap item. CGM especially — verify whether Cureocity's CGM flow relies on Spike today; if yes, that's a feature-gap conversation, not a provider gap.

---

## 2. What Cureocity's `workout-management/src/spike/*` actually does

### Module files
```
workout-management/src/spike/
├── spike.controller.ts        4 gRPC methods (below)
├── spike.service.ts           business logic; ~5 async methods
├── spike-api.client.ts        HTTP client to spikeapi.com
├── spike.module.ts            NestJS wiring
├── repository/spike.repository.ts   Prisma writes to `health_record` table
└── (tests)
```

### gRPC surface exposed to rest of Cureocity (`SpikeController`)

| gRPC method | What it does | Consumed by |
|---|---|---|
| `ProcessSpikeWebhook` | Receives Spike's push (new data notification), pulls via `SpikeApiClient.getDailyStats` / `getTimeseries`, writes to `health_record` via Prisma. | Spike cloud → gRPC gateway → this |
| `UpsertHealthRecord` | Direct write of a `HealthRecord` row. | Flutter app (via another service) + webhook path |
| `GetLatestUserHealth` | Latest row per metric for a user. | Flutter app via `getLatestUserHealth` GQL |
| `GetUserHealth` | Range query. | Flutter app via `getUserHealth` GQL |

### External HTTP surface hit (`SpikeApiClient`)

| Method | Spike REST path | Purpose |
|---|---|---|
| `getAuthToken(userId)` | `POST /auth/hmac` | HMAC-sign per-user access token; cached in memory |
| `getDailyStats({userId, types, from, to})` | `GET /queries/statistics/daily?...` | Day-level rollups |
| `getTimeseries({userId, types, from, to})` | `GET /queries/timeseries?...` | Minute/hourly raw points |

### DB schema (`health_record` table, owned by this service)
Stores provider-agnostic rows: `{userId, provider, metric, timestamp, value, unit, device, ...}`. This is Cureocity's normalised tier. Everything downstream reads from this table.

---

## 3. Open Wearables backend equivalents — 1:1 mapping

All OW endpoints require header `X-Open-Wearables-API-Key`. All user-scoped paths are `/api/v1/users/{user_id}/...`. Base URL in Cureocity dev: `http://localhost:8000`.

| Spike side | Open Wearables equivalent |
|---|---|
| `POST /auth/hmac` (per-user token) | Not needed — OW uses a long-lived API key per application + a user ID. One-shot config. |
| `GET /queries/statistics/daily` | `GET /api/v1/users/{id}/summaries/activity` + `/summaries/sleep` + `/summaries/recovery` (pre-aggregated daily; prettier than Spike) |
| `GET /queries/timeseries` | `GET /api/v1/users/{id}/timeseries?types=…&start_time=…&end_time=…&resolution=raw|1min|5min|15min|1hour` |
| Workouts (via `/queries/records/workouts`) | `GET /api/v1/users/{id}/events/workouts` |
| Sleep records | `GET /api/v1/users/{id}/events/sleep` |
| Spike webhook push | OW supports webhooks via Svix (already running — we saw `svix-server__open-wearables` on port 8071). Configure an endpoint in Svix; OW publishes data-ready events. |
| Provider connect redirect (Spike) | `GET /api/v1/oauth/{provider}/authorize` → OW returns redirect URL just like Spike |
| Disconnect provider | `DELETE /api/v1/users/{user_id}/connections/{provider}` |
| Spike derived `stress_score`, `readiness_score` | **NOT present in OW.** If Cureocity uses these, they must be computed in Cureocity backend or added to the fork. |

**Body summary extra** — OW's `/summaries/body` returns weight / BMI / body-fat / temperature / blood pressure in one call. Spike requires multiple record queries.

---

## 4. Migration patterns — pick one

### Pattern A: Drop-in proxy (minimal blast radius)

Keep `workout-management` and its gRPC surface identical. Replace `SpikeApiClient` internals with an `OpenWearablesApiClient`. Keep storing normalised `health_record` rows in the Cureocity DB (webhooks still ingest). Flutter app sees zero change.

- **Effort**: ~3–5 days
- Replace `spike-api.client.ts` with `open-wearables-api.client.ts`, implementing the three methods above against OW endpoints.
- Update payload mappers in `spike.service.ts` + `spike.utils.ts` for OW response shapes.
- Repoint the webhook receiver to Svix signature verification.
- Rename files/symbols (`SpikeService` → keep or rename) — low-priority cosmetic.
- Update tests.

**Pros:** No upstream/downstream surface change. Lowest risk. Can ship incrementally (feature-flag per provider).
**Cons:** Cureocity still owns a health_record table — duplicated with OW's own timeseries DB. Two sources of truth.

### Pattern B: Delegate — treat OW as the source of truth (recommended per earlier decision)

Deploy OW backend as a Cureocity microservice (already agreed). `workout-management` becomes a **thin proxy** to OW's REST API. `health_record` table gets deprecated over time.

- **Effort**: ~7–12 days (most of it is data-migration + feature-gap filling)
- `GetLatestUserHealth` / `GetUserHealth` now call OW's `/summaries/*` + `/timeseries` instead of Prisma. No Cureocity-side write path needed.
- Delete `ProcessSpikeWebhook` (OW owns webhook ingestion now). Or keep it as a pass-through if GraphQL layer needs a Cureocity-side event.
- Backfill: migrate existing `health_record` rows into OW, or accept that historical data stays readable from the old table during cutover.
- Feature-gap filling: `stress_score` computation, CGM ingestion (if needed), any Cureocity-specific derived metrics.

**Pros:** Single source of truth. Less DB to maintain. Matches your stated intent. Easier to track upstream.
**Cons:** Bigger surface area; slower to ship; cutover has more moving pieces.

### Pattern C: Both — Spike stays alive for Fitbit/CGM/etc., OW takes the rest (hybrid)

Not recommended unless Spike has must-have providers OW lacks. Since Fitbit + Garmin + Apple + HC + Samsung are all in OW, this is only relevant if CGM / Withings / Peloton / etc. are load-bearing.

---

## 5. Recommended migration path (concrete)

Given the current state — demo works end-to-end, 128 samples synced, all production providers covered, OW backend already deployed — I'd recommend **Pattern A first, then Pattern B**:

**Phase 1 (≈1 week)** — *Pattern A: swap the client, keep the schema*
1. Add an `OpenWearablesApiClient` TypeScript class under `workout-management/src/open-wearables/` (do NOT delete `spike/` yet).
2. Shadow-run: behind a feature flag, the new client pulls from OW for a small % of users. Compare outputs with Spike's responses for those users.
3. Once parity is confirmed, flip the flag globally. Spike module becomes unused code.

**Phase 2 (≈1–2 weeks)** — *Pattern B: collapse the schema*
4. Replace `GetUserHealth` / `GetLatestUserHealth` Prisma calls with OW REST calls. No more writes to `health_record`. Keep the table read-only for 2-4 weeks as a fallback.
5. Decommission `ProcessSpikeWebhook` (OW owns the webhook path via Svix).
6. Delete `workout-management/src/spike/*`, rename `open-wearables/*` → `health/*` (provider-agnostic name), drop the `health_record` table in a later cleanup PR.

**Phase 3 (deferred)** — feature-gap filling
7. `stress_score` derivation in Cureocity backend if still consumed. (Input: HRV + sleep + RHR.)
8. CGM ingestion if needed (investigate Cureocity's `features/cgm/` dependencies on Spike).
9. Any Cureocity-specific provider that Spike had and OW doesn't — file one ticket per.

**Total estimated effort for full migration:** 15-25 engineer-days end-to-end. Not weeks-of-engineering; a focused backend person could ship Phase 1 in a sprint.

---

## 6. Known gotchas & risks

| Risk | Severity | Mitigation |
|---|---|---|
| OW's per-provider data shape differs subtly from Spike's | Medium | Shadow-run in Phase 1 with output comparison |
| Svix webhook signature verification differs from Spike's webhook signing | Low | Svix has official NestJS + node SDK; ~1 day to swap |
| OW is self-hosted → Cureocity ops now owns uptime | Medium | Standard docker-compose deployment; SRE bandwidth; monitor already exists for other services |
| OW is at v0.1.0 (API not yet 1.0) | Medium | Pin to a commit SHA; audit upstream changelogs before each upgrade |
| Existing `health_record` rows live in Cureocity DB only | Medium | Phase 2 cutover keeps old table readable for N weeks; backfill job if needed |
| `stress_score` / `readiness_score` consumers in Flutter | Low | One derivation in Cureocity backend covers both |
| CGM (FreeStyle Libre / Dexcom) is a Spike-only feature if Cureocity uses it | Potentially high | Audit `features/cgm/` for Spike coupling before Phase 2 |

---

## 7. TL;DR

**Providers:** Open Wearables covers every provider Cureocity uses in production today (apple, google, samsung, garmin, fitbit). The theoretical gap (Spike's long tail: Withings / Peloton / Zepp / iHealth / CGM / …) does not affect current Cureocity users unless CGM turns out to be Spike-backed.

**Replacement effort:** ≈15–25 engineer-days for full Pattern-A → Pattern-B migration. Phase 1 (swap client, keep schema) is a 1-week sprint and is the only phase that affects production behavior for users. Phases 2 and 3 are cleanup + derived-metric work.

**Recommendation:** Start Phase 1 next sprint. Ship behind a feature flag. Decide Pattern B vs. keeping the normalised table as-is after 2-4 weeks of shadow data.
