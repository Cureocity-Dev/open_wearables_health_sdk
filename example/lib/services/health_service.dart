import 'health_metric.dart';

/// Trimmed copy of the `HealthService` abstract class from
/// `CureocityApps/packages/health_integration/lib/src/health_service_interface.dart`.
/// Only the members that the demo implements are included. The Cureocity-
/// specific read-path members (fetchHealthData, fetchHistoricalHealthData,
/// writeWaterIntake, buildDailyPayload) are represented here but the
/// impl throws [UnsupportedError] / returns false — by design, to surface
/// the architectural gap (see comparison doc).
abstract class HealthService {
  bool get isInitialized;
  bool get supportsWaterWrite;
  bool get supportsDeviceListing;
  bool supportsMetric(HealthMetric metric);

  Future<void> init({
    String? userId,
    String? accessToken,
    String? refreshToken,
    String? apiKey,
  });

  Future<bool> requestPermissions({required Set<HealthMetric> metrics});

  Future<void> installHealthConnect();

  /// Unsupported in this SDK — demo throws [UnsupportedError].
  Future<void> fetchHealthData();

  /// Unsupported — demo throws [UnsupportedError].
  Future<void> fetchHistoricalHealthData();

  /// Unsupported — returns false.
  Future<bool> writeWaterIntake(double waterMl);

  /// Unsupported — demo throws [UnsupportedError].
  Future<void> buildDailyPayload();
}
