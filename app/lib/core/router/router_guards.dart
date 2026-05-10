import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/token_storage.dart';
import 'app_router.dart';

class RouterGuards {
  /// Redirige al login si no hay un token válido presente.
  static FutureOr<String?> requiresAuth(BuildContext context, GoRouterState state) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      return AppRoutes.login;
    }
    return null;
  }

  /// Redirige a la pantalla de sesión si el usuario ya está logueado e intenta ir al login.
  static FutureOr<String?> redirectIfAuthenticated(BuildContext context, GoRouterState state) async {
    final token = await TokenStorage.getToken();
    if (token != null) {
      return AppRoutes.home;
    }
    return null;
  }
}
