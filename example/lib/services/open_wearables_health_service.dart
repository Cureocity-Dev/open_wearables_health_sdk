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

  // ignore: unused_field
  final OpenWearablesSdkApi _sdk;
  // ignore: unused_field
  final String _host;

  @override
  bool get isInitialized => false;

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
  // ignore: unused_element
  List<HealthDataType> _mappedTypesFor(Iterable<HealthMetric> metrics) =>
      metrics.map((m) => _metricMap[m]).whereType<HealthDataType>().toList();

  @override
  Future<void> init({
    String? userId,
    String? accessToken,
    String? refreshToken,
    String? apiKey,
  }) =>
      throw UnimplementedError('implemented in Task 12');

  @override
  Future<bool> requestPermissions({required Set<HealthMetric> metrics}) =>
      throw UnimplementedError('implemented in Task 13');

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
