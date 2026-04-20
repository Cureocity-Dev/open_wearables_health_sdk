import 'package:flutter/material.dart';

import '../../services/health_metric.dart';
import '../../services/health_service_controller.dart';

class PermissionsSection extends StatefulWidget {
  const PermissionsSection({super.key, required this.controller});
  final HealthServiceController controller;

  @override
  State<PermissionsSection> createState() => _PermissionsSectionState();
}

class _PermissionsSectionState extends State<PermissionsSection> {
  final Set<HealthMetric> _selected = {};

  void _selectCureocitySet() {
    setState(() {
      _selected
        ..clear()
        ..addAll(HealthMetric.values.where(widget.controller.supportsMetric));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('PERMISSIONS',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: HealthMetric.values.map((m) {
                final supported = widget.controller.supportsMetric(m);
                return FilterChip(
                  label: Text(m.name),
                  selected: _selected.contains(m),
                  onSelected: supported
                      ? (on) => setState(() {
                            if (on) {
                              _selected.add(m);
                            } else {
                              _selected.remove(m);
                            }
                          })
                      : null,
                  tooltip: supported ? null : 'gap — not in SDK',
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: _selectCureocitySet,
                child: const Text('Select Cureocity set'),
              ),
              FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => widget.controller.requestPermissions(_selected),
                child: const Text('Request Authorization'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
