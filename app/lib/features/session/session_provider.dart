import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

class SessionState {
  final bool isActive;
  final bool isLoading;
  final int? activeProfileId;

  SessionState({this.isActive = false, this.isLoading = false, this.activeProfileId});
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
      state = SessionState(isActive: false, isLoading: false);
    } catch (e) {
      state = SessionState(isActive: false, isLoading: false);
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});
