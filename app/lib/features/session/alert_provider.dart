import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/websocket/alert_evaluator.dart';
import '../../core/websocket/websocket_provider.dart';
import '../profiles/profiles_provider.dart';

class AlertState {
  final Map<String, bool> alerts;
  final bool hasActiveAlert;
  final String? primaryAlertMessage;

  AlertState({
    this.alerts = const {},
    this.hasActiveAlert = false,
    this.primaryAlertMessage,
  });

  AlertState copyWith({
    Map<String, bool>? alerts,
    bool? hasActiveAlert,
    String? primaryAlertMessage,
  }) {
    return AlertState(
      alerts: alerts ?? this.alerts,
      hasActiveAlert: hasActiveAlert ?? this.hasActiveAlert,
      primaryAlertMessage: primaryAlertMessage ?? this.primaryAlertMessage,
    );
  }
}

class AlertNotifier extends StateNotifier<AlertState> {
  final Ref ref;

  AlertNotifier(this.ref) : super(AlertState()) {
    _init();
  }

  void _init() {
    // Escuchar el stream del WebSocket
    ref.listen(websocketProvider, (previous, next) {
      final reading = next.value;
      if (reading == null) return;

      final profilesState = ref.read(profilesProvider);
      final activeProfile = profilesState.activeProfile;
      
      if (activeProfile == null || activeProfile.thresholds == null) return;

      final results = AlertEvaluator.evaluate(reading, activeProfile.thresholds!);
      final isAnyAlert = results.values.any((v) => v);

      state = state.copyWith(
        alerts: results,
        hasActiveAlert: isAnyAlert,
        primaryAlertMessage: _getPrimaryMessage(results),
      );
    });
  }

  String? _getPrimaryMessage(Map<String, bool> alerts) {
    if (alerts['alert_posture'] == true) return 'Postura encorvada';
    if (alerts['alert_noise'] == true) return 'Nivel de ruido excesivo';
    if (alerts['alert_temp'] == true) return 'Temperatura fuera de rango';
    if (alerts['alert_light'] == true) return 'Iluminación inadecuada';
    if (alerts['alert_humidity'] == true) return 'Humedad fuera de rango';
    return null;
  }

  void dismiss() {
    state = state.copyWith(hasActiveAlert: false, alerts: {});
  }
}

final alertProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  return AlertNotifier(ref);
});
