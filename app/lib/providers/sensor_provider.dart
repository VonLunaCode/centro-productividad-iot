import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading.dart';
import '../services/ws_service.dart';

// WsService singleton
final wsServiceProvider = Provider<WsService>((ref) {
  final service = WsService();
  service.connect();
  ref.onDispose(service.dispose);
  return service;
});

// Stream of sensor readings
final sensorStreamProvider = StreamProvider<SensorReading>((ref) {
  final ws = ref.watch(wsServiceProvider);
  return ws.stream;
});

// Alert state derived from the sensor stream
final alertStateProvider = Provider<({bool posture, bool lowLight})>((ref) {
  final reading = ref.watch(sensorStreamProvider).valueOrNull;
  if (reading == null) return (posture: false, lowLight: false);
  return (
    posture: reading.alerts.posture,
    lowLight: reading.alerts.lowLight,
  );
});
