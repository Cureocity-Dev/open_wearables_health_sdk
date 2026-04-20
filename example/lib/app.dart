import 'package:flutter/material.dart';

import 'services/health_service_controller.dart';
import 'services/open_wearables_health_service.dart';
import 'services/open_wearables_sdk_api.dart';
import 'ui/dev_console_screen.dart';

class ParityProbeApp extends StatefulWidget {
  const ParityProbeApp({super.key});

  @override
  State<ParityProbeApp> createState() => _ParityProbeAppState();
}

class _ParityProbeAppState extends State<ParityProbeApp> {
  late final HealthServiceController _controller;

  @override
  void initState() {
    super.initState();
    const sdk = OpenWearablesSdkApi();
    final service = OpenWearablesHealthService(
      sdk: sdk,
      host: 'http://localhost:8000',
    );
    _controller = HealthServiceController(service: service);
  }

  @override
  void dispose() {
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
      home: DevConsoleScreen(controller: _controller),
    );
  }
}
