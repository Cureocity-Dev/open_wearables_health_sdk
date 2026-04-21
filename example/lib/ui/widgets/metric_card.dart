import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A stat block: icon + title + big primary number + unit, with an
/// optional sparkline rendered on the right.
///
/// `sparkline` is a list of y-values (same order as x, x is implicit 0..n-1).
/// Nulls are treated as gaps. If the list is null or has <2 non-null points,
/// the sparkline is hidden.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.icon,
    this.accent,
    this.sparkline,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? accent;
  final List<double?>? sparkline;
  final String? subtitle;

  List<FlSpot>? _spots() {
    if (sparkline == null) return null;
    final spots = <FlSpot>[];
    for (var i = 0; i < sparkline!.length; i++) {
      final y = sparkline![i];
      if (y != null) spots.add(FlSpot(i.toDouble(), y));
    }
    if (spots.length < 2) return null;
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = accent ?? theme.colorScheme.primary;
    final spots = _spots();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: accentColor),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(letterSpacing: 1.2, color: accentColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: value,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (unit != null)
                          TextSpan(
                            text: ' ${unit!}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (spots != null)
              SizedBox(
                width: 88,
                height: 40,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        barWidth: 2,
                        color: accentColor,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
