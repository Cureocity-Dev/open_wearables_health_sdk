# Open Wearables Parity Probe (Cureocity fork)

A Flutter dev-console app that probes every relevant method of
`open_wearables_health_sdk` against a locally-running self-hosted
Open Wearables backend. Used to validate that the Flutter SDK can
stand in for the current Spike integration in Cureocity.

See `../../docs/superpowers/specs/2026-04-20-open-wearables-flutter-demo-design.md`
and `../../docs/research/2026-04-20-spike-vs-openwearables-comparison.md` (in
the top-level `open_wearables/` working directory) for the design and
comparison rationale.

> **Path B**: this demo lives alongside the upstream `lib/main.dart` (which
> is the-momentum's generic dev console). Our demo's entry point is
> `lib/parity_probe.dart`. The two coexist so upstream updates to `main.dart`
> never conflict with Cureocity work.

## Quick start

### 1. Start the backend (once)

From the sibling `open-wearables/` clone:
```bash
cd /Users/apple/Documents/Workspace/open_wearables/open-wearables
docker compose up -d
docker compose ps   # confirm backend/frontend/postgres/redis/celery/svix are Up
```

The React dev portal runs at `http://localhost:3000`, API at `http://localhost:8000`.

### 2. Get credentials

Log in to `http://localhost:3000/login` with the seeded admin account (see
`backend/config/.env` in the open-wearables clone for the values). Create an
application and a user under it; copy the issued API key (or access/refresh
token pair).

### 3. Run the parity probe

```bash
cd /Users/apple/Documents/Workspace/open_wearables/open_wearables_health_sdk/example
flutter pub get           # if not done
flutter run -t lib/parity_probe.dart
```

In the app:
1. Paste `http://localhost:8000` in the Host URL field (informational).
2. Paste the user ID and either API Key or Access Token.
3. Tap **Configure + Sign In** → log shows `init ok`.
4. Tap **Select Cureocity set** → **Request Authorization** → grant permissions.
5. Tap **Sync Now** → log shows `syncNow ok`.
6. Verify data arrived in the backend Postgres (see "Verification" below).

### 4. Run the upstream demo instead

If you want to run the-momentum's generic dev console:
```bash
flutter run -t lib/main.dart
```

## The 8-metric exit criterion

On both iOS simulator (with HealthKit seeded data) and Android emulator
(with Health Connect seeded data), after tapping **Sync Now**, these eight
metrics should appear in the backend DB for the demo user:

1. `steps`
2. `sleep`
3. `heartRate`
4. `bodyTemperature`
5. `bloodPressure`
6. `heartRateVariabilitySDNN`
7. `oxygenSaturation`
8. `respiratoryRate`

Three metrics are **known gaps** and are disabled in the UI with a tooltip:
- `stressScore` — not computed by the SDK
- `calories` — derivable from `activeEnergy + basalEnergy` (Cureocity backend)
- `bodyComposition` — partial via `bodyFat + leanMass + bodyMass`

## Verification

Inspect the backend Postgres directly:
```bash
cd /Users/apple/Documents/Workspace/open_wearables/open-wearables
docker compose exec postgres psql -U postgres
\c <db_name>       # the db name defaults to something from config; check \l
\dt                # list tables to find where metrics land
```
Or use the React dev portal at `http://localhost:3000` — it visualises per-user sync state and timeseries.

## Architecture

- `lib/parity_probe.dart` — entry point (runs `ParityProbeApp`).
- `lib/app.dart` — builds the service + controller + mounts `DevConsoleScreen`.
- `lib/services/open_wearables_health_service.dart` — wrapper matching
  Cureocity's `HealthService` interface; reusable artifact for sub-project C.
- `lib/services/open_wearables_sdk_api.dart` — test seam that forwards to the
  static `OpenWearablesHealthSdk` plugin class.
- `lib/services/health_service_controller.dart` — `ChangeNotifier` holding
  state and event log; all UI wires through it.
- `lib/services/{health_metric.dart,health_event.dart,health_service.dart}` —
  models + abstract interface copied verbatim from Cureocity.
- `lib/ui/dev_console_screen.dart` — single scrollable screen.
- `lib/ui/widgets/*.dart` — one file per section.

## Testing

```bash
flutter test test/services/
```

Runs the 36 service-layer unit tests (models, SDK wrapper, service, controller).
UI widgets have no tests — real-device/simulator validation is the source of
truth for UI behavior.

Note: upstream's `test/widget_test.dart` and `integration_test/plugin_integration_test.dart` are broken upstream (they reference a `MyApp` class that no longer exists). **Do not** run bare `flutter test` — always scope to `test/services/`.

## Troubleshooting

- **401 Unauthorized** on sync: the credential is wrong or expired. Check
  the Open Wearables portal to reissue.
- **Android foreground notification persists**: by design for background
  sync on Android; see upstream SDK README.
- **Samsung Health not available**: requires a real Samsung device. The
  emulator will only surface Health Connect.
- **`flutter test` fails on upstream widget tests**: run `flutter test test/services/` instead (see note above).

## Upstream tracking

Everything Cureocity-added in `example/` begins with the commit-message prefix
`cureocity(example):`. To see just our changes:
```bash
git log --grep "^cureocity" --oneline example/
```

To pull upstream updates:
```bash
git fetch upstream
git checkout cureocity/main
git rebase upstream/main   # conflicts should be rare because we added new files, not modified
git push --force-with-lease origin cureocity/main
```
