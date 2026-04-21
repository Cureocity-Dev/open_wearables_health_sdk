import 'package:flutter/foundation.dart';

import 'models.dart';
import 'open_wearables_backend_api.dart';

enum HealthRange { day, week, month }

extension HealthRangeLabel on HealthRange {
  String get label {
    switch (this) {
      case HealthRange.day:
        return 'Day';
      case HealthRange.week:
        return 'Week';
      case HealthRange.month:
        return 'Month';
    }
  }
}

typedef Clock = DateTime Function();

class HealthDataController extends ChangeNotifier {
  HealthDataController({
    required OpenWearablesBackendApi api,
    Clock? now,
  })  : _api = api,
        _now = now ?? DateTime.now;

  final OpenWearablesBackendApi _api;
  final Clock _now;

  HealthRange _range = HealthRange.day;
  bool _loading = false;
  String? _error;
  List<ActivitySummary> _activity = const [];
  List<SleepSummary> _sleep = const [];
  List<RecoverySummary> _recovery = const [];
  BodySummary? _body;

  HealthRange get range => _range;
  bool get loading => _loading;
  String? get error => _error;
  List<ActivitySummary> get activity => _activity;
  List<SleepSummary> get sleep => _sleep;
  List<RecoverySummary> get recovery => _recovery;
  BodySummary? get body => _body;

  ({String start, String end}) _windowFor(HealthRange r) {
    final end = _now();
    final DateTime start;
    switch (r) {
      case HealthRange.day:
        start = DateTime(end.year, end.month, end.day);
        break;
      case HealthRange.week:
        start = end.subtract(const Duration(days: 6));
        break;
      case HealthRange.month:
        start = end.subtract(const Duration(days: 30));
        break;
    }
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return (start: fmt(start), end: fmt(end));
  }

  Future<void> selectRange(HealthRange r) async {
    _range = r;
    _error = null;
    _loading = true;
    notifyListeners();

    final w = _windowFor(r);
    try {
      final results = await Future.wait<Object?>([
        _api.fetchActivitySummaries(startDate: w.start, endDate: w.end),
        _api.fetchSleepSummaries(startDate: w.start, endDate: w.end),
        _api.fetchRecoverySummaries(startDate: w.start, endDate: w.end),
        _api.fetchBodySummary(),
      ]);
      _activity = (results[0] as List<ActivitySummary>);
      _sleep = (results[1] as List<SleepSummary>);
      _recovery = (results[2] as List<RecoverySummary>);
      _body = results[3] as BodySummary?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => selectRange(_range);
}
