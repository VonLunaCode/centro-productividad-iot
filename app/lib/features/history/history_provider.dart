import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'models/session_history.dart';

class HistoryState {
  final List<SessionHistory> sessions;
  final bool isLoading;
  final String? error;

  HistoryState({this.sessions = const [], this.isLoading = false, this.error});
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(HistoryState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = HistoryState(isLoading: true);
    try {
      final response = await ApiClient.get(Endpoints.sessionHistory);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = HistoryState(sessions: data.map((e) => SessionHistory.fromJson(e)).toList());
      } else {
        state = HistoryState(error: 'Error al cargar historial');
      }
    } catch (_) {
      state = HistoryState(error: 'Sin conexión');
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
