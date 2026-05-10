import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ws_service.dart';

final wsServiceProvider = Provider<WsService>((ref) {
  final service = WsService();
  ref.onDispose(() => service.disconnect());
  return service;
});

final websocketProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(wsServiceProvider);
  service.connect();
  return service.stream;
});

void reconnectWebSocket(WidgetRef ref) {
  ref.read(wsServiceProvider).forceReconnect();
}

// Mantiene el estado online/offline del ESP32 de forma persistente
final deviceOnlineProvider = StateNotifierProvider<DeviceStatusNotifier, bool>((ref) {
  final notifier = DeviceStatusNotifier();
  ref.listen(websocketProvider, (_, next) {
    if (next.hasValue) notifier.onMessage(next.value!);
  });
  return notifier;
});

class DeviceStatusNotifier extends StateNotifier<bool> {
  DeviceStatusNotifier() : super(false);

  void onMessage(Map<String, dynamic> msg) {
    final type = msg['type'];
    if (type == 'device_status') {
      state = msg['status'] == 'online';
    } else if (type == 'sensor_update') {
      state = true;
    }
  }
}
