import 'package:flutter/material.dart';

import '../../services/health_event.dart';

class LogView extends StatelessWidget {
  const LogView({super.key, required this.events});

  final List<HealthEvent> events;

  Color _colorFor(HealthEventLevel l) {
    switch (l) {
      case HealthEventLevel.ok:
        return Colors.green.shade800;
      case HealthEventLevel.info:
        return Colors.amber.shade800;
      case HealthEventLevel.err:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('— no events yet —'),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: Scrollbar(
        child: ListView.builder(
          reverse: true,
          itemCount: events.length,
          itemBuilder: (_, i) {
            final e = events[events.length - 1 - i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Text(
                e.toLogLine(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _colorFor(e.level),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
