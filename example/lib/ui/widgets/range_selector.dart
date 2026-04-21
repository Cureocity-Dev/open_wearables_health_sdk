import 'package:flutter/material.dart';

import '../../services/backend/health_data_controller.dart';

class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final HealthRange current;
  final ValueChanged<HealthRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<HealthRange>(
      segments: HealthRange.values
          .map((r) => ButtonSegment(value: r, label: Text(r.label)))
          .toList(),
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
