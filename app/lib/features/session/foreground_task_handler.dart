import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../core/websocket/ws_service.dart';

class MyTaskHandler extends TaskHandler {
  final WsService _wsService = WsService();
  StreamSubscription? _wsSubscription;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Recuperar token y conectar WS
    // Nota: TokenStorage puede no funcionar directo en isolate si usa platform channels complejos,
    // pero flutter_secure_storage suele ser compatible o se puede pasar el token al iniciar.
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // Tareas repetitivas si son necesarias
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _wsSubscription?.cancel();
    _wsService.disconnect();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
