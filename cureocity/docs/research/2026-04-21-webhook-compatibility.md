# Webhook Compatibility — Spike vs Open Wearables (Svix)

**Date:** 2026-04-21
**Purpose:** Compare the two webhook contracts side-by-side and describe the exact work needed to make Cureocity's existing webhook ingestion flow consume Open Wearables events instead of Spike's. Companion to `2026-04-21-provider-matrix-and-migration.md`.

Headline: **~3–4 engineer-days for webhook-only migration.** The receiving pattern stays intact; only the guard, DTO, and payload mapping change.

---

## 1. Spike's webhook contract (what Cureocity consumes today)

**Delivery**
- Spike POSTs directly to your configured endpoint — Cureocity uses `POST /public-gateway/spike/event` on the public gateway.
- Body: **JSON array of events**.
- Retry: 10 attempts, exponential backoff (5s → 2m → 30m → 2h → every 12h), 30s timeout. Must respond HTTP 200.

**Signature**
- Header: `X-Body-Signature: <hex HMAC-SHA256 of raw body with shared secret>`
- Cureocity guard: `SpikeWebhookGuard` uses `SPIKE_WEBHOOK_SECRET` + `crypto.createHmac('sha256', …).update(rawBody).digest('hex')`.

**Event shape** (from `dto/spike.dto.ts` + Spike docs)
```json
[
  {
    "application_user_id": "User1",
    "timestamp": "2026-04-20T13:33:55Z",
    "event_type": "record_change",
    "metrics": ["steps", "distance", "calories_burned_active"],
    "activity_types": ["sedentary"],
    "provider_slug": "oura",
    "earliest_record_start_at": "2026-04-20T13:33:00Z",
    "latest_record_end_at": "2026-04-20T13:33:00Z"
  }
]
```

Event types: `record_change`, `provider_integration_created`, `provider_integration_deleted`.

**Important:** the webhook is a **notification, not the data**. Cureocity's `SpikeService` in workout-management then calls `SpikeApiClient.getDailyStats`/`getTimeseries` to pull the actual data for `[earliest_record_start_at, latest_record_end_at]`.

---

## 2. Open Wearables' webhook contract (what you'd consume instead)

**Delivery**
- OW emits events through **Svix** (open-source webhook-as-a-service, already bundled in docker-compose on port 8071).
- Svix POSTs to your endpoint — same mechanism, different signer.
- Per-endpoint retry + built-in observability dashboard. Svix has an official NestJS-compatible Node SDK.
- Per-user channel scoping: `channels=["user.{user_id}"]` so endpoints can subscribe to one user, one metric category, or everything.

**Signature (the real difference)**
- Headers: `svix-id`, `svix-timestamp`, `svix-signature`
- Signing scheme: `HMAC-SHA256(secret, "{svix-id}.{svix-timestamp}.{body}")` base64-encoded
- Verify using `svix` npm package — one line of code (`new Webhook(secret).verify(body, headers)`).
- Timestamp check prevents replay attacks (Spike doesn't do this).

**Event shape** (from `services/outgoing_webhooks/svix.py` and `events.py`)
```json
{
  "type": "workout.created",
  "data": {
    "id": "<uuid>",
    "user_id": "<uuid>",
    "type": "running",
    "start_time": "2026-04-20T06:30:00Z",
    "end_time": "2026-04-20T07:15:00Z",
    "zone_offset": "+05:30",
    "duration_seconds": 2700,
    "source": {"provider": "garmin", "device": "Fenix 7"},
    "calories_kcal": 420,
    "distance_meters": 6000,
    "avg_heart_rate_bpm": 148,
    "max_heart_rate_bpm": 172,
    "avg_pace_sec_per_km": 450,
    "elevation_gain_meters": 90
  }
}
```

Single-event envelope (not a list). `type` identifies the event; `data` carries the full record.

Event types emitted (from `schemas/webhooks/event_types.py`):
- **Provider connection:** `connection.created`
- **Discrete sessions:** `workout.created`, `sleep.created`
- **Group events (per metric category):**
  `heart_rate.created`, `heart_rate_variability.created`, `steps.created`,
  `calories.created`, `spo2.created`, `respiratory_rate.created`,
  `body_temperature.created`, `stress.created`, `blood_glucose.created`,
  `blood_pressure.created`, `body_composition.created`, `fitness_metrics.created`,
  `recovery_score.created`, `activity_timeseries.created`, `workout_metrics.created`,
  `environmental.created`
- **Granular (per series type):** `series.<series_type>.created` (e.g., `series.heart_rate.created`, `series.resting_heart_rate.created`, etc.)

Large batches (>2500 samples / ~500 KB) are **chunked** into multiple messages with `chunk_index` / `total_chunks` envelope fields.

**CRITICAL advantage over Spike:** the webhook **carries the full data**. No REST pull-back round-trip needed in Cureocity's handler. Direct write to `health_record` is possible.

---

## 3. Side-by-side comparison

| Aspect | Spike | Open Wearables (Svix) |
|---|---|---|
| Body format | JSON array of events | Single `{type, data}` JSON object |
| Carries data? | ❌ Notification only | ✅ Full record in payload |
| Signature header | `X-Body-Signature` | `svix-signature` + `svix-id` + `svix-timestamp` |
| Signature scheme | hex HMAC-SHA256 over body | base64 HMAC-SHA256 over `id.timestamp.body` |
| Replay protection | ❌ | ✅ (timestamp validated) |
| Retry on failure | 10 attempts, 5s→2m→30m→2h→12h, 30s timeout | Svix default: 5 attempts over 24h; configurable |
| Observability | Minimal | Svix dashboard (delivery log, replays, status codes) |
| User-scoped delivery | All events to one URL | `channels=["user.{id}"]` supports per-user endpoints |
| Event taxonomy | 3 types (`record_change`, integration created/deleted) | ~40+ fine-grained types (category + granular) |
| Endpoint registration | Admin console | OW's `/api/v1/outgoing-webhooks/endpoints` REST API |
| Large-batch strategy | Single large body | Chunked with `chunk_index` envelope (max 500 KB per message) |

---

## 4. What Cureocity needs to change — concrete file-level diff

### Files to modify in `apps/gateway/public-gateway/src/`

**`spike/spike-webhook.guard.ts` — replace**
```diff
- // HMAC-SHA256 hex over raw body with SPIKE_WEBHOOK_SECRET
+ // Svix signature verification using the svix npm package
  import { Webhook } from "svix";
  ...
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const wh = new Webhook(this.configService.get("OW_WEBHOOK_SECRET"));
    try {
      wh.verify(req.rawBody, {
        "svix-id": req.headers["svix-id"],
        "svix-timestamp": req.headers["svix-timestamp"],
        "svix-signature": req.headers["svix-signature"],
      });
      return true;
    } catch {
      throw new UnauthorizedException("Invalid Svix signature");
    }
  }
```
- **Add npm dep:** `npm install svix`
- **Add env var:** `OW_WEBHOOK_SECRET` — obtained when registering the endpoint via OW's `/endpoints` API.

**`dto/spike.dto.ts` — replace with an OW DTO** (rename file for clarity)
```typescript
// dto/open-wearables-webhook.dto.ts
export interface OpenWearablesWebhookEvent {
  type: string;              // e.g. "workout.created"
  data: Record<string, any>; // full record, varies by event type
}
```

**`spike/spike.controller.ts` — rename + route to a more neutral path**
```typescript
@Controller("public-gateway")
export class OpenWearablesWebhookController {
  @Post("open-wearables/event")   // new path
  @HttpCode(200)
  @UseGuards(OpenWearablesWebhookGuard)
  handle(@Body() event: OpenWearablesWebhookEvent) {
    this.service.dispatch(event);
    return { success: true };
  }
}
```

**`spike/spike.service.ts` in public-gateway — rewrite the dispatcher**

```typescript
async dispatch(event: OpenWearablesWebhookEvent) {
  switch (event.type) {
    case "workout.created":
    case "sleep.created":
    case "steps.created":
    case "heart_rate.created":
    // ... others we care about
      await this.forwardToWorkoutManagement(event);
      break;
    case "connection.created":
      // log only for now — may power a UI event later
      break;
    default:
      // ignore unknown types
  }
}
```

### Files to modify in `apps/services/workout-management/src/`

**Pattern A — Minimal change, keep existing gRPC contract**
Map OW event into the existing `GrpcProcessSpikeWebhookRequest` shape:
```typescript
// In public-gateway, before calling workout-management:
const req = GrpcProcessSpikeWebhookRequest.fromObject({
  userId: event.data.user_id,
  providerSlug: event.data.source?.provider ?? "unknown",
  fromDate: event.data.start_time ?? event.data.timestamp,
  toDate: event.data.end_time ?? event.data.timestamp,
  metrics: [eventTypeToMetric(event.type)],
});
```
Then `workout-management.processSpikeWebhook` works unchanged — but it still does a REST pull-back via `SpikeApiClient`. That's wasted work because the data is already in the webhook.

**Pattern B — Better: use the data directly**
Add a new gRPC method `ProcessOpenWearablesEvent(OWEvent)` that accepts the rich payload and writes straight to `health_record`:

```typescript
// new gRPC method in workout-management
async processOpenWearablesEvent(
  req: GrpcProcessOpenWearablesEventRequest,
): Promise<...> {
  const { type, data } = req;
  const healthData = mapOpenWearablesEventToHealthData(type, data);
  await this.spikeRepository.upsertHealthRecord({
    userId: data.user_id,
    provider: data.source.provider,
    // ...existing upsert shape
  });
}
```
Requires a small proto change (+ regenerate `@cureocity/proto-common`). Removes the need to call an external API at all after receiving the webhook.

### File deletions (once both paths have landed)
- `apps/gateway/public-gateway/src/spike/*` (after rename/rewire)
- `apps/services/workout-management/src/spike/spike-api.client.ts` (no more pull-backs needed in Pattern B)
- Later: whole `spike/` folder in workout-management

### No change needed
- `SpikeRepository` stays — it just writes to `health_record`. Provider-agnostic at the storage layer.
- Database schema stays.
- Flutter-facing gRPC methods (`GetLatestUserHealth`, `GetUserHealth`) stay.

---

## 5. Endpoint registration on the OW side

OW doesn't auto-push to arbitrary URLs — endpoints must be created. One-time setup per environment via OW's REST API:

```bash
# Create the Cureocity endpoint on OW
curl -X POST http://localhost:8000/api/v1/outgoing-webhooks/endpoints \
  -H "Authorization: Bearer $OW_DEVELOPER_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://cureocity-public-gateway/public-gateway/open-wearables/event",
    "description": "Cureocity workout-management ingestion",
    "filter_types": [
      "workout.created", "sleep.created",
      "steps.created", "heart_rate.created",
      "heart_rate_variability.created", "spo2.created",
      "respiratory_rate.created", "body_temperature.created",
      "blood_pressure.created", "calories.created"
    ]
  }'
# Response includes endpoint_id and the signing secret → save as OW_WEBHOOK_SECRET
```

In Phase-1 (dev), register the endpoint to an ngrok / cloudflare tunnel URL so the local docker-compose OW can reach a non-localhost Cureocity gateway.

---

## 6. Effort breakdown

| Task | Effort |
|---|---|
| Add `svix` npm dep + new guard implementation | 0.5d |
| New DTO + controller + rename in public-gateway | 0.5d |
| Event-type → metric mapping function | 0.5d |
| Pattern A wiring to existing gRPC (fastest path) | 0.5d |
| Register endpoint on OW backend (config + doc) | 0.25d |
| Test with real webhook from OW via ngrok | 1d |
| **Pattern A subtotal** | **~3.25 days** |
| Pattern B: proto change + new gRPC method + upsert mapping | +2–3d |
| **Pattern B subtotal** | **~5.5–6 days** |

Pattern A is the fastest path to "webhooks are flowing"; Pattern B is a follow-up cleanup that removes the extraneous REST pull-back. Can land in that order across two sprints.

---

## 7. Risks / things to verify

1. **Cureocity public-gateway preserves `rawBody`** for signature verification — it does today for Spike, should work the same for Svix. No change needed.
2. **Svix's per-message payload limit (500 KB)** — historical bulk ingestion (e.g., Apple XML import) may exceed this; OW chunks automatically. Cureocity dispatcher must handle chunked envelopes by reassembling or treating each chunk as a separate event. For real-time deltas (the common case), chunking never kicks in.
3. **Timestamp replay tolerance** — Svix rejects messages older than 5 minutes by default. If Cureocity's network or processing lags, tune the `tolerance_in_seconds` option in `Webhook.verify`.
4. **Idempotency** — OW sets `idempotency_key` per message (e.g., `workout.created.{record_id}`). Svix dedupes on retries. `upsertHealthRecord` must also be idempotent (it looks like it already is via the `recordIds` field).

---

## 8. TL;DR

**Webhook compatibility is good.** The receiving architecture — public-gateway HTTP endpoint → signature guard → forward to workout-management gRPC → Prisma upsert — stays **entirely intact**. What changes is the guard implementation (Svix signing), the DTO shape (`{type, data}` single event vs. array), and the mapper that translates OW event types into the internal representation.

**Pattern A** ships in ~3 engineer-days and does not touch workout-management. Later **Pattern B** removes the SpikeApiClient pull-back (+2–3 days) since OW webhooks carry full data — a meaningful simplification that Spike's notification-only design didn't allow.

Verdict: **yes, easy to replace.** The only structural incompatibility (signing scheme) is a 1-line change using the official `svix` npm package.
