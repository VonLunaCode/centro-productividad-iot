import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../profiles/profiles_provider.dart';

class SessionState {
  final bool isActive;
  final bool isLoading;

  SessionState({this.isActive = false, this.isLoading = false});
}

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref ref;

  SessionNotifier(this.ref) : super(SessionState());

  Future<bool> startSession() async {
    state = SessionState(isLoading: true);
    try {
      final response = await ApiClient.post(Endpoints.sessionStart, {});
      if (response.statusCode == 200) {
        // Iniciar servicio foreground aquí en el futuro (PR 3 final)
        state = SessionState(isActive: true, isLoading: false);
        return true;
      }
      state = SessionState(isActive: false, isLoading: false);
      return false;
    } catch (e) {
      state = SessionState(isActive: false, isLoading: false);
      return false;
    }
  }

  Future<void> stopSession() async {
    state = SessionState(isLoading: true, isActive: true);
    try {
      await ApiClient.post(Endpoints.sessionStop, {});
      await FlutterForegroundTask.stopService();
      state = SessionState(isActive: false, isLoading: false);
    } catch (e) {
      state = SessionState(isActive: false, isLoading: false);
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
