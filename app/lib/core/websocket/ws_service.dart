import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/endpoints.dart';
import '../storage/token_storage.dart';

class WsService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();
  bool _isConnecting = false;

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<void> connect() async {
    if (_isConnecting || _channel != null) return;
    _isConnecting = true;

    try {
      final token = await TokenStorage.getToken();
      if (token == null) return;

      // Usar ws:// o wss:// según el entorno (Backend v2 usa WebSocket)
      final uri = Uri.parse(Endpoints.baseUrl.replaceFirst('http', 'ws') + '/ws?token=$token');
      
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            _controller.add(decoded);
          } catch (e) {
            // Ignorar errores de parseo
          }
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
    Timer(const Duration(seconds: 5), () => connect());
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
