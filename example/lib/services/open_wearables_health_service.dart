import 'dart:io' show Platform;

import 'package:open_wearables_health_sdk/health_data_type.dart';

import 'health_metric.dart';
import 'health_service.dart';
import 'open_wearables_sdk_api.dart';
import 'url_launcher_api.dart';

class OpenWearablesHealthService implements HealthService {
  OpenWearablesHealthService({
    required OpenWearablesSdkApi sdk,
    required String host,
    UrlLauncherApi? launcher,
  })  : _sdk = sdk,
        _host = host,
        _launcher = launcher ?? const UrlLauncherApi();

  final OpenWearablesSdkApi _sdk;
  final String _host;
  final UrlLauncherApi _launcher;

  static const String _healthConnectPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';

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
  Future<void> installHealthConnect() async {
    await _launcher.launch(_healthConnectPlayStoreUrl);
  }

  @override
  Future<void> fetchHealthData() {
    throw UnsupportedError(
      'Open Wearables SDK has no local-read API. Data is written to backend; '
      'read paths live in your backend (e.g. via REST /api/v1/...).',
    );
  }

  @override
  Future<void> fetchHistoricalHealthData() {
    throw UnsupportedError(
      'Historical reads go through your backend, not the SDK.',
    );
  }

  @override
  Future<bool> writeWaterIntake(double waterMl) async => false;

  @override
  Future<void> buildDailyPayload() {
    throw UnsupportedError(
      'SDK self-uploads to backend; no client-built payload.',
    );
  }

  // --- SDK passthroughs for the dev console (not part of HealthService contract) ---

  Future<void> syncNow() => _sdk.syncNow();

  Future<bool> startBackgroundSync({int? syncDaysBack}) =>
      _sdk.startBackgroundSync(syncDaysBack: syncDaysBack);

  Future<void> stopBackgroundSync() => _sdk.stopBackgroundSync();

  Future<void> resetAnchors() => _sdk.resetAnchors();

  Future<void> resumeSync() => _sdk.resumeSync();

  Future<void> clearSyncSession() => _sdk.clearSyncSession();

  Future<Map<String, dynamic>> getSyncStatus() => _sdk.getSyncStatus();
}
