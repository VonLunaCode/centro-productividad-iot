import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/audio_alarm_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/websocket/alert_evaluator.dart';
import '../../core/websocket/websocket_provider.dart';
import '../profiles/profiles_provider.dart';

class AlertState {
  final Map<String, bool> alerts;
  final bool hasActiveAlert;
  final String? primaryAlertMessage;
  final String? alertDetail;
  final String? alertAdvice;
  final bool isSnoozed;

  AlertState({
    this.alerts = const {},
    this.hasActiveAlert = false,
    this.primaryAlertMessage,
    this.alertDetail,
    this.alertAdvice,
    this.isSnoozed = false,
  });

  AlertState copyWith({
    Map<String, bool>? alerts,
    bool? hasActiveAlert,
    String? primaryAlertMessage,
    String? alertDetail,
    String? alertAdvice,
    bool? isSnoozed,
  }) {
    return AlertState(
      alerts: alerts ?? this.alerts,
      hasActiveAlert: hasActiveAlert ?? this.hasActiveAlert,
      primaryAlertMessage: primaryAlertMessage ?? this.primaryAlertMessage,
      alertDetail: alertDetail ?? this.alertDetail,
      alertAdvice: alertAdvice ?? this.alertAdvice,
      isSnoozed: isSnoozed ?? this.isSnoozed,
    );
  }
}

class AlertNotifier extends StateNotifier<AlertState> {
  final Ref ref;
  final Map<String, int> _consecutiveCounts = {};
  Timer? _snoozeTimer;

  // 4 lecturas × 2s = 8 segundos sostenidos antes de alertar
  static const int _requiredCount = 4;

  AlertNotifier(this.ref) : super(AlertState()) {
    _init();
  }

  void _init() {
    ref.listen(websocketProvider, (previous, next) {
      if (state.isSnoozed || state.hasActiveAlert) return;

      final msg = next.value;
      if (msg == null || msg['type'] != 'sensor_update') return;

      final reading = (msg['sensors'] as Map<String, dynamic>?) ?? {};
      final profilesState = ref.read(profilesProvider);
      final activeProfile = profilesState.activeProfile;

      if (activeProfile == null || activeProfile.thresholds == null) return;

      final thresholds = activeProfile.thresholds!;
      final results = AlertEvaluator.evaluate(reading, thresholds);

      String? firstTriggered;
      for (final entry in results.entries) {
        if (entry.value) {
          _consecutiveCounts[entry.key] = (_consecutiveCounts[entry.key] ?? 0) + 1;
          if (_consecutiveCounts[entry.key]! >= _requiredCount && firstTriggered == null) {
            firstTriggered = entry.key;
          }
        } else {
          _consecutiveCounts[entry.key] = 0;
        }
      }

      if (firstTriggered != null) {
        final title = _getTitle(firstTriggered);
        final detail = _buildDetail(firstTriggered, reading, thresholds);
        final advice = _getAdvice(firstTriggered);

        state = state.copyWith(
          alerts: results,
          hasActiveAlert: true,
          primaryAlertMessage: title,
          alertDetail: detail,
          alertAdvice: advice,
        );

        NotificationService.showAlert(title: title, body: detail);
        AudioAlarmService.start();
      }
    });
  }

  Future<void> dismiss() async {
    _consecutiveCounts.clear();
    await AudioAlarmService.stop();
    await NotificationService.cancelAlert();
    state = AlertState();
  }

  Future<void> snooze() async {
    _snoozeTimer?.cancel();
    _consecutiveCounts.clear();
    await AudioAlarmService.stop();
    await NotificationService.cancelAlert();
    state = AlertState(isSnoozed: true);
    _snoozeTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) state = state.copyWith(isSnoozed: false);
    });
  }

  String _getTitle(String sensor) {
    switch (sensor) {
      case 'alert_posture':   return 'Postura encorvada';
      case 'alert_temp':      return 'Temperatura fuera de rango';
      case 'alert_noise':     return 'Nivel de ruido excesivo';
      case 'alert_light':     return 'Iluminación inadecuada';
      case 'alert_humidity':  return 'Humedad fuera de rango';
      default:                return 'Anomalía detectada';
    }
  }

  String _buildDetail(String sensor, Map<String, dynamic> reading, Map<String, dynamic> thresholds) {
    switch (sensor) {
      case 'alert_posture':
        final val = (reading['distance_mm'] as num?)?.toStringAsFixed(0) ?? '?';
        final t = thresholds['posture'];
        final minVal = (t?['min'] as num?)?.toDouble() ?? 0;
        final maxVal = (t?['max'] as num?)?.toDouble() ?? 0;
        final current = (reading['distance_mm'] as num?)?.toDouble() ?? 0;
        if (current < minVal) {
          return '$val mm — distancia menor al umbral ${minVal.toStringAsFixed(0)} mm';
        }
        return '$val mm — distancia mayor al umbral ${maxVal.toStringAsFixed(0)} mm';
      case 'alert_temp':
        final val = (reading['temperature'] as num?)?.toStringAsFixed(1) ?? '?';
        final t = thresholds['temp'];
        final min = (t?['min'] as num?)?.toStringAsFixed(1) ?? '?';
        final max = (t?['max'] as num?)?.toStringAsFixed(1) ?? '?';
        return '$val °C — rango normal: $min - $max °C';
      case 'alert_noise':
        final val = (reading['noise_peak'] as num?)?.toStringAsFixed(0) ?? '?';
        final t = thresholds['noise'];
        final max = (t?['max'] as num?)?.toStringAsFixed(0) ?? '?';
        return '$val — supera el umbral de $max';
      case 'alert_light':
        final val = (reading['lux'] as num?)?.toStringAsFixed(0) ?? '?';
        final t = thresholds['light'];
        final min = (t?['min'] as num?)?.toStringAsFixed(0) ?? '?';
        final max = (t?['max'] as num?)?.toStringAsFixed(0) ?? '?';
        return '$val lux — rango normal: $min - $max lux';
      case 'alert_humidity':
        final val = (reading['humidity'] as num?)?.toStringAsFixed(0) ?? '?';
        final t = thresholds['humidity'];
        final min = (t?['min'] as num?)?.toStringAsFixed(0) ?? '?';
        final max = (t?['max'] as num?)?.toStringAsFixed(0) ?? '?';
        return '$val% — rango normal: $min - $max%';
      default:
        return '';
    }
  }

  String _getAdvice(String sensor) {
    switch (sensor) {
      case 'alert_posture':
        return 'Aleja el torso de la pantalla y endereza la espalda para recuperar una postura saludable.';
      case 'alert_temp':
        return 'Ajustá la ventilación o el aire acondicionado para mantener una temperatura confortable.';
      case 'alert_noise':
        return 'El nivel de ruido puede afectar tu concentración. Considerá usar auriculares o reducir la fuente de sonido.';
      case 'alert_light':
        return 'Ajustá la iluminación del cuarto para evitar fatiga visual.';
      case 'alert_humidity':
        return 'La humedad fuera de rango puede afectar tu comodidad y concentración.';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _snoozeTimer?.cancel();
    super.dispose();
  }
}

final alertProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  return AlertNotifier(ref);
});
