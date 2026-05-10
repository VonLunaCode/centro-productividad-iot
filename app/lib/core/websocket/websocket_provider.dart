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
