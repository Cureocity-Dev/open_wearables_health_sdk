import 'package:flutter/material.dart';

import '../../services/health_service_controller.dart';
import 'metric_gap_dialog.dart';

class IntrospectionSection extends StatelessWidget {
  const IntrospectionSection({super.key, required this.controller});
  final HealthServiceController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('INTROSPECTION',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: controller.refreshStoredCredentials,
                child: const Text('Get Stored Credentials'),
              ),
              OutlinedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => MetricGapDialog(controller: controller),
                ),
                child: const Text('Show Metric Map & Gaps'),
              ),
            ]),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => Text(
                'Stored: ${controller.lastStoredCredentials ?? '—'}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
