class AlertEvaluator {
  /// Evalúa las lecturas actuales contra los umbrales estadísticos del perfil.
  /// Retorna un mapa con las banderas de alerta activas para los 5 sensores.
  static Map<String, bool> evaluate(Map<String, dynamic> reading, Map<String, dynamic> thresholds) {
    return {
      'alert_posture': _isOutOfRange(reading['distance_mm'], thresholds['posture']),
      'alert_temp': _isOutOfRange(reading['temperature'], thresholds['temp']),
      'alert_noise': _isOutOfRange(reading['noise_peak'], thresholds['noise']),
      'alert_light': _isOutOfRange(reading['lux'], thresholds['light']),
      'alert_humidity': _isOutOfRange(reading['humidity'], thresholds['humidity']),
    };
  }

  static bool _isOutOfRange(dynamic value, dynamic threshold) {
    if (value == null || threshold == null) return false;
    
    try {
      final val = (value as num).toDouble();
      final min = (threshold['min'] as num).toDouble();
      final max = (threshold['max'] as num).toDouble();
      
      return val < min || val > max;
    } catch (e) {
      return false;
    }
  }
}
