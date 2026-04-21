/// Plain DTOs for the Open Wearables backend REST API. Fields are
/// intentionally minimal — only what the demo UI (Batch B) consumes.
/// Kept separate from the SDK-facing types in `../`.

class SourceMetadata {
  const SourceMetadata({required this.provider, this.device});
  final String provider;
  final String? device;

  factory SourceMetadata.fromJson(Map<String, dynamic> j) => SourceMetadata(
        provider: j['provider'] as String? ?? 'unknown',
        device: j['device'] as String?,
      );
}

class ActivitySummary {
  const ActivitySummary({
    required this.date,
    required this.source,
    this.steps,
    this.distanceMeters,
    this.floorsClimbed,
    this.activeCaloriesKcal,
    this.totalCaloriesKcal,
    this.activeMinutes,
    this.heartRate,
  });

  final String date;
  final SourceMetadata source;
  final int? steps;
  final double? distanceMeters;
  final int? floorsClimbed;
  final double? activeCaloriesKcal;
  final double? totalCaloriesKcal;
  final int? activeMinutes;
  final Map<String, dynamic>? heartRate;

  factory ActivitySummary.fromJson(Map<String, dynamic> j) => ActivitySummary(
        date: j['date'] as String,
        source: SourceMetadata.fromJson(j['source'] as Map<String, dynamic>),
        steps: (j['steps'] as num?)?.toInt(),
        distanceMeters: (j['distance_meters'] as num?)?.toDouble(),
        floorsClimbed: (j['floors_climbed'] as num?)?.toInt(),
        activeCaloriesKcal: (j['active_calories_kcal'] as num?)?.toDouble(),
        totalCaloriesKcal: (j['total_calories_kcal'] as num?)?.toDouble(),
        activeMinutes: (j['active_minutes'] as num?)?.toInt(),
        heartRate: j['heart_rate'] as Map<String, dynamic>?,
      );
}

class SleepSummary {
  const SleepSummary({
    required this.date,
    required this.source,
    this.durationMinutes,
    this.efficiencyPercent,
    this.avgHeartRateBpm,
    this.avgHrvSdnnMs,
    this.avgRespiratoryRate,
    this.avgSpo2Percent,
  });

  final String date;
  final SourceMetadata source;
  final int? durationMinutes;
  final double? efficiencyPercent;
  final int? avgHeartRateBpm;
  final double? avgHrvSdnnMs;
  final double? avgRespiratoryRate;
  final double? avgSpo2Percent;

  factory SleepSummary.fromJson(Map<String, dynamic> j) => SleepSummary(
        date: j['date'] as String,
        source: SourceMetadata.fromJson(j['source'] as Map<String, dynamic>),
        durationMinutes: (j['duration_minutes'] as num?)?.toInt(),
        efficiencyPercent: (j['efficiency_percent'] as num?)?.toDouble(),
        avgHeartRateBpm: (j['avg_heart_rate_bpm'] as num?)?.toInt(),
        avgHrvSdnnMs: (j['avg_hrv_sdnn_ms'] as num?)?.toDouble(),
        avgRespiratoryRate: (j['avg_respiratory_rate'] as num?)?.toDouble(),
        avgSpo2Percent: (j['avg_spo2_percent'] as num?)?.toDouble(),
      );
}

class RecoverySummary {
  const RecoverySummary({
    required this.date,
    required this.source,
    this.recoveryScore,
    this.restingHeartRateBpm,
    this.avgHrvSdnnMs,
    this.avgSpo2Percent,
    this.sleepDurationSeconds,
  });

  final String date;
  final SourceMetadata source;
  final int? recoveryScore;
  final int? restingHeartRateBpm;
  final double? avgHrvSdnnMs;
  final double? avgSpo2Percent;
  final int? sleepDurationSeconds;

  factory RecoverySummary.fromJson(Map<String, dynamic> j) => RecoverySummary(
        date: j['date'] as String,
        source: SourceMetadata.fromJson(j['source'] as Map<String, dynamic>),
        recoveryScore: (j['recovery_score'] as num?)?.toInt(),
        restingHeartRateBpm: (j['resting_heart_rate_bpm'] as num?)?.toInt(),
        avgHrvSdnnMs: (j['avg_hrv_sdnn_ms'] as num?)?.toDouble(),
        avgSpo2Percent: (j['avg_spo2_percent'] as num?)?.toDouble(),
        sleepDurationSeconds: (j['sleep_duration_seconds'] as num?)?.toInt(),
      );
}

class BodySlowChanging {
  const BodySlowChanging({
    this.weightKg,
    this.heightCm,
    this.bodyFatPercent,
    this.muscleMassKg,
    this.bmi,
    this.age,
  });
  final double? weightKg;
  final double? heightCm;
  final double? bodyFatPercent;
  final double? muscleMassKg;
  final double? bmi;
  final int? age;

  factory BodySlowChanging.fromJson(Map<String, dynamic> j) => BodySlowChanging(
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        heightCm: (j['height_cm'] as num?)?.toDouble(),
        bodyFatPercent: (j['body_fat_percent'] as num?)?.toDouble(),
        muscleMassKg: (j['muscle_mass_kg'] as num?)?.toDouble(),
        bmi: (j['bmi'] as num?)?.toDouble(),
        age: (j['age'] as num?)?.toInt(),
      );
}

class BodyLatest {
  const BodyLatest({
    this.bodyTemperatureCelsius,
    this.skinTemperatureCelsius,
    this.bloodPressure,
  });
  final double? bodyTemperatureCelsius;
  final double? skinTemperatureCelsius;
  final Map<String, dynamic>? bloodPressure;

  factory BodyLatest.fromJson(Map<String, dynamic> j) => BodyLatest(
        bodyTemperatureCelsius:
            (j['body_temperature_celsius'] as num?)?.toDouble(),
        skinTemperatureCelsius:
            (j['skin_temperature_celsius'] as num?)?.toDouble(),
        bloodPressure: j['blood_pressure'] as Map<String, dynamic>?,
      );
}

class BodySummary {
  const BodySummary({
    required this.source,
    required this.slowChanging,
    required this.latest,
  });
  final SourceMetadata source;
  final BodySlowChanging slowChanging;
  final BodyLatest latest;

  factory BodySummary.fromJson(Map<String, dynamic> j) => BodySummary(
        source: SourceMetadata.fromJson(j['source'] as Map<String, dynamic>),
        slowChanging: BodySlowChanging.fromJson(
            j['slow_changing'] as Map<String, dynamic>? ?? const {}),
        latest: BodyLatest.fromJson(
            j['latest'] as Map<String, dynamic>? ?? const {}),
      );
}
