import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backend/health_data_controller.dart';
import '../services/health_service_controller.dart';
import 'health_data_screen.dart';
import 'widgets/connection_section.dart';
import 'widgets/introspection_section.dart';
import 'widgets/log_view.dart';
import 'widgets/permissions_section.dart';
import 'widgets/providers_section.dart';
import 'widgets/sync_section.dart';

class DevConsoleScreen extends StatefulWidget {
  const DevConsoleScreen({
    super.key,
    required this.controller,
    required this.healthDataController,
  });
  final HealthServiceController controller;
  final HealthDataController healthDataController;

  @override
  State<DevConsoleScreen> createState() => _DevConsoleScreenState();
}

class _DevConsoleScreenState extends State<DevConsoleScreen> {
  final _hostController = TextEditingController(text: 'http://localhost:8000');

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Wearables Parity Probe'),
        actions: [
          IconButton(
            tooltip: 'Health data',
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HealthDataScreen(
                  controller: widget.healthDataController,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Clear logs',
            onPressed: widget.controller.clearLogs,
            icon: const Icon(Icons.delete_sweep),
          ),
          IconButton(
            tooltip: 'Copy logs',
            onPressed: () => Clipboard.setData(
              ClipboardData(text: widget.controller.eventsAsJsonLines()),
            ),
            icon: const Icon(Icons.copy_all),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host URL (display-only for v1)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ConnectionSection(controller: widget.controller),
            PermissionsSection(controller: widget.controller),
            ProvidersSection(controller: widget.controller),
            SyncSection(controller: widget.controller),
            IntrospectionSection(controller: widget.controller),
            Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedBuilder(
                animation: widget.controller,
                builder: (_, __) =>
                    LogView(events: widget.controller.events),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
