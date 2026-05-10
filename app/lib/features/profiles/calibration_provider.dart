import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
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

  CalibrationNotifier(this.ref) : super(CalibrationState());

  Future<void> startCalibration(int profileId) async {
    state = state.copyWith(status: CalibrationStatus.inProgress, secondsRemaining: 30);
    try {
      final response = await ApiClient.post(Endpoints.calibrateStart(profileId), {});
      if (response.statusCode == 200) {
        _startTimer(profileId);
      } else {
        state = state.copyWith(status: CalibrationStatus.error, error: 'Error al iniciar');
      }
    } catch (e) {
      state = state.copyWith(status: CalibrationStatus.error, error: 'Sin conexión');
    }
  }

  void _startTimer(int profileId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.secondsRemaining > 0) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        timer.cancel();
        await _finishCalibration(profileId);
      }
    });
  }

  Future<void> _finishCalibration(int profileId) async {
    state = state.copyWith(status: CalibrationStatus.inProgress);
    try {
      final response = await ApiClient.post(Endpoints.calibrateFinish(profileId), {});
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
    state = CalibrationState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final calibrationProvider = StateNotifierProvider<CalibrationNotifier, CalibrationState>((ref) {
  return CalibrationNotifier(ref);
});
