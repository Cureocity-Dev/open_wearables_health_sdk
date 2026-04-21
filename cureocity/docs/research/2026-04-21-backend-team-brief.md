# Open Wearables Migration — Brief for Backend Team

**Date:** 21 April 2026
**From:** Rebin (frontend / integration testing)
**To:** Cureocity backend team
**Subject:** Replacing Spike with the open-source Open Wearables platform — test results and next steps

---

## 1. Background

As you are aware, we have been evaluating **Open Wearables** (https://github.com/the-momentum/open-wearables) as an open-source replacement for Spike. Kindly note that we have forked both the backend and the Flutter SDK into `Cureocity-Dev` org:

- Backend: https://github.com/Cureocity-Dev/open-wearables
- Flutter SDK: https://github.com/Cureocity-Dev/open_wearables_health_sdk

Both forks are set up with `upstream` remote pointing to the-momentum, so we can pull upstream updates regularly.

---

## 2. What has been tested

A parity-probe Flutter demo (`example/` folder of the SDK fork) has been built and validated end-to-end on iPhone. Please find the summary below:

1. **Flutter SDK → Open Wearables backend (running locally via `docker compose up`).**
   - Authentication: API key (`X-Open-Wearables-API-Key`). Works as expected.
   - Data flow: `Apple HealthKit → SDK → backend sync endpoint`. Verified with HTTP 202 response.
   - First sync pushed **128 samples across 7 metric types** (StepCount, SleepAnalysis, HeartRate, RespiratoryRate, BodyTemperature, HeartRateVariabilitySDNN, OxygenSaturation).
   - Subsequent syncs confirmed the SDK's **anchor-based incremental delta** is working correctly (0 samples on re-sync, as expected).

2. **Backend REST API** — successfully consumed from the demo app to render a Health Data screen with day / week / month views (Activity, Sleep, Recovery, Body sections with sparklines).

3. **36 unit tests + 11 additional backend-client tests** — all passing on `cureocity/main` branch of the SDK fork.

---

## 3. Provider coverage

The running Open Wearables backend supports the following **11 providers** (verified live via `GET /api/v1/oauth/providers`):

| Provider | Type | In use at Cureocity today |
|---|---|---|
| apple | SDK | Yes |
| google (Health Connect) | SDK | Yes |
| samsung | SDK | Yes |
| garmin | Cloud OAuth | Yes |
| fitbit | Cloud OAuth | Yes |
| polar | Cloud OAuth | — |
| suunto | Cloud OAuth | — |
| whoop | Cloud OAuth | — |
| oura | Cloud OAuth | — |
| strava | Cloud OAuth | — |
| ultrahuman | Cloud OAuth | — |

**All providers currently integrated at Cureocity (Apple, Health Connect, Samsung, Garmin, Fitbit) are covered by Open Wearables.** No provider is a blocker.

**Known gaps vs Spike** — Withings, Peloton, Zepp, iHealth, and CGM (FreeStyle Libre / Dexcom). Kindly confirm that these are **not** currently in use. I have verified that CGM at Cureocity does not rely on Spike, so this should be safe to proceed.

**Derived metrics gap:** Spike provides `stress_score` and `readiness_score` pre-computed. Open Wearables does not expose these. If Cureocity app consumes them, please plan to derive these in our backend (HRV + sleep + RHR heuristics).

---

## 4. Migration impact on `workout-management` service

The existing `apps/services/workout-management/src/spike/*` module is well isolated. The migration work is contained and can be done in two phases:

### Phase 1 — Backend API replacement (~5–7 engineer-days)

Replace `SpikeApiClient` with an `OpenWearablesApiClient`. The four gRPC methods (`ProcessSpikeWebhook`, `UpsertHealthRecord`, `GetLatestUserHealth`, `GetUserHealth`) and the `health_record` Prisma table remain unchanged.

Endpoint mapping is 1:1:
- `/queries/statistics/daily` → `/api/v1/users/{id}/summaries/{activity|sleep|recovery}`
- `/queries/timeseries` → `/api/v1/users/{id}/timeseries`
- Workouts → `/api/v1/users/{id}/events/workouts`
- Provider OAuth redirect → `/api/v1/oauth/{provider}/authorize`

Kindly do the needful to feature-flag this per-user so we can shadow-run in production for 2–4 weeks before full cut-over.

### Phase 2 — Webhook compatibility (~3–4 engineer-days)

Open Wearables uses **Svix** (open-source webhook service, already running on port 8071 of the docker-compose stack) for webhook emission. Please note the following differences from Spike:

| Aspect | Spike | Open Wearables (Svix) |
|---|---|---|
| Signature header | `X-Body-Signature` | `svix-signature` + `svix-id` + `svix-timestamp` |
| Signature scheme | Hex HMAC-SHA256 over raw body | Svix scheme (use official `svix` npm package) |
| Body | JSON array of `{event_type, application_user_id, metrics, …}` | Single `{type: "workout.created", data: {…}}` object |
| Carries data? | No (notification only — requires REST pull-back) | **Yes (full data in payload)** |

Changes required in `apps/gateway/public-gateway/src/`:

1. Install `svix` npm package.
2. Replace `SpikeWebhookGuard` with an `OpenWearablesWebhookGuard` that uses `new Webhook(secret).verify(body, headers)` — one-line verification.
3. Update DTO shape (`{type, data}` instead of array).
4. Add small event-type-to-internal-metric mapping function (~40 event types → existing metrics).
5. **Rename** route from `/public-gateway/spike/event` to `/public-gateway/open-wearables/event` (or keep old path if preferred to avoid gateway config change).

Kindly do the needful to register the endpoint on the Open Wearables backend using its admin API:

```bash
POST /api/v1/outgoing-webhooks/endpoints
{
  "url": "https://<cureocity-public-gateway>/public-gateway/open-wearables/event",
  "filter_types": ["workout.created", "sleep.created", "steps.created",
                   "heart_rate.created", "heart_rate_variability.created",
                   "spo2.created", "respiratory_rate.created",
                   "body_temperature.created", "blood_pressure.created",
                   "calories.created"]
}
```

The response will include the signing secret — please store as `OW_WEBHOOK_SECRET` env var.

### Phase 3 — Cleanup (~2–3 engineer-days)

Since Open Wearables webhooks carry full data, the REST pull-back inside `processSpikeWebhook` becomes redundant. Recommend a small proto addition — `ProcessOpenWearablesEvent(OWEvent)` — that writes directly to `health_record` from the webhook payload. After parity is proven, the whole `spike/` module and the `SpikeApiClient` can be deleted.

---

## 5. Deployment model

As discussed earlier, Open Wearables backend will be deployed **as a Cureocity microservice** (peer to `workout-management`, not as a separate third-party dependency). The stack is:

- Backend: FastAPI (Python 3.13)
- DB: PostgreSQL
- Queue: Redis + Celery
- Webhooks: Svix server
- Admin UI: React + TanStack (Vite)

`docker-compose.yml` is already in the fork. Kindly coordinate with DevOps to deploy this alongside existing Cureocity services. Single-VM or containerised deployment is fine; multi-tenancy is not required (single Cureocity org per deployment).

---

## 6. Total effort estimate

| Phase | Effort |
|---|---|
| Phase 1 — API client replacement (shadow + cut-over) | 5–7 engineer-days |
| Phase 2 — Webhook compatibility | 3–4 engineer-days |
| Phase 3 — Cleanup (drop REST pull-back, delete `spike/` module) | 2–3 engineer-days |
| **Total** | **~10–14 engineer-days** |

---

## 7. Reference material

All detailed analysis is available in the `open_wearables` workspace under `docs/research/`:

- `2026-04-20-spike-vs-openwearables-comparison.md` — full comparison including data types, auth, sync model
- `2026-04-21-provider-matrix-and-migration.md` — provider matrix + three migration patterns (A/B/C)
- `2026-04-21-webhook-compatibility.md` — full webhook contract diff with file-level changes

Kindly go through the same when planning the actual migration. I shall be happy to discuss further in our next sync-up.

---

## 8. Next action

Request you to kindly confirm:

1. Is Open Wearables approved for deployment as a Cureocity microservice?
2. Which engineer will own Phase 1?
3. Target sprint for Phase 1 kick-off?

Please revert with your thoughts at your earliest convenience. Thanks and regards.

— Rebin
