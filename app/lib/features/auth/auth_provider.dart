import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/storage/token_storage.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await TokenStorage.getToken();
    if (token != null) {
      state = state.copyWith(isAuthenticated: true);
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
        final token = data['access_token'];
        await TokenStorage.saveToken(token);
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        return true;
      } else {
        // En v2, el backend devuelve 401 para fallos de auth
        state = state.copyWith(
          isLoading: false, 
          error: 'Credenciales inválidas. Verifica con el administrador.'
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: 'No se pudo conectar con el servidor.'
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
