# Open Wearables Flutter Demo — Design Spec

**Date:** 2026-04-20
**Author:** Claude (brainstormed with user)
**Status:** Awaiting user review
**Sub-project:** A (of 3) — the parity-probe Flutter demo. Sub-projects B (feature-gap doc) and C (implement missing features in the fork) are follow-ups that build on this.

---

## 1. Goal & non-goals

### Goal
Build a Flutter demo app that exercises the `open_wearables_health_sdk` against a locally-running self-hosted Open Wearables backend, proving that the **8 cleanly-mapped Cureocity health metrics** flow device → SDK → backend end-to-end on both iOS and Android. The demo is the test bench that drives the feature-gap analysis (sub-project B) and the fork-implementation work (sub-project C).

### Non-goals (these are later sub-projects)
- Replacing Spike in `CureocityApps` — this is a standalone probe.
- Wiring the Open Wearables backend to the existing Cureocity backend (`workout-management`). That's backend-team work, separate sub-project.
- Adding Fitbit (or any provider not yet supported by Open Wearables). Fitbit will be built directly in Cureocity backend later.
- Deriving `stressScore` / unifying `calories` / completing `bodyComposition`. Later.
- Production-polish UI, auth flows, persistent storage, charts, i18n, a11y, CI.

---

## 2. Context (derived from prior exploration)

- `CureocityApps` already has a clean `HealthService` abstract interface in `packages/health_integration/` with two implementations: `SpikeHealthService`, `NativeHealthService`. The demo's reusable artifact mirrors this interface so sub-project C becomes a drop-in.
- Cureocity `HealthMetric` enum has 11 values: `steps`, `sleepDuration`, `heartrate`, `stressScore`, `breathingRate`, `bodyTemperature`, `bloodPressure`, `bodyComposition`, `hrv`, `spo2`, `calories`.
- Open Wearables SDK (v0.0.15) is **write-only**: device → SDK → backend. No local read. Data for the app comes from the backend, not the SDK.
- Open Wearables supports Apple HealthKit, Health Connect, Samsung Health (SDK); Garmin, Suunto, Polar (OAuth cloud). **Fitbit is not yet supported** — hard blocker for full Cureocity parity, addressed outside this sub-project.
- See `docs/research/2026-04-20-spike-vs-openwearables-comparison.md` for the full comparison.

---

## 3. Architecture & repo layout

Two forks live as siblings inside `/Users/apple/Documents/Workspace/open_wearables/`. The demo app is the `example/` of the SDK fork.

```
/Users/apple/Documents/Workspace/open_wearables/
├── open_wearables_health_sdk/            # FORK (Flutter SDK)
│   ├── .git/                             # origin=Cureocity-Dev, upstream=the-momentum
│   ├── lib/ android/ ios/                # SDK plugin source (touched in sub-project C)
│   └── example/                          # ← DEMO APP (this sub-project)
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── services/
│       │   │   ├── health_service.dart                   # trimmed abstract (copied from Cureocity)
│       │   │   ├── health_metric.dart                    # enum copy
│       │   │   ├── open_wearables_health_service.dart    # impl — the Section-2 artifact
│       │   │   ├── health_service_controller.dart        # ChangeNotifier holding state + log stream
│       │   │   └── health_event.dart                     # { level, timestamp, message, errorClass? }
│       │   └── ui/
│       │       ├── dev_console_screen.dart
│       │       └── widgets/
│       │           ├── connection_section.dart
│       │           ├── permissions_section.dart
│       │           ├── providers_section.dart            # Android-only; hidden on iOS
│       │           ├── sync_section.dart
│       │           ├── introspection_section.dart
│       │           ├── log_view.dart
│       │           └── metric_gap_dialog.dart
│       ├── test/services/open_wearables_health_service_test.dart
│       ├── android/ ios/ pubspec.yaml
│       └── README.md
│
└── open-wearables/                       # FORK (backend + platform)
    ├── .git/                             # origin=Cureocity-Dev, upstream=the-momentum
    └── docker-compose.yml                # local stack: FastAPI + Postgres + Redis + Celery + React portal
```

### Fork configuration (applies to both repos)
- `origin` = `https://github.com/Cureocity-Dev/<repo>.git`
- `upstream` = `https://github.com/the-momentum/<repo>.git`
- Long-lived integration branch: `cureocity/main`
- Deploy / use off `cureocity/main`; rebase on `upstream/main` on a regular cadence
- Cureocity-specific additions that can't be upstreamed live under a dedicated `cureocity/` subdirectory (minimizes merge conflict surface)

### Runtime data flow

```
[Demo UI] → [HealthServiceController] → [OpenWearablesHealthService] → [OpenWearablesHealthSdk plugin]
                                                                                 ↓
                                          Apple HealthKit / Health Connect / Samsung Health
                                                                                 ↓
                               POST http://localhost:8000/api/v1/sdk/users/{userId}/sync
                                                                                 ↓
                                            [self-hosted Open Wearables backend (docker compose)]
                                                                                 ↓
                                            [Postgres] — user inspects via React portal or psql
```

---

## 4. The reusable artifact — `OpenWearablesHealthService`

A class that mirrors `CureocityApps`' `HealthService` interface so sub-project C can drop it into `packages/health_integration/lib/src/impl/` with minimal edits.

### Interface (trimmed copy of Cureocity's)

```dart
abstract class HealthService {
  bool get isInitialized;
  bool get supportsWaterWrite;
  bool get supportsDeviceListing;
  bool supportsMetric(HealthMetric metric);
  Future<void> init();
  Future<void> requestPermissions();
  Future<void> installHealthConnect();
  // Cureocity-specific members omitted from demo copy:
  //   fetchHealthData, fetchHistoricalHealthData, writeWaterIntake, buildDailyPayload
  // The impl below throws UnsupportedError for these, preserving the contract shape.
}
```

### Method mapping

| `HealthService` member                 | Impl in `OpenWearablesHealthService`                      | Status                                           |
|----------------------------------------|-----------------------------------------------------------|--------------------------------------------------|
| `isInitialized`                        | flag after `configure` + `signIn` both succeed            | direct                                           |
| `supportsWaterWrite`                   | `false`                                                   | SDK is read-only                                 |
| `supportsDeviceListing`                | `Platform.isAndroid`                                      | Android multi-provider via `getAvailableProviders` |
| `supportsMetric(m)`                    | `_metricMap[m] != null`                                   | direct                                           |
| `init()`                               | `OpenWearablesHealthSdk.configure(host: _host)` then `signIn(userId, accessToken/apiKey)` | direct              |
| `requestPermissions()`                 | `requestAuthorization(types: _mappedTypes(selected))`     | direct                                           |
| `installHealthConnect()`               | `url_launcher` → Play Store Health Connect page           | standard Flutter pattern                         |
| `fetchHealthData(refresh)`             | throw `UnsupportedError('Data on backend; demo only probes sync')` | ⚠️ architectural gap — Cureocity reads via GQL digest, not SDK |
| `fetchHistoricalHealthData(...)`       | throw `UnsupportedError`                                  | ⚠️ architectural gap                              |
| `writeWaterIntake(ml)`                 | return `false`                                            | ❌ SDK doesn't write                              |
| `buildDailyPayload({date})`            | throw `UnsupportedError('SDK self-uploads')`              | not applicable                                   |

### Extra SDK-surface passthroughs (not in Cureocity contract; demo-only)

These are exposed on `OpenWearablesHealthService` purely so the dev console can probe them. They stay in demo code if sub-project C ports the class over.

- `syncNow()`, `startBackgroundSync()`, `stopBackgroundSync()`
- `getSyncStatus()`, `resetAnchors()`, `resumeSync()`, `clearSyncSession()`
- `getAvailableProviders()`, `setProvider(provider)` — Android
- `signOut()`, `updateTokens(...)`, `getStoredCredentials()`

### Metric map (the gap analysis encoded as code)

```dart
static const Map<HealthMetric, OpenWearablesDataType?> _metricMap = {
  HealthMetric.steps:           OpenWearablesDataType.steps,
  HealthMetric.sleepDuration:   OpenWearablesDataType.sleep,
  HealthMetric.heartrate:       OpenWearablesDataType.heartRate,
  HealthMetric.bodyTemperature: OpenWearablesDataType.bodyTemperature,
  HealthMetric.bloodPressure:   OpenWearablesDataType.bloodPressure,
  HealthMetric.hrv:             OpenWearablesDataType.heartRateVariabilitySDNN,
  HealthMetric.spo2:            OpenWearablesDataType.oxygenSaturation,
  HealthMetric.breathingRate:   OpenWearablesDataType.respiratoryRate,
  HealthMetric.calories:        null, // ⚠️ derive activeEnergy + basalEnergy (Cureocity backend)
  HealthMetric.bodyComposition: null, // ⚠️ partial via bodyFatPercentage + leanBodyMass + bodyMass
  HealthMetric.stressScore:     null, // ❌ not supported (Cureocity backend derives, or dropped)
};
```

The three `null` rows are the concrete feature-gap deliverables for sub-project C or for Cureocity backend (per the production architecture decision).

---

## 5. UI — single dev-console screen

Single `Scaffold`, vertically scrollable. No navigation, no forms beyond three text fields.

### Sections (all on one screen)

```
▼ CONNECTION
  [Host URL          ]  [User ID          ]  [API Key / Token    ]
  [Configure]  [Sign In]  [Sign Out]
  Status chips: configured=✓/✗  signedIn=✓/✗

▼ PERMISSIONS
  Checkboxes for all 23 Open Wearables data types
  [Select Cureocity set] — preselects the 11 mapped types; disables 3 gap rows with tooltip
  [Request Authorization]

▼ PROVIDERS  (Android only — hidden on iOS)
  Current: <samsung|healthConnect|none>
  Available: <list from getAvailableProviders>
  [Get Available] [Set Samsung] [Set HC]

▼ SYNC
  [Sync Now] [Start BG] [Stop BG]
  [Reset Anchors] [Resume] [Clear Session] [Get Sync Status]
  Last status: <json>

▼ INTROSPECTION
  [Get Stored Credentials]  [Show Metric Map & Gaps]

─── LOGS (auto-scrolling list) ───
  <timestamp> [OK|INFO|ERR] <message>
  [Clear Logs] [Copy All] [Export JSONL]
```

### State & event flow

- `HealthServiceController extends ChangeNotifier`
  - holds: `isConfigured`, `isSignedIn`, `lastSyncStatus`, `currentProvider`, `availableProviders`, `selectedTypes`, `events: List<HealthEvent>`
  - wraps every action with try/catch; appends `HealthEvent` on both success and failure; calls `notifyListeners()`
- `HealthEvent { DateTime ts; Level level; String message; String? errorClass; Map<String,dynamic>? context; }` where `Level = ok | info | err`
- `LogView` listens to the controller and renders events colored by level

---

## 6. Backend (local Open Wearables fork)

### Stand-up (one-time)

```bash
cd /Users/apple/Documents/Workspace/open_wearables
git clone https://github.com/Cureocity-Dev/open-wearables.git
cd open-wearables
git remote add upstream https://github.com/the-momentum/open-wearables.git
git fetch upstream

docker compose up -d
docker compose ps   # verify fastapi, postgres, redis, celery, react frontend are Up
```

Then via the React dev portal (URL printed by docker compose):
1. Create an application.
2. Create a user under it.
3. Copy issued credentials (API key or access/refresh pair).
4. Paste `http://localhost:8000`, user ID, and credential into the demo's three text fields.

### Upstream upgrade workflow

```bash
cd /Users/apple/Documents/Workspace/open_wearables/open-wearables
git fetch upstream
git checkout cureocity/main
git rebase upstream/main    # resolve conflicts if any (minimize by keeping changes in cureocity/ subdir)
git push --force-with-lease origin cureocity/main
```

### Pre-flight
- Docker Desktop running, ~4GB memory allocation
- Ports free: 8000 (API), 5432 (Postgres), 6379 (Redis), React port
- macOS-native Docker; no Lima/Colima caveats expected

---

## 7. Error handling (demo-grade, visible)

- Every SDK call wrapped in `try/catch` inside `OpenWearablesHealthService`.
- Errors classified into four buckets, tagged in `HealthEvent.errorClass`:
  - `AuthError` — 401/403, token refresh failure
  - `NetworkError` — host unreachable, timeout, DNS
  - `PlatformError` — permission denied, HealthKit/HC unavailable, background misconfig
  - `ValidationError` — unsupported metric, unsupported operation
- UI shows: red row for `err`, yellow for `info`, green for `ok`.
- **No retry, no backoff, no circuit breaker.** User clicks again. This is a probe.

---

## 8. Testing

### Unit tests — `test/services/open_wearables_health_service_test.dart`
- Mock `OpenWearablesHealthSdk` via `mocktail`.
- Per method: happy path + each error class.
- `supportsMetric(HealthMetric.stressScore)` returns `false` without throwing.
- `_metricMap` completeness: every `HealthMetric` enum value is present as a key.

### No widget tests, no integration tests
Real-device signal is cheap; fake widget trees add noise.

### Manual-test harness

**iOS simulator**: seed HealthKit via Simulator → Features → Sample Data, or manually via Device → Edit Health Data.

**Android emulator**: Pixel AVD with Google Play, install Health Connect, seed data manually (Health Connect → Manage data) or with a sample-data app. Samsung Health requires a real Samsung device (known limitation).

**Physical device**: required for production-like signal once simulator passes. Real iPhone + Apple Watch; real Pixel or Samsung.

### Definition of done (exit criterion for sub-project A)

1. `flutter test` passes — unit tests for the service wrapper.
2. iOS simulator with seeded data: all 8 cleanly-mapped metrics (`steps`, `sleep`, `heartRate`, `bodyTemperature`, `bloodPressure`, `hrv`, `oxygenSaturation`, `respiratoryRate`) produce rows in the backend Postgres after `Sync Now`.
3. Android emulator with seeded Health Connect data: same 8 metrics produce rows.
4. `supportsMetric(stressScore)` returns `false`; UI disables that checkbox with gap tooltip.
5. Background sync toggle starts and stops cleanly on both platforms (Android notification appears; iOS BGTask registered).
6. Token refresh path exercised by expiring a token manually and verifying the SDK auto-refreshes.
7. Demo README documents reproduction steps.

---

## 9. Build order (high-level sequence)

1. Create Cureocity-Dev forks for both repos on GitHub.
2. Clone both, set `upstream` remotes, confirm `git fetch upstream` works.
3. Boot the backend (`docker compose up`); create app + user; capture credentials.
4. Scaffold the demo app inside `open_wearables_health_sdk/example/` (replace any existing example with a minimal one if present).
5. Copy/adapt `HealthService` interface + `HealthMetric` enum from CureocityApps.
6. Implement `OpenWearablesHealthService` against the SDK, fully.
7. Implement `HealthServiceController` and the log/event plumbing.
8. Build dev console UI section by section (connection → permissions → providers → sync → introspection → logs).
9. Configure iOS (Info.plist, HealthKit capability, BGTask identifiers) and Android (minSdk 29, FlutterFragmentActivity, Health Connect activity aliases).
10. Wire `url_launcher` for the Health Connect install fallback.
11. Write unit tests for `OpenWearablesHealthService`.
12. Seed simulator data, run through the 8-metric exit-criterion checklist on both platforms.
13. Write demo README with reproduction steps.

Details for each step belong in the implementation plan (writing-plans skill), not this design.

---

## 10. Risks & open questions

| Risk / question                                                    | Severity | Mitigation / owner                                                  |
|--------------------------------------------------------------------|----------|---------------------------------------------------------------------|
| Samsung Health testing requires real device                        | Low      | Ship demo tested on real Samsung device before sign-off, or scope Samsung validation to follow-up |
| Background sync on simulators is restricted                        | Low      | Validate on real device post-simulator-green                        |
| Upstream SDK v0.0.x is young; API may break                        | Medium   | Pin to specific tag in `pubspec.yaml`; review upstream changelogs   |
| Open Wearables backend setup docs may be incomplete                | Medium   | Capture gaps in demo README; upstream PR for docs if blocking       |
| Open Wearables React portal UX unknown; may need API direct        | Low      | Fallback to hitting FastAPI endpoints directly with curl/httpie     |
| `OpenWearablesDataType` enum shape not verified in code (only docs)| Low      | Read actual SDK Dart source when implementing `_metricMap`          |
| SDK fork URL not yet confirmed                                     | Low      | User to confirm; assumed `https://github.com/Cureocity-Dev/open_wearables_health_sdk.git` |

---

## 11. Follow-ups (spawn their own specs)

- **Sub-project B** — Feature-gap analysis document (partially done in the comparison doc; sharpen with demo observations).
- **Sub-project C** — Implement missing pieces in the fork (or forward to Cureocity backend): `stressScore` derivation, `calories` unification, `bodyComposition` completion.
- **Backend sub-project** — Wire Open Wearables backend as a Cureocity microservice; webhook or direct ingestion into `workout-management`.
- **Fitbit** — Build Fitbit OAuth directly in Cureocity backend (not in the fork).
