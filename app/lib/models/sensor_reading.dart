class SensorData {
  final int distanceMm;
  final double temperatureC;
  final double humidityPct;
  final int lightRaw;
  final int noisePeak;

  const SensorData({
    required this.distanceMm,
    required this.temperatureC,
    required this.humidityPct,
    required this.lightRaw,
    required this.noisePeak,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
        distanceMm: json['distance_mm'] as int,
        temperatureC: (json['temperature_c'] as num).toDouble(),
        humidityPct: (json['humidity_pct'] as num).toDouble(),
        lightRaw: json['light_raw'] as int,
        noisePeak: json['noise_peak'] as int,
      );
}

class Alerts {
  final bool posture;
  final bool lowLight;

  const Alerts({required this.posture, required this.lowLight});

  factory Alerts.fromJson(Map<String, dynamic> json) => Alerts(
        posture: json['posture'] as bool,
        lowLight: json['low_light'] as bool,
      );

  bool get hasAlert => posture || lowLight;
}

class SensorReading {
  final String deviceId;
  final int ts;
  final SensorData sensors;
  final Alerts alerts;

  const SensorReading({
    required this.deviceId,
    required this.ts,
    required this.sensors,
    required this.alerts,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
        deviceId: json['device_id'] as String,
        ts: json['ts'] as int,
        sensors: SensorData.fromJson(json['sensors'] as Map<String, dynamic>),
        alerts: Alerts.fromJson(json['alerts'] as Map<String, dynamic>),
      );
}
