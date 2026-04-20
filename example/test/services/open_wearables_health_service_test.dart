import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_wearables_health_sdk_example/services/health_metric.dart';
import 'package:open_wearables_health_sdk_example/services/open_wearables_health_service.dart';
import 'package:open_wearables_health_sdk_example/services/open_wearables_sdk_api.dart';

class MockSdkApi extends Mock implements OpenWearablesSdkApi {}

void main() {
  late MockSdkApi sdk;
  late OpenWearablesHealthService service;

  setUp(() {
    sdk = MockSdkApi();
    service = OpenWearablesHealthService(sdk: sdk, host: 'http://localhost:8000');
  });

  group('OpenWearablesHealthService capability flags', () {
    test('isInitialized is false before init', () {
      expect(service.isInitialized, isFalse);
    });

    test('supportsWaterWrite is false', () {
      expect(service.supportsWaterWrite, isFalse);
    });

    test('supportsDeviceListing matches Platform.isAndroid', () {
      expect(service.supportsDeviceListing, Platform.isAndroid);
    });
  });

  group('OpenWearablesHealthService.supportsMetric', () {
    test('returns true for cleanly-mapped metrics', () {
      expect(service.supportsMetric(HealthMetric.steps), isTrue);
      expect(service.supportsMetric(HealthMetric.sleepDuration), isTrue);
      expect(service.supportsMetric(HealthMetric.heartrate), isTrue);
      expect(service.supportsMetric(HealthMetric.bodyTemperature), isTrue);
      expect(service.supportsMetric(HealthMetric.bloodPressure), isTrue);
      expect(service.supportsMetric(HealthMetric.hrv), isTrue);
      expect(service.supportsMetric(HealthMetric.spo2), isTrue);
      expect(service.supportsMetric(HealthMetric.breathingRate), isTrue);
    });

    test('returns false for gap metrics (stressScore/calories/bodyComposition)', () {
      expect(service.supportsMetric(HealthMetric.stressScore), isFalse);
      expect(service.supportsMetric(HealthMetric.calories), isFalse);
      expect(service.supportsMetric(HealthMetric.bodyComposition), isFalse);
    });

    test('metric map covers every HealthMetric value (no throws)', () {
      for (final m in HealthMetric.values) {
        service.supportsMetric(m);
      }
    });
  });
}
