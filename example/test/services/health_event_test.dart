import 'package:flutter_test/flutter_test.dart';
import 'package:open_wearables_health_sdk_example/services/health_event.dart';

void main() {
  group('HealthEvent', () {
    test('constructs with required fields', () {
      final ts = DateTime(2026, 4, 20, 10, 32, 45);
      final e = HealthEvent(
        timestamp: ts,
        level: HealthEventLevel.ok,
        message: 'configured',
      );
      expect(e.timestamp, ts);
      expect(e.level, HealthEventLevel.ok);
      expect(e.message, 'configured');
      expect(e.errorClass, isNull);
      expect(e.context, isNull);
    });

    test('toLogLine produces HH:MM:SS [LEVEL][class] message', () {
      final e = HealthEvent(
        timestamp: DateTime.utc(2026, 4, 20, 10, 32, 45),
        level: HealthEventLevel.err,
        message: 'signIn failed',
        errorClass: 'AuthError',
      );
      final line = e.toLogLine();
      expect(line, contains('10:32:45'));
      expect(line, contains('[ERR]'));
      expect(line, contains('signIn failed'));
      expect(line, contains('AuthError'));
    });

    test('toJson returns expected keys', () {
      final e = HealthEvent(
        timestamp: DateTime.utc(2026, 4, 20),
        level: HealthEventLevel.info,
        message: 'status',
        context: {'k': 'v'},
      );
      final j = e.toJson();
      expect(j['level'], 'info');
      expect(j['message'], 'status');
      expect(j['context'], {'k': 'v'});
      expect(j.containsKey('errorClass'), isFalse); // omitted when null
    });
  });
}
