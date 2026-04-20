import 'package:flutter/foundation.dart';
import 'package:open_wearables_health_sdk/open_wearables_health_sdk.dart';

import 'health_event.dart';
import 'health_metric.dart';
import 'open_wearables_health_service.dart';

class HealthServiceController extends ChangeNotifier {
  HealthServiceController({required OpenWearablesHealthService service})
      : _service = service;

  final OpenWearablesHealthService _service;
  final List<HealthEvent> _events = [];
  Map<String, dynamic>? _lastSyncStatus;
  Map<String, dynamic>? _lastStoredCreds;
  List<AvailableProvider> _availableProviders = const [];

  List<HealthEvent> get events => List.unmodifiable(_events);
  Map<String, dynamic>? get lastSyncStatus => _lastSyncStatus;
  Map<String, dynamic>? get lastStoredCredentials => _lastStoredCreds;
  List<AvailableProvider> get availableProviders => _availableProviders;
  bool get isInitialized {
    try {
      return _service.isInitialized;
    } catch (_) {
      return false;
    }
  }

  bool get supportsDeviceListing {
    try {
      return _service.supportsDeviceListing;
    } catch (_) {
      return false;
    }
  }

  void _emit(HealthEventLevel level, String message,
      {String? errorClass, Map<String, dynamic>? context}) {
    _events.add(HealthEvent(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      errorClass: errorClass,
      context: context,
    ));
    notifyListeners();
  }

  String _classifyError(Object e) {
    final s = e.toString();
    if (s.contains('401') ||
        s.contains('Unauthorized') ||
        s.contains('SignIn')) {
      return 'AuthError';
    }
    if (s.contains('SocketException') ||
        s.contains('TimeoutException') ||
        s.contains('Connection')) {
      return 'NetworkError';
    }
    if (s.contains('PlatformException') ||
        s.contains('HealthConnect') ||
        s.contains('HealthKit')) {
      return 'PlatformError';
    }
    return 'ValidationError';
  }

  Future<T?> _run<T>(String label, Future<T> Function() op,
      {Map<String, dynamic>? ctx}) async {
    try {
      final result = await op();
      _emit(HealthEventLevel.ok, '$label ok', context: ctx);
      return result;
    } catch (e) {
      _emit(HealthEventLevel.err, '$label failed: $e',
          errorClass: _classifyError(e), context: ctx);
      return null;
    }
  }

  // --- Actions wired by the UI ---

  Future<void> configureAndSignIn({
    required String userId,
    String? accessToken,
    String? refreshToken,
    String? apiKey,
  }) async {
    await _run<void>(
      'init',
      () => _service.init(
        userId: userId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        apiKey: apiKey,
      ),
      ctx: {'userId': userId, 'mode': apiKey != null ? 'apiKey' : 'tokens'},
    );
  }

  Future<void> signOut() async {
    await _run<void>('signOut', _service.signOut);
  }

  Future<void> requestPermissions(Set<HealthMetric> metrics) async {
    await _run<bool>(
      'requestPermissions',
      () => _service.requestPermissions(metrics: metrics),
      ctx: {'metrics': metrics.map((m) => m.name).toList()},
    );
  }

  Future<void> installHealthConnect() async {
    await _run<void>('installHealthConnect', _service.installHealthConnect);
  }

  Future<void> syncNow() async {
    await _run<void>('syncNow', _service.syncNow);
  }

  Future<void> startBackgroundSync({int? syncDaysBack}) async {
    await _run<bool>(
      'startBackgroundSync',
      () => _service.startBackgroundSync(syncDaysBack: syncDaysBack),
      ctx: {'syncDaysBack': syncDaysBack},
    );
  }

  Future<void> stopBackgroundSync() async {
    await _run<void>('stopBackgroundSync', _service.stopBackgroundSync);
  }

  Future<void> resetAnchors() async {
    await _run<void>('resetAnchors', _service.resetAnchors);
  }

  Future<void> resumeSync() async {
    await _run<void>('resumeSync', _service.resumeSync);
  }

  Future<void> clearSyncSession() async {
    await _run<void>('clearSyncSession', _service.clearSyncSession);
  }

  Future<void> refreshSyncStatus() async {
    final status = await _run<Map<String, dynamic>>(
      'getSyncStatus',
      _service.getSyncStatus,
    );
    if (status != null) {
      _lastSyncStatus = status;
      notifyListeners();
    }
  }

  Future<void> refreshStoredCredentials() async {
    final creds = await _run<Map<String, dynamic>>(
      'getStoredCredentials',
      _service.getStoredCredentials,
    );
    if (creds != null) {
      _lastStoredCreds = creds;
      notifyListeners();
    }
  }

  Future<void> refreshAvailableProviders() async {
    final list = await _run<List<AvailableProvider>>(
      'getAvailableProviders',
      _service.getAvailableProviders,
    );
    if (list != null) {
      _availableProviders = list;
      notifyListeners();
    }
  }

  Future<void> setProvider(AndroidHealthProvider p) async {
    await _run<void>('setProvider(${p.id})', () => _service.setProvider(p));
  }

  bool supportsMetric(HealthMetric m) => _service.supportsMetric(m);

  void clearLogs() {
    _events.clear();
    notifyListeners();
  }

  String eventsAsJsonLines() =>
      _events.map((e) => e.toJson().toString()).join('\n');
}
