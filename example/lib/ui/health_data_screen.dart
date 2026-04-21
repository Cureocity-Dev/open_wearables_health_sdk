import 'package:flutter/material.dart';

import '../services/backend/health_data_controller.dart';
import '../services/backend/models.dart';
import 'widgets/metric_card.dart';
import 'widgets/range_selector.dart';

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key, required this.controller});
  final HealthDataController controller;

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.controller.selectRange(widget.controller.range));
  }

  String _formatNumber(num? n, {int decimals = 0}) {
    if (n == null) return '—';
    if (decimals == 0) return n.round().toString();
    return n.toStringAsFixed(decimals);
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  List<double?> _series<T>(List<T> items, double? Function(T) selector) =>
      items.map(selector).toList();

  double? _avg(Iterable<num?> values) {
    final nn = values.whereType<num>().toList();
    if (nn.isEmpty) return null;
    return nn.fold<double>(0, (s, v) => s + v) / nn.length;
  }

  num? _sum(Iterable<num?> values) {
    final nn = values.whereType<num>().toList();
    if (nn.isEmpty) return null;
    return nn.fold<num>(0, (s, v) => s + v);
  }

  Widget _buildActivitySection(List<ActivitySummary> list) {
    final stepsSeries = _series(list, (a) => a.steps?.toDouble());
    final distanceSeries = _series(list, (a) => a.distanceMeters);
    final activeCaloriesSeries = _series(list, (a) => a.activeCaloriesKcal);

    final totalSteps = _sum(list.map((a) => a.steps));
    final totalDistanceM = _sum(list.map((a) => a.distanceMeters));
    final totalActiveKcal = _sum(list.map((a) => a.activeCaloriesKcal));

    final singleDay = list.length == 1;
    final stepsValue =
        singleDay ? (list.first.steps ?? 0) : (totalSteps?.round() ?? 0);
    final stepsLabel = singleDay ? 'today' : 'total · ${list.length}d';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Activity'),
        MetricCard(
          title: 'Steps',
          value: _formatNumber(stepsValue),
          subtitle: stepsLabel,
          icon: Icons.directions_walk,
          accent: Colors.indigo,
          sparkline: stepsSeries,
        ),
        MetricCard(
          title: 'Distance',
          value: _formatNumber(
              ((singleDay ? list.first.distanceMeters : totalDistanceM) ?? 0) /
                  1000,
              decimals: 2),
          unit: 'km',
          icon: Icons.route,
          accent: Colors.teal,
          sparkline: distanceSeries,
        ),
        MetricCard(
          title: 'Active calories',
          value: _formatNumber(
              (singleDay ? list.first.activeCaloriesKcal : totalActiveKcal)),
          unit: 'kcal',
          icon: Icons.local_fire_department,
          accent: Colors.orange,
          sparkline: activeCaloriesSeries,
        ),
      ],
    );
  }

  Widget _buildSleepSection(List<SleepSummary> list) {
    final durationSeries =
        _series(list, (s) => s.durationMinutes?.toDouble());
    final avgDuration = _avg(list.map((s) => s.durationMinutes));
    final avgEff = _avg(list.map((s) => s.efficiencyPercent));
    final avgSpo2 = _avg(list.map((s) => s.avgSpo2Percent));
    final avgHr = _avg(list.map((s) => s.avgHeartRateBpm));
    final singleDay = list.length == 1;
    final duration =
        singleDay ? list.first.durationMinutes : avgDuration?.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sleep'),
        MetricCard(
          title: singleDay ? 'Sleep duration' : 'Avg sleep duration',
          value: _formatDuration(duration),
          icon: Icons.bedtime,
          accent: Colors.deepPurple,
          sparkline: durationSeries,
          subtitle: singleDay
              ? null
              : 'avg over ${list.length} day${list.length == 1 ? '' : 's'}',
        ),
        MetricCard(
          title: 'Efficiency',
          value: _formatNumber(avgEff, decimals: 1),
          unit: '%',
          icon: Icons.nightlight,
          accent: Colors.deepPurple,
        ),
        MetricCard(
          title: 'Avg HR (sleep)',
          value: _formatNumber(avgHr),
          unit: 'bpm',
          icon: Icons.favorite,
          accent: Colors.redAccent,
        ),
        MetricCard(
          title: 'Avg SpO₂ (sleep)',
          value: _formatNumber(avgSpo2, decimals: 1),
          unit: '%',
          icon: Icons.bloodtype,
          accent: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildRecoverySection(List<RecoverySummary> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    final score = _avg(list.map((r) => r.recoveryScore));
    final rhr = _avg(list.map((r) => r.restingHeartRateBpm));
    final hrv = _avg(list.map((r) => r.avgHrvSdnnMs));
    final scoreSeries =
        _series(list, (r) => r.recoveryScore?.toDouble());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Recovery'),
        MetricCard(
          title: 'Recovery score',
          value: _formatNumber(score),
          unit: '/100',
          icon: Icons.autorenew,
          accent: Colors.green,
          sparkline: scoreSeries,
        ),
        MetricCard(
          title: 'Resting HR',
          value: _formatNumber(rhr),
          unit: 'bpm',
          icon: Icons.favorite_border,
          accent: Colors.redAccent,
        ),
        MetricCard(
          title: 'HRV (SDNN)',
          value: _formatNumber(hrv, decimals: 1),
          unit: 'ms',
          icon: Icons.timeline,
          accent: Colors.pink,
        ),
      ],
    );
  }

  Widget _buildBodySection(BodySummary? body) {
    if (body == null) return const SizedBox.shrink();
    final sc = body.slowChanging;
    final latest = body.latest;
    final hasAnything = sc.weightKg != null ||
        sc.bmi != null ||
        sc.bodyFatPercent != null ||
        latest.bodyTemperatureCelsius != null;
    if (!hasAnything) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Body'),
        if (sc.weightKg != null)
          MetricCard(
            title: 'Weight',
            value: _formatNumber(sc.weightKg, decimals: 1),
            unit: 'kg',
            icon: Icons.monitor_weight,
            accent: Colors.brown,
          ),
        if (sc.bmi != null)
          MetricCard(
            title: 'BMI',
            value: _formatNumber(sc.bmi, decimals: 1),
            icon: Icons.scale,
            accent: Colors.brown,
          ),
        if (sc.bodyFatPercent != null)
          MetricCard(
            title: 'Body fat',
            value: _formatNumber(sc.bodyFatPercent, decimals: 1),
            unit: '%',
            icon: Icons.accessibility_new,
            accent: Colors.brown,
          ),
        if (latest.bodyTemperatureCelsius != null)
          MetricCard(
            title: 'Body temperature',
            value: _formatNumber(latest.bodyTemperatureCelsius, decimals: 1),
            unit: '°C',
            icon: Icons.thermostat,
            accent: Colors.orangeAccent,
          ),
      ],
    );
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          s,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Data'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: c.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: c,
          builder: (_, __) {
            return RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Center(
                      child: RangeSelector(
                        current: c.range,
                        onChanged: c.selectRange,
                      ),
                    ),
                  ),
                  if (c.loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (c.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            c.error!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!c.loading && c.error == null) ...[
                    if (c.activity.isEmpty &&
                        c.sleep.isEmpty &&
                        c.recovery.isEmpty &&
                        c.body == null)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('— no data yet —\nSync from the dev console.'),
                        ),
                      )
                    else ...[
                      if (c.activity.isNotEmpty) _buildActivitySection(c.activity),
                      if (c.sleep.isNotEmpty) _buildSleepSection(c.sleep),
                      _buildRecoverySection(c.recovery),
                      _buildBodySection(c.body),
                      const SizedBox(height: 24),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
