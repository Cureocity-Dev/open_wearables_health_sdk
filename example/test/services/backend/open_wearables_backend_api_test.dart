import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:open_wearables_health_sdk_example/services/backend/models.dart';
import 'package:open_wearables_health_sdk_example/services/backend/open_wearables_backend_api.dart';

void main() {
  group('OpenWearablesBackendApi', () {
    late MockClient mock;
    late OpenWearablesBackendApi api;
    late List<http.Request> captured;

    OpenWearablesBackendApi withHandler(http.Response Function(http.Request) h) {
      mock = MockClient((req) async {
        captured.add(req);
        return h(req);
      });
      return OpenWearablesBackendApi(
        host: 'http://localhost:8000',
        apiKey: 'sk-test',
        userId: 'user-1',
        httpClient: mock,
      );
    }

    setUp(() {
      captured = [];
    });

    test('GET activity summaries forwards date range + api key header', () async {
      api = withHandler((_) => http.Response(
            jsonEncode({
              'data': [
                {
                  'date': '2026-04-20',
                  'source': {'provider': 'apple_health'},
                  'steps': 5000,
                },
              ],
              'pagination': {'has_more': false},
              'metadata': {},
            }),
            200,
          ));

      final list = await api.fetchActivitySummaries(
        startDate: '2026-04-01',
        endDate: '2026-04-21',
      );

      expect(list, hasLength(1));
      expect(list.first.steps, 5000);
      expect(captured.single.url.path,
          '/api/v1/users/user-1/summaries/activity');
      expect(captured.single.url.queryParameters['start_date'], '2026-04-01');
      expect(captured.single.url.queryParameters['end_date'], '2026-04-21');
      expect(captured.single.headers['X-Open-Wearables-API-Key'], 'sk-test');
    });

    test('GET sleep summaries decodes duration_minutes', () async {
      api = withHandler((_) => http.Response(
            jsonEncode({
              'data': [
                {
                  'date': '2026-04-20',
                  'source': {'provider': 'apple_health'},
                  'duration_minutes': 430,
                }
              ],
              'pagination': {'has_more': false},
              'metadata': {},
            }),
            200,
          ));
      final list = await api.fetchSleepSummaries(
        startDate: '2026-04-20',
        endDate: '2026-04-21',
      );
      expect(list.single.durationMinutes, 430);
    });

    test('GET recovery summaries decodes recovery_score', () async {
      api = withHandler((_) => http.Response(
            jsonEncode({
              'data': [
                {
                  'date': '2026-04-20',
                  'source': {'provider': 'apple_health'},
                  'recovery_score': 72,
                }
              ],
              'pagination': {'has_more': false},
              'metadata': {},
            }),
            200,
          ));
      final list = await api.fetchRecoverySummaries(
        startDate: '2026-04-20',
        endDate: '2026-04-21',
      );
      expect(list.single.recoveryScore, 72);
    });

    test('GET body summary returns null on 204 / null body', () async {
      api = withHandler((_) => http.Response('null', 200));
      final body = await api.fetchBodySummary();
      expect(body, isNull);
    });

    test('GET body summary decodes BodySummary', () async {
      api = withHandler((_) => http.Response(
            jsonEncode({
              'source': {'provider': 'apple_health'},
              'slow_changing': {'weight_kg': 70.5, 'bmi': 23.1},
              'latest': {'body_temperature_celsius': 36.6},
            }),
            200,
          ));
      final body = await api.fetchBodySummary();
      expect(body, isA<BodySummary>());
      expect(body!.slowChanging.weightKg, 70.5);
      expect(body.latest.bodyTemperatureCelsius, 36.6);
    });

    test('non-2xx raises OpenWearablesApiException with status', () async {
      api = withHandler((_) => http.Response('{"detail":"bad"}', 401));
      expect(
        () => api.fetchActivitySummaries(
          startDate: '2026-04-20',
          endDate: '2026-04-21',
        ),
        throwsA(isA<OpenWearablesApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });
}
