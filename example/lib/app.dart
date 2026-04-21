import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config/demo_credentials.dart';
import 'services/backend/health_data_controller.dart';
import 'services/backend/open_wearables_backend_api.dart';
import 'services/health_service_controller.dart';
import 'services/open_wearables_health_service.dart';
import 'services/open_wearables_sdk_api.dart';
import 'ui/dev_console_screen.dart';

/// Host used by the demo. Override at build time with:
///   --dart-define=OW_HOST=http://192.168.x.x:8000
///
/// Defaults:
///   - iOS simulator / macOS / web: localhost (docker compose on the Mac).
///   - iOS device / Android device: developer's Mac LAN IP (phones can't
///     reach localhost — `localhost` on the phone is the phone itself).
///   - Android emulator: 10.0.2.2 (the emulator's alias for the host).
String _defaultHost() {
  const override = String.fromEnvironment('OW_HOST', defaultValue: '');
  if (override.isNotEmpty) return override;
  if (kIsWeb) return 'http://localhost:8000';
  if (Platform.isIOS || Platform.isAndroid) {
    // Hardcoded Cureocity-dev Mac LAN IP. Change when your IP changes, or
    // pass --dart-define=OW_HOST=... to override.
    return 'http://192.168.29.94:8000';
  }
  return 'http://localhost:8000';
}

class ParityProbeApp extends StatefulWidget {
  const ParityProbeApp({super.key});

  @override
  State<ParityProbeApp> createState() => _ParityProbeAppState();
}

class _ParityProbeAppState extends State<ParityProbeApp> {
  late final HealthServiceController _controller;
  late final OpenWearablesBackendApi _backend;
  late final HealthDataController _healthData;

  @override
  void initState() {
    super.initState();
    const sdk = OpenWearablesSdkApi();
    final host = _defaultHost();
    final service = OpenWearablesHealthService(sdk: sdk, host: host);
    _controller = HealthServiceController(service: service);

    _backend = OpenWearablesBackendApi(
      host: host,
      apiKey: kDemoApiKey,
      userId: kDemoUserId,
    );
    _healthData = HealthDataController(api: _backend);
  }

  @override
  void dispose() {
    _healthData.dispose();
    _backend.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Wearables Parity Probe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: DevConsoleScreen(
        controller: _controller,
        healthDataController: _healthData,
      ),
    );
  }
}
