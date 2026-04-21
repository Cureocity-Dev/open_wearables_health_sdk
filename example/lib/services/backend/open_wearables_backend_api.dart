import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class OpenWearablesApiException implements Exception {
  OpenWearablesApiException(
    this.statusCode, {
    this.body,
    this.message,
  });
  final int statusCode;
  final String? body;
  final String? message;

  @override
  String toString() =>
      'OpenWearablesApiException($statusCode${message != null ? ": $message" : ""})';
}

/// Client for the Open Wearables backend REST API.
///
/// Scope: the endpoints consumed by the Cureocity parity-probe
/// health-data screen — activity/sleep/recovery/body summaries.
/// Ignore workouts/events/timeseries/health-scores for now.
class OpenWearablesBackendApi {
  OpenWearablesBackendApi({
    required this.host,
    required this.apiKey,
    required this.userId,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String host;
  final String apiKey;
  final String userId;
  final http.Client _http;

  Map<String, String> get _headers => {
        'X-Open-Wearables-API-Key': apiKey,
        'Accept': 'application/json',
      };

  Uri _u(String path, [Map<String, String>? query]) => Uri.parse(host).replace(
        path: path,
        queryParameters: query,
      );

  Future<List<ActivitySummary>> fetchActivitySummaries({
    required String startDate,
    required String endDate,
    int limit = 50,
    String sortOrder = 'asc',
  }) async {
    final resp = await _http.get(
      _u('/api/v1/users/$userId/summaries/activity', {
        'start_date': startDate,
        'end_date': endDate,
        'limit': '$limit',
        'sort_order': sortOrder,
      }),
      headers: _headers,
    );
    _ensureOk(resp);
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return (payload['data'] as List<dynamic>)
        .map((e) => ActivitySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SleepSummary>> fetchSleepSummaries({
    required String startDate,
    required String endDate,
    int limit = 50,
  }) async {
    final resp = await _http.get(
      _u('/api/v1/users/$userId/summaries/sleep', {
        'start_date': startDate,
        'end_date': endDate,
        'limit': '$limit',
      }),
      headers: _headers,
    );
    _ensureOk(resp);
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return (payload['data'] as List<dynamic>)
        .map((e) => SleepSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecoverySummary>> fetchRecoverySummaries({
    required String startDate,
    required String endDate,
    int limit = 50,
  }) async {
    final resp = await _http.get(
      _u('/api/v1/users/$userId/summaries/recovery', {
        'start_date': startDate,
        'end_date': endDate,
        'limit': '$limit',
      }),
      headers: _headers,
    );
    _ensureOk(resp);
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return (payload['data'] as List<dynamic>)
        .map((e) => RecoverySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BodySummary?> fetchBodySummary({
    int averagePeriodDays = 7,
    int latestWindowHours = 4,
  }) async {
    final resp = await _http.get(
      _u('/api/v1/users/$userId/summaries/body', {
        'average_period': '$averagePeriodDays',
        'latest_window_hours': '$latestWindowHours',
      }),
      headers: _headers,
    );
    _ensureOk(resp);
    if (resp.body.trim().isEmpty) return null;
    final decoded = jsonDecode(resp.body);
    if (decoded == null) return null;
    return BodySummary.fromJson(decoded as Map<String, dynamic>);
  }

  void _ensureOk(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw OpenWearablesApiException(
      r.statusCode,
      body: r.body,
      message: r.reasonPhrase,
    );
  }

  void dispose() => _http.close();
}
