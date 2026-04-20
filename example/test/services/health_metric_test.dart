import 'package:flutter_test/flutter_test.dart';
import 'package:open_wearables_health_sdk_example/services/health_metric.dart';

void main() {
  group('HealthMetric', () {
    test('has the 11 Cureocity metric values', () {
      expect(HealthMetric.values.length, 11);
      expect(HealthMetric.values, containsAll([
        HealthMetric.steps,
        HealthMetric.sleepDuration,
        HealthMetric.heartrate,
        HealthMetric.stressScore,
        HealthMetric.breathingRate,
        HealthMetric.bodyTemperature,
        HealthMetric.bloodPressure,
        HealthMetric.bodyComposition,
        HealthMetric.hrv,
        HealthMetric.spo2,
        HealthMetric.calories,
      ]));
    });
  });
}
