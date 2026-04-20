import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:open_wearables_health_sdk/open_wearables_health_sdk.dart';

import '../../services/health_service_controller.dart';

class ProvidersSection extends StatelessWidget {
  const ProvidersSection({super.key, required this.controller});
  final HealthServiceController controller;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('PROVIDERS (Android)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => Text(
                'Available: ${controller.availableProviders.map((p) => p.displayName).join(', ')}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: controller.refreshAvailableProviders,
                child: const Text('Get Available'),
              ),
              FilledButton(
                onPressed: () =>
                    controller.setProvider(AndroidHealthProvider.samsungHealth),
                child: const Text('Set Samsung'),
              ),
              FilledButton(
                onPressed: () =>
                    controller.setProvider(AndroidHealthProvider.healthConnect),
                child: const Text('Set HC'),
              ),
              OutlinedButton(
                onPressed: controller.installHealthConnect,
                child: const Text('Install HC'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
