/// Cureocity health metrics — verbatim copy of the enum from
/// CureocityApps/packages/health_integration/lib/src/models/health_metric.dart.
/// Kept identical so sub-project C can drop this demo's service class into
/// that package with zero rename.
enum HealthMetric {
  steps,
  sleepDuration,
  heartrate,
  stressScore,
  breathingRate,
  bodyTemperature,
  bloodPressure,
  bodyComposition,
  hrv,
  spo2,
  calories,
}
