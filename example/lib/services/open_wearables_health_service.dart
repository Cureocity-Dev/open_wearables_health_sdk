import 'dart:io' show Platform;

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

  @override
  bool supportsMetric(HealthMetric metric) =>
      throw UnimplementedError('metric map added in Task 11');

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
