import 'package:flutter/material.dart';

import '../../services/health_metric.dart';
import '../../services/health_service_controller.dart';

class MetricGapDialog extends StatelessWidget {
  const MetricGapDialog({super.key, required this.controller});
  final HealthServiceController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cureocity ⇄ Open Wearables metric map'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: HealthMetric.values.map((m) {
            final supported = controller.supportsMetric(m);
            return ListTile(
              dense: true,
              leading: Icon(
                supported ? Icons.check_circle : Icons.error,
                color: supported ? Colors.green : Colors.red,
              ),
              title: Text(m.name),
              subtitle:
                  Text(supported ? 'mapped to SDK' : 'gap — missing / partial'),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
