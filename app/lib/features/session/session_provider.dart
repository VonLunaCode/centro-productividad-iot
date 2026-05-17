import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/services/foreground_task_handler.dart';

class SessionState {
  final bool isActive;
  final bool isLoading;
  final bool isPaused;
  final int? activeProfileId;

  SessionState({
    this.isActive = false,
    this.isLoading = false,
    this.isPaused = false,
    this.activeProfileId,
  });

  SessionState copyWith({bool? isActive, bool? isLoading, bool? isPaused, int? activeProfileId}) {
    return SessionState(
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      isPaused: isPaused ?? this.isPaused,
      activeProfileId: activeProfileId ?? this.activeProfileId,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(SessionState());

  Future<bool> startSession(int profileId) async {
    state = SessionState(isLoading: true);
    try {
      final response = await ApiClient.post(Endpoints.sessionStart, {
        'device_id': 'esp32-01',
        'profile_id': profileId,
      });
      if (response.statusCode == 201) {
        state = SessionState(isActive: true, isLoading: false, activeProfileId: profileId);
        await _startForegroundService();
        return true;
      }
      state = SessionState(isActive: false, isLoading: false);
      return false;
    } catch (e) {
      state = SessionState(isActive: false, isLoading: false);
      return false;
    }
  }

  void pauseSession() {
    state = state.copyWith(isPaused: true);
    FlutterForegroundTask.updateService(
      notificationTitle: 'Centro de Productividad',
      notificationText: '⏸ Sesión en pausa',
    );
  }

  void resumeSession() {
    state = state.copyWith(isPaused: false);
    FlutterForegroundTask.updateService(
      notificationTitle: 'Centro de Productividad',
      notificationText: 'Monitoreando tu ambiente de trabajo...',
    );
  }

  Future<void> stopSession() async {
    state = SessionState(isLoading: true, isActive: true);
    try {
      await ApiClient.post(Endpoints.sessionStop, {});
      state = SessionState(isActive: false, isLoading: false);
    } catch (e) {
      state = SessionState(isActive: false, isLoading: false);
    } finally {
      await _stopForegroundService();
    }
  }

  Future<void> _startForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Centro de Productividad',
      notificationText: 'Monitoreando tu ambiente de trabajo...',
      callback: startForegroundCallback,
    );
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});
