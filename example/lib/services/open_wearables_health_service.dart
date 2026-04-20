import 'dart:io' show Platform;

import 'package:open_wearables_health_sdk/health_data_type.dart';

import 'health_metric.dart';
import 'health_service.dart';
import 'open_wearables_sdk_api.dart';

class OpenWearablesHealthService implements HealthService {
  OpenWearablesHealthService({
    required OpenWearablesSdkApi sdk,
    required String host,
  })  : _sdk = sdk,
        _host = host;

  final OpenWearablesSdkApi _sdk;
  final String _host;

  bool _configured = false;
  bool _signedIn = false;

  @override
  bool get isInitialized => _configured && _signedIn;

  @override
  bool get supportsWaterWrite => false;

  @override
  bool get supportsDeviceListing => Platform.isAndroid;

  /// Cureocity → Open Wearables metric mapping. `null` means the SDK
  /// does not cover this metric (the gap list driving sub-project C).
  static const Map<HealthMetric, HealthDataType?> _metricMap = {
    HealthMetric.steps:           HealthDataType.steps,
    HealthMetric.sleepDuration:   HealthDataType.sleep,
    HealthMetric.heartrate:       HealthDataType.heartRate,
    HealthMetric.bodyTemperature: HealthDataType.bodyTemperature,
    HealthMetric.bloodPressure:   HealthDataType.bloodPressure,
    HealthMetric.hrv:             HealthDataType.heartRateVariabilitySDNN,
    HealthMetric.spo2:            HealthDataType.oxygenSaturation,
    HealthMetric.breathingRate:   HealthDataType.respiratoryRate,
    HealthMetric.calories:        null, // derive activeEnergy + basalEnergy (Cureocity backend)
    HealthMetric.bodyComposition: null, // partial via bodyFat + lean + mass
    HealthMetric.stressScore:     null, // not in SDK at all
  };

  @override
  bool supportsMetric(HealthMetric metric) => _metricMap[metric] != null;

  /// Returns SDK types corresponding to provided Cureocity metrics.
  /// Skips `null` (gap) entries. Used by later tasks.
  List<HealthDataType> _mappedTypesFor(Iterable<HealthMetric> metrics) =>
      metrics.map((m) => _metricMap[m]).whereType<HealthDataType>().toList();

  @override
  Future<void> init({
    String? userId,
    String? accessToken,
    String? refreshToken,
    String? apiKey,
  }) async {
    if (userId == null || userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must be a non-empty string');
    }
    if (apiKey == null && accessToken == null) {
      throw ArgumentError('Either apiKey or accessToken must be provided');
    }

    await _sdk.configure(host: _host);
    _configured = true;

    try {
      await _sdk.signIn(
        userId: userId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        apiKey: apiKey,
      );
      _signedIn = true;
    } catch (_) {
      _signedIn = false;
      rethrow;
    }
  }

  @override
  Future<bool> requestPermissions({required Set<HealthMetric> metrics}) async {
    final mapped = _mappedTypesFor(metrics);
    if (mapped.isEmpty) return false;
    return _sdk.requestAuthorization(types: mapped);
  }

  @override
  Future<void> installHealthConnect() =>
      throw UnimplementedError('implemented in Task 14');

  @override
  Future<void> fetchHealthData() =>
      throw UnimplementedError('implemented in Task 15');

  @override
  Future<void> fetchHistoricalHealthData() =>
      throw UnimplementedError('implemented in Task 15');

  @override
  Future<bool> writeWaterIntake(double waterMl) =>
      throw UnimplementedError('implemented in Task 15');

  @override
  Future<void> buildDailyPayload() =>
      throw UnimplementedError('implemented in Task 15');
}
