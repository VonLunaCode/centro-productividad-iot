class SessionHistoryItem {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? durationMinutes;
  final String? profileName;
  final int totalReadings;
  final double postureAlertPct;
  final double tempAlertPct;
  final double noiseAlertPct;
  final double lightAlertPct;
  final double humidityAlertPct;

  SessionHistoryItem({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.profileName,
    required this.totalReadings,
    required this.postureAlertPct,
    required this.tempAlertPct,
    required this.noiseAlertPct,
    required this.lightAlertPct,
    required this.humidityAlertPct,
  });

  factory SessionHistoryItem.fromJson(Map<String, dynamic> json) {
    return SessionHistoryItem(
      id: json['id'],
      startedAt: DateTime.parse(json['started_at']).toLocal(),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']).toLocal() : null,
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble(),
      profileName: json['profile_name'],
      totalReadings: json['total_readings'] ?? 0,
      postureAlertPct: (json['posture_alert_pct'] as num?)?.toDouble() ?? 0,
      tempAlertPct: (json['temp_alert_pct'] as num?)?.toDouble() ?? 0,
      noiseAlertPct: (json['noise_alert_pct'] as num?)?.toDouble() ?? 0,
      lightAlertPct: (json['light_alert_pct'] as num?)?.toDouble() ?? 0,
      humidityAlertPct: (json['humidity_alert_pct'] as num?)?.toDouble() ?? 0,
    );
  }

  String get durationFormatted {
    if (durationMinutes == null) return '--';
    final mins = durationMinutes!.round();
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String get dominantAlert {
    final alerts = {
      'Postura': postureAlertPct,
      'Temperatura': tempAlertPct,
      'Ruido': noiseAlertPct,
      'Iluminación': lightAlertPct,
      'Humedad': humidityAlertPct,
    };
    final max = alerts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return max.value > 0 ? max.key : 'Ninguna';
  }
}
