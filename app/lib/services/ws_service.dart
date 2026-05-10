import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../models/sensor_reading.dart';

class WsService {
  WebSocketChannel? _channel;
  final _controller = StreamController<SensorReading>.broadcast();

  Stream<SensorReading> get stream => _controller.stream;

  void connect() {
    _disconnect();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiConstants.wsUrl));
      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String);
            _controller.add(SensorReading.fromJson(data));
          } catch (_) {}
        },
        onDone: () => _reconnect(),
        onError: (_) => _reconnect(),
      );
    } catch (_) {
      _reconnect();
    }
  }

  void _disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 3), connect);
  }

  void dispose() {
    _disconnect();
    _controller.close();
  }
}
