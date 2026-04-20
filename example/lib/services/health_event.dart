enum HealthEventLevel { ok, info, err }

class HealthEvent {
  const HealthEvent({
    required this.timestamp,
    required this.level,
    required this.message,
    this.errorClass,
    this.context,
  });

  final DateTime timestamp;
  final HealthEventLevel level;
  final String message;
  final String? errorClass;
  final Map<String, dynamic>? context;

  String toLogLine() {
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    final ss = timestamp.second.toString().padLeft(2, '0');
    final tag = switch (level) {
      HealthEventLevel.ok => 'OK',
      HealthEventLevel.info => 'INFO',
      HealthEventLevel.err => 'ERR',
    };
    final err = errorClass != null ? ' [$errorClass]' : '';
    return '$hh:$mm:$ss [$tag]$err $message';
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        if (errorClass != null) 'errorClass': errorClass,
        if (context != null) 'context': context,
      };
}
