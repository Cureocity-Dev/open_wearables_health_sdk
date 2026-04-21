import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_wearables_health_sdk_example/services/backend/health_data_controller.dart';
import 'package:open_wearables_health_sdk_example/services/backend/models.dart';
import 'package:open_wearables_health_sdk_example/services/backend/open_wearables_backend_api.dart';

class MockApi extends Mock implements OpenWearablesBackendApi {}

void main() {
  late MockApi api;
  late HealthDataController ctrl;

  setUp(() {
    api = MockApi();
    ctrl = HealthDataController(
      api: api,
      now: () => DateTime(2026, 4, 21, 12),
    );
  });

  test('initial state: range=day, loading=false, empty lists', () {
    expect(ctrl.range, HealthRange.day);
    expect(ctrl.loading, isFalse);
    expect(ctrl.activity, isEmpty);
    expect(ctrl.sleep, isEmpty);
    expect(ctrl.recovery, isEmpty);
    expect(ctrl.body, isNull);
    expect(ctrl.error, isNull);
  });

  test('selectRange=day fetches today only and populates lists', () async {
    when(() => api.fetchActivitySummaries(
          startDate: '2026-04-21',
          endDate: '2026-04-21',
        )).thenAnswer((_) async => [
          ActivitySummary(
              date: '2026-04-21',
              source: const SourceMetadata(provider: 'apple_health'),
              steps: 2500),
        ]);
    when(() => api.fetchSleepSummaries(
          startDate: '2026-04-21',
          endDate: '2026-04-21',
        )).thenAnswer((_) async => []);
    when(() => api.fetchRecoverySummaries(
          startDate: '2026-04-21',
          endDate: '2026-04-21',
        )).thenAnswer((_) async => []);
    when(() => api.fetchBodySummary()).thenAnswer((_) async => null);

    await ctrl.selectRange(HealthRange.day);

    expect(ctrl.range, HealthRange.day);
    expect(ctrl.activity.single.steps, 2500);
    expect(ctrl.loading, isFalse);
    expect(ctrl.error, isNull);
  });

  test('selectRange=week uses 7-day window ending today', () async {
    when(() => api.fetchActivitySummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchSleepSummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchRecoverySummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchBodySummary()).thenAnswer((_) async => null);

    await ctrl.selectRange(HealthRange.week);

    final captured = verify(() => api.fetchActivitySummaries(
          startDate: captureAny(named: 'startDate'),
          endDate: captureAny(named: 'endDate'),
        )).captured;
    expect(captured, ['2026-04-15', '2026-04-21']);
  });

  test('selectRange=month uses 30-day window ending today', () async {
    when(() => api.fetchActivitySummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchSleepSummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchRecoverySummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchBodySummary()).thenAnswer((_) async => null);

    await ctrl.selectRange(HealthRange.month);

    final captured = verify(() => api.fetchActivitySummaries(
          startDate: captureAny(named: 'startDate'),
          endDate: captureAny(named: 'endDate'),
        )).captured;
    expect(captured, ['2026-03-22', '2026-04-21']);
  });

  test('when an API call throws, error is populated and loading is false', () async {
    when(() => api.fetchActivitySummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenThrow(OpenWearablesApiException(500, message: 'boom'));
    when(() => api.fetchSleepSummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchRecoverySummaries(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);
    when(() => api.fetchBodySummary()).thenAnswer((_) async => null);

    await ctrl.selectRange(HealthRange.day);

    expect(ctrl.error, isNotNull);
    expect(ctrl.loading, isFalse);
  });
}
