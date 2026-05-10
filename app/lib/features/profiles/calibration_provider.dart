import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/websocket/websocket_provider.dart';
import 'profiles_provider.dart';

enum CalibrationStatus { idle, inProgress, success, error }

class CalibrationState {
  final CalibrationStatus status;
  final int secondsRemaining;
  final String? error;

  CalibrationState({
    this.status = CalibrationStatus.idle,
    this.secondsRemaining = 30,
    this.error,
  });

  CalibrationState copyWith({
    CalibrationStatus? status,
    int? secondsRemaining,
    String? error,
  }) {
    return CalibrationState(
      status: status ?? this.status,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      error: error ?? this.error,
    );
  }
}

class CalibrationNotifier extends StateNotifier<CalibrationState> {
  final Ref ref;
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  final List<Map<String, dynamic>> _samples = [];

  CalibrationNotifier(this.ref) : super(CalibrationState());

  Future<void> startCalibration(int profileId) async {
    state = state.copyWith(status: CalibrationStatus.inProgress, secondsRemaining: 30);
    _samples.clear();

    try {
      final response = await ApiClient.post(Endpoints.calibrateStart(profileId), {});
      if (response.statusCode == 200) {
        _subscribeToSensors();
        _startTimer(profileId);
      } else {
        state = state.copyWith(status: CalibrationStatus.error, error: 'Error al iniciar');
      }
    } catch (e) {
      state = state.copyWith(status: CalibrationStatus.error, error: 'Sin conexión');
    }
  }

  void _subscribeToSensors() {
    _wsSub?.cancel();
    _wsSub = ref.read(wsServiceProvider).stream.listen((msg) {
      if (msg['type'] == 'sensor_update') {
        final s = msg['sensors'];
        if (s is Map<String, dynamic>) _samples.add(s);
      }
    });
  }

  void _startTimer(int profileId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.secondsRemaining > 0) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        timer.cancel();
        _wsSub?.cancel();
        await _finishCalibration(profileId);
      }
    });
  }

  Future<void> _finishCalibration(int profileId) async {
    state = state.copyWith(status: CalibrationStatus.inProgress);
    try {
      if (_samples.isEmpty) {
        state = state.copyWith(status: CalibrationStatus.error, error: 'No se recibieron datos del sensor. Asegurate de que el ESP32 esté conectado.');
        return;
      }
      final response = await ApiClient.post(Endpoints.calibrateFinish(profileId), {'samples': _samples});
      if (response.statusCode == 200) {
        state = state.copyWith(status: CalibrationStatus.success);
        await ref.read(profilesProvider.notifier).fetchProfiles();
      } else {
        state = state.copyWith(status: CalibrationStatus.error, error: 'Error al finalizar (${response.statusCode})');
      }
    } catch (e) {
      state = state.copyWith(status: CalibrationStatus.error, error: 'Error de red al finalizar');
    }
  }

  void reset() {
    _timer?.cancel();
    _wsSub?.cancel();
    _samples.clear();
    state = CalibrationState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }
}

final calibrationProvider = StateNotifierProvider<CalibrationNotifier, CalibrationState>((ref) {
  return CalibrationNotifier(ref);
});
