import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class GameClient {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onDisconnect;

  void connect(String ip, String nombre) {
    final uri = Uri.parse('ws://$ip:8080');
    
    try {
      _channel = WebSocketChannel.connect(uri);

      // Enviar mensaje de unión al conectar
      _channel!.sink.add(jsonEncode({
        'type': 'join',
        'nombre': nombre,
      }));

      _channel!.stream.listen(
        (message) {
          if (onMessageReceived != null) {
            onMessageReceived!(jsonDecode(message));
          }
        },
        onDone: () {
          if (onDisconnect != null) onDisconnect!();
        },
        onError: (error) {
          print('Error en el cliente: $error');
          if (onDisconnect != null) onDisconnect!();
        },
      );
    } catch (e) {
      print('Error al conectar: $e');
    }
  }

  void sendMessage(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
