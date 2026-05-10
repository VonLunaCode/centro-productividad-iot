import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/storage/token_storage.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? username;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.username,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? username,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    try {
      final meResponse = await ApiClient.get(Endpoints.me);
      if (meResponse.statusCode == 200) {
        final user = jsonDecode(meResponse.body);
        state = state.copyWith(
          isAuthenticated: true,
          username: user['username'] as String?,
        );
      } else {
        await TokenStorage.deleteToken();
      }
    } catch (_) {
      await TokenStorage.deleteToken();
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient.post(Endpoints.login, {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await TokenStorage.saveToken(data['access_token']);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          username: username,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Credenciales inválidas. Verifica con el administrador.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo conectar con el servidor.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
