import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'models/session_history.dart';

class HistoryState {
  final List<SessionHistory> sessions;
  final bool isLoading;
  final String? error;

  HistoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<SessionHistory>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(HistoryState()) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Nota: En v2, /readings devuelve las lecturas, 
      // pero necesitaríamos un endpoint de /sessions si queremos la lista de sesiones.
      // Asumiré que el backend tiene /sessions/history o similar.
      final response = await ApiClient.get('/sessions/history');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final sessions = data.map((e) => SessionHistory.fromJson(e)).toList();
        state = state.copyWith(sessions: sessions, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Error al cargar historial');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Sin conexión');
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
