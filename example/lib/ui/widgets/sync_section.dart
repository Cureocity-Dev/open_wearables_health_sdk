import 'package:flutter/material.dart';

import '../../services/health_service_controller.dart';

class SyncSection extends StatelessWidget {
  const SyncSection({super.key, required this.controller});
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
            const Text('SYNC', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton(
                onPressed: controller.syncNow,
                child: const Text('Sync Now'),
              ),
              FilledButton(
                onPressed: () =>
                    controller.startBackgroundSync(syncDaysBack: 30),
                child: const Text('Start BG (30d)'),
              ),
              OutlinedButton(
                onPressed: controller.stopBackgroundSync,
                child: const Text('Stop BG'),
              ),
              OutlinedButton(
                onPressed: controller.resetAnchors,
                child: const Text('Reset Anchors'),
              ),
              OutlinedButton(
                onPressed: controller.resumeSync,
                child: const Text('Resume'),
              ),
              OutlinedButton(
                onPressed: controller.clearSyncSession,
                child: const Text('Clear Session'),
              ),
              OutlinedButton(
                onPressed: controller.refreshSyncStatus,
                child: const Text('Get Status'),
              ),
            ]),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => Text(
                'Last status: ${controller.lastSyncStatus ?? '—'}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
