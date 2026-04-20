import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:open_wearables_health_sdk_example/services/health_event.dart';
import 'package:open_wearables_health_sdk_example/services/health_metric.dart';
import 'package:open_wearables_health_sdk_example/services/health_service_controller.dart';
import 'package:open_wearables_health_sdk_example/services/open_wearables_health_service.dart';

class MockService extends Mock implements OpenWearablesHealthService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<HealthMetric>{});
  });

  late MockService svc;
  late HealthServiceController ctrl;

  setUp(() {
    svc = MockService();
    ctrl = HealthServiceController(service: svc);
  });

  test('events start empty', () {
    expect(ctrl.events, isEmpty);
    expect(ctrl.isInitialized, isFalse);
    expect(ctrl.lastSyncStatus, isNull);
    expect(ctrl.lastStoredCredentials, isNull);
    expect(ctrl.availableProviders, isEmpty);
  });

  test('configureAndSignIn appends an OK event on success', () async {
    when(() => svc.init(
          userId: any(named: 'userId'),
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async {});
    when(() => svc.isInitialized).thenReturn(true);

    await ctrl.configureAndSignIn(userId: 'u', apiKey: 'k');

    expect(ctrl.events, hasLength(1));
    expect(ctrl.events.first.level, HealthEventLevel.ok);
    expect(ctrl.events.first.message, contains('init'));
  });

  test('configureAndSignIn appends an ERR event with classified error', () async {
    when(() => svc.init(
          userId: any(named: 'userId'),
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          apiKey: any(named: 'apiKey'),
        )).thenThrow(Exception('401 Unauthorized'));
    when(() => svc.isInitialized).thenReturn(false);

    await ctrl.configureAndSignIn(userId: 'u', apiKey: 'k');

    expect(ctrl.events, hasLength(1));
    expect(ctrl.events.first.level, HealthEventLevel.err);
    expect(ctrl.events.first.errorClass, 'AuthError');
  });

  test('syncNow / startBg / stopBg / getSyncStatus each append an event', () async {
    when(() => svc.syncNow()).thenAnswer((_) async {});
    when(() => svc.startBackgroundSync(syncDaysBack: any(named: 'syncDaysBack')))
        .thenAnswer((_) async => true);
    when(() => svc.stopBackgroundSync()).thenAnswer((_) async {});
    when(() => svc.getSyncStatus()).thenAnswer((_) async => {'state': 'idle'});

    await ctrl.syncNow();
    await ctrl.startBackgroundSync(syncDaysBack: 30);
    await ctrl.stopBackgroundSync();
    await ctrl.refreshSyncStatus();

    expect(ctrl.events, hasLength(4));
    expect(ctrl.lastSyncStatus, {'state': 'idle'});
  });

  test('requestPermissions forwards the metric set', () async {
    when(() => svc.requestPermissions(metrics: any(named: 'metrics')))
        .thenAnswer((_) async => true);
    await ctrl.requestPermissions({HealthMetric.steps, HealthMetric.stressScore});
    final captured = verify(() => svc.requestPermissions(
          metrics: captureAny(named: 'metrics'),
        )).captured.single as Set<HealthMetric>;
    expect(captured, {HealthMetric.steps, HealthMetric.stressScore});
  });

  test('clearLogs removes all events and notifies', () async {
    when(() => svc.syncNow()).thenAnswer((_) async {});
    await ctrl.syncNow();
    expect(ctrl.events, isNotEmpty);

    var notified = 0;
    ctrl.addListener(() => notified++);
    ctrl.clearLogs();

    expect(ctrl.events, isEmpty);
    expect(notified, 1);
  });
}
