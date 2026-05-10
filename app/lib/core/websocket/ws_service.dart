import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/endpoints.dart';
import '../storage/token_storage.dart';

class WsService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();
  bool _isConnecting = false;
  int _reconnectDelay = 3;

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<void> connect() async {
    if (_isConnecting || _channel != null) return;
    _isConnecting = true;

    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        _isConnecting = false;
        return;
      }

      final uri = Uri.parse('${Endpoints.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _reconnectDelay = 3;
      _channel!.stream.listen(
        (data) {
          try {
            _controller.add(jsonDecode(data) as Map<String, dynamic>);
          } catch (_) {}
        },
        onDone: () => _handleReconnect(),
        onError: (_) => _handleReconnect(),
      );
    } catch (e) {
      _handleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleReconnect() {
    _channel = null;
    final delay = _reconnectDelay;
    _reconnectDelay = (_reconnectDelay * 2).clamp(3, 60);
    Timer(Duration(seconds: delay), () => connect());
  }

  void forceReconnect() {
    _channel?.sink.close();
    _channel = null;
    _reconnectDelay = 3;
    connect();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
