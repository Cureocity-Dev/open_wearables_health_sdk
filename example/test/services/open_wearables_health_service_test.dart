import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
}
