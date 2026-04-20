import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_wearables_health_sdk/health_data_type.dart';
import 'package:open_wearables_health_sdk_example/services/health_metric.dart';
import 'package:open_wearables_health_sdk_example/services/open_wearables_health_service.dart';
import 'package:open_wearables_health_sdk_example/services/open_wearables_sdk_api.dart';

class MockSdkApi extends Mock implements OpenWearablesSdkApi {}

void main() {
  late MockSdkApi sdk;
  late OpenWearablesHealthService service;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(<HealthDataType>[]);
  });

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

  group('OpenWearablesHealthService.init', () {
    test('calls configure(host) then signIn(userId, apiKey) in order', () async {
      when(() => sdk.configure(host: any(named: 'host')))
          .thenAnswer((_) async {});
      // signIn returns OpenWearablesHealthSdkUser which is hard to construct in tests.
      // We throw from the stub; the service's try/catch will rethrow, and the
      // caller below catches. We only assert that BOTH methods were called in order.
      when(() => sdk.signIn(
                userId: any(named: 'userId'),
                accessToken: any(named: 'accessToken'),
                refreshToken: any(named: 'refreshToken'),
                apiKey: any(named: 'apiKey'),
              ))
          .thenThrow(UnsupportedError('signIn return type unused in this test'));

      await service.init(userId: 'demo-user-1', apiKey: 'key-123').catchError((_) {});

      verifyInOrder([
        () => sdk.configure(host: 'http://localhost:8000'),
        () => sdk.signIn(
              userId: 'demo-user-1',
              accessToken: null,
              refreshToken: null,
              apiKey: 'key-123',
            ),
      ]);
    });

    test('throws ArgumentError when userId missing', () async {
      expect(
        () => service.init(apiKey: 'k'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when no credential provided', () async {
      expect(
        () => service.init(userId: 'u'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('OpenWearablesHealthService.requestPermissions', () {
    test('maps metrics to SDK types, skipping gap entries', () async {
      when(() => sdk.requestAuthorization(types: any(named: 'types')))
          .thenAnswer((_) async => true);

      final ok = await service.requestPermissions(metrics: {
        HealthMetric.steps,
        HealthMetric.stressScore, // gap — silently skipped
        HealthMetric.heartrate,
      });

      expect(ok, isTrue);
      final captured = verify(() => sdk.requestAuthorization(
            types: captureAny(named: 'types'),
          )).captured.single as List<HealthDataType>;
      expect(captured, containsAll([HealthDataType.steps, HealthDataType.heartRate]));
      expect(captured.length, 2);
    });

    test('returns false when no metrics map after filtering gaps', () async {
      when(() => sdk.requestAuthorization(types: any(named: 'types')))
          .thenAnswer((_) async => true);
      final ok = await service.requestPermissions(metrics: {
        HealthMetric.stressScore,
      });
      expect(ok, isFalse);
      verifyNever(() => sdk.requestAuthorization(types: any(named: 'types')));
    });
  });
}
