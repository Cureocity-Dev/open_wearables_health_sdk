# Task 3 notes — example/ replacement decision

Decision: **EXTEND**

Reason: The existing `example/` is already a fully-built Cureocity-flavored dev
console (single `lib/main.dart`, ~1249 lines) that wires configure / signIn /
requestAuthorization / syncNow / signOut / provider selection / log streaming /
Sentry / auth-error handling against a real `/invitations/{code}/redeem`
endpoint — i.e. it IS the demo we were planning to build. iOS and Android
native configs are also already fully wired (HealthKit entitlements +
BGTaskScheduler identifiers + Health Connect activity-aliases +
FlutterFragmentActivity). Replacing would discard working, on-brand code; we
should extend/refine in place.

## Current example/ inventory

- `example/pubspec.yaml` — path dep on `../`, pulls sentry_flutter + http.
- `example/pubspec.lock` — present (pre-resolved; we'll regenerate after any
  dep change).
- `example/README.md` — stock Flutter boilerplate, non-informative.
- `example/analysis_options.yaml` — present (lint config).
- `example/.gitignore` — standard Flutter.
- `example/lib/main.dart` — the entire app (1249 lines): `OWColors` design
  tokens (zinc palette + indigo accent), `MyApp` dark Material3 theme,
  `HomePage` with invitation-code flow (host + code -> POST
  `/invitations/{code}/redeem` -> `configure` + `signIn`), provider selection
  (Android `getAvailableProviders` / `setProvider`), `requestAuthorization`
  against `HealthDataType.values`, `syncNow` with days-back picker
  (null = full), sign-out, native log stream piped to `appLogs` with
  throttled rebuilds, `LogsPage` viewer, Sentry init + breadcrumbs +
  `authErrorStream` -> forced sign-out.
- `example/integration_test/plugin_integration_test.dart` — one integration
  test (likely stock Flutter template).
- `example/test/widget_test.dart` — stock widget test.
- `example/assets/open_wearables_logo.png` — branded logo asset.
- `example/ios/Runner/{Info.plist, Runner.entitlements, AppDelegate.swift,
  Assets.xcassets, Base.lproj, Runner-Bridging-Header.h}` — fully wired.
- `example/android/app/src/main/{AndroidManifest.xml,
  kotlin/.../MainActivity.kt, res/}` — fully wired.

## pubspec.yaml status

- SDK dependency: **`path: ../`** (path dep on parent plugin — exactly what
  the plan assumed).
- Flutter/Dart SDK constraint: **`sdk: ^3.9.2`** (Dart SDK constraint; no
  separate `flutter:` version pin).
- Other notable deps: `sentry_flutter: ^9.16.0`, `http: ^1.6.0`,
  `cupertino_icons: ^1.0.8`. Dev: `integration_test`, `flutter_test`,
  `flutter_lints: ^5.0.0`.

## iOS config present

- `NSHealthShareUsageDescription`: **yes** ("This app syncs your health data
  to your account.").
- `NSHealthUpdateUsageDescription`: **yes**.
- `BGTaskSchedulerPermittedIdentifiers`: **yes** —
  `com.openwearables.healthsdk.task.refresh` and
  `com.openwearables.healthsdk.task.process`.
- `UIBackgroundModes`: **yes** — includes `fetch` and `processing`.
- HealthKit entitlement in `Runner.entitlements`: **yes** —
  `com.apple.developer.healthkit = true` AND
  `com.apple.developer.healthkit.background-delivery = true`.
- Bundle display name already set to "Open Wearables".

## Android config present

- `minSdk`: **29** (Android 10).
- `compileSdk` / `targetSdk`: `flutter.compileSdkVersion` /
  `flutter.targetSdkVersion` (defaults from Flutter tooling).
- `applicationId`: `com.openwearables.health.sdk.example`.
- `MainActivity` extends `FlutterFragmentActivity`: **yes** (required by
  Health Connect permission contract).
- Health Connect `<activity-alias>` entries in `AndroidManifest.xml`:
  **yes** — both `ViewPermissionUsageActivity` (Android 14+
  `VIEW_PERMISSION_USAGE` + `HEALTH_PERMISSIONS` category) and
  `ShowPermissionRationaleActivity`
  (`androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE`) are present.
- `<queries>` block for `PROCESS_TEXT` present.

## Task 4 adjustments required

- Do **not** rewrite `example/lib/main.dart`. Keep it. Any Task-4 changes
  should be surgical edits to existing methods, or additive extraction into
  `example/lib/services/` and `example/lib/ui/` only if a specific feature
  demands it (most don't — current file is coherent).
- The `http` dep is used by `_connectWithInvitationCode` to POST
  `/invitations/{code}/redeem` — matches Task-2's backend endpoint shape;
  no change needed unless Task 2 uncovered a different path.
- `sentry_flutter` is wired with a hardcoded DSN
  (`https://3d912364254042549967f3560053f841@sentry.mntm.dev/109`). For
  the Cureocity demo we probably want to either (a) leave it, (b) replace
  with a Cureocity DSN, or (c) gate behind `--dart-define`. Ask before
  touching it.
- The README is stock boilerplate; Task 4 should replace it with actual
  "how to run this demo" instructions (host URL, invitation code flow,
  logs page, iOS/Android setup pointers).
- `test/widget_test.dart` and `integration_test/plugin_integration_test.dart`
  likely reference the old stock counter template — verify and update/delete
  if they don't compile against the current `HomePage`.
- Do NOT run `flutter pub get` until Task 4 explicitly kicks off; note that
  `pubspec.lock` is already checked in.

## Task 5/6 adjustments required

- **Task 5 (iOS)**: Nearly nothing to do. HealthKit entitlement, background
  delivery entitlement, both usage descriptions, BGTaskScheduler IDs, and
  `UIBackgroundModes` (fetch + processing) are ALL already present. Task 5
  should reduce to: (a) verify bundle id / signing team if we're building
  on a real device, (b) optionally add a `CFBundleURLTypes` entry if we
  decide on a deep-link-based invitation flow later, (c) sanity-check the
  BGTask identifier strings match what the SDK actually registers (search
  SDK native code for `com.openwearables.healthsdk.task.*`). If all match,
  Task 5 is a no-op.
- **Task 6 (Android)**: Also nearly nothing. `minSdk=29`,
  `FlutterFragmentActivity`, and both Health Connect activity-aliases are
  in place. Task 6 should reduce to: (a) confirm the app's package name
  (`com.openwearables.health.sdk.example`) is acceptable for the demo or
  change to `city.cureo.*`, (b) verify the SDK's own AndroidManifest.xml
  merges in the Health Connect `<uses-permission>` reads we need (the
  example manifest has none — they come from the plugin manifest), (c)
  confirm Gradle plugin versions / Kotlin version are current. No manifest
  or activity rewrites expected.
- In short: most of the "native wiring" work the original plan budgeted
  for Tasks 5 & 6 is already done in the fork. Those tasks collapse to
  verification + packaging tweaks.
